import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tellulu/services/gemini_service.dart';
import 'package:tellulu/services/stability_service.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
GeminiService geminiService(Ref ref) {
  // Check dart-define first (Web/CI), then dotenv (Mobile dev)
  final apiKey = const String.fromEnvironment('GEMINI_KEY').isNotEmpty
      ? const String.fromEnvironment('GEMINI_KEY')
      : dotenv.env['GEMINI_KEY'] ?? '';
      
  if (apiKey.isEmpty) {
    debugPrint('WARNING: GEMINI_KEY is missing (checked dart-define and .env)');
  }
  return GeminiService(apiKey);
}

@Riverpod(keepAlive: true)
StabilityService stabilityService(Ref ref) {
  final apiKey = const String.fromEnvironment('STABILITY_KEY').isNotEmpty
      ? const String.fromEnvironment('STABILITY_KEY')
      : dotenv.env['STABILITY_KEY'] ?? '';
      
  if (apiKey.isEmpty) {
    debugPrint('WARNING: STABILITY_KEY is missing (checked dart-define and .env)');
  }
  return StabilityService(apiKey);
}
