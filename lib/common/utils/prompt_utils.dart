/// Shared utilities for image generation prompt construction.
/// Extracted from StoryWeaver and StoryResultView to eliminate duplication.
class PromptUtils {
  PromptUtils._(); // Prevent instantiation

  /// Maps story vibes to contextually appropriate clothing hints for SDXL.
  ///
  /// The story vibe determines what characters should wear, overriding
  /// the base clothing from the character's Cast profile.
  static String getVibeClothingHint(String vibe) {
    final vibeLC = vibe.toLowerCase().trim();

    const vibeClothingMap = {
      'space': 'characters wearing spacesuits with helmets',
      'underwater': 'characters wearing diving suits and goggles',
      'pirate': 'characters wearing pirate outfits with hats and boots',
      'medieval': 'characters wearing medieval fantasy clothing and armor',
      'superhero': 'characters wearing superhero costumes and capes',
      'jungle': 'characters wearing explorer outfits with safari hats',
      'arctic': 'characters wearing thick winter parkas and snow boots',
      'detective': 'characters wearing detective trench coats and hats',
      'fairy tale': 'characters wearing fairy tale clothing',
      'western': 'characters wearing cowboy outfits with hats and boots',
      'dinosaur': 'characters wearing explorer adventure gear',
      'robot': 'characters wearing futuristic tech suits',
      'sports': 'characters wearing sports uniforms',
      'cooking': 'characters wearing chef aprons and hats',
      'safari': 'characters wearing safari exploration gear',
      'camping': 'characters wearing camping outdoor clothing',
      'winter': 'characters wearing warm winter coats and scarves',
      'beach': 'characters wearing beach swimwear and sandals',
      'halloween': 'characters wearing Halloween costumes',
      'circus': 'characters wearing colorful circus performer outfits',
    };

    // Direct match
    if (vibeClothingMap.containsKey(vibeLC)) {
      return vibeClothingMap[vibeLC]!;
    }

    // Partial match (e.g., "Space Adventure" matches "space")
    for (final entry in vibeClothingMap.entries) {
      if (vibeLC.contains(entry.key)) {
        return entry.value;
      }
    }

    // No clothing override needed for generic vibes (Magical, Funny, etc.)
    return '';
  }

  /// Strips base clothing descriptions from character text so the
  /// vibe-contextual clothing can take over in the SDXL prompt.
  ///
  /// Removes phrases like "wearing a striped shirt and dark blue pants".
  static String stripClothing(String text) {
    if (text.isEmpty) return text;

    // Remove "wearing ..." up to the next period or end of text
    String result = text.replaceAll(
      RegExp(r'\s*(and\s+)?wearing\s+[^.]+', caseSensitive: false),
      '',
    );

    // Remove "His/Her shoes are ..." phrases
    result = result.replaceAll(
      RegExp(r'\.\s*(His|Her|Their)\s+shoes\s+are\s+[^.]+\.?', caseSensitive: false),
      '',
    );

    // Remove "He/She wears ..." phrases
    result = result.replaceAll(
      RegExp(r'\.\s*(He|She|They)\s+wears?\s+[^.]+\.?', caseSensitive: false),
      '',
    );

    // Clean up double spaces and trailing dots
    result = result.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    result = result.replaceAll(RegExp(r'\.{2,}'), '.').trim();

    return result;
  }
}
