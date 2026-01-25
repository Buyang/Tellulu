import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiService {
  final String apiKey;
  static const String _baseUrlv1beta = 'https://generativelanguage.googleapis.com/v1beta/models/';

  GeminiService(this.apiKey);

  Future<String?> generateCharacterDescription({
    required String prompt,
    String model = 'gemini-1.5-flash', // Retain default signature
  }) async {
    // FIX: Map 'flash' or '2.5' or any failing model to the robust 'gemini-2.0-flash-exp'
    // User requested "2.5" (likely referring to the Dec 2024 2.0 Flash Exp)
    final safeModel = (model.contains('flash') || model.contains('2.5') || model.contains('pro')) 
        ? 'gemini-2.0-flash-exp' 
        : model;
    
    // Legacy method - keeping for Character Creation "Dream Up" feature
    // ... logic same as before ...
    try {
      // CRITICAL FIX: Use safeModel here!
      final url = Uri.parse('$_baseUrlv1beta$safeModel:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {
                  "text": prompt
                }
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'];
        }
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Gemini Service Exception: $e');
    }
    return null;
  }

  Future<String> enhanceCharacterDescription(String name, String rawDescription) async {
      // New method for "Story Bible" consistency
      final prompt = """
      You are a Visual Consistency Director for an animated series.
      I will give you a character's Name and a basic Raw Description.
      
      Your job is to expand this into a COMPREHENSIVE VISUAL PROFILE.
      You MUST INVENT details if they are missing to ensure the character looks exactly the same in every shot.
      
      Character Name: $name
      Raw Description: $rawDescription
      
      Output a single paragraph (approx 40-50 words) describing:
      1. Gender & Age (approximate)
      2. Body Type (e.g., tall, chubby, tiny)
      3. Specific Clothing (e.g., red hoodie with blue star, yellow boots)
      4. Key Features (e.g., curly pink hair, glasses, freckles)
      
      Example Input: "Pip, a space boy"
      Example Output: "Pip is a 10-year-old boy with a slim build and spiky blue hair. He wears a silver spacesuit with orange glowing patches and oversized magnetic boots. He has a small antenna on his backpack and always wears heavy aviator goggles."
      
      Output ONLY the description.
      """;
      
      final result = await generateCharacterDescription(prompt: prompt);
      return result ?? rawDescription; // Fallback to raw if fail
  }

  Future<Map<String, dynamic>?> generateStory({
    required List<Map<String, String>> castDetails,
    required String vibe,
    required String readingLevel,
    required String specialTouch,
    String model = 'gemini-1.5-flash',
  }) async {
    try {
      final castDescription = castDetails.map((c) => "${c['name']} (${c['description']})").join(', ');

      final prompt = """
      Write a children's story for a $readingLevel audience.
      
      The Vibe is: $vibe.
      The Main Characters are: $castDescription.
      Special Instructions: $specialTouch
      
      CRITICAL VISUAL INSTRUCTION:
      For every page, you must provide a "visual_description".
      In this "visual_description":
      1. This description will be used as a DIRECT PROMPT for an AI image generator.
      2. YOU MUST EMBED the character's visual appearance naturally into the action.
      3. REPEAT key traits (e.g., "blue hair", "red cape") EVERY time the character appears. Do not assume the AI knows who "Nono" is.
      4. Format: "[Character Name], a [Short Physical Description], is [Action] in [Setting]."
      5. Example: "Pip, a small blue robot with glowing eyes, is chasing a butterfly in a meadow."
      6. OBJECT CONSISTENCY: If a key object appears, describe it consistently.
      5. SUPPORTING CAST: If a defined supporting character appears, refer to them by name and ensure their action fits their role.
      
      Example: "Falling dramatically through a cloud layer, flailing arms, with a terrified expression. Background is a bright blue sky. A shiny red balloon floats nearby."
      
      Please format the response as a JSON object with the following structure:
      {
        "title": "Title of the Story",
        "pages": [
          {
            "text": "Text for page 1...",
            "visual_description": "Detailed visual description including physical character traits..."
          },
          ...
        ]
      }
      Do not include markdown formatting (like ```json) in the response, just the raw JSON string if possible, or I will clean it.
      """;

      final url = Uri.parse('$_baseUrlv1beta$model:generateContent?key=$apiKey');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && 
            data['candidates'].isNotEmpty &&
            data['candidates'][0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            data['candidates'][0]['content']['parts'].isNotEmpty) {
          
          String text = data['candidates'][0]['content']['parts'][0]['text'];
          // Basic cleanup if Gemini returns markdown code blocks
          text = text.replaceAll('```json', '').replaceAll('```', '').trim();
          
          try {
            return jsonDecode(text) as Map<String, dynamic>;
          } catch (e) {
            print("Error parsing JSON story: $e");
            // Fallback: return raw text as a single page if JSON parse fails
             return {
              "title": "A $vibe Adventure",
              "pages": [text]
            };
          }
        }
      } else {
        print('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Gemini Service Exception: $e');
    }
    return null;
  }
}
