import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:tellulu/services/gemini_service.dart';

@GenerateMocks([http.Client])
import 'gemini_service_test.mocks.dart';

void main() {
  group('GeminiService', () {
    late GeminiService service;
    late MockClient mockClient;
    const apiKey = 'fake-key';

    setUp(() {
      mockClient = MockClient();
      service = GeminiService(apiKey, client: mockClient);
    });

    test('generateCharacterDescription returns text on success', () async {
      final responseBody = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'A brave knight'}
              ]
            }
          }
        ]
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final result = await service.generateCharacterDescription(prompt: 'test');

      expect(result, 'A brave knight');
      verify(mockClient.post(any, headers: anyNamed('headers'), body: anyNamed('body'))).called(1);
    });

    test('generateStory parses valid JSON response', () async {
      final storyJson = {
        'title': 'Test Story',
        'pages': [
          {'text': 'Page 1', 'visual_description': 'Scene 1'}
        ]
      };

      final responseBody = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '```json\n${jsonEncode(storyJson)}\n```'}
              ]
            }
          }
        ]
      };

      when(mockClient.post(
        any,
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      final result = await service.generateStory(
        castDetails: [],
        vibe: 'happy',
        readingLevel: 'beginner',
        specialTouch: 'none',
        model: 'gemini-1.5-flash',
      );

      expect(result!['title'], 'Test Story');
      expect(result['pages'].length, 1);
      
      // Verify model resolution: flash -> gemini-2.0-flash-exp
      verify(mockClient.post(
        argThat(predicate((uri) => uri.toString().contains('gemini-2.0-flash'))),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);
    });

    test('resolveModel maps "flash" and "2.5" to 2.0-flash-exp', () async {
      // Mock successful response
      final responseBody = { 'candidates': [ { 'content': { 'parts': [ {'text': 'Ok'} ] } } ] };
      when(mockClient.post(
        any, 
        headers: anyNamed('headers'), 
        body: anyNamed('body')
      )).thenAnswer((_) async => http.Response(jsonEncode(responseBody), 200));

      // 1. Test "flash" alias
      await service.generateCharacterDescription(prompt: 'test', model: 'flash');
      verify(mockClient.post(
        argThat(predicate((uri) => uri.toString().contains('gemini-2.0-flash'))),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);

      // 2. Test "2.5" alias
      await service.generateCharacterDescription(prompt: 'test', model: 'gemini-2.5');
      verify(mockClient.post(
        argThat(predicate((uri) => uri.toString().contains('gemini-2.0-flash'))),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);
      
      // 3. Test "pro" alias -> Forced migration to 2.0-flash (stable)
      await service.generateCharacterDescription(prompt: 'test', model: 'gemini-1.5-pro');
      verify(mockClient.post(
        argThat(predicate((uri) => uri.toString().contains('gemini-2.0-flash'))),
        headers: anyNamed('headers'),
        body: anyNamed('body'),
      )).called(1);
    });
  });
}
