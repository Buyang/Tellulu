import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

const apiKey = 'sk-HRE8NYqwregvjykkelrM2Cv7kvgoJziUdcafULRoeYjEjCda'; // From CharacterCreationPage
const modelId = 'stable-diffusion-xl-1024-v1-0'; // From main.dart
const baseUrl = 'https://api.stability.ai/v1/generation';

void main() {
  test('Stability API Connectivity', () async {
    print('Testing Stability API with model: $modelId');
    
    final url = '$baseUrl/$modelId/text-to-image';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $apiKey',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode({
          'text_prompts': [
            {'text': 'A cute cartoon rabbit in watercolor style', 'weight': 1}
          ],
          'cfg_scale': 7,
          'samples': 1,
          'steps': 30,
          'height': 1024,
          'width': 1024,
        }),
      );

      print('Response Status: ${response.statusCode}');
      
      if (response.statusCode == 200) {
        print('Success! Image generated.');
        final data = jsonDecode(response.body);
        final artifacts = data['artifacts'] as List;
        if (artifacts.isNotEmpty) {
          print('Artifact received. Length of base64: ${artifacts[0]['base64'].length}');
        }
      } else {
        print('Error Body: ${response.body}');
        print('Response Headers: ${response.headers}');
      }
    } catch (e) {
      print('Exception caught: $e');
    }
  });
}
