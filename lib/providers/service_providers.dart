import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:tellulu/common/app_config.dart';
import 'package:tellulu/services/gemini_service.dart';
import 'package:tellulu/services/stability_service.dart';
import 'package:tellulu/services/storage_service.dart';

part 'service_providers.g.dart';

@Riverpod(keepAlive: true)
GeminiService geminiService(Ref ref) {
  if (!AppConfig.isGeminiConfigured) {
     debugPrint('WARNING: Gemini Service initialized without API Key');
  }
  return GeminiService();
}

@Riverpod(keepAlive: true)
StabilityService stabilityService(Ref ref) {
  if (!AppConfig.isStabilityConfigured) {
     debugPrint('WARNING: Stability Service initialized without API Key');
  }
  return StabilityService();
}

@Riverpod(keepAlive: true)
StorageService storageService(Ref ref) {
  return StorageService();
}
