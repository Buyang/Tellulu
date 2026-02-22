import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:tellulu/common/utils/prompt_utils.dart';
import 'package:tellulu/features/stories/consistency_engine.dart';
import 'package:tellulu/services/gemini_service.dart'; // [FIX] Ensure import // [NEW]

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
    Future<void> Function(Map<String, dynamic> draft)? onIntermediateSave, // [NEW] Safety Net
    double? cfgScale, // [NEW] Consistency setting
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
       final enhancedDesc = await geminiService.enhanceCharacterDescription(
           name, 
           rawDesc,
           context: specialTouch, // Pass user context
           visualDNA: c['forensicAnalysis'] as String?, // [NEW] Pass Forensic Context
       );
       
       // [FIX] Forcefully embed the Visual DNA into the description specifically for the Story Writer
       final String dna = c['forensicAnalysis'] as String? ?? "";
       final String finalDescForStory = dna.isNotEmpty 
           ? "$enhancedDesc. [MANDATORY TRAITS: $dna]" 
           : enhancedDesc;

       return {
         'name': name,
         'description': finalDescForStory, // Use the UPGRADED description + DNA
       };
    });
    
    castDetails = await Future.wait(futures);

 
    
    // Seed for Visual Consistency (One seed to rule them all)
    final int storySeed = DateTime.now().millisecondsSinceEpoch % 4294967295;
    
    // [FIX] Generate ID once for consistency between Draft and Final
    final String storyId = DateTime.now().millisecondsSinceEpoch.toString();

    // 2. Generate Story Text
    onProgress('Weaving story text...');
    Map<String, dynamic>? story;
    try {
      story = await geminiService.generateStory(
        castDetails: castDetails, // Pass rich details
        vibe: vibe,
        readingLevel: readingLevel,
        specialTouch: specialTouch,
        model: geminiModel, 
      );
    } catch (e) {
      // [FIX] Catch specific Gemini errors and bubble them up clearly
      final msg = e.toString();
      if (msg.contains('Authentication Error')) {
         throw Exception("Configuration Error: API Key missing or invalid. Please check your settings.");
      } else if (msg.contains('Safety') || msg.contains('safety')) {
         throw Exception("Story Blocked by Safety Filters. Please try a different Vibe or softer instructions.");
      } else if (msg.contains('API Error')) {
         throw Exception("AI Service Unavailable. Please try again later.");
      }
      throw Exception("Story Generation Failed: ${msg.replaceAll('Exception:', '').trim()}");
    }

    if (story == null) {
      throw Exception("Story generation returned empty result. (Unknown Cause)");
    }

    // 3. Generate Cover Image (using Stability AI)
    onProgress('Painting the cover...');
    String? coverBase64;
    
    // [NEW] Intelligent Style Merging: Avatar Style + Vibe Atmosphere
    // 1. Get the Vibe (Atmosphere) & Fail Fast
    final consistency = ConsistencyEngine();
    final vibeRules = consistency.getStyle(vibe) ?? _getEmergencyFallback(vibe);
    
    // [NEW] Smart Consistency: Distill Visual Tags
    String visualTags = "";
    if (selectedCast.isNotEmpty) {
      final mainChar = selectedCast.first;
      final dna = mainChar['forensicAnalysis'] as String?;
      if (dna != null && dna.isNotEmpty) {
         onProgress('Optimizing visual consistency...');
         visualTags = await geminiService.distillVisualTags(dna);
         debugPrint("🧪 Distilled Consistency Tags: $visualTags");
      }
    }

    // 2. Get the Avatar Style (Rendering)
    // We prioritize the first character's style as the "Showrunner" visual style
    StoryStyle finalStyle = vibeRules;
    String combinedPositive = vibeRules.positivePrompt;
    String combinedNegative = vibeRules.negativePrompt;

    if (selectedCast.isNotEmpty && selectedCast.first['style'] != null) {
       final String avatarStyleKey = selectedCast.first['style'] as String;
       final avatarRules = consistency.getStyle(avatarStyleKey);
       
       if (avatarRules != null) {
          // MERGE STRATEGY: 
          // - Preset: Avatar Style (Visuals must match characters)
          // - Prompt: Avatar Keywords ONLY. Vibe Keywords are ignored to prevent style conflict.
          // - DNA Tags: Injected via Weighted Prompts (High priority)
          finalStyle = avatarRules; 
          
          // STRICT SEPARATION: Visual Style rules rendering. Vibe rules content (via Gemini).
          combinedPositive = avatarRules.positivePrompt;
          combinedNegative = avatarRules.negativePrompt;
          
          debugPrint('✨ Style Strategy: Visuals [${avatarRules.name}] | Content Vibe [${vibeRules.name}]');
          debugPrint('🎨 DEBUG: Initial Generation Style Preset: "${finalStyle.stylePreset}"');
       } else {
          debugPrint('⚠️ WARNING: Avatar Style "$avatarStyleKey" not found in registry. Falling back to Vibe "${vibeRules.name}".');
          // Fallback to Vibe is cleaner than crashing
       }
    } else {
       debugPrint('✨ Style Strategy: Pure Vibe [${vibeRules.name}]');
       debugPrint('🎨 DEBUG: Initial Generation Style Preset: "${finalStyle.stylePreset}"');
    }
    
    // ... [Resize Logic] ...

    // 3b. Generate Cover Image
    final String coverClothingHint = PromptUtils.getVibeClothingHint(vibe);
    final String coverPromptText = '${combinedPositive}, children\'s book cover illustration'
        '${coverClothingHint.isNotEmpty ? ", $coverClothingHint" : ""}'
        '${visualTags.isNotEmpty ? ", $visualTags" : ""}';

    try {
      onProgress('Painting the cover...');
      coverBase64 = await stabilityService.generateImage(
        prompt: GeminiService.cleanGarbage(coverPromptText),
        negativePrompt: combinedNegative,
        stylePreset: finalStyle.stylePreset,
        modelId: stabilityModel,
        seed: storySeed,
        cfgScale: (cfgScale ?? 0) + finalStyle.cfgScaleAdjustment,
      );
      debugPrint('✅ Cover image generated successfully');
    } catch (e) {
      // [LOUD FALLBACK] Cover generation failure is non-fatal.
      // Story saves with coverBase64: null; UI handles this gracefully.
      debugPrint('⚠️ COVER GENERATION FAILED: $e — Story will have no cover image.');
    }

    // 4. Generate Images ensuring Consistency
    onProgress('Illustrating pages...');


    // [NEW] SAFETY NET: Save Draft
    if (onIntermediateSave != null) {
       debugPrint('💾 Safety Net: Saving text-only draft before image generation...');
       final draftStory = {
          'id': storyId, // [FIX] Consistent ID
          'title': story['title'],
          'pages': story['pages'], // Text only pages
          'date': DateTime.now().toIso8601String(),
          'vibe': vibe, // [FIX] Include Vibe
          'coverBase64': null, 
          'cast': castDetails.map((c) => {
               // Re-merge original cast data with enhanced descriptions
               ...selectedCast.firstWhere((o) => o['name'] == c['name'], orElse: () => {}), 
               'description': c['description']
           }).toList(),
          'seed': storySeed,
       };
       
       await onIntermediateSave(draftStory);
    }
    
    // Normalize pages deeply first
    final List<Map<String, dynamic>> workingPages = (story['pages'] as List).map((p) {
      if (p is String) return {'text': p, 'visual_description': p};
      return Map<String, dynamic>.from(p as Map);
    }).toList();

     // Iterate consistently
    for (int i = 0; i < workingPages.length; i++) {
       final page = workingPages[i];
       
       // [NEW] Weighted Prompt Logic using Distilled Tags
       final String? chars = page['visual_characters']; 
       final String? setting = page['visual_setting']; 
       final String legacyDesc = page['visual_description'] ?? page['text'];

       // [FIX V10] Strip base clothing from character description
       final String cleanChars = chars != null ? PromptUtils.stripClothing(GeminiService.cleanGarbage(chars)) : '';
       final String cleanSetting = setting != null ? GeminiService.cleanGarbage(setting) : '';
       
       // [FIX V10] Vibe-contextual clothing hint
       final String clothingHint = PromptUtils.getVibeClothingHint(vibe);

       final String fullPromptLegacy = "$legacyDesc. $combinedPositive";
       List<Map<String, dynamic>>? weightedPrompts;
       
       // Scenario A: We have rich tags (Visual DNA)
       if (visualTags.isNotEmpty) {
           // [FIX] Invert Weights: Dynamic Story overrides Static DNA
           // If we have specific page details, use them!
           if (chars != null && setting != null) {
              weightedPrompts = [
                 if (clothingHint.isNotEmpty) {'text': clothingHint, 'weight': 1.2}, // [V10] Vibe clothing (high priority)
                 {'text': cleanSetting, 'weight': 1.5}, // [V10] Scene/Setting (Primary - was chars)
                 {'text': cleanChars, 'weight': 1.0}, // [V10] Character identity without clothing
                 {'text': visualTags, 'weight': 0.8}, // Static DNA 
                 {'text': combinedPositive, 'weight': 1.0}, // [FIX] Boosted Style Weight to 1.0
              ];
           } else {
              // Fallback 
              weightedPrompts = [
                 if (clothingHint.isNotEmpty) {'text': clothingHint, 'weight': 1.2},
                 {'text': visualTags, 'weight': 1.2},
                 {'text': GeminiService.cleanGarbage(legacyDesc), 'weight': 1.0},
                 {'text': combinedPositive, 'weight': 1.0}, // [FIX] Boosted Style Weight
              ];
           }
       } 

       // Scenario B: No DNA, just Page Details
       else if (chars != null && setting != null) {
          weightedPrompts = [
             if (clothingHint.isNotEmpty) {'text': clothingHint, 'weight': 1.2}, // [V10] Vibe clothing
             {'text': cleanSetting, 'weight': 1.5}, // [V10] Scene first
             {'text': cleanChars, 'weight': 1.0}, // [V10] Character identity
             {'text': combinedPositive, 'weight': 1.0}, // [FIX] Boosted Style Weight
          ];
       }
       
       onProgress('Illustrating page ${i + 1} of ${workingPages.length}...');
       
       String? acceptedImageBase64;
       int attempts = 0;
       
        // Loop for Safety Check and Stability
        // We use exponential backoff: 2s, 4s, 8s
        while (attempts < 3 && acceptedImageBase64 == null) {
          attempts++;
          if (attempts > 1) {
             final delay = Duration(seconds: pow(2, attempts).toInt()); // 2s, 4s, 8s
             // Update status for user visibility
             if (attempts > 1) onProgress('Retrying image for page ${i + 1} (Attempt $attempts/3)...');
             
             debugPrint('⏳ Stability 503/Error. Retrying in ${delay.inSeconds}s (Attempt $attempts/3)...');
             await Future.delayed(delay);
          }
 
          try {
             final candidateBase64 = await stabilityService.generateImage(
                 prompt: GeminiService.cleanGarbage(fullPromptLegacy), 
                 weightedPrompts: weightedPrompts,
                 stylePreset: finalStyle.stylePreset,
                 modelId: stabilityModel,
                 seed: storySeed + attempts, // Shift seed slightly for retry
                 cfgScale: (cfgScale ?? 0) + finalStyle.cfgScaleAdjustment,
                 negativePrompt: combinedNegative,
            );
             
             if (candidateBase64 != null) {
                // --- SAFETY AUDIT ---
                final bytes = base64Decode(candidateBase64);
                final audit = await geminiService.validateImageSafety(bytes);
                
                if (audit != null && audit['safe'] == true) {
                  acceptedImageBase64 = candidateBase64;
                } else {
                  debugPrint('⚠️ UNSAFE IMAGE BLOCKED: ${audit?['reason'] ?? "Unknown"}');
                  onProgress('Re-generating safe content...'); 
                  // Don't count unsafe content as a "server error" retry, but we need a new seed
                  // so we continue the loop but maybe don't backoff as aggressively? 
                  // For now, simple loop is fine.
                }
             }
          } on Object catch (e) {
            debugPrint('❌ Image Gen Error for page $i (Attempt $attempts): $e');
            // If it's a 400 (Bad Request), retrying might not help unless we change params. 
            // But 500/503/504 definitely needs backoff.
          }
        }

       if (acceptedImageBase64 != null) {
         workingPages[i]['image'] = acceptedImageBase64;
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
       'id': storyId, // [FIX] Consistent ID
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
  
  // _cleanPrompt removed in favor of GeminiService.cleanGarbage

  StoryStyle _getEmergencyFallback(String name) {
    debugPrint('🚨 CRITICAL: Style "$name" missing from ConsistencyEngine. Using Emergency Fallback (Digital Art).');
    return StoryStyle(
      name: name,
      positivePrompt: '$name style, colorful, highly detailed, storybook illustration',
      negativePrompt: 'low quality, blurry, text, watermark, distorted',
      stylePreset: 'digital-art', 
    );
  }
}
