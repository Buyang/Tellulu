import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class StabilityService {
  final String apiKey;
  static const String _baseUrl = 'https://api.stability.ai/v1/generation';

  StabilityService(this.apiKey);

  Future<String?> generateImage({
    Uint8List? initImageBytes,
    required String prompt,
    String? stylePreset, // Changed from required style to optional stylePreset
    required String modelId,
    double imageStrength = 0.35,
    int? seed, // New: Consistency Anchor
  }) async {
    try {
      print('StabilityService: generateImage called');
      print('StabilityService: stylePreset=$stylePreset, modelId=$modelId');
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
        print('StabilityService: Original prompt length: ${finalPrompt.length}');
        if (finalPrompt.length > 1000) {
          finalPrompt = finalPrompt.substring(0, 1000);
          print('StabilityService: Truncated prompt to 1000 chars');
        }
        print('StabilityService: Final prompt length: ${finalPrompt.length}');
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
        final data = jsonDecode(response.body);
        if (data['artifacts'] != null && data['artifacts'].isNotEmpty) {
          return data['artifacts'][0]['base64'];
        }
      } else {
        print('Stability API Error: ${response.statusCode} - ${response.body}');
        print('Request Headers: ${response.request?.headers}');
      }
    } catch (e) {
      print('Stability Service Exception: $e');
    }
    return null;
  }
}
