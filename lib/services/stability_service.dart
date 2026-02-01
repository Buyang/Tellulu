import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class StabilityService {

  StabilityService(this.apiKey);
  final String apiKey;
  static const String _baseUrl = 'https://api.stability.ai/v1/generation';

  Future<String?> generateImage({
    required String prompt, required String modelId, Uint8List? initImageBytes,
    String? stylePreset, // Changed from required style to optional stylePreset
    double imageStrength = 0.35,
    int? seed, // New: Consistency Anchor
  }) async {
    try {
      debugPrint('StabilityService: generateImage called');
      debugPrint('StabilityService: stylePreset=$stylePreset, modelId=$modelId');
      final isImg2Img = initImageBytes != null;
      final endpoint = isImg2Img ? 'image-to-image' : 'text-to-image';
      final url = '$_baseUrl/$modelId/$endpoint';
      
      http.Response response;

      if (isImg2Img) {
        final request = http.MultipartRequest('POST', Uri.parse(url));
        request.headers.addAll({
          'Authorization': 'Bearer $apiKey',
          'Accept': 'application/json',
        });
        
        String finalPrompt = prompt;
        debugPrint('StabilityService: Original prompt length: ${finalPrompt.length}');
        if (finalPrompt.length > 1000) {
          finalPrompt = finalPrompt.substring(0, 1000);
          debugPrint('StabilityService: Truncated prompt to 1000 chars');
        }
        debugPrint('StabilityService: Final prompt length: ${finalPrompt.length}');
        request.fields['text_prompts[0][text]'] = finalPrompt;
        request.fields['text_prompts[0][weight]'] = '1';
        if (stylePreset != null) {
          request.fields['style_preset'] = stylePreset;
        }
        request.fields['cfg_scale'] = '7';
        request.fields['samples'] = '1';
        request.fields['steps'] = '30';
        request.fields['init_image_mode'] = 'IMAGE_STRENGTH';
        request.fields['image_strength'] = imageStrength.toString();
        
        request.files.add(
          http.MultipartFile.fromBytes(
            'init_image',
            initImageBytes,
            filename: 'init_image.png',
            contentType: MediaType('image', 'png'),
          ),
        );

        final streamedResponse = await request.send();
        response = await http.Response.fromStream(streamedResponse);
      } else {
        // Text-to-Image (JSON)
        final body = {
            'text_prompts': [
              {'text': prompt.length > 2000 ? prompt.substring(0, 2000) : prompt, 'weight': 1}
            ],
            'cfg_scale': 7,
            'samples': 1,
            'steps': 30,
            'height': 1024,
            'width': 1024,
        };
        
        if (stylePreset != null) {
          body['style_preset'] = stylePreset;
        }

        response = await http.post(
          Uri.parse(url),
          headers: {
            'Authorization': 'Bearer $apiKey',
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          body: jsonEncode(body),
        );
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final artifacts = data['artifacts'] as List<dynamic>?;
        if (artifacts != null && artifacts.isNotEmpty) {
          return artifacts[0]['base64'] as String?;
        }
      } else {
        debugPrint('Stability API Error: ${response.statusCode} - ${response.body}');
        debugPrint('Request Headers: ${response.request?.headers}');
      }
    } on Object catch (e) {
      debugPrint('Stability Service Exception: $e');
    }
    return null;
  }

  /// Verifies if the selected model ID is valid and reachable.
  Future<bool> verifyModelHealth(String modelId) async {
    try {
      // We start by assuming the model ID is valid if we get a 400 (Bad Request)
      // instead of a 404 (Not Found) when sending an empty/invalid payload.
      final url = '$_baseUrl/$modelId/text-to-image';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({}), // Empty body should trigger 400 if model exists
      );

      // 400 means "I heard you, but you sent garbage" -> Model exists!
      // 404 means "Model not found".
      // 401 means "Unauthorized" (Health check failed due to key).
      // 200 is unlikely with empty body, but would be success.
      if (response.statusCode == 400 || response.statusCode == 200) {
        return true;
      }
      
      debugPrint('Stability Health Check ($modelId): ${response.statusCode}');
      return false;
      
    } on Object catch (e) {
      debugPrint('Stability Health Check Exception: $e');
      return false;
    }
  }
}
