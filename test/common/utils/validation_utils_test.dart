import 'package:flutter_test/flutter_test.dart';
import 'package:tellulu/common/utils/validation_utils.dart';

void main() {
  group('ValidationUtils.sanitizeInput', () {
    test('trims whitespace', () {
      expect(ValidationUtils.sanitizeInput('  hello  '), 'hello');
    });

    test('caps length', () {
      final long = 'a' * 300;
      expect(ValidationUtils.sanitizeInput(long, maxLength: 50).length, 50);
    });

    test('handles empty string', () {
      expect(ValidationUtils.sanitizeInput(''), '');
    });
  });

  group('ValidationUtils.validateCharacterName', () {
    test('accepts valid names', () {
      expect(ValidationUtils.validateCharacterName('Luna'), isNull);
      expect(ValidationUtils.validateCharacterName('Bun-Bun'), isNull);
    });

    test('rejects empty names', () {
      expect(ValidationUtils.validateCharacterName(''), isNotNull);
      expect(ValidationUtils.validateCharacterName('  '), isNotNull);
    });

    test('rejects names over limit', () {
      final longName = 'a' * 51;
      expect(ValidationUtils.validateCharacterName(longName), isNotNull);
    });
  });

  group('ValidationUtils.validateVibeName', () {
    test('accepts valid vibe names', () {
      expect(ValidationUtils.validateVibeName('Space Adventure'), isNull);
    });

    test('rejects empty vibe names', () {
      expect(ValidationUtils.validateVibeName(''), isNotNull);
    });

    test('rejects names over limit', () {
      final longVibe = 'a' * 31;
      expect(ValidationUtils.validateVibeName(longVibe), isNotNull);
    });
  });
}
