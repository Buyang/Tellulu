import 'package:flutter/foundation.dart';

class AppConfig {
  static const String geminiKey = String.fromEnvironment('GEMINI_KEY');
  static const String stabilityKey = String.fromEnvironment('STABILITY_KEY');

  /// Proxy URL for Stability AI on web (avoids CORS and key exposure)
  static const String stabilityProxyUrl = String.fromEnvironment(
    'STABILITY_PROXY_URL',
    defaultValue: 'https://us-central1-tellulu.cloudfunctions.net/generateStabilityImage',
  );

  static bool get isGeminiConfigured => geminiKey.isNotEmpty;
  static bool get isStabilityConfigured => stabilityKey.isNotEmpty;

  /// Whether Firebase initialized successfully. Set in main.dart.
  static bool firebaseAvailable = true;

  static void logConfigStatus() {
    if (kDebugMode) {
      debugPrint('🔧 App Configuration Status:');
      debugPrint('   - Note: Keys are injected at build time via --dart-define-from-file=.env');
      if (isGeminiConfigured) {
         debugPrint('   ✅ GEMINI_KEY: Configured');
      } else {
         debugPrint('   ⚠️ GEMINI_KEY: Missing! Story Weaving will struggle.');
      }
      
      if (isStabilityConfigured) {
        debugPrint('   ✅ STABILITY_KEY: Configured');
      } else {
        debugPrint('   ⚠️ STABILITY_KEY: Missing! Image Generation will fail.');
      }
    }
  }
}
