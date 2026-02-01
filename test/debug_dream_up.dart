// ignore_for_file: avoid_print
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:tellulu/services/gemini_service.dart';

Future<void> main() async {
  final envFile = File('.env');
  if (!envFile.existsSync()) {
    print('ERROR: .env file not found');
    return;
  }
  await dotenv.load(fileName: '.env');

  final geminiKey = dotenv.env['GEMINI_KEY'] ?? '';
  if (geminiKey.isEmpty) {
    print('ERROR: GEMINI_KEY missing in .env');
    return;
  }

  final service = GeminiService(geminiKey);
  
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
