import 'package:flutter_test/flutter_test.dart';
import 'package:tellulu/common/utils/prompt_utils.dart';

void main() {
  group('PromptUtils.getVibeClothingHint', () {
    test('returns exact match for known vibes', () {
      expect(PromptUtils.getVibeClothingHint('space'),
          'characters wearing spacesuits with helmets');
      expect(PromptUtils.getVibeClothingHint('pirate'),
          'characters wearing pirate outfits with hats and boots');
      expect(PromptUtils.getVibeClothingHint('underwater'),
          'characters wearing diving suits and goggles');
    });

    test('is case-insensitive', () {
      expect(PromptUtils.getVibeClothingHint('SPACE'),
          'characters wearing spacesuits with helmets');
      expect(PromptUtils.getVibeClothingHint('Pirate'),
          'characters wearing pirate outfits with hats and boots');
    });

    test('returns partial match for compound vibes', () {
      expect(PromptUtils.getVibeClothingHint('Space Adventure'),
          'characters wearing spacesuits with helmets');
      expect(PromptUtils.getVibeClothingHint('Epic Medieval Quest'),
          'characters wearing medieval fantasy clothing and armor');
    });

    test('returns empty string for generic vibes', () {
      expect(PromptUtils.getVibeClothingHint('Magical'), '');
      expect(PromptUtils.getVibeClothingHint('Funny'), '');
      expect(PromptUtils.getVibeClothingHint('Happy'), '');
    });

    test('trims whitespace', () {
      expect(PromptUtils.getVibeClothingHint('  space  '),
          'characters wearing spacesuits with helmets');
    });
  });

  group('PromptUtils.stripClothing', () {
    test('removes "wearing" phrases', () {
      const input = 'A young boy with brown hair wearing a red shirt and blue jeans.';
      final result = PromptUtils.stripClothing(input);
      expect(result.contains('wearing'), isFalse);
      expect(result.contains('brown hair'), isTrue);
    });

    test('handles empty input', () {
      expect(PromptUtils.stripClothing(''), '');
    });

    test('returns text unchanged if no clothing mentioned', () {
      const input = 'A large grey elephant with big ears.';
      expect(PromptUtils.stripClothing(input), input);
    });
  });
}
