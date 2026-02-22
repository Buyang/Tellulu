/// Shared text sanitization utilities.
/// Extracted from GeminiService and StabilityService to eliminate duplication.
class SanitizeUtils {
  SanitizeUtils._(); // Prevent instantiation

  /// Blocked keywords for content safety.
  static const List<String> _blockedKeywords = [
    'nude', 'naked', 'sex', 'violent', 'gore', 'blood', 'murder', 'kill',
    'weapon', 'gun', 'knife', 'drug', 'alcohol', 'cigarette', 'smoking',
    'horror', 'scary', 'nightmare', 'devil', 'demon', 'hell', 'damn',
    'suicide', 'abuse', 'torture', 'mutilation', 'explicit', 'pornograph',
    'breast', 'genital', 'erotic', 'fetish', 'bondage', 'lingerie',
    'profanity', 'slur', 'hate', 'racist', 'sexist', 'offensive',
  ];

  /// Sanitizes text by replacing blocked keywords with [REDACTED].
  ///
  /// Used for content that needs to remain readable (e.g., logs, UI display).
  static String sanitizeWithRedaction(String text) {
    String sanitized = text;
    for (final keyword in _blockedKeywords) {
      sanitized = sanitized.replaceAll(
        RegExp(keyword, caseSensitive: false),
        '[REDACTED]',
      );
    }
    return sanitized;
  }

  /// Sanitizes text by removing blocked keywords entirely.
  ///
  /// Used for content sent to external APIs (e.g., image generation prompts).
  static String sanitizeByRemoval(String text) {
    String sanitized = text;
    for (final keyword in _blockedKeywords) {
      sanitized = sanitized.replaceAll(
        RegExp(keyword, caseSensitive: false),
        '',
      );
    }
    // Clean up double spaces
    return sanitized.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
  }

  /// Removes common garbage/artifact characters from AI-generated text.
  static String cleanGarbage(String input) {
    // Remove markdown code fences
    input = input.replaceAll(RegExp(r'```(json)?'), '');
    // Remove excessive newlines
    input = input.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    return input.trim();
  }
}
