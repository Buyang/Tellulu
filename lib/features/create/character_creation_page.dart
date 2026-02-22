import 'dart:async';
import 'dart:convert';

// import 'dart:typed_data'; // Unnecessary


import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:tellulu/common/widgets/tellulu_card.dart';
import 'package:tellulu/features/home/home_page.dart';
import 'package:tellulu/features/publish/publish_page.dart';
import 'package:tellulu/features/settings/settings_page.dart';
import 'package:tellulu/features/stories/stories_page.dart';
import 'package:tellulu/providers/service_providers.dart';
import 'package:tellulu/providers/settings_providers.dart';
import 'package:tellulu/services/gemini_service.dart';
import 'package:tellulu/services/stability_service.dart';

// ... imports

class CharacterCreationPage extends ConsumerStatefulWidget {

  const CharacterCreationPage({
    super.key,
    this.geminiService,
    this.stabilityService,
    this.imagePicker,
  });

  final GeminiService? geminiService;
  final StabilityService? stabilityService;
  final ImagePicker? imagePicker;

  @override
  ConsumerState<CharacterCreationPage> createState() => _CharacterCreationPageState();
}

class _CharacterCreationPageState extends ConsumerState<CharacterCreationPage> {
  late final GeminiService _geminiService;
  late final StabilityService _stabilityService;
  
  // Keys are now handled via Service Providers and .env 
  
  final _descriptionController = TextEditingController();
  // Safe nullable picker
  ImagePicker? _pickerInstance;
  ImagePicker get _picker => _pickerInstance ??= widget.imagePicker ?? ImagePicker();
  

  @override
  void initState() {
    super.initState();
    _geminiService = widget.geminiService ?? ref.read(geminiServiceProvider);
    _stabilityService = widget.stabilityService ?? ref.read(stabilityServiceProvider);
    
    // _picker is lazy loaded now
    
    _selectedStyleKey = _stylePresets.keys.first;
    unawaited(_loadCast());
    
    // [NEW] Listen for background sync completion to refresh data
    _syncSubscription = ref.read(storageServiceProvider).onSyncComplete.listen((_) {
      if (mounted) {
         debugPrint('Background Sync Complete. Refreshing UI...');
         // Reload cast to show new data
         _loadCast();
         
         // Optional: Show a small toast
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
               content: Text('Stories synced!'), 
               duration: Duration(seconds: 2),
               behavior: SnackBarBehavior.floating, // Nice floating touch
            ),
         );
      }
    });
  }
  
  StreamSubscription? _syncSubscription; // [NEW]

  // State

  Uint8List? _selectedImageBytes;
  // No local state for models anymore
  bool _isDreaming = false;
  bool _isDrawing = false;
  bool _isAnalyzing = false; // [NEW] Analysis state
  
  // Forensics
  String? _forensicAnalysis; // [NEW] Stores the visual traits

  // SDXL Style Presets Mapping
  final Map<String, String> _stylePresets = {
    '3D Model': '3d-model',
    'Anime': 'anime',
    'Comic Book': 'comic-book',
    'Digital Art': 'digital-art',
    'Fantasy Art': 'fantasy-art',
    'Line Art': 'line-art',
    'Pixel Art': 'pixel-art',
    'Photographic': 'photographic',
    'Cinematic': 'cinematic',
    'Claymation': 'craft-clay', // [NEW] Fun for kids
    'Low Poly': 'low-poly',     // [NEW] Fun for kids
    'Origami': 'origami',       // [NEW] Fun for kids
  };
  
  late String _selectedStyleKey; // Track selected key
  
  // Cast Data
  List<Map<String, dynamic>> _cast = [];

  Future<void> _loadCast() async {
    // [REF] Use StorageService for Cloud Sync support
    try {
      final cast = await ref.read(storageServiceProvider).loadCast();
      debugPrint('🔍 DEBUG: Loaded ${cast.length} cast members from StorageService');
      
      if (cast.isNotEmpty) {
        setState(() {
          _cast = cast.map((item) {
             debugPrint('🔍 DEBUG ITEM: Name=${item['name']} Keys=${item.keys.toList()}');
             if (item.containsKey('imageBase64')) {
                final val = item['imageBase64'];
                debugPrint('   > imageBase64 found. Type: ${val.runtimeType}, Length: ${val?.toString().length}');
             } else {
                debugPrint('   > ⚠️ imageBase64 MISSING');
             }

             // Restoration: Decode Base64 if imageBytes is missing
             if (item['imageBytes'] == null && item['imageBase64'] != null) {
               try {
                 item['imageBytes'] = base64Decode(item['imageBase64'] as String);
               } catch (e) {
                 debugPrint('Error decoding cast image: $e');
               }
             }

             if (item['originalImageBytes'] == null && item['originalImageBase64'] != null) {
               try {
                 item['originalImageBytes'] = base64Decode(item['originalImageBase64'] as String);
               } catch (e) {
                 debugPrint('Error decoding original cast image: $e');
               }
             }
             
             // Ensure 'color' is int
             if (item['color'] is String) {
               item['color'] = int.tryParse(item['color']) ?? 0xFFE0F7FA;
             }
             return item;
          }).toList();
        });
      } else {
        // Default initial mock data if nothing saved
        setState(() {
          _cast = [
            {'name': 'Luna the Brave', 'role': 'space explorer', 'color': 0xFFE0E7FF},
            {'name': 'Bun-Bun', 'role': 'magic guide', 'color': 0xFFFDF4E3},
            {'name': 'Dino Dan', 'role': 'prehistoric pal', 'color': 0xFFE8F5E9},
            {'name': 'Princess Pea', 'role': 'royal highness', 'color': 0xFFFCE4EC},
          ];
        });
      }
    } catch (e) {
      debugPrint('Error loading cast: $e');
    }
  }

  Future<void> _saveCast() async {
    // [REF] Use StorageService
    // We pass the list directly. Hive handles many types, but for Cloud Sync (JSON),
    // we should ensure binary data (Uint8List) is handled or compatible.
    // Hive supports Uint8List. Firestore/JSON might need Base64.
    // StorageService might handle it, or we prepare it here.
    // Looking at StorageService.saveCast -> CloudStorageService.uploadCast...
    // Let's keep the logic of converting imageBytes to base64 HERE to be safe for JSON serialization layers.
    
    final safeCast = _cast.map((item) {
      final Map<String, dynamic> jsonItem = Map<String, dynamic>.from(item);
      
      // Convert bytes to base64 for storage portability
      if (jsonItem['imageBytes'] != null && jsonItem['imageBytes'] is Uint8List) {
        jsonItem['imageBase64'] = base64Encode(jsonItem['imageBytes'] as List<int>);
        jsonItem.remove('imageBytes'); // Remove raw bytes
      }
      
      if (jsonItem['originalImageBytes'] != null && jsonItem['originalImageBytes'] is Uint8List) {
        jsonItem['originalImageBase64'] = base64Encode(jsonItem['originalImageBytes'] as List<int>);
        jsonItem.remove('originalImageBytes');
      }
      
      return jsonItem;
    }).toList();

    await ref.read(storageServiceProvider).saveCast(safeCast);
  }

  String? _uploadError;

  Future<void> _pickImage() async {
    setState(() => _uploadError = null);
    try {
      Uint8List? bytes;
      
      // Use FilePicker for Web to avoid Blob/XFile issues
      if (kIsWeb) {
        debugPrint('Picking file on Web...');
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true, 
        );
        if (result != null && result.files.isNotEmpty) {
          bytes = result.files.first.bytes;
        }
      } else {
        // Use ImagePicker for Mobile (Native UI)
        debugPrint('Picking file on Mobile (ImagePicker)...');
        final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          bytes = await image.readAsBytes();
        }
      }

      if (bytes != null) {
        setState(() {
          _selectedImageBytes = bytes;
          _uploadError = null;
        });
      }
    } catch (e, stack) {
      debugPrint('Character Image Picker Error: $e');
      debugPrint('Stack: $stack');
      setState(() => _uploadError = '[Web:$kIsWeb] $e');
    }

    // Trigger Forensic Analysis automatically if image exists
    if (_selectedImageBytes != null) {
      await _performForensicAnalysis();
    }
  }

  Future<void> _performForensicAnalysis() async {
    setState(() {
      _isAnalyzing = true; 
      _forensicAnalysis = null; // Clear old result
    });

    final analysis = await _geminiService.analyzeImage(_selectedImageBytes!);

    if (mounted) {
      setState(() {
        _isAnalyzing = false;
        _forensicAnalysis = analysis;
      });
      
      if (analysis != null) {
        ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Forensic Analysis Complete: Traits identified!')),
        );
      }
    }
  }

  Future<void> _dreamUpDescription() async {
    setState(() => _isDreaming = true);
    final model = ref.read(geminiModelProvider).value ?? 'gemini-2.0-flash';
    final description = await _geminiService.generateCharacterDescription(
      prompt: "Create a creative, playful character description for a children's story hero. The character is a $_selectedStyleKey. Keep it under 1000 characters.",
      model: model,
      visualContext: _forensicAnalysis, // [NEW] Pass the visual analysis
    );
    if (mounted) {
      if (description != null) {
        _descriptionController.text = description;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to dream up a description. Try again!')),
        );
      }
      setState(() => _isDreaming = false);
    }
  }

  // Draw It Action
  Future<void> _drawIt() async {

    if (_descriptionController.text.isEmpty) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe your hero!')),
      );
      return;
    }

    debugPrint('DrawIt: Called');
    setState(() => _isDrawing = true);
    debugPrint('DrawIt: Image bytes: ${_selectedImageBytes?.length}');
    debugPrint('DrawIt: Description: ${_descriptionController.text}');
    debugPrint('DrawIt: Style: $_selectedStyleKey');
    
    // Resize to 1024x1024 (Square Crop) for Stability API
    Uint8List? finalImageBytes = _selectedImageBytes;

    if (finalImageBytes != null) {
      try {
        final cmd = img.Command()
          ..decodeImage(finalImageBytes)
          ..copyResizeCropSquare(size: 1024) // Crop to square instead of stretching
          ..encodePng();
        
        final resizedBytes = await cmd.getBytesThread();
        if (resizedBytes != null) {
          finalImageBytes = resizedBytes;
        }
      } on Object catch (e) {
        debugPrint('Error resizing image: $e');
        // Proceed with original, might fail but worth a try
      }
    }

    // Use providers
    final modelId = ref.read(stabilityModelProvider).value ?? 'stable-diffusion-xl-1024-v1-0';
    final imageStrength = ref.read(creativityProvider).value ?? 0.35;

    // Safety Engine Loop
    String? acceptedBase64;
    int attempts = 0;

    while (attempts < 2 && acceptedBase64 == null) {
      attempts++;
      
      final candidateBase64 = await _stabilityService.generateImage(
        initImageBytes: finalImageBytes,
        prompt: _descriptionController.text,
        stylePreset: _stylePresets[_selectedStyleKey],
        modelId: modelId,
        imageStrength: imageStrength,
        seed: attempts > 1 ? DateTime.now().millisecondsSinceEpoch : null, // Shift seed on retry
      );

      if (candidateBase64 != null) {
         // --- SAFETY AUDIT ---
         final bytes = base64Decode(candidateBase64);
         final audit = await _geminiService.validateImageSafety(bytes);
         
         if (audit != null && audit['safe'] == true) {
           acceptedBase64 = candidateBase64;
         } else {
           final reason = audit?['reason'] ?? "Content Safety Flag";
           debugPrint('⚠️ DRAW IT UNSAFE BLOCK: $reason');
           
           if (mounted && attempts < 2) {
              ScaffoldMessenger.of(context).showSnackBar(
                 SnackBar(content: Text('Safety Engine: Refining content... ($reason)')),
              );
           }
         }
      }
    }

    final base64Image = acceptedBase64;

    if (mounted) {
      if (base64Image != null) {
        final bytes = base64Decode(base64Image);
        
        // Optimize image for storage to avoid QuotaExceededError
        Uint8List optimizedBytes = bytes;
        try {
          final rawImage = img.decodeImage(bytes);
          if (rawImage != null) {
            // Resize to reasonable size for storage (e.g. 512x512)
            final resized = img.copyResize(rawImage, width: 512); 
            // Encode as JPEG with quality 70
            optimizedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
          }
        } on Object catch (e) {
          debugPrint('Error optimizing image: $e');
        }

        setState(() {
          _isDrawing = false;
          // Add to cast automatically for fun
          // Optimize ORIGINAL image for storage too (prevent crash)
          Uint8List? optimizedOriginalBytes;
          if (_selectedImageBytes != null) {
             try {
                final rawOrg = img.decodeImage(_selectedImageBytes!);
                if (rawOrg != null) {
                   // Resize to reasonable size (e.g. 512px)
                   final resizedOrg = img.copyResize(rawOrg, width: 512);
                   optimizedOriginalBytes = Uint8List.fromList(img.encodeJpg(resizedOrg, quality: 70));
                }
             } catch (e) {
                debugPrint("Error optimizing original image: $e");
             }
          }

          _cast.insert(0, {
             'name': 'New Hero',
             'role': _descriptionController.text.split(',').first, // Extract a brief role
             'style': _selectedStyleKey, // [NEW] Explicit Style Persistence
             'description': _descriptionController.text, // Finalized Description
             'color': 0xFFFFF9C4, 
             'imageBytes': optimizedBytes, // Generated Image
             
             // [NEW] Persisted Artifacts
             'originalImageBytes': optimizedOriginalBytes, // 1. Original Reference
             'forensicAnalysis': _forensicAnalysis,        // 2. Forensic Analysis
             'stabilityPrompt': _descriptionController.text, // 4. Prompt Sent (User/Gemini text)
          });
          _saveCast(); // Save changes
        });
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Magic failed! Try again.')),
        );
        setState(() => _isDrawing = false);
      }
    }
  }

  @override
  void dispose() {
    _syncSubscription?.cancel(); // [NEW]
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            final headerSize = isSmallScreen ? 20.0 : 24.0; // Reduced from 24
            final titleSize = isSmallScreen ? 18.0 : 22.0;
            final subtitleSize = isSmallScreen ? 14.0 : 18.0; // Reduced from 16
          
          return TelluluCard(
            maxWidth: isSmallScreen ? 400 : 600, // Widened for tablet/desktop
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header
                  _buildHeader(context, fontSize: headerSize),
                  const SizedBox(height: 16),
                  
                  // Title & Subtitle
                  Text(
                    'Who is the hero today?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.quicksand(
                      fontSize: titleSize,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  Text(
                    'Bring a new friend...',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.chewy(
                      fontSize: subtitleSize,
                      color: const Color(0xFF9FA0CE),
                    ),
                  ),
                  const SizedBox(height: 16),
      
                  // Uploaded Image Preview (If exists)
                  if (_selectedImageBytes != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Stack(
                         alignment: Alignment.topRight,
                         children: [
                           ClipRRect(
                             borderRadius: BorderRadius.circular(16),
                             child: Image.memory(_selectedImageBytes!, height: 150, fit: BoxFit.cover),
                           ),
                           IconButton(
                             icon: const Icon(Icons.close, color: Colors.red),
                             onPressed: () => setState(() => _selectedImageBytes = null),
                           ),
                         ],
                      ),
                    ),
      
                  const SizedBox(height: 8),
      
                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Upload Button (now first)
                      _buildActionButton(
                        '1. Pick Actor', 
                        const Color(0xFFF8E8C0), 
                        onPressed: _pickImage,
                        isLoading: _isAnalyzing, // Show loading during analysis
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      // Dream Up Button (now second)
                      _buildActionButton(
                        '3. Dream Up More', 
                        const Color(0xFFF8E8C0), 
                        onPressed: _dreamUpDescription,
                        isLoading: _isDreaming,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ],
                  ),
                    if (_uploadError != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          'Start Error: $_uploadError',
                          style: GoogleFonts.quicksand(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                      ),
                const SizedBox(height: 24),

                // Paper Input Section
                _buildPaperInputSection(isSmallScreen),

                const SizedBox(height: 24),

                // Your Cast Section
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Your Cast',
                    style: GoogleFonts.quicksand(
                      fontSize: titleSize, // Consistent with title
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCastGrid(isSmallScreen), // Pass screen size

                 const SizedBox(height: 24),
                 // Bottom Nav Placeholder (Visual)
                 _buildBottomNav(isSmallScreen),
              ],
            ),
          ),
        );
       }
      ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, {double fontSize = 24.0}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Invisible spacer to balance the right icon and center the title
        const Opacity(
          opacity: 0.0, 
          child: IconButton(
            icon: Icon(Icons.settings_outlined), 
            onPressed: null,
          ),
        ),
        
        Flexible(
          child: Text(
            'Tellulu Tales',
            style: GoogleFonts.chewy(
               fontSize: fontSize,
               color: const Color(0xFF9FA0CE), 
            ),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        
        IconButton(
          icon: Icon(Icons.settings_outlined, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute<void>(builder: (context) => const SettingsPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, Color color, {required VoidCallback onPressed, bool isLoading = false, double fontSize = 16.0}) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.black87,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Colors.black87, width: 1.5),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      child: isLoading 
        ? const SizedBox(
            width: 20, 
            height: 20, 
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black87)
          )
        : Text(
            label,
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: fontSize),
          ),
    );
  }

  Widget _buildPaperInputSection(bool isSmallScreen) {
    return Stack(
      alignment: Alignment.bottomCenter,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 28), // Reserve space for the button hanging out
          child: Container(
            width: double.infinity,
             padding: const EdgeInsets.all(16),
             decoration: BoxDecoration(
               color: const Color(0xFFFFF9E6), // Pale yellow paper look
               border: Border.all(color: Colors.black87, width: 1.5),
               borderRadius: BorderRadius.circular(20), // [Updated] All 4 corners round
               boxShadow: [
                 BoxShadow(
                   color: Colors.black.withValues(alpha: 0.1),
                   blurRadius: 4,
                   offset: const Offset(2, 4),
                 ),
               ],
             ),
             child: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 Text(
                   '2. Choose Avatar Style',
                   style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                 ),
                 const SizedBox(height: 8),
                 Wrap(
                   spacing: 8,
                   runSpacing: 8,
                    children: _stylePresets.keys.map(_buildStyleChip).toList(),
                 ),
                 const SizedBox(height: 12),
                 const Divider(color: Colors.black12, thickness: 1),
                 const SizedBox(height: 8),
                 Text(
                   '4. Finalize Description',
                   style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.black87),
                 ),
                 const SizedBox(height: 8),
                 TextField(
                   controller: _descriptionController,
                   maxLines: 3,
                   style: GoogleFonts.quicksand(color: Colors.black87), // Force black input text
                   decoration: InputDecoration(
                     border: InputBorder.none,
                     hintText: 'Describe your hero...',
                     hintStyle: GoogleFonts.quicksand(color: Colors.black38),
                   ),
                 ),
                  const SizedBox(height: 30), // Space inside for button overlap
               ],
             ),
          ),
        ),
        // Draw It Button (Positioned at bottom center of stack)
        Positioned(
          bottom: 0,
          child: ElevatedButton(
            onPressed: _isDrawing ? null : () => unawaited(_drawIt()),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF9FA0CE),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Colors.black87, width: 1.5),
              ),
                padding: const EdgeInsets.symmetric(horizontal: 100, vertical: 12),
               elevation: 4,
            ),
            child: _isDrawing 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text(
              'Draw it!',
              style: GoogleFonts.chewy(
                fontSize: isSmallScreen ? 18 : 24, // Increased to 24 to match other Chewy buttons
                color: Colors.white,
                fontWeight: FontWeight.normal, // Chewy is naturally bold/thick
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStyleChip(String label) {
    final isSelected = _selectedStyleKey == label;
    
    return GestureDetector(
      onTap: () => setState(() => _selectedStyleKey = label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9FA0CE) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black54),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 12, 
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : Colors.black87,
          ),
        ),
      ),
    );
  }

  Widget _buildCastGrid(bool isSmallScreen) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 3, // More columns on larger screens
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _cast.length,
      itemBuilder: (context, index) {
        final char = _cast[index];
        final imageBytes = char['imageBytes'] as Uint8List?;
        
        return Container(
          decoration: BoxDecoration(
            color: Color(char['color'] as int),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black87, width: 1.5),
             boxShadow: [
               BoxShadow(
                 color: Colors.black.withValues(alpha: 0.05),
                 blurRadius: 4,
                 offset: const Offset(0, 4),
               ),
             ],
          ),
          child: Stack(
            children: [
              InkWell(
                onTap: () => _showViewDialog(char),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Avatar Placeholder or Real Image
                      Container(
                         width: 80,
                         height: 80, // Increased size
                         decoration: const BoxDecoration(
                           color: Colors.white,
                           shape: BoxShape.circle,
                         ),
                         child: ClipOval(
                           child: imageBytes != null 
                            ? Image.memory(imageBytes, fit: BoxFit.cover)
                            : Icon(Icons.person_outline, color: Colors.grey[400], size: 40),
                         ),
                      ),
                      const SizedBox(height: 8),
                      // Style Chips
                  Center(
                        child: Text(
                          char['name'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Center(
                        child: Text(
                          char['role'] as String,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.quicksand(
                            fontSize: 12,
                            color: Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Action Icons (Top Right)
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildIconAction(Icons.visibility, () => _showViewDialog(char)),
                    const SizedBox(width: 4),
                    _buildIconAction(Icons.edit, () => _showEditDialog(index, char)),
                    const SizedBox(width: 4),
                    _buildIconAction(Icons.delete, () => _showDeleteDialog(index)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildIconAction(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.8),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: Colors.black87),
      ),
    );
  }

  void _showViewDialog(Map<String, dynamic> char) {
    showDialog<void>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16), // Allow it to be larger on mobile if needed
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500), // Loosened constraint
          child: Padding(
            padding: const EdgeInsets.all(16), // Tighter padding
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (char['imageBytes'] != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.memory(
                        char['imageBytes'] as Uint8List, 
                        // Let height drive the size, but cap it so it fits on screen
                        height: MediaQuery.of(context).size.height * 0.6,
                        // No fixed width -> allows dialog to shrink to image width
                        fit: BoxFit.contain,
                    ),
                  ),
                const SizedBox(height: 12),
                
                // Detailed Info Scrollable
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Text(
                          char['name'] as String,
                          style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        Text(
                          char['role'] as String,
                          style: GoogleFonts.quicksand(fontSize: 16, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        
                        // Show Prompt
                        if (char['stabilityPrompt'] != null) ...[
                          Text("Design Prompt", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                          Text(char['stabilityPrompt'] as String, style: GoogleFonts.quicksand(fontSize: 14)),
                          const SizedBox(height: 12),
                        ],
                        
                        // Show Forensics
                        if (char['forensicAnalysis'] != null) ...[
                          Text("Visual DNA (Forensics)", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                          Text(char['forensicAnalysis'] as String, style: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey[700])),
                          const SizedBox(height: 12),
                        ],

                        // Show Original Reference
                        if (char['originalImageBytes'] != null) ...[
                           Text("Role Model", style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                           const SizedBox(height: 8),
                           ClipRRect(
                             borderRadius: BorderRadius.circular(8),
                             child: Image.memory(
                               char['originalImageBytes'] as Uint8List,
                               height: 100, // Thumbnail
                               fit: BoxFit.cover,
                             ),
                           ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditDialog(int index, Map<String, dynamic> char) {
    final nameController = TextEditingController(text: char['name'] as String?);
    final roleController = TextEditingController(text: char['role'] as String?);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Character', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: roleController,
              decoration: const InputDecoration(labelText: 'Role'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _cast[index]['name'] = nameController.text;
                _cast[index]['role'] = roleController.text;
              });
              unawaited(_saveCast()); // Save changes to disk
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int index) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Character?'),
        content: const Text('Are you sure you want to remove this character from your cast?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _cast.removeAt(index);
              });
              unawaited(_saveCast()); // Save changes
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  
  Widget _buildBottomNav(bool isSmallScreen) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavIcon(Icons.logout_outlined, 'Log Off', onTap: () => _showLogOffDialog(context)),
        _buildNavIcon(Icons.edit_outlined, 'Friends', isActive: true),
        _buildNavIcon(Icons.book_outlined, 'Stories', onTap: () {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute<void>(builder: (context) => const StoriesPage())
            );
        }),
        _buildNavIcon(Icons.publish, 'Publish', onTap: () {
             Navigator.push(
               context,
               MaterialPageRoute<void>(builder: (context) => const PublishPage()),
             );
        }),
      ],
    );
  }

  void _showLogOffDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Log Off?', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to go back to the login screen?', style: GoogleFonts.quicksand()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const HomePage()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF9FA0CE), foregroundColor: Colors.white),
            child: const Text('Log Off'),
          ),
        ],
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Icon(
            icon,
            color: isActive ? const Color(0xFF9FA0CE) : Theme.of(context).iconTheme.color?.withValues(alpha: 0.6),
             size: 28,
          ),
          Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 12,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
               color: isActive ? const Color(0xFF9FA0CE) : Theme.of(context).textTheme.bodySmall?.color,
            ),
          ),
        ],
      ),
    );
  }
}
