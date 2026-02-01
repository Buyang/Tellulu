// ignore_for_file: unused_import, unreachable_from_main

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tellulu/features/create/character_creation_page.dart';
import 'package:tellulu/services/gemini_service.dart';
import 'package:tellulu/services/stability_service.dart';

// Mock AssetBundle
class MockAssetBundle extends CachingAssetBundle {
  @override
  Future<ByteData> load(String key) async {
    // Return empty bytes for any asset (fonts)
    return ByteData(0);
  }
}

// Mock Services
class MockImagePicker extends ImagePicker {
  @override
  Future<XFile?> pickImage({
    required ImageSource source,
    double? maxWidth,
    double? maxHeight,
    int? imageQuality,
    CameraDevice preferredCameraDevice = CameraDevice.rear,
    bool requestFullMetadata = true,
  }) async {
    // Return a dummy 1x1 png image
    final bytes = Uint8List.fromList([137, 80, 78, 71, 13, 10, 26, 10, 0, 0, 0, 13, 73, 72, 68, 82, 0, 0, 0, 1, 0, 0, 0, 1, 8, 6, 0, 0, 0, 31, 21, 196, 137, 0, 0, 0, 13, 73, 68, 65, 84, 120, 153, 99, 100, 248, 255, 191, 30, 0, 5, 132, 2, 127, 194, 91, 30, 42, 0, 0, 0, 0, 73, 69, 78, 68, 174, 66, 96, 130]);
    return XFile.fromData(bytes);
  }
}

class MockStabilityService extends StabilityService {
  MockStabilityService() : super('mock-key');

  String? lastStylePreset;
  double? lastImageStrength;
  Uint8List? lastInitImageBytes;

  @override
  Future<String?> generateImage({
    required String prompt, required String modelId, Uint8List? initImageBytes,
    String? stylePreset,
    double imageStrength = 0.35,
    int? seed,
  }) async {
    lastStylePreset = stylePreset;
    lastImageStrength = imageStrength;
    lastInitImageBytes = initImageBytes;
    return 'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mNk+P+/HgAFhAJ/wlseKgAAAABJRU5ErkJggg=='; // 1x1 pixel base64
  }
}

class MockGeminiService extends GeminiService {
  MockGeminiService() : super('mock-key');

  @override
  Future<String?> generateCharacterDescription({
    required String prompt,
    String model = 'gemini-1.5-flash',
  }) async {
    return 'A brave hero description.';
  }
}

void main() {
  // setUp(() {
  //    GoogleFonts.config.allowRuntimeFetching = true;
  // });

  testWidgets('SDXL Style Preset Selection Verification', (WidgetTester tester) async {
    // TODO: Fix GoogleFonts mocking or allow runtime fetching properly
  }, skip: true);

}
