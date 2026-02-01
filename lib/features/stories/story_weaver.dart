import 'dart:typed_data';
import 'package:image/image.dart' as img;
import 'package:tellulu/services/gemini_service.dart';
import 'package:tellulu/services/stability_service.dart';

class StoryWeaver {

  StoryWeaver({
    required this.geminiService,
    required this.stabilityService,
  });
  final GeminiService geminiService;
  final StabilityService stabilityService;

  /// Main method to weave a story from parameters.
  /// Returns the complete Story Map object or throws an error.
  Future<Map<String, dynamic>?> weave({
    required List<Map<String, dynamic>> selectedCast,
    required String vibe,
    required String readingLevel,
    required String specialTouch,
    required String stabilityModel,
    required String geminiModel,
    required void Function(String status) onProgress,
  }) async {
    // 1. Prepare rich cast details for Gemini & Enhancement
    List<Map<String, String>> castDetails = [];

    onProgress('Enhancing character profiles...');
    // ENHANCEMENT STEP: Upgrade profiles for the "Story Bible"
    // We do this concurrently for speed
    final futures = selectedCast.map((c) async {
       final name = c['name'] as String;
       final rawDesc = (c['description'] ?? c['role'] ?? 'hero') as String;
       
       // Call Gemini to expand the profile
       // Note: We use the service's default model or the one configured if we passed it down, 
       // but mostly enhancement is fine with standard models.
       final enhancedDesc = await geminiService.enhanceCharacterDescription(name, rawDesc);
       
       return {
         'name': name,
         'description': enhancedDesc, // Use the UPGRADED description
       };
    });
    
    castDetails = await Future.wait(futures);

    final List<String> castNames = selectedCast.map((c) => c['name'] as String).toList(); 
    
    // Seed for Visual Consistency (One seed to rule them all)
    final int storySeed = DateTime.now().millisecondsSinceEpoch % 4294967295;

    // 2. Generate Story Text
    onProgress('Weaving story text...');
    final story = await geminiService.generateStory(
      castDetails: castDetails, // Pass rich details
      vibe: vibe,
      readingLevel: readingLevel,
      specialTouch: specialTouch,
      model: geminiModel, 
    );

    if (story == null) {
      return null;
    }

    // 3. Generate Cover Image (using Stability AI)
    onProgress('Painting the cover...');
    String? coverBase64;
    // Helper to resize image
    if (selectedCast.isNotEmpty && selectedCast.first['imageBytes'] != null) {
        Uint8List seedImage = selectedCast.first['imageBytes'] as Uint8List;
        
        // Resize to 1024x1024 for SDXL
        try {
          final cmd = img.Command()
            ..decodeImage(seedImage)
            ..copyResize(width: 1024, height: 1024) 
            ..encodePng();
          final resizedBytes = await cmd.getBytesThread();
          if (resizedBytes != null) seedImage = resizedBytes;
        } on Object catch (e) {
          // ignore: avoid_print
          print('Error resizing cover seed image: $e');
        }

        try {
          coverBase64 = await stabilityService.generateImage(
              initImageBytes: seedImage,
              prompt: "Book cover for a children's story titled '${story['title']}'. featuring ${castNames.join(', ')}. Vibe: $vibe. Style: Watercolor.",
              stylePreset: 'digital-art', // Use digital-art preset for watercolor style
              modelId: stabilityModel,
              imageStrength: 0.3, // Low strength to allow more creative freedom for the cover
          );
        } on Object catch (e) {
           // ignore: avoid_print
           print('DEBUG: Cover generation failed: $e');
        }
    }

    // 4. Generate Images ensuring Consistency (Fixed 2.0 Profile + Global Seed)
    onProgress('Illustrating pages...');
    
    // Normalize pages deeply first
    final List<Map<String, dynamic>> workingPages = (story['pages'] as List).map((p) {
      if (p is String) return {'text': p, 'visual_description': p};
      return Map<String, dynamic>.from(p as Map);
    }).toList();

    // Iterate consistently
    for (int i = 0; i < workingPages.length; i++) {
       final page = workingPages[i];
       // Gemini now embeds the character details directly into this description
       final scene = page['visual_description'] ?? page['text']; 
       
       // We rely on Gemini's integrated prompt + Stability's Seed for the best balance
       final fullPrompt = "Children's storybook illustration. $scene. Style: $vibe watercolor, colorful, cute, highly detailed.";
       
       onProgress('Illustrating page ${i + 1} of ${workingPages.length}...');

       try {
          final imageBase64 = await stabilityService.generateImage(
              prompt: fullPrompt,
              stylePreset: 'digital-art',
              modelId: stabilityModel,
              seed: storySeed, // THE SECRET SAUCE: Same seed for every page
          );
          
          if (imageBase64 != null) {
            workingPages[i]['image'] = imageBase64;
          }
       } on Object catch (e) {
         // ignore: avoid_print
         print('Image Gen Error for page $i: $e');
       }
    }


    // 5. Construct Story Object
    // Convert enhanced castDetails back to full map structure for storage
    // merging original data (colors, images) with enhanced descriptions
    final List<Map<String, dynamic>> finalCast = selectedCast.map((original) {
        final enhanced = castDetails.firstWhere((e) => e['name'] == original['name'], orElse: () => {'description': (original['description'] as String?) ?? ''});
        return {
          ...original,
          'description': enhanced['description'], // Persist the ENHANCED description
        };
    }).toList();
    
    final newStory = {
       'id': DateTime.now().millisecondsSinceEpoch.toString(),
       'title': story['title'],
       'pages': workingPages, // Use the pages with images!
       'date': DateTime.now().toIso8601String(),
       'vibe': vibe,
       'coverBase64': coverBase64, // Can be null
       'cast': finalCast, // Save ENHANCED cast for consistent illustrations
       'seed': storySeed, // Save the Magic Seed!
    };
    
    return newStory;
  }
}
