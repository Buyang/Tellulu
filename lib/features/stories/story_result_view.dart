import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tellulu/services/stability_service.dart';

class StoryResultView extends StatefulWidget { // Callback to save changes to parent list

  const StoryResultView({
    required this.story, required this.onBack, required this.onSave, super.key,
  });
  final Map<String, dynamic> story;
  final VoidCallback onBack;
  final void Function(Map<String, dynamic>) onSave;

  @override
  State<StoryResultView> createState() => _StoryResultViewState();
}

class _StoryResultViewState extends State<StoryResultView> {
  late Map<String, dynamic> _storyData;
  late StabilityService _stabilityService;
  late List<dynamic> _pages; // Can contain String (legacy) or Map (new)
  // bool _isGeneratingImage = false; // REMOVED

  @override
  void initState() {
    super.initState();
    _storyData = widget.story;
    _stabilityService = StabilityService('sk-HRE8NYqwregvjykkelrM2Cv7kvgoJziUdcafULRoeYjEjCda');
    
    // Initialize pages, handling potential legacy format
    final rawPages = _storyData['pages'] as List<dynamic>? ?? [];
    _pages = rawPages.map((p) {
      if (p is String) {
        // Convert legacy string to new object format
        return {
          'text': p,
          'visual_description': p, // Fallback for legacy string pages
          'image': null,
          'style': {
             'color': Colors.black87.toARGB32(),
             'fontSize': 18.0,
             'fontFamily': 'Quicksand'
          }
        };
      }
      return p; // Already a map
    }).toList();
  }

  void _saveChanges() {
     _storyData['pages'] = _pages;
     widget.onSave(_storyData);
  }

  @override
  Widget build(BuildContext context) {
    final title = (_storyData['title'] as String?) ?? 'My Story';

    return Column(
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.center, 
          children: [
            Flexible( 
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.chewy(
                   textStyle: Theme.of(context).textTheme.titleLarge,
                  fontSize: 24,
                  color: const Color(0xFF9FA0CE),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Pages
        SizedBox(
          height: 450,
          child: PageView.builder(
            itemCount: _pages.length,
            itemBuilder: (context, index) {
              return _buildPageItem(index);
            },
          ),
        ),
        
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
      final pageData = _pages[index] as Map<String, dynamic>;
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
              child: Container(
                height: 200,
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black87),
                  image: imageBase64 != null 
                    ? DecorationImage(
                        image: MemoryImage(base64Decode(imageBase64)),
                        fit: BoxFit.cover
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

  int? _generatingPageIndex; // Track which page is loading

  // ... (Update build method below to use this) ...

  // Track regen attempts to vary the seed deterministically
  final Map<int, int> _regenCounts = {};

  Future<void> _handleImageTap(int index, {bool forceRegenerate = false}) async {
      final pageData = _pages[index] as Map<String, dynamic>;
      if (pageData['image'] != null && !forceRegenerate) return; 
      
      setState(() => _generatingPageIndex = index); 
      
      try {
         // Smart Fusion Prompt (V2)
         // Trust the "visual_description" which has Gemini 2.0's integrated character details
         final sceneDescription = pageData['visual_description'] ?? pageData['text'];
         
         final prompt = "Children's storybook illustration. $sceneDescription. Style: Watercolor, colorful, cute, highly detailed.";
         print('DEBUG: REGEN V2 - Page $index Prompt: $prompt');
         
         // Seed Logic:
         // 1. Get the original "Good Seed" that made the rest of the book consistent.
         // 2. If generating for the first time (null image), use it as is.
         // 3. If regenerating (user clicked retry), shift it slightly so we don't get the exacting same pixels, 
         //    but stay in the same "Math Neighborhood" (if that were a thing, but mostly we just want a controlled random).
         final int baseSeed = (_storyData['seed'] as int?) ?? 0;
         if (baseSeed == 0) {
             print('DEBUG: No base seed found, using random.');
         }

         int currentRegenCount = _regenCounts[index] ?? 0;
         if (forceRegenerate) {
            currentRegenCount++;
            _regenCounts[index] = currentRegenCount;
         }
         
         // If baseSeed is present, we use it. 
         // For regen, we add a huge offset (e.g. 10000 * count) to jump to a new "random" spot 
         // but one that is reproducible if we ever needed to (determinism).
         // Actually, to fix "Consistency", using the SAME seed with the SAME prompt gives the SAME image.
         // But the user clicked "Regen" because they didn't like the image.
         // So we MUST change the seed.
         // The "Consistency" comes from the PROMPT (Gemini 2.0) being rock solid.
         final int? effectiveSeed = (baseSeed != 0) ? (baseSeed + (currentRegenCount * 12345)) : null;

         final imageBase64 = await _stabilityService.generateImage(
            prompt: prompt,
            stylePreset: 'digital-art', 
            modelId: 'stable-diffusion-xl-1024-v1-0',
            seed: effectiveSeed,
         );
         
         if (imageBase64 != null) {
            setState(() {
               _pages[index]['image'] = imageBase64;
            });
            _saveChanges();
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
    final bgColor = isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE0E7FF);
    final contentColor = isDark ? Colors.white : Colors.black87;

    return Chip(
      avatar: Icon(icon, size: 18, color: contentColor),
      label: Text(
        label,
        style: TextStyle(color: contentColor, fontWeight: FontWeight.bold),
      ),
      backgroundColor: bgColor,
      side: isDark ? const BorderSide(color: Colors.white24) : BorderSide.none,
    );
  }
}
