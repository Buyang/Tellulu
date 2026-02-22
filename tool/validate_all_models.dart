import 'package:tellulu/common/app_config.dart';
import 'package:tellulu/services/gemini_service.dart';
import 'package:tellulu/services/stability_service.dart';

Future<void> main() async {
  // Ensure we have keys from --dart-define
  if (AppConfig.geminiKey.isEmpty || AppConfig.stabilityKey.isEmpty) {
    print('ERROR: Keys missing. Run with: dart --dart-define-from-file=.env test/validate_all_models.dart');
    return;
  }

  // Services now self-configure from AppConfig
  final geminiService = GeminiService();
  final stabilityService = StabilityService();

  final geminiModels = [
    'gemini-1.5-flash',
    'gemini-1.5-pro',
    'gemini-1.5-pro-latest',
    'gemini-1.5-pro-001',
    'gemini-2.0-flash-exp',
    'gemini-2.0-pro-exp',
    'gemini-2.0-pro-exp-02-05',
  ];

  final geminiAliases = [
    'gemini-2.5-flash',
    'gemini-2.5-pro', 
  ];

  final stabilityModels = [
    'stable-diffusion-xl-1024-v1-0',
    'stable-diffusion-v1-6',
    'stable-diffusion-3-sd3-medium', 
  ];

  print('\n--- Validating GEMINI Models ---');
  for (final model in [...geminiModels, ...geminiAliases]) {
    final isHealthy = await geminiService.verifyModelHealth(model);
    print('${isHealthy ? "[OK]" : "[FAIL]"} $model');
  }

  print('\n--- Validating STABILITY Models ---');
  for (final model in stabilityModels) {
    final isHealthy = await stabilityService.verifyModelHealth(model);
    print('${isHealthy ? "[OK]" : "[FAIL]"} $model');
  }
}
