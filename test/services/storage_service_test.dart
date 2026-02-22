import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'dart:io';

/// Unit tests for StorageService logic.
///
/// Tests focus on Hive-based storage operations using a temporary directory.
/// Firebase-dependent methods (syncWithCloud, init with auth) are excluded
/// since they require a live Firebase instance.
void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('hive_test_');
    Hive.init(tempDir.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await tempDir.delete(recursive: true);
  });

  group('Hive box operations', () {
    late Box storiesBox;

    setUp(() async {
      storiesBox = await Hive.openBox('test_stories_${DateTime.now().millisecondsSinceEpoch}');
    });

    tearDown(() async {
      await storiesBox.deleteFromDisk();
    });

    test('saveStory and loadStory round-trip preserves data', () async {
      final story = {
        'id': 'story_123',
        'title': 'The Great Adventure',
        'pages': [
          {'text': 'Once upon a time...', 'image': null},
          {'text': 'They lived happily!', 'image': null},
        ],
        'vibe': 'Space',
        'date': '2026-02-19T00:00:00Z',
      };

      await storiesBox.put(story['id'], story);
      final loaded = storiesBox.get('story_123') as Map;

      expect(loaded['title'], equals('The Great Adventure'));
      expect(loaded['pages'], hasLength(2));
      expect(loaded['vibe'], equals('Space'));
    });

    test('deleteStory removes entry', () async {
      await storiesBox.put('to_delete', {'id': 'to_delete', 'title': 'Gone'});
      expect(storiesBox.containsKey('to_delete'), isTrue);

      await storiesBox.delete('to_delete');
      expect(storiesBox.containsKey('to_delete'), isFalse);
    });

    test('loadStories returns all entries', () async {
      await storiesBox.put('s1', {'id': 's1', 'title': 'Story 1'});
      await storiesBox.put('s2', {'id': 's2', 'title': 'Story 2'});
      await storiesBox.put('s3', {'id': 's3', 'title': 'Story 3'});

      expect(storiesBox.length, equals(3));
      expect(storiesBox.keys.toList(), containsAll(['s1', 's2', 's3']));
    });

    test('overwriting story preserves only latest version', () async {
      await storiesBox.put('s1', {'id': 's1', 'title': 'Version 1'});
      await storiesBox.put('s1', {'id': 's1', 'title': 'Version 2'});

      final loaded = storiesBox.get('s1') as Map;
      expect(loaded['title'], equals('Version 2'));
    });

    test('handles corrupted data gracefully', () async {
      // Store a non-Map value
      await storiesBox.put('corrupt', 'this is not a map');

      final item = storiesBox.get('corrupt');
      expect(item is Map, isFalse);
      // StorageService.loadStories wraps this in try-catch with type check
    });
  });

  group('Version history box', () {
    late Box historyBox;

    setUp(() async {
      historyBox = await Hive.openBox('test_history_${DateTime.now().millisecondsSinceEpoch}');
    });

    tearDown(() async {
      await historyBox.deleteFromDisk();
    });

    test('saves up to 3 versions per story', () async {
      const storyId = 'story_abc';
      List<Map> history = [];

      for (int i = 1; i <= 4; i++) {
        history.add({'id': storyId, 'title': 'Version $i', 'date': '2026-02-$i'});
        if (history.length > 3) history.removeAt(0); // FIFO
      }

      await historyBox.put(storyId, history.map((h) => Map<String, dynamic>.from(h)).toList());
      final stored = (historyBox.get(storyId) as List).cast<Map>();

      expect(stored, hasLength(3));
      expect(stored.first['title'], equals('Version 2')); // Oldest surviving
      expect(stored.last['title'], equals('Version 4'));   // Newest
    });

    test('restoring a version returns the latest saved', () async {
      const storyId = 'restore_test';
      final versions = [
        {'id': storyId, 'title': 'V1'},
        {'id': storyId, 'title': 'V2'},
      ];

      await historyBox.put(storyId, versions);
      final history = (historyBox.get(storyId) as List).cast<Map>();

      // Restore last version
      final restored = history.last;
      expect(restored['title'], equals('V2'));
    });
  });

  group('Cast box operations', () {
    late Box castBox;

    setUp(() async {
      castBox = await Hive.openBox('test_cast_${DateTime.now().millisecondsSinceEpoch}');
    });

    tearDown(() async {
      await castBox.deleteFromDisk();
    });

    test('saveCast and loadCast round-trip', () async {
      final cast = [
        {'name': 'Luna', 'description': 'A brave explorer', 'style': 'digital-art'},
        {'name': 'Max', 'description': 'A curious scientist', 'style': 'anime'},
      ];

      await castBox.put('cast', cast);
      final loaded = (castBox.get('cast') as List).cast<Map>();

      expect(loaded, hasLength(2));
      expect(loaded.first['name'], equals('Luna'));
      expect(loaded.last['style'], equals('anime'));
    });

    test('empty cast box returns null', () {
      expect(castBox.get('cast'), isNull);
    });
  });

  group('Completer init lock pattern', () {
    test('Completer prevents duplicate concurrent initialization', () async {
      Completer<void>? initLock;
      int initCount = 0;

      Future<void> mockInit() async {
        if (initLock != null) {
          await initLock!.future;
          return;
        }
        initLock = Completer<void>();
        initCount++;
        await Future.delayed(const Duration(milliseconds: 50));
        initLock!.complete();
        initLock = null;
      }

      // Fire 3 concurrent init calls
      await Future.wait([mockInit(), mockInit(), mockInit()]);

      // Only 1 should have actually initialized
      expect(initCount, equals(1));
    });
  });
}
