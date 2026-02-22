import 'package:flutter_test/flutter_test.dart';
import 'package:tellulu/common/utils/sanitize_utils.dart';

void main() {
  group('SanitizeUtils.sanitizeWithRedaction', () {
    test('replaces blocked keywords with [REDACTED]', () {
      expect(SanitizeUtils.sanitizeWithRedaction('This is violent content'),
          contains('[REDACTED]'));
      expect(SanitizeUtils.sanitizeWithRedaction('A nude scene'),
          contains('[REDACTED]'));
    });

    test('is case insensitive', () {
      expect(SanitizeUtils.sanitizeWithRedaction('VIOLENT'),
          contains('[REDACTED]'));
    });

    test('leaves clean text unchanged', () {
      const clean = 'A magical adventure with unicorns';
      expect(SanitizeUtils.sanitizeWithRedaction(clean), clean);
    });

    test('handles empty input', () {
      expect(SanitizeUtils.sanitizeWithRedaction(''), '');
    });

    test('replaces multiple blocked keywords', () {
      final result = SanitizeUtils.sanitizeWithRedaction('violent and nude');
      expect(result, '[REDACTED] and [REDACTED]');
    });
  });

  group('SanitizeUtils.sanitizeByRemoval', () {
    test('removes blocked keywords entirely', () {
      final result = SanitizeUtils.sanitizeByRemoval('This is violent content');
      expect(result.contains('violent'), isFalse);
      expect(result, isNotEmpty);
    });

    test('cleans up extra whitespace after removal', () {
      final result = SanitizeUtils.sanitizeByRemoval('A nude scene');
      expect(result.contains('  '), isFalse);
    });
  });

  group('SanitizeUtils.cleanGarbage', () {
    test('removes markdown code fences', () {
      expect(SanitizeUtils.cleanGarbage('```json\n{"key": "val"}\n```'),
          '{"key": "val"}');
    });

    test('collapses excessive newlines', () {
      expect(SanitizeUtils.cleanGarbage('a\n\n\n\nb'), 'a\n\nb');
    });

    test('trims whitespace', () {
      expect(SanitizeUtils.cleanGarbage('  hello  '), 'hello');
    });
  });
}
