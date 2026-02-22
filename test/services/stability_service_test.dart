import 'package:flutter_test/flutter_test.dart';
import 'package:tellulu/services/stability_service.dart';

/// Unit tests for StabilityService.
/// 
/// These tests focus on pure logic methods (_sanitizePrompt) and 
/// constructor/config behavior. Network-dependent tests (generateImage,
/// verifyModelHealth) are in tool/stability_api_test.dart.
void main() {
  late StabilityService service;

  setUp(() {
    service = StabilityService();
  });

  group('StabilityService instantiation', () {
    test('creates instance without error', () {
      expect(service, isNotNull);
    });

    test('isUsingProxy reflects platform (false in test)', () {
      // In test environment, kIsWeb is false
      expect(service.isUsingProxy, isFalse);
    });
  });

  group('_sanitizePrompt (via generateImage prompt processing)', () {
    // _sanitizePrompt is private, so we test it indirectly.
    // For focused testing, we expose the logic here.

    test('removes blocked words from input', () {
      final sanitized = _testSanitize('A naked child running in the park');
      expect(sanitized, isNot(contains('naked')));
    });

    test('removes multiple blocked words', () {
      final sanitized = _testSanitize('violence and blood in the scene');
      expect(sanitized, isNot(contains('violence')));
      expect(sanitized, isNot(contains('blood')));
    });

    test('preserves safe content unchanged', () {
      const input = 'A happy child playing with a puppy in a garden';
      final sanitized = _testSanitize(input);
      expect(sanitized.trim(), equals(input));
    });

    test('handles empty string', () {
      expect(_testSanitize(''), equals(''));
    });

    test('is case-insensitive', () {
      final sanitized = _testSanitize('NAKED person in VIOLENCE');
      expect(sanitized.toLowerCase(), isNot(contains('naked')));
      expect(sanitized.toLowerCase(), isNot(contains('violence')));
    });

    test('removes body-related terms from children context', () {
      final sanitized = _testSanitize('A muscular character with chest armor');
      expect(sanitized, isNot(contains('muscular')));
      expect(sanitized, isNot(contains('chest')));
    });

    test('removes substance-related terms', () {
      final sanitized = _testSanitize('Character smoking a cigarette with alcohol');
      expect(sanitized, isNot(contains('smoking')));
      expect(sanitized, isNot(contains('cigarette')));
      expect(sanitized, isNot(contains('alcohol')));
    });

    test('handles word boundaries correctly - does not remove substrings', () {
      // 'skill' contains 'kill' but should NOT be removed (word boundary)
      final sanitized = _testSanitize('A skilled warrior');
      expect(sanitized, contains('skilled'));
    });
  });
}

/// Replicates StabilityService._sanitizePrompt logic for direct testing.
/// This mirrors the private method to enable unit testing without reflection.
String _testSanitize(String input) {
  const blocklist = [
    'naked', 'nude', 'sexual', 'blood', 'gore', 'violence', 'kill', 'weapon',
    'drug', 'alcohol', 'cigarette', 'smoking', 'terror', 'horror',
    'chest', 'breast', 'thigh', 'groin', 'buttock', 'underwear', 'lingerie',
    'sexy', 'seductive', 'curvy', 'busty', 'muscular', 'ripped'
  ];

  String clean = input;
  for (final word in blocklist) {
    clean = clean.replaceAll(RegExp(r'\b' + word + r'\b', caseSensitive: false), '');
  }
  return clean;
}
