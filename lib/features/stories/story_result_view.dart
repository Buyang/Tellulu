import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tellulu/common/utils/prompt_utils.dart';
import 'package:tellulu/features/stories/consistency_engine.dart'; // [FIX] Added Import
import 'package:tellulu/services/gemini_service.dart'; // [FIX] Added Import
import 'package:tellulu/services/stability_service.dart';

class StoryResultView extends StatefulWidget { // Callback to save changes to parent list

  const StoryResultView({
    required this.story, required this.onBack, required this.onSave, 
    required this.geminiService, required this.stabilityService, 
    this.onRestore, // [NEW] Undo Capability
    this.cfgScale, // [V10] From creativity setting
    this.stabilityModel, // [V10] From settings provider
    super.key,
  });
  final Map<String, dynamic> story;
  final VoidCallback onBack;
  final void Function(Map<String, dynamic>) onSave;
  final Future<Map<String, dynamic>?> Function()? onRestore; // [NEW] Returns restored story or null
  final GeminiService geminiService;
  final StabilityService stabilityService;
  final double? cfgScale; // [V10] User's creativity-derived CFG scale
  final String? stabilityModel; // [V10] User's selected stability model

  @override
  State<StoryResultView> createState() => _StoryResultViewState();
}

class _StoryResultViewState extends State<StoryResultView> {
  late Map<String, dynamic> _storyData;
  late List<Map<String, dynamic>> _pages; // Strictly typed now
  
  final PageController _pageController = PageController();
  int _currentPage = 0;
  int? _generatingPageIndex; // Track which page is loading
  
  // Track regen attempts to vary the seed deterministically
  final Map<int, int> _regenCounts = {};

  @override
  void initState() {
    super.initState();
    _storyData = widget.story;
    _initPages();
    
    // [FIX] CLEAN ON LOAD - SAFE MODE
    _repairPollutedDataSafe();
  }

  void _initPages() {
    final rawPages = _storyData['pages'] as List<dynamic>? ?? [];
    
    _pages = rawPages.map<Map<String, dynamic>>((p) {
      if (p is String) {
        return {
          'text': p,
          'visual_description': p,
          'image': null,
          'style': {'color': Colors.black87.toARGB32(), 'fontSize': 18.0, 'fontFamily': 'Quicksand'}
        };
      }
      if (p is Map) {
         return Map<String, dynamic>.from(p);
      }
      return {'text': '', 'image': null}; 
    }).toList();
  }
  
  void _repairPollutedDataSafe() {
     final List<dynamic> cast = _storyData['cast'] as List<dynamic>? ?? [];
     bool needsSave = false;
     
     for (var c in cast) {
        if (c is Map) {
           final String desc = (c['description'] as String?) ?? '';
           final String clean = GeminiService.cleanGarbage(desc);
           if (clean != desc) {
              debugPrint('🧹 Safe Repair: Cleaning polluted character: ${c['name']}');
              c['description'] = clean;
              needsSave = true;
           }
        }
     }
     
     if (needsSave) {
        final pages = _storyData['pages'] as List<dynamic>? ?? [];
        if (pages.isEmpty) {
           debugPrint('⚠️ ABORTING SAVE: Pages list is empty! Cannot safely repair.');
           return;
        }

        debugPrint('💾 Safe Save: Casting repaired data to storage...');
        Future.microtask(() => widget.onSave(_storyData));
     }
  }

  void _saveChanges() {
     _storyData['pages'] = _pages;
     widget.onSave(_storyData);
  }

  Future<void> _handleUndo() async {
     if (widget.onRestore == null) return;
     
     final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
           title: const Text('Undo Last Change?'),
           content: const Text('Revert to the previous saved version? Current unsaved changes will be lost.'),
           actions: [
              TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
              TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Undo')),
           ],
        ),
     );
     
     if (confirm == true) {
        final restored = await widget.onRestore!();
        if (restored != null && mounted) {
           setState(() {
              _storyData = restored;
              _initPages(); // Re-parse pages
           });
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Restored previous version!')));
        } else if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No previous version to restore.')));
        }
     }
  }

  @override
  Widget build(BuildContext context) {
    final title = (_storyData['title'] as String?) ?? 'My Story';

    return Column(
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
               // Back Button (already in parent? No, onBack handles it)
               IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack),
               
               // Title
               Flexible( // Use flexible to avoid overflow
                  child: Text(
                    title,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.chewy(
                       textStyle: Theme.of(context).textTheme.titleLarge,
                      fontSize: 24,
                      color: const Color(0xFF9FA0CE),
                    ),
                  ),
               ),
               
               // Undo Button
               if (widget.onRestore != null)
                 IconButton(
                    icon: const Icon(Icons.undo),
                    onPressed: _handleUndo,
                    tooltip: 'Undo last save',
                 )
               else 
                 const SizedBox(width: 48), // Spacer
            ],
          ),
        ),
        const SizedBox(height: 8),
        
        // Pages with Navigation Arrows
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
               PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  return _buildPageItem(index);
                },
              ),
              
              // Previous Button (Floating)
              if (_currentPage > 0)
                Positioned(
                  left: 8,
                  child: IconButton(
                    onPressed: () => _pageController.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    icon: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.8),
                      child: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black87),
                    ),
                  ),
                ),
                
               // Next Button (Floating)
              if (_currentPage < _pages.length - 1)
                Positioned(
                  right: 8,
                  child: IconButton(
                    onPressed: () => _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut),
                    icon: CircleAvatar(
                      backgroundColor: Colors.white.withValues(alpha: 0.8),
                      child: const Icon(Icons.arrow_forward_ios, size: 20, color: Colors.black87),
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        // Indicator
        Text('Page ${_currentPage + 1} of ${_pages.length}', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        
        const SizedBox(height: 16),
        // Actions
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionChip(Icons.share, 'Share'),
            _buildActionChip(Icons.download, 'Download'),
            _buildActionChip(Icons.print, 'Print'),
          ],
        ),
      ],
    );
  }

  Widget _buildPageItem(int index) {
      final pageData = _pages[index];
      final text = pageData['text'] as String;
      final imageBase64 = pageData['image'] as String?;
      final styleData = pageData['style'] as Map<String, dynamic>? ?? {};
      
      final savedColorValue = styleData['color'];
      Color displayColor;

      // Logic: If saved color is explicitly null, use Theme.
      // If saved color is "Black", but we are in Dark Mode, force White (unless explicitly customized to black? For now assume adaptive).
      if (savedColorValue == null) {
          displayColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
      } else {
         displayColor = Color((savedColorValue as num).toInt());
         // Auto-adapt legacy black text to white in dark mode if it matches standard black
         final isDarkMode = Theme.of(context).brightness == Brightness.dark;
         if (isDarkMode && displayColor.toARGB32() == Colors.black87.toARGB32()) {
            displayColor = Colors.white; 
         }
      }

      final style = TextStyle(
         color: displayColor,
         fontSize: (styleData['fontSize'] as num?)?.toDouble() ?? 18.0,
         fontFamily: (styleData['fontFamily'] as String?) ?? 'Quicksand',
         height: 1.5,
      );

      return SingleChildScrollView(
        child: Column(
          children: [
            // Illustration Area
            GestureDetector(
              onTap: () => _handleImageTap(index),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 500), // Prevent massive images on desktop
                  child: AspectRatio(
                    aspectRatio: 1.0, // Square container for square images
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF9E6),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black87),
                        image: imageBase64 != null 
                          ? DecorationImage(
                              image: MemoryImage(base64Decode(imageBase64)),
                              fit: BoxFit.contain // Ensure WHOLE image is seen
                            )
                          : null,
                      ),
                  child: imageBase64 == null 
                    ? Center(
                        child: _generatingPageIndex == index
                          ? const CircularProgressIndicator()
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                 const Icon(Icons.brush, size: 48, color: Color(0xFF9FA0CE)),
                                 const SizedBox(height: 8),
                                 Text('Tap to Weave Illustration', style: GoogleFonts.quicksand(color: Colors.black54, fontWeight: FontWeight.bold))
                              ],
                          ),
                      )
                    : Stack(
                        children: [
                          Positioned.fill(child: _generatingPageIndex == index 
                              ? const ColoredBox(color: Colors.white54, child: Center(child: CircularProgressIndicator()))
                              : const SizedBox.shrink()
                          ),
                          if (_generatingPageIndex != index) // Only show refresh if not currently loading
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () => _handleImageTap(index, forceRegenerate: true),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.8),
                                  shape: BoxShape.circle,
                                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                ),
                                child: const Icon(Icons.refresh, color: Colors.black87, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                  ),
                ),
              ),
            ),
            
            // Editable Text Area
            GestureDetector(
              onTap: () => _showEditDialog(index, text, styleData),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  text,
                  style: GoogleFonts.getFont(style.fontFamily!, textStyle: style),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text( // Hint
               'Tap text to edit style', 
               style: GoogleFonts.quicksand(fontSize: 10, color: Colors.grey[400])
            ),
            const SizedBox(height: 16),
            Text(
              '${index + 1} of ${_pages.length}',
              style: GoogleFonts.quicksand(color: Colors.black38),
            ),
          ],
        ),
      );
  }

  Future<void> _handleImageTap(int index, {bool forceRegenerate = false}) async {
      final pageData = _pages[index];
      if (pageData['image'] != null && !forceRegenerate) return; 
      
      setState(() => _generatingPageIndex = index); 
            try {
         // [FIX V10] Scene-First + Vibe-Contextual Clothing
         // SDXL processes prompts in ~77-token chunks. The FIRST chunk has the most influence.
         // Priority order: Style → Vibe Clothing → Scene Action → Character Identity
         
         String scenePart = '';
         String characterPart = '';
         
         if (pageData['visual_setting'] != null) {
             scenePart = GeminiService.cleanGarbage(pageData['visual_setting'] ?? '');
         }
         if (pageData['visual_characters'] != null) {
             characterPart = GeminiService.cleanGarbage(pageData['visual_characters'] ?? '');
         }
         
         // Fallback: use visual_description or raw text
         if (scenePart.isEmpty && characterPart.isEmpty) {
             scenePart = GeminiService.cleanGarbage(pageData['visual_description'] ?? pageData['text']);
         }
         
         // [FIX V10] Strip base clothing from character to avoid vibe conflicts
         // Remove clothing phrases so vibe context can guide attire
         characterPart = PromptUtils.stripClothing(characterPart);

         // [FIX] Dynamic Style Rules from Consistency Engine
         // 1. Check if the Main Character has a specific style (Avatar-Centric)
         final List<dynamic> cast = _storyData['cast'] as List<dynamic>? ?? [];
         String vibe = (_storyData['vibe'] as String?) ?? 'Magical'; 
         
         if (cast.isNotEmpty) {
             final mainChar = cast.first; // Usually the hero
             if (mainChar['style'] != null) {
                 vibe = mainChar['style'] as String;
                 debugPrint('DEBUG: Using Avatar Style: $vibe');
             }
         }
         
         // [FIX] Handle null style from ConsistencyEngine (Fail Safe)
         var styleRules = ConsistencyEngine().getStyle(vibe);
         if (styleRules == null) {
            debugPrint('🚨 CRITICAL: Style "$vibe" missing in ResultView. Using emergency fallback.');
            styleRules = StoryStyle(
               name: vibe,
               positivePrompt: '$vibe style, colorful, highly detailed',
               negativePrompt: 'low quality, blurry',
               stylePreset: 'digital-art', 
            );
         }

         debugPrint('🎨 DEBUG: Regeneration Vibe/Style selected: "$vibe" -> Preset: "${styleRules.stylePreset}"');
         
         // [FIX V10] Vibe-contextual clothing hint
         // The story vibe determines what characters should wear.
         // This overrides the base clothing from the character's Cast profile.
         final String storyVibe = (_storyData['vibe'] as String?) ?? '';
         final String clothingHint = PromptUtils.getVibeClothingHint(storyVibe);
         debugPrint('DEBUG: Story Vibe: "$storyVibe" -> Clothing Hint: "$clothingHint"');
         
         // [FIX V10] Prompt = Style → Clothing Context → Scene Action → Character Identity
         final String clothingPrefix = clothingHint.isNotEmpty ? '$clothingHint, ' : '';
         final prompt = "${styleRules.positivePrompt}, $clothingPrefix$scenePart. $characterPart";
         debugPrint('DEBUG: REGEN V10 (VibeAware) - Page ${index + 1} Prompt: $prompt');
         
         final int baseSeed = (_storyData['seed'] as int?) ?? 0;
         int currentRegenCount = _regenCounts[index] ?? 0;
         if (forceRegenerate) {
            currentRegenCount++;
            _regenCounts[index] = currentRegenCount;
         }
         
         final int? effectiveSeed = (baseSeed != 0) ? (baseSeed + (currentRegenCount * 12345)) : null;

         String? acceptedImageBase64;
         int attempts = 0;
         
         // [NEW] Retry Logic for Regeneration (Handle 503s)
         // Exponential backoff: 2s, 4s, 8s, 16s, 32s
         while (attempts < 5 && acceptedImageBase64 == null) {
             attempts++;
             if (attempts > 1) {
                // Backoff
                final delay = Duration(seconds: pow(2, attempts).toInt());
                debugPrint('⏳ Regen Stability 503/Error. Retrying in ${delay.inSeconds}s (Attempt $attempts/5)...');
                await Future.delayed(delay);
             }
             
             try {
                 // [FIX] Use injected service with CORRECT style rules
                 acceptedImageBase64 = await widget.stabilityService.generateImage(
                    prompt: prompt,
                    stylePreset: styleRules.stylePreset, 
                    modelId: widget.stabilityModel ?? 'stable-diffusion-xl-1024-v1-0',
                    seed: effectiveSeed != null ? effectiveSeed + attempts : null,
                    negativePrompt: styleRules.negativePrompt, // [NEW] Negative Prompt
                    cfgScale: (widget.cfgScale ?? 7.0) + styleRules.cfgScaleAdjustment, // [V10] Uses creativity setting
                 );
             } catch (e) {
                 debugPrint('❌ Regen Error (Attempt $attempts): $e');
             }
         }
         
         if (acceptedImageBase64 != null) {
            // --- SAFETY AUDIT ---
            final bytes = base64Decode(acceptedImageBase64);
            final audit = await widget.geminiService.validateImageSafety(bytes);
            
            if (audit != null && audit['safe'] == true) {
                 if (mounted) {
                    setState(() {
                       _pages[index]['image'] = acceptedImageBase64;
                    });
                    _saveChanges();
                 }
            } else {
                 debugPrint('⚠️ UNSAFE REGEN BLOCKED: ${audit?['reason'] ?? "Unknown"}');
                 if (mounted) {
                     ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Safety Guard: Image blocked (${audit?['reason'] ?? "Unsafe content"}). Try again.'),
                          backgroundColor: Colors.red,
                        )
                     );
                 }
            }
         } else {
            // Throw if all attempts failed
            throw Exception("Failed to regenerate image after $attempts attempts. Please try again.");
         }
      } on Object catch (e) {
             if (mounted) {
               ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to weave illustration: $e')));
             }
      } finally {
         if (mounted) setState(() => _generatingPageIndex = null);
      }
  }

  void _showEditDialog(int index, String currentText, Map<String, dynamic> currentStyle) {
      final TextEditingController textController = TextEditingController(text: currentText);
      double fontSize = (currentStyle['fontSize'] as num?)?.toDouble() ?? 18.0;
      
      // Resolve initial color for dialog
      Color fontColor = Color((currentStyle['color'] as int?) ?? Colors.black87.toARGB32());
      if (Theme.of(context).brightness == Brightness.dark && fontColor.toARGB32() == Colors.black87.toARGB32()) {
         fontColor = Colors.white;
      }
      // Simple font toggle for MVP
       final String fontFamily = (currentStyle['fontFamily'] as String?) ?? 'Quicksand'; 
      // ...
      showModalBottomSheet<void>(
         context: context,
         isScrollControlled: true,
         builder: (context) => StatefulBuilder(
            builder: (context, setSheetState) => Container(
               padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 24, right: 24, top: 24),
               child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                     Text('Edit Page', style: GoogleFonts.chewy(fontSize: 24)),
                     const SizedBox(height: 16),
                     TextField(
                        controller: textController,
                        maxLines: 4,
                        decoration: const InputDecoration(border: OutlineInputBorder(), labelText: 'Content'),
                     ),
                     const SizedBox(height: 16),
                     Row(
                        children: [
                           Text('Size: ${fontSize.toInt()}', style: GoogleFonts.quicksand()),
                           Expanded(
                              child: Slider(
                                 value: fontSize, 
                                 min: 12, max: 36, 
                                 onChanged: (v) => setSheetState(() => fontSize = v)
                              ),
                           ),
                        ],
                     ),
                     Row( // Simple Color Picker
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                           _colorDot(Colors.black87, fontColor, (c) => setSheetState(() => fontColor = c)),
                           _colorDot(const Color(0xFFE91E63), fontColor, (c) => setSheetState(() => fontColor = c)), // Pink
                           _colorDot(const Color(0xFF2196F3), fontColor, (c) => setSheetState(() => fontColor = c)), // Blue
                           _colorDot(const Color(0xFF4CAF50), fontColor, (c) => setSheetState(() => fontColor = c)), // Green
                           _colorDot(const Color(0xFFFF9800), fontColor, (c) => setSheetState(() => fontColor = c)), // Orange
                        ],
                     ),
                     const SizedBox(height: 16),
                     SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                           style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF8E8C0)),
                           onPressed: () {
                              setState(() {
                                 _pages[index]['text'] = textController.text;
                                 _pages[index]['style'] = {
                                    'color': fontColor.toARGB32(),
                                    'fontSize': fontSize,
                                    'fontFamily': fontFamily
                                 };
                              });
                              _saveChanges();
                              Navigator.pop(context);
                           },
                           child: Text('Save Changes', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.black87)),
                        ),
                     ),
                     const SizedBox(height: 24),
                  ],
               ),
            ),
         ),
      );
  }

   Widget _colorDot(Color color, Color selectedColor, void Function(Color) onTap) {
      final isSelected = color.toARGB32() == selectedColor.toARGB32();
      return GestureDetector(
        onTap: () => onTap(color),
        child: Container(
           width: 30, height: 30,
           decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: isSelected ? Border.all(color: Colors.black87, width: 2) : null,
              boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(1,1), blurRadius: 2)]
           ),
        ),
     );
   }
   
   Widget _buildActionChip(IconData icon, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFE0E7FF).withValues(alpha: 0.5);
    final contentColor = isDark ? Colors.white38 : Colors.black38;

    return Tooltip(
      message: '$label — Coming Soon!',
      child: Opacity(
        opacity: 0.5,
        child: Chip(
          avatar: Icon(icon, size: 18, color: contentColor),
          label: Text(
            label,
            style: TextStyle(color: contentColor, fontWeight: FontWeight.bold),
          ),
          backgroundColor: bgColor,
          side: isDark ? const BorderSide(color: Colors.white12) : BorderSide.none,
        ),
      ),
    );
  }

}
