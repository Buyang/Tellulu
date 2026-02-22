// ignore_for_file: avoid_print

import 'package:tellulu/common/app_config.dart';
import 'package:tellulu/services/gemini_service.dart';

Future<void> main() async {
  // Check keys from --dart-define
  if (AppConfig.geminiKey.isEmpty) {
    print('ERROR: GEMINI_KEY missing. Run with --dart-define-from-file=.env');
    return;
  }

  final service = GeminiService();
  
  // Model selected by user
  const model = 'gemini-2.0-flash-exp';
  const styleKey = 'digital-art'; // Example style
  const prompt = "Create a creative, playful character description for a children's story hero. The character is a $styleKey. Keep it under 1000 characters.";

  print('Testing Dream Up with model: $model');
  print('Prompt: $prompt');

  final result = await service.generateCharacterDescription(
    prompt: prompt,
  );

  if (result != null) {
    print('\n[SUCCESS] Generated Description:');
    print(result);
  } else {
    print('\n[FAILURE] Returned null. Check service logs (if any).');
  }
}
