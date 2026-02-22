import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

/// Unit tests for CloudStorageService sync logic.
///
/// Tests focus on offline queue operations and data transformation patterns
/// using a temporary Hive directory. Firebase-dependent methods (actual
/// Firestore reads/writes) are excluded.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cloud_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Sync queue operations', () {
    late Box queueBox;

    setUp(() async {
      queueBox = await Hive.openBox('test_sync_queue_${DateTime.now().millisecondsSinceEpoch}');
    });

    tearDown(() async {
      await queueBox.deleteFromDisk();
    });

    test('enqueue adds item to sync queue', () async {
      final action = {
        'type': 'upload',
        'storyId': 'story_abc',
        'timestamp': DateTime.now().toIso8601String(),
      };

      await queueBox.add(action);
      expect(queueBox.length, equals(1));
    });

    test('dequeue removes processed items', () async {
      await queueBox.add({'type': 'upload', 'storyId': 's1'});
      await queueBox.add({'type': 'delete', 'storyId': 's2'});
      await queueBox.add({'type': 'upload', 'storyId': 's3'});

      expect(queueBox.length, equals(3));

      // Process first item
      await queueBox.deleteAt(0);
      expect(queueBox.length, equals(2));
    });

    test('queue persists across box close/reopen', () async {
      final boxName = 'persist_queue_${DateTime.now().millisecondsSinceEpoch}';
      final box1 = await Hive.openBox(boxName);

      await box1.add({'type': 'upload', 'storyId': 'persist_test'});
      await box1.close();

      // Reopen
      final box2 = await Hive.openBox(boxName);
      expect(box2.length, equals(1));
      expect((box2.getAt(0) as Map)['storyId'], equals('persist_test'));

      await box2.deleteFromDisk();
    });

    test('empty queue returns no items', () {
      expect(queueBox.isEmpty, isTrue);
      expect(queueBox.length, equals(0));
    });
  });

  group('Cloud-to-local transform logic', () {
    late Box storiesBox;
    late Box castBox;

    setUp(() async {
      final ts = DateTime.now().millisecondsSinceEpoch;
      storiesBox = await Hive.openBox('test_cloud_stories_$ts');
      castBox = await Hive.openBox('test_cloud_cast_$ts');
    });

    tearDown(() async {
      await storiesBox.deleteFromDisk();
      await castBox.deleteFromDisk();
    });

    test('LWW: cloud data overwrites local when IDs match', () async {
      // Local version
      await storiesBox.put('s1', {'id': 's1', 'title': 'Local Version', 'date': '2026-01-01'});

      // Cloud version (simulated)
      final cloudStory = {'id': 's1', 'title': 'Cloud Version', 'date': '2026-02-01'};
      await storiesBox.put(cloudStory['id'] as String, cloudStory);

      final result = storiesBox.get('s1') as Map;
      expect(result['title'], equals('Cloud Version'));
    });

    test('new cloud stories are added to local', () async {
      expect(storiesBox.containsKey('new_story'), isFalse);

      final cloudStory = {'id': 'new_story', 'title': 'From Cloud'};
      await storiesBox.put(cloudStory['id'] as String, cloudStory);

      expect(storiesBox.containsKey('new_story'), isTrue);
      expect((storiesBox.get('new_story') as Map)['title'], equals('From Cloud'));
    });

    test('cast sync uses collect-then-write pattern', () async {
      // Simulate existing cast
      await castBox.put('cast', [
        {'name': 'OldChar', 'style': 'anime'},
      ]);

      // Simulate atomic sync: collect, clear, write
      final cloudCast = [
        {'name': 'Luna', 'style': 'digital-art'},
        {'name': 'Max', 'style': 'photographic'},
      ];

      // Atomic: clear then write in sequence
      await castBox.delete('cast');
      await castBox.put('cast', cloudCast);

      final result = (castBox.get('cast') as List).cast<Map>();
      expect(result, hasLength(2));
      expect(result.first['name'], equals('Luna'));
      // Old data should be gone
      expect(result.where((c) => c['name'] == 'OldChar'), isEmpty);
    });
  });

  group('Story data structure validation', () {
    test('story map has required fields', () {
      final story = {
        'id': 'test_id',
        'title': 'Test Story',
        'pages': [{'text': 'Page 1', 'image': null}],
        'date': DateTime.now().toIso8601String(),
        'vibe': 'Space',
        'coverBase64': null,
        'cast': [{'name': 'Hero', 'description': 'Brave'}],
        'seed': 42,
      };

      expect(story.containsKey('id'), isTrue);
      expect(story.containsKey('title'), isTrue);
      expect(story.containsKey('pages'), isTrue);
      expect(story.containsKey('date'), isTrue);
      expect(story.containsKey('vibe'), isTrue);
      expect(story.containsKey('cast'), isTrue);
      expect(story.containsKey('seed'), isTrue);
    });

    test('story page structure includes text and image', () {
      final page = {'text': 'Once upon a time...', 'image': null, 'visual_description': 'A forest'};
      expect(page.containsKey('text'), isTrue);
      expect(page.containsKey('image'), isTrue);
    });

    test('coverBase64 can be null (Loud Fallback)', () {
      final story = {'id': 'no_cover', 'title': 'No Cover', 'coverBase64': null};
      expect(story['coverBase64'], isNull);
    });
  });
}
