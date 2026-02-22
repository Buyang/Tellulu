/// Input validation utilities for user-facing text fields.
class ValidationUtils {
  ValidationUtils._(); // Prevent instantiation

  static const int maxCharacterNameLength = 50;
  static const int maxDescriptionLength = 1000;
  static const int maxVibeNameLength = 30;
  static const int maxSpecialTouchLength = 200;

  /// Sanitizes and trims user input to a maximum length.
  static String sanitizeInput(String input, {int maxLength = 200}) {
    return input.trim().substring(0, input.trim().length.clamp(0, maxLength));
  }

  /// Validates a character name. Returns null if valid, or an error message.
  static String? validateCharacterName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Name cannot be empty';
    if (trimmed.length > maxCharacterNameLength) {
      return 'Name must be $maxCharacterNameLength characters or less';
    }
    return null;
  }

  /// Validates a description. Returns null if valid, or an error message.
  static String? validateDescription(String description) {
    final trimmed = description.trim();
    if (trimmed.length > maxDescriptionLength) {
      return 'Description must be $maxDescriptionLength characters or less';
    }
    return null;
  }

  /// Validates a custom vibe name. Returns null if valid, or an error message.
  static String? validateVibeName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Vibe name cannot be empty';
    if (trimmed.length > maxVibeNameLength) {
      return 'Vibe name must be $maxVibeNameLength characters or less';
    }
    return null;
  }
}
