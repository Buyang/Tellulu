import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import 'package:tellulu/common/app_config.dart';

class GeminiService {

  GeminiService({http.Client? client}) : _client = client ?? http.Client();
  
  // Use secure configuration
  String get apiKey => AppConfig.geminiKey;
  
  static const String _baseUrlv1beta = 'https://generativelanguage.googleapis.com/v1beta/models/';

  final http.Client _client;

  // Constants for Model Versions
  static const String _defaultModel = GeminiModels.defaultModel;


  Future<String?> generateCharacterDescription({
    required String prompt,
    String? visualContext, // Forensics result
    String model = _defaultModel,
  }) async {
    final safeModel = _resolveModel(model);
    
    // Construct prompt with visual context if available
    final fullPrompt = visualContext != null 
        ? "$prompt\n\nCRITICAL: You must base the character's physical appearance EXACTLY on this visual analysis:\n$visualContext"
        : prompt;

    try {
      final url = Uri.parse('$_baseUrlv1beta$safeModel:generateContent');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': fullPrompt}
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['candidates'] != null && 
            (data['candidates'] as List).isNotEmpty &&
            (data['candidates'] as List)[0]['content'] != null &&
            data['candidates'][0]['content']['parts'] != null &&
            (data['candidates'][0]['content']['parts'] as List).isNotEmpty) {
          return data['candidates'][0]['content']['parts'][0]['text'] as String;
        }
      } else if (response.statusCode == 403 || response.statusCode == 401) {
          debugPrint('Gemini API Auth Error: ${response.statusCode} - ${response.body}');
          throw Exception('Authentication Error: API Key missing or invalid (Check .env or Referrer).');
      } else {
        debugPrint('Gemini API Error: ${response.statusCode} - ${response.body}');
      }
    } on Object catch (e) {
      debugPrint('Gemini Service Exception: $e');
    }
    return null;
  }

  Future<String?> analyzeImage(Uint8List imageBytes) async {
    final safeModel = _resolveModel(_defaultModel);
    debugPrint('GeminiService: Analyzing image with $safeModel...');

    try {
      final url = Uri.parse('$_baseUrlv1beta$safeModel:generateContent');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': "Perform a FORENSIC ANALYSIS of the MAIN CHARACTER in this image. Focus ONLY on the primary human, animal, or creature. Ignore background/irrelevant objects.\n\nFor HUMAN characters, strictly identify:\n1. Ethnic Group\n2. Biological Gender (M or F)\n3. Age Group (Exact Match: Infant, Toddler, Preschooler, Elementary, Middle Schooler, High Schooler, College, Adult)\n4. Body Build (Underweight, Norm, Overweight)\n5. Hair Style & Color\n6. Seasonal Clothing & Shoes description.\n\nBe factual and precise."},
                {
                  'inline_data': {
                    'mime_type': 'image/png',
                    'data': base64Encode(imageBytes)
                  }
                }
              ]
            }
          ]
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
             final text = data['candidates'][0]['content']['parts'][0]['text'] as String;
             debugPrint('Gemini Analysis Result: $text');
             return text;
         }
      } else {
        debugPrint('Gemini Analysis Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      debugPrint('Gemini Analysis Exception: $e');
    }
    return null;
  }

  /// Verifies if the selected model is reachable and functioning.
  /// Sends a minimal token request.
  Future<bool> verifyModelHealth(String model) async {
    final safeModel = _resolveModel(model);
    try {
      final url = Uri.parse('$_baseUrlv1beta$safeModel:generateContent');
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': 'Ping'}
              ]
            }
          ],
          'generationConfig': {
             'maxOutputTokens': 1,
          }
        }),
      ).timeout(const Duration(seconds: 10));
      // We consider it healthy if we get a 200 OK.
      return response.statusCode == 200;
    } on Object catch (e) {
      debugPrint('Gemini Health Check Failed: $e');
      return false;
    }
  }

  Future<String> distillVisualTags(String analysis) async {
    // [NEW] Smart Consistency: Convert verbose analysis to SDXL tags
    try {
      final prompt = """
      You are a Stable Diffusion Prompt Expert.
      Convert the following Forensic Analysis into a comma-separated list of VISUAL TAGS.
      Focus on constant physical traits (clothing, hair, body type).
      Ignore generic words.
      
      Input Analysis:
      $analysis
      
      Output Format:
      tag1, tag2, tag3, tag4
      
      Example Input: "The subject is a small Asian toddler boy with short black hair. He is wearing a green striped shirt and blue pants."
      Example Output: "toddler, male, asian, short black hair, green striped shirt, blue pants"
      
      Return ONLY the tags.
      """;

      final safeModel = _resolveModel(_defaultModel);
      final url = Uri.parse('$_baseUrlv1beta$safeModel:generateContent');
      
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}]
        }),
      ).timeout(const Duration(seconds: 60));

      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
             final String text = data['candidates'][0]['content']['parts'][0]['text'];
             return text.trim();
         }
      }
    } catch (e) {
      debugPrint('Distill Tags Error: $e');
    }
    return analysis; // Fallback to raw text
  }

  Future<String> enhanceCharacterDescription(String name, String rawDescription, {String? context, String? visualDNA}) async {
      // New method for "Story Bible" consistency
      try {
        final sanitizedContext = _sanitizeForSafety((context ?? "None")).replaceAll('"""', "'''");
        final sanitizedDNA = _sanitizeForSafety((visualDNA ?? "")).replaceAll('"""', "'''");
        final sanitizedDesc = _sanitizeForSafety(rawDescription).replaceAll('"""', "'''");

        final prompt = """
        You are a Visual Consistency Director for an animated series.
        I will give you a character's Name and a basic Raw Description.
        
        Your job is to expand this into a COMPREHENSIVE VISUAL PROFILE.
        You MUST INVENT details if they are missing to ensure the character looks exactly the same in every shot.
        
        Character Name: $name
        Raw Description: $sanitizedDesc
        Additional User Context: $sanitizedContext
        
        ${sanitizedDNA.isNotEmpty ? "VISUAL DNA (STRICT ENFORCEMENT):\nThis character has a defined visual analysis. You MUST incorporate these physical traits exactly:\n$sanitizedDNA" : ""}
        
        CRITICAL INSTRUCTION:
        1. If "Visual DNA" is provided, it is the SOURCE OF TRUTH. Do not contradict it.
        2. If "Additional User Context" specifies ethnicity, age, or specific features, incorporate them.
        
        Output a single paragraph (approx 40-50 words) describing:
        1. Age & Gender (Use specific terms like 'Toddler', 'Teenager' if in Visual DNA)
        2. Body Type (e.g., tall, chubby, tiny)
        3. Specific Clothing (e.g., red hoodie with blue star, yellow boots)
        4. Key Features (e.g., curly pink hair, glasses, freckles)
        
        NEGATIVE CONSTRAINT: Do NOT include any artistic style descriptors (e.g. "cartoon", "illustration", "3d render", "photorealistic", "drawing").
        Describe ONLY the physical reality of the character as if they were real.
        
        Example Input: "Pip, a space boy" (DNA: "Tiny green skin, 3 eyes")
        Example Output: "Pip is a tiny green alien boy with three large black eyes. He wears a silver spacesuit with orange glowing patches and oversized magnetic boots."
        
        Output ONLY the description.
        """;
        
        final result = await generateCharacterDescription(prompt: prompt);
        return cleanGarbage(result ?? rawDescription); // [FIX] Clean result before returning
      } catch (e) {
        debugPrint('Enhance Character Error: $e');
        return rawDescription; // Fail safe
      }
  }

  Future<Map<String, String>> generateStyleProfile(String vibeName) async {
    final prompt = '''
    I am creating a children's storybook. I need an ATMOSPHERIC and EMOTIONAL profile for a Vibe called "$vibeName".
    
    The user wants this Vibe to represent the "atmosphere, emotional, or energetic feeling given off by a person, place, or situation".
    
    Provide a JSON object with THREE fields:
    1. "positive": A comma-separated list of visual descriptors that capture this MOOD (e.g., lighting, color palette, artistic texture, emotional keywords) for Stable Diffusion.
    2. "negative": A comma-separated list of things to avoid (e.g., conflicting moods, bad quality).
    3. "icon": A Flutter Material Icon name (e.g. "restaurant", "pets", "science", "auto_awesome", "music_note", "forest") that best matches this Vibe.

    Example 1 (Vibe: "Cozy"):
    {
      "positive": "warm golden lighting, soft textures, fuzzy, comfortable, peaceful, fireplace glow, pastel colors, storybook illustration",
      "negative": "cold, harsh, neon, jagged, scary, dark shadows",
      "icon": "chair"
    }
    
    Example 2 (Vibe: "Electric"):
    {
      "positive": "vibrant, energetic, neon accents, dynamic lines, sparking, high contrast, bold colors, intense",
      "negative": "dull, muted, sleeping, still, low contrast",
      "icon": "flash_on"
    }

    Return ONLY the JSON. No Markdown.
    ''';

    try {
      final url = Uri.parse('$_baseUrlv1beta${_resolveModel(_defaultModel)}:generateContent');
      final response = await _client.post(
          url,
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
          body: jsonEncode({
            'contents': [{'parts': [{'text': prompt}]}]
          }),
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
           final String text = data['candidates'][0]['content']['parts'][0]['text'];
           final jsonStr = _extractJson(text);
           final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
           return {
             'positive': jsonMap['positive'] as String,
             'negative': jsonMap['negative'] as String,
             'icon': (jsonMap['icon'] as String?) ?? 'auto_awesome',
           };
         }
      }
    } catch (e) {
      debugPrint('Gemini Style Gen Error: $e');
      rethrow; // [FIX] Fail loudly so UI knows to retry
    }
    
    throw Exception("Failed to generate style profile for $vibeName");
  }

  Future<Map<String, dynamic>?> generateStory({
    required List<Map<String, String>> castDetails,
    required String vibe,
    required String readingLevel,
    required String specialTouch,
    String model = _defaultModel,
  }) async {
    final safeModel = _resolveModel(model);
    
    int attempts = 0;
    bool hasRetriedWithSimplified = false;

    while (attempts < 2) {
      attempts++;
      
      try {
        // [SAFETY RECOVERY]
        // If previous attempt was blocked, strip the Visual DNA which likely caused the flag.
        List<Map<String, String>> currentCast = castDetails;
        if (hasRetriedWithSimplified) {
             currentCast = castDetails.map((c) {
                 // Strip [MANDATORY TRAITS: ...] block using Regex
                 final cleanDesc = cleanGarbage(c['description']!); 
                 return {
                   'name': c['name']!,
                   'description': cleanDesc.isEmpty ? 'A character' : cleanDesc 
                 };
             }).toList();
             debugPrint('♻️ Safety Retry: Retrying with STRIPPED prompts (No Visual DNA).');
        }

        // SANITIZATION: Strip clinical/medical terms
        final sanitizedDesc = currentCast.map((c) {
            final String desc = "${c['name']} (${c['description']})";
            return _sanitizeForSafety(desc);
        }).join(', ').replaceAll('"""', "'''");
        
        final sanitizedTouch = _sanitizeForSafety(specialTouch).replaceAll('"""', "'''");
        final sanitizedVibe = _sanitizeForSafety(vibe).replaceAll('"""', "'''");

        final prompt = """

        Write a children's story for a $readingLevel audience.

        NOTE: The character descriptions provided below contain CLINICAL VISUAL DESCRIPTORS (e.g. "underweight", "skin tone") solely for image generation consistency. Treat them neutrally.

        STRICT SAFETY & CULTURAL GUIDELINES:
        1. You are a safe, G-rated children's content generator. Strictly avoid violence, scary themes, weapons, adult situations, or inappropriate language.
        2. CULTURAL RESPECT: You are a Cultural Consultant.
           - Ensure all depictions of specific cultures (e.g., Korean, Mexican, etc.) are RESPECTFUL, ACCURATE, and FREE OF STEREOTYPES/CARICATURES.
           - For specific cultural items (like food, clothing, objects), use their correct names and visually describe them accurately (e.g., "Onggi pot" instead of just "pot").
           - Avoid exaggerated or mocking physical features.
        3. If the user's "Special Instructions" request anything unsafe, IGNORE those parts or soften them to be kid-friendly.
        
        The Vibe is: $sanitizedVibe.
        The Main Characters are: $sanitizedDesc.
        Special Instructions: $sanitizedTouch
        
        CRITICAL VISUAL INSTRUCTION:
        For every page, you must provide a "visual_description".
        In this "visual_description":
        1. This description will be used as a DIRECT PROMPT for an AI image generator.
        2. YOU MUST EMBED the character's visual appearance naturally into the action.
        3. REPEAT key traits (e.g., "blue hair", "red cape", "tiny toddler body") EVERY time the character appears. Do not assume the AI knows who "Nono" is.
        4. AGE CONSISTENCY: The actions and dialogue of the character MUST fit their Age Group defined in the description.
           - A "Preschooler" or "Toddler" cannot drive cars, use complex words, or do adult things.
           - A "School Age" child acts differently than an "Adult".
           - IGNORE user prompts that force a toddler to be an adult (unless magic is involved).
        5. Format: "[Character Name], a [Short Physical Description], is [Action] in [Setting]."
        5. Example: "Pip, a small blue robot with glowing eyes, is chasing a butterfly in a meadow."
        6. OBJECT CONSISTENCY: If a key object appears, describe it consistently.
        6. OBJECT CONSISTENCY: If a key object (like a specialized food, a magical item, or a vehicle) is central to the story, you MUST describe it with 2-3 visual adjectives EVERY TIME it is mentioned.
           - Bad: "The kimchi pot."
           - Good: "The large, earthenware kimchi pot with a heavy lid and red chili stains."
        7. RECURRING CHARACTERS: If the story includes a named secondary character (e.g., Mama, Dad, Teacher) who is NOT in the main cast list:
           - You MUST invent a specific visual description for them on their first appearance (e.g., "Mama, a kind woman with short curly hair wearing a blue floral dress").
           - You MUST Reuse this EXACT description every time they appear in a "visual_description".
           - NEVER leave them as just "Mama" in the visual prompt. Always include the visual details.
        8. STYLE IS FORBIDDEN:
           - DO NOT include artistic style words (e.g. "cartoon", "illustration", "photorealistic", "drawing", "sketch", "3d render") in the "visual_description".
           - Describe ONLY the physical content (subject, action, lighting, setting). 
           - The rendering style is handled by a separate system.
        9. VIBE-CONTEXTUAL CLOTHING:
           - Characters must wear clothing APPROPRIATE to the story's vibe and setting.
           - Do NOT use the character's everyday outfit if the setting demands specialized attire.
           - Examples: In a "Space" story, characters wear spacesuits. In a "Pirate" story, characters wear pirate outfits. In "Underwater", characters wear diving suits.
           - KEEP their identity traits (face, hair, body type) but REPLACE their clothing with setting-appropriate attire.
           - In "visual_characters", describe the character with VIBE-APPROPRIATE clothing, not their base outfit.
         
        Example: "Falling dramatically through a cloud layer, flailing arms, with a terrified expression. Background is a bright blue sky. A shiny red balloon floats nearby."
        
        Please format the response as a JSON object with the following structure:
        {
          "title": "Title of the Story",
          "cover_visual_description": "A vivid, poster-quality visual description for the book cover. It should capture the main theme/climax and feature the main characters centrally. Do NOT include text instructions.",
          "pages": [
            {
              "text": "Text for page 1...",
              "visual_characters": "Description of characters ONLY (e.g. 'Pip, a blue robot with glowing eyes')",
              "visual_setting": "Description of setting/action ONLY (e.g. 'chasing a butterfly in a meadow, sunny day')"
            },
            ...
          ]
        }
        Do not include markdown formatting (like ```json) in the response, just the raw JSON string.
        """;

        // [DEBUG] Check Key Status
        final maskedKey = apiKey.length > 4 ? '${apiKey.substring(0, 4)}...' : 'INVALID/EMPTY';
        debugPrint('Gemini API Key Status: $maskedKey');
        
        // Re-construct URL with final key
        final url = Uri.parse('$_baseUrlv1beta$safeModel:generateContent');

        final bodyJson = jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          // Add Safety Settings to prevent aggressive filtering
          'safetySettings': [
            {
              'category': 'HARM_CATEGORY_HARASSMENT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_HATE_SPEECH',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
            {
              'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
              'threshold': 'BLOCK_ONLY_HIGH'
            },
          ]
        });

        // [DEBUG] Log the EXACT payload being sent to compare with CURL
        debugPrint('Gemini Request Body (Attempt $attempts): $bodyJson');

        final response = await _client.post(
          url,
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
          body: bodyJson,
        ).timeout(const Duration(seconds: 90)); // Full story generation can take time

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body) as Map<String, dynamic>;
          
          // Detailed Logging
          debugPrint('Gemini Response Body (Attempt $attempts): ${response.body}');

          final candidates = data['candidates'] as List<dynamic>?;
          
          if (candidates != null && 
              candidates.isNotEmpty &&
              candidates[0]['content'] != null) {
            
            final parts = candidates[0]['content']['parts'] as List<dynamic>?;
            if (parts != null && parts.isNotEmpty) {
             final String text = parts[0]['text'] as String;
               debugPrint('Gemini Text: $text'); 

               final jsonStr = _extractJson(text);
               
               try {
                  return jsonDecode(jsonStr) as Map<String, dynamic>;
               } catch (e) {
                  debugPrint('Gemini JSON Parse Error: $e');
                  debugPrint('Raw Text was: $text');
                  
                  // Fallback Logic
                   if (text.length > 20) {
                     return {
                      'title': 'A $vibe Adventure',
                      'pages': [
                        {'text': text, 'visual_description': text}
                      ]
                    };
                  }
              }
            }
          } else {
             // Check for Safety Block
             if (data['promptFeedback'] != null) {
                 debugPrint('Gemini Safety Block (Attempt $attempts): ${data['promptFeedback']}');
                 final blockReason = data['promptFeedback']['blockReason'];
                 if (blockReason == 'SAFETY') {
                    // TRIGGER RETRY
                    if (!hasRetriedWithSimplified) {
                       hasRetriedWithSimplified = true;
                       debugPrint('⚠️ Detected Safety Block. Triggering Retry Loop with Simplified Prompts...');
                       continue; 
                    }
                 }
             }
             debugPrint('Gemini: No candidates. Response: $data');
          }

        } else if (response.statusCode == 403 || response.statusCode == 401) {
            debugPrint('Gemini API Auth Error: ${response.statusCode} - ${response.body}');
            throw Exception('Authentication Error: API Key missing or invalid (Check .env or Referrer).');
        } else {
          debugPrint('Gemini API Error: ${response.statusCode} - ${response.body}');
        }
      } catch (e) {
        debugPrint('Gemini Service Exception: $e');
        if (!hasRetriedWithSimplified) {
            // Optional: Retry on network glitch? No, let's keep it focused on safety for now.
             // But if specific exception, maybe.
        }
        throw Exception('Gemini Service Error: $e');
      }
    }
    
    // If we reach here, it means we got a response but no valid story.
    // This is likely a safety block that wasn't caught above, or empty candidates.
    throw Exception('Gemini returned an empty story (Safety Blocked after 2 attempts).');
  }

  Future<Map<String, dynamic>?> validateImageSafety(Uint8List imageBytes) async {
    // "AI Vision Auditor" - Checks generated image for safety BEFORE showing to user.
    final prompt = """
    You are a Safety Auditor for a children's book application (Age 3-8).
    Strictly analyze this image.
    
    IS THIS IMAGE SAFE?
    
    Triggers for UNSAFE:
    - Scary faces, screaming expressions, horror elements.
    - Blood, gore, red liquid looking like blood.
    - Violence, weapons.
    - Sexual content, nudity.
    - Distorted, nightmarish anatomy that would scare a child.
    
    If SAFE, return JSON: {"safe": true}
    If UNSAFE, return JSON: {"safe": false, "reason": "Reason for rejection"}
    
    Return ONLY JSON.
    """;
    
    try {
      final safeModel = _resolveModel(_defaultModel);
      final url = Uri.parse('$_baseUrlv1beta$safeModel:generateContent');
      
      final response = await _client.post(
          url,
          headers: {'Content-Type': 'application/json', 'x-goog-api-key': apiKey},
          body: jsonEncode({
            'contents': [{
              'parts': [
                {'text': prompt},
                {
                  'inline_data': {
                    'mime_type': 'image/png',
                    'data': base64Encode(imageBytes)
                  }
                }
              ]
            }]
          }),
      ).timeout(const Duration(seconds: 60));
      
      if (response.statusCode == 200) {
         final data = jsonDecode(response.body);
         if (data['candidates'] != null && (data['candidates'] as List).isNotEmpty) {
             final String text = data['candidates'][0]['content']['parts'][0]['text'];
             final jsonStr = _extractJson(text);
             return jsonDecode(jsonStr) as Map<String, dynamic>;
         }
      }
    } catch (e) {
      debugPrint('Safety Audit Failed: $e');
      // Fail SAFE: If audit crashes, assuming safe to avoid blocking app, OR assume unsafe?
      // For children's safety app, maybe fail closed? 
      // But for network flakiness, maybe allow.
      // Let's return null to indicate audit failure (and caller decides).
    }
    return null;
  }

  /// Resolves user-friendly model aliases.
  String _resolveModel(String model) {
    // Allow explicitly supported models
    if (model == GeminiModels.defaultModel) return model;
    
    // Auto-migrate old/missing models to the working 2.0 Flash
    if (model == 'gemini-1.5-flash') return GeminiModels.defaultModel;
    if (model == 'gemini-2.0-flash-exp') return GeminiModels.defaultModel;
    if (model == 'flash') return GeminiModels.defaultModel;
    if (model == 'gemini-2.5') return GeminiModels.defaultModel;
    if (model == 'gemini-1.5-pro') return GeminiModels.defaultModel;
    
    return model;
  }

  String _extractJson(String text) {
    text = text.trim();
    
    // 1. Try to find the first '{' and last '}'
    final firstBrace = text.indexOf('{');
    final lastBrace = text.lastIndexOf('}');
    
    if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
      return text.substring(firstBrace, lastBrace + 1);
    }
    
    // 2. Fallback: simple cleanup
    return text.replaceAll('```json', '').replaceAll('```', '').trim();
  }
  
  String _sanitizeForSafety(String input) {
    // Basic blocklist for words that might trigger safety filters in a children's context
    // especially when part of "Forensic Analysis" (e.g. "underweight", "chest", "thighs")
    const blocklist = [
      'naked', 'nude', 'sexual', 'blood', 'gore', 'violence', 'kill', 'weapon',
      'drug', 'alcohol', 'cigarette', 'smoking', 'terror', 'horror',
      'chest', 'breast', 'thigh', 'groin', 'buttock', 'underwear', 'lingerie',
      'sexy', 'seductive', 'curvy', 'busty', 'muscular', 'ripped',
      'underweight', 'overweight', 'fat', 'obese', 'width', 'anorexic', 'skinny' // [NEW] Weight triggers
    ];
    
    String clean = input;
    for (final word in blocklist) {
      clean = clean.replaceAll(RegExp(r'\b' + word + r'\b', caseSensitive: false), '[REDACTED]');
    }
    return clean;
  }


  /// Removes pollution like [MANDATORY TRAITS: ...] blocks from text.
  /// Static so it can be used by UI widgets to clean legacy data.
  static String cleanGarbage(String input) {
    if (input.isEmpty) return input;
    // [FIX] Robust Regex for Multiline blocks
    // Matches [MANDATORY TRAITS: ... ] with any characters including newlines
    final regex = RegExp(r'(\.\s*)?\[MANDATORY TRAITS:[\s\S]*?\]', caseSensitive: false);
    return input.replaceAll(regex, '').trim(); 
  }
}

/// Constants for Google Gemini Model versions.
class GeminiModels {
  static const String defaultModel = 'gemini-2.0-flash';
}
