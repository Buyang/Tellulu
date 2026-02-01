import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tellulu/common/widgets/tellulu_card.dart';
import 'package:tellulu/features/home/home_page.dart';
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
  late final ImagePicker _picker;
  

  @override
  void initState() {
    super.initState();
    // In ConsumerStatefulWidget, we can access ref in initState but read/watch is nuanced.
    // For services (stateless/singletons), reading the provider is fine.
    // For providers created with riverpod_annotation they are auto-disposed or keepAlive.
    
    // Fallback to provider if not injected
    _geminiService = widget.geminiService ?? ref.read(geminiServiceProvider);
    _stabilityService = widget.stabilityService ?? ref.read(stabilityServiceProvider);
    
    _picker = widget.imagePicker ?? ImagePicker();
    _selectedStyleKey = _stylePresets.keys.first;
    unawaited(_loadCast());
  }

  // State

  Uint8List? _selectedImageBytes;
  // No local state for models anymore
  bool _isDreaming = false;
  bool _isDrawing = false;

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
  };
  
  late String _selectedStyleKey; // Track selected key
  
  // Cast Data
  List<Map<String, dynamic>> _cast = [];

  Future<void> _loadCast() async {
    final prefs = await SharedPreferences.getInstance();
    final String? castJson = prefs.getString('cast_data');
    
    if (castJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(castJson);
        setState(() {
          _cast = decodedList.map((item) {
            final Map<String, dynamic> castItem = Map<String, dynamic>.from(item as Map);
            // Decode Base64 image back to bytes if present
            if (castItem['imageBase64'] != null) {
              castItem['imageBytes'] = base64Decode(castItem['imageBase64'] as String);
            }
            return castItem;
          }).toList();
        });
      } on Object catch (e) {
        print('Error loading cast: $e');
      }
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
  }

  Future<void> _saveCast() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Convert list to JSON-encodable format (bytes -> base64)
    final jsonList = _cast.map((item) {
      final Map<String, dynamic> jsonItem = Map<String, dynamic>.from(item);
      if (jsonItem['imageBytes'] != null) {
        jsonItem['imageBase64'] = base64Encode(jsonItem['imageBytes'] as List<int>);
        jsonItem.remove('imageBytes'); // Remove bytes from JSON object
      }
      return jsonItem;
    }).toList();

    await prefs.setString('cast_data', jsonEncode(jsonList));
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _dreamUpDescription() async {
    setState(() => _isDreaming = true);
    final model = ref.read(geminiModelProvider).value ?? 'gemini-2.0-flash-exp';
    final description = await _geminiService.generateCharacterDescription(
      prompt: "Create a creative, playful character description for a children's story hero. The character is a $_selectedStyleKey. Keep it under 1000 characters.",
      model: model,
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

    print('DrawIt: Called');
    setState(() => _isDrawing = true);
    print('DrawIt: Image bytes: ${_selectedImageBytes?.length}');
    print('DrawIt: Description: ${_descriptionController.text}');
    print('DrawIt: Style: $_selectedStyleKey');
    
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
        print('Error resizing image: $e');
        // Proceed with original, might fail but worth a try
      }
    }

    // Use providers
    final modelId = ref.read(stabilityModelProvider).value ?? 'stable-diffusion-xl-1024-v1-0';
    final imageStrength = ref.read(creativityProvider).value ?? 0.35;

    final base64Image = await _stabilityService.generateImage(
      initImageBytes: finalImageBytes,
      prompt: _descriptionController.text,
      stylePreset: _stylePresets[_selectedStyleKey],
      modelId: modelId,
      imageStrength: imageStrength,
    );

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
            optimizedBytes = Uint8List.fromList(img.encodeJpg(resized, quality: 70));
          }
        } on Object catch (e) {
          print('Error optimizing image: $e');
        }

        setState(() {
          _isDrawing = false;
          // Add to cast automatically for fun
          _cast.insert(0, {
             'name': 'New Hero',
             'role': _selectedStyleKey,
             'description': _descriptionController.text, // Save description for story consistency
             'color': 0xFFFFF9C4, // Yellowish
             'imageBytes': optimizedBytes, // Save optimized version
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
                      // Dream Up Button
                      _buildActionButton(
                        'Dream Up', 
                        const Color(0xFFF8E8C0), 
                        onPressed: _dreamUpDescription,
                        isLoading: _isDreaming,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                      // Upload Button
                      _buildActionButton(
                        'Upload', 
                        const Color(0xFFF8E8C0), 
                        onPressed: _pickImage,
                        fontSize: isSmallScreen ? 14 : 16,
                      ),
                    ],
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
        IconButton(
          icon: Icon(Icons.arrow_back, color: Theme.of(context).iconTheme.color),
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute<void>(builder: (context) => const HomePage()),
              (route) => false,
            );
          },
        ),
        Flexible(
          child: Text(
            'Tellulu Tales',
            style: GoogleFonts.chewy(
               fontSize: fontSize,
               color: const Color(0xFF9FA0CE), 
            ),
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
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
               borderRadius: const BorderRadius.only(
                 topLeft: Radius.circular(2), // Slight irregularity
                 topRight: Radius.circular(2),
                 bottomLeft: Radius.circular(2),
                 bottomRight: Radius.circular(30), // Folded corner effect area
               ),
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
                   'Choose Your Style',
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
               padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (char['imageBytes'] != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.memory(char['imageBytes'] as Uint8List, height: 200, fit: BoxFit.cover),
                ),
              const SizedBox(height: 16),
              Text(
                char['name'] as String,
                style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              Text(
                char['role'] as String,
                style: GoogleFonts.quicksand(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 20),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
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
        _buildNavIcon(Icons.home_outlined, 'Home', onTap: () {
           Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const HomePage()),
              (route) => false,
            );
        }),
        _buildNavIcon(Icons.edit_outlined, 'Friends', isActive: true),
        _buildNavIcon(Icons.book_outlined, 'Stories', onTap: () {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute<void>(builder: (context) => const StoriesPage())
            );
        }),
        _buildNavIcon(Icons.person_outline, 'Profile'),
      ],
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
