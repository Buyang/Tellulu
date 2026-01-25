import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image/image.dart' as img; // Added for resizing
import 'package:shared_preferences/shared_preferences.dart';
import '../../services/gemini_service.dart';
import '../../services/stability_service.dart';
import '../../features/stories/new_story_view.dart';
import '../../features/stories/story_result_view.dart';
import '../../common/widgets/tellulu_card.dart'; // Added TelluluCard import
import '../create/character_creation_page.dart';
import '../home/home_page.dart';
import '../settings/settings_page.dart';


enum StoriesViewMode { list, create, read }

class StoriesPage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<String> geminiModelNotifier;
  final ValueNotifier<String> stabilityModelNotifier;
  final ValueNotifier<double> creativityNotifier;

  const StoriesPage({
    super.key,
    required this.themeNotifier,
    required this.geminiModelNotifier,
    required this.stabilityModelNotifier,
    required this.creativityNotifier,
  });

  @override
  State<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends State<StoriesPage> {
  // Navigation State
  StoriesViewMode _viewMode = StoriesViewMode.list;
  bool _isWeaving = false;

  // Data
  List<Map<String, dynamic>> _stories = [];
  Map<String, dynamic>? _currentStory;
  List<Map<String, dynamic>> _cast = [];
  
  // Services
  late final GeminiService _geminiService;
  late final StabilityService _stabilityService; 

  @override
  void initState() {
    super.initState();
    _geminiService = GeminiService('AIzaSyCZlW80K2vriEK_i_ry07zlle1q_mk-sJ4');
    _stabilityService = StabilityService('sk-HRE8NYqwregvjykkelrM2Cv7kvgoJziUdcafULRoeYjEjCda');
    _loadData();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Cast
    final String? castJson = prefs.getString('cast_data');
    if (castJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(castJson);
        setState(() {
          _cast = decodedList.map((item) {
            Map<String, dynamic> castItem = Map<String, dynamic>.from(item);
            if (castItem['imageBase64'] != null) {
              castItem['imageBytes'] = base64Decode(castItem['imageBase64']);
            }
            return castItem;
          }).toList();
        });
      } catch (e) {
        print('Error loading cast: $e');
      }
    }

    // Load Stories
    final String? storiesJson = prefs.getString('stories_data');
    if (storiesJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(storiesJson);
        setState(() {
          _stories = decodedList.map((item) => Map<String, dynamic>.from(item)).toList();
        });
      } catch (e) {
        print('Error loading stories: $e');
      }
    }
  }

  Future<void> _saveStories() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = _stories.map((s) => s).toList(); 
    await prefs.setString('stories_data', jsonEncode(jsonList));
  }

  void _renameStory(int index) {
      TextEditingController renameController = TextEditingController(text: _stories[index]['title']);
      showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Story'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(hintText: "New Title"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _stories[index]['title'] = renameController.text;
                // If this is the current story being viewed, we might need to update that too if it's a reference issue,
                // but since we are in list view when renaming, it should be fine.
              });
              _saveStories();
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _handleWeaveStory(Map<String, dynamic> params) async {
    print("DEBUG: _handleWeaveStory started");
    setState(() => _isWeaving = true);

    final List<Map<String, dynamic>> selectedCast = params['cast'];
    
    // Prepare rich cast details for Gemini & Enhancement
    List<Map<String, String>> castDetails = [];

    // ENHANCEMENT STEP: Upgrade profiles for the "Story Bible"
    // We do this concurrently for speed
    print("DEBUG: Enhancing Cast Profiles...");
    final futures = selectedCast.map((c) async {
       final name = c['name'] as String;
       final rawDesc = (c['description'] ?? c['role'] ?? 'hero') as String;
       
       // Call Gemini to expand the profile - FORCE 'gemini-pro'
       final enhancedDesc = await _geminiService.enhanceCharacterDescription(name, rawDesc);
       print("DEBUG: Enhanced $name: $enhancedDesc");
       
       return {
         'name': name,
         'description': enhancedDesc, // Use the UPGRADED description
       };
    });
    
    castDetails = await Future.wait(futures);

    final List<String> castNames = selectedCast.map((c) => c['name'] as String).toList(); 
    final String vibe = params['vibe'];
    
    // Seed for Visual Consistency (One seed to rule them all)
    final int storySeed = DateTime.now().millisecondsSinceEpoch % 4294967295;
    print("DEBUG: Story Seed: $storySeed");

    try {
      // 1. Generate Story Text
      print("DEBUG: Calling generateStory...");
      final story = await _geminiService.generateStory(
        castDetails: castDetails, // Pass rich details
        vibe: vibe,
        readingLevel: params['readingLevel'],
        specialTouch: params['specialTouch'],
        model: 'gemini-2.0-flash-exp', // Upgrade to 2.0 Flash Exp per user request
      );
      print("DEBUG: generateStory result: ${story?.keys}");

      if (story != null) {
        // 2. Generate Cover Image (using Stability AI)
        print("DEBUG: generating cover image...");
        String? coverBase64;
        if (selectedCast.isNotEmpty && selectedCast.first['imageBytes'] != null) {
            Uint8List seedImage = selectedCast.first['imageBytes'];
            
            // Resize to 1024x1024 for SDXL
            try {
              final cmd = img.Command()
                ..decodeImage(seedImage)
                ..copyResize(width: 1024, height: 1024) 
                ..encodePng();
              final resizedBytes = await cmd.getBytesThread();
              if (resizedBytes != null) seedImage = resizedBytes;
            } catch (e) {
              print("Error resizing cover seed image: $e");
            }

            try {
              coverBase64 = await _stabilityService.generateImage(
                  initImageBytes: seedImage,
                  prompt: "Book cover for a children's story titled '${story['title']}'. featuring ${castNames.join(', ')}. Vibe: $vibe. Style: Watercolor.",
                  stylePreset: "digital-art", // Use digital-art preset for watercolor style
                  modelId: widget.stabilityModelNotifier.value,
                  imageStrength: 0.3, // Low strength to allow more creative freedom for the cover
              );
              print("DEBUG: Cover generated successfully (base64 length: ${coverBase64?.length})");
            } catch (e) {
               print("DEBUG: Cover generation failed: $e");
            }
        }

        // 2.5 Generate Images ensuring Consistency (Fixed 2.0 Profile + Global Seed)
        print("DEBUG: Generating Images (Sequential with Locked Seed)...");
        
        // Normalize pages deeply first
        final List<Map<String, dynamic>> workingPages = (story['pages'] as List).map((p) {
          if (p is String) return {'text': p, 'visual_description': p};
          return Map<String, dynamic>.from(p);
        }).toList();

        // Iterate consistently
        for (int i = 0; i < workingPages.length; i++) {
           final page = workingPages[i];
           // Gemini now embeds the character details directly into this description
           final scene = page['visual_description'] ?? page['text']; 
           
           // We rely on Gemini's integrated prompt + Stability's Seed for the best balance
           final fullPrompt = "Children's storybook illustration. $scene. Style: $vibe watercolor, colorful, cute, highly detailed.";
           
           print("DEBUG: Generating Page $i Prompt: ${fullPrompt.substring(0, 50)}...");

           try {
              final imageBase64 = await _stabilityService.generateImage(
                  prompt: fullPrompt,
                  stylePreset: "digital-art",
                  modelId: widget.stabilityModelNotifier.value,
                  seed: storySeed, // THE SECRET SAUCE: Same seed for every page
              );
              
              if (imageBase64 != null) {
                workingPages[i]['image'] = imageBase64;
              }
           } catch (e) {
             print("Image Gen Error for page $i: $e");
           }
        }


        // 3. Construct Story Object
        // workingPages already has images and normalized structure
        
        // Convert enhanced castDetails back to full map structure for storage
        // merging original data (colors, images) with enhanced descriptions
        final List<Map<String, dynamic>> finalCast = selectedCast.map((original) {
            final enhanced = castDetails.firstWhere((e) => e['name'] == original['name'], orElse: () => {'description': original['description']});
            return {
              ...original,
              'description': enhanced['description'], // The key fix: Persist the ENHANCED description
            };
        }).toList();
        
        // DEBUG: Verify enhanced descriptions
        for (var c in finalCast) {
          print("DEBUG: Final Cast Save - ${c['name']}: ${c['description']}");
        }

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
        
        print("DEBUG: Updating state with new story...");

        // 4. Auto-save
        setState(() {
           _stories.insert(0, newStory); // Add to top
           _currentStory = newStory;
           _viewMode = StoriesViewMode.read; // Go to result
        });
        await _saveStories();
        print("DEBUG: Story saved and state updated.");

      } else {
        print("DEBUG: generateStory returned null");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to weave story. Please try again!')),
        );
      }
    } catch (e, stack) {
      print("Weaving Error: $e");
      print(stack);
       ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('An error occurred while weaving.')),
        );
    } finally {
      if (mounted) setState(() => _isWeaving = false);
      print("DEBUG: _handleWeaveStory finished");
    }
  }

  void _deleteStory(int index) {
      showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Story?'),
        content: const Text('Are you sure you want to delete this story?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                _stories.removeAt(index);
              });
              _saveStories();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Wrap content in TelluluCard, but keeping header outside or inside?
      // In CharacterCreationPage, the whole body is TelluluCard, and Header is INSIDE.
      // Let's match that.
      body: TelluluCard( 
        child: SingleChildScrollView( // Add ScrollView back for the main page wrapper
          child: Column(
            children: [
              // Header
               _buildHeader(context),

              // Content
              Padding( // Add some padding around the dynamic content
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: _buildContent(),
              ),
              
              const SizedBox(height: 16),

              // Bottom Nav
              if (_viewMode == StoriesViewMode.list) _buildBottomNav(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
           // Left Action: Back or Add
          if (_viewMode == StoriesViewMode.list)
             // Spacer for alignment if no back button, or maybe a "Hidden" back button?
             // Actually, the designs usually have the "Logo/Title" centered or left.
             // In Friends page: Back (left), Title (Center), Settings (Right).
             // Since we are on a "Main Tab" (Stories), maybe no Back button?
             // But wait, Friends page HAS a back button to Home.
             // Let's replicate that logic.
            GestureDetector(
              onTap: () {
                 setState(() {
                   _viewMode = StoriesViewMode.create;
                 });
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8E8C0), // Gold/Yellow
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black87),
                  boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(2, 2))],
                ),
                child: const Icon(Icons.add, color: Colors.black87),
              ),
            )
          else
            IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    // If coming from result, go back to list
                    _viewMode = StoriesViewMode.list;
                    _currentStory = null;
                  });
                },
            ),

          Text(
             // Matches Friends Page Header Title
            'Tellulu Tales', 
            style: GoogleFonts.chewy(
               fontSize: 24,
               color: const Color(0xFF9FA0CE), 
            ),
          ),

          // Right Action: Settings (only in List)
          // Or just standard Settings icon everywhere?
           IconButton(
            icon: Icon(Icons.settings_outlined, color: _viewMode == StoriesViewMode.list ? Theme.of(context).iconTheme.color : Colors.transparent),
            onPressed: _viewMode == StoriesViewMode.list ? () {
                Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SettingsPage(
                  themeNotifier: widget.themeNotifier,
                  geminiModelNotifier: widget.geminiModelNotifier,
                  stabilityModelNotifier: widget.stabilityModelNotifier,
                  creativityNotifier: widget.creativityNotifier,
                )),
              );
            } : null,
          ),
        ],
      );
  }

  Widget _buildContent() {
    switch (_viewMode) {
      case StoriesViewMode.list:
        return Column( // Wrap in column to add titles
          children: [
             Text(
                'My Storybooks',
                textAlign: TextAlign.center,
                style: GoogleFonts.quicksand(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.bodyLarge?.color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Adventures waiting for you...',
                textAlign: TextAlign.center,
                style: GoogleFonts.chewy(
                  fontSize: 18,
                  color: const Color(0xFF9FA0CE),
                ),
              ),
              const SizedBox(height: 24),
              // "Add New" Bubble - Floating or part of the grid?
              // The user liked the "Add New" bubble in the header previously, but maybe here it fits better as a big button?
              // Or keep the floating header button?
              // Let's put a nice big "Weave New Story" button at the top here.




             _buildStoriesList(),
          ],
        );
      case StoriesViewMode.create:
        return NewStoryView(
          cast: _cast,
          onWeaveStory: _handleWeaveStory,
          isWeaving: _isWeaving,
        );
      case StoriesViewMode.read:
        if (_currentStory != null) {
           return StoryResultView(
            story: _currentStory!,
            onBack: () => setState(() => _viewMode = StoriesViewMode.list),
            onSave: (updatedStory) {
              setState(() {
                 // Find and update the story in the main list
                 final index = _stories.indexWhere((s) => s['id'] == updatedStory['id']);
                 if (index != -1) {
                    _stories[index] = updatedStory;
                    _currentStory = updatedStory; // Keep current view in sync
                 }
              });
              _saveStories();
            },
          );
        } else {
          return const Center(child: Text("Error loading story"));
        }
    }
  }

  Widget _buildStoriesList() {
    if (_stories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No stories yet!",
              style: GoogleFonts.quicksand(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true, // Important inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Scroll handled by parent
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75, // Book shape
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final story = _stories[index];
        final coverBase64 = story['coverBase64'];
        
        return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black87, width: 1.5), // Match Friends Style
              boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 4),
                  ),
               ],
            ),
            child: Stack( // Use Stack for absolute positioning of icons like Friends page
              children: [
                  // Make the whole card clickable (Background Layer)
                   Positioned.fill(
                       child: Material(
                           color: Colors.transparent,
                           child: InkWell(
                               borderRadius: BorderRadius.circular(16),
                               onTap: () {
                                   setState(() {
                                      _currentStory = story;
                                      _viewMode = StoriesViewMode.read;
                                    });
                               },
                           ),
                       )
                   ),
                   
                  // Book Content
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Cover Image
                      Expanded(
                        flex: 3,
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(14)), // slightly less than container
                          child: coverBase64 != null
                              ? Image.memory(base64Decode(coverBase64), fit: BoxFit.cover)
                              : Container(
                                  color: const Color(0xFFE0E7FF),
                                  child: Icon(Icons.book, size: 40, color: Colors.grey[400]),
                                ),
                        ),
                      ),
                      // Title
                      Expanded(
                        flex: 2,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Center(
                            child: Text(
                              story['title'] ?? 'Untitled',
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.quicksand(
                                fontSize: 13, 
                                fontWeight: FontWeight.bold,
                                color: Colors.black87
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                   
                   // Floating Action Icons (Top Right)
                   Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildIconAction(Icons.visibility, () {
                           setState(() {
                              _currentStory = story;
                              _viewMode = StoriesViewMode.read;
                            });
                        }),
                        const SizedBox(width: 4),
                        _buildIconAction(Icons.edit, () => _renameStory(index)),
                        const SizedBox(width: 4),
                        _buildIconAction(Icons.delete, () => _deleteStory(index), isDestructive: true),
                      ],
                    ),
                  ),


              ],
            ),
        );
      },
    );
  }

  Widget _buildIconAction(IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
        ),
        child: Icon(icon, size: 16, color: isDestructive ? Colors.redAccent : Colors.black87),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Row( // Changed from padding+row to just row matching Friends page
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavIcon(Icons.home_outlined, 'Home', onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => HomePage(
                themeNotifier: widget.themeNotifier,
                geminiModelNotifier: widget.geminiModelNotifier,
                stabilityModelNotifier: widget.stabilityModelNotifier,
                creativityNotifier: widget.creativityNotifier,
              )),
              (route) => false,
            );
        }),
        _buildNavIcon(Icons.edit_outlined, 'Friends', onTap: () {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute(builder: (context) => CharacterCreationPage(
                  themeNotifier: widget.themeNotifier,
                  geminiModelNotifier: widget.geminiModelNotifier,
                  stabilityModelNotifier: widget.stabilityModelNotifier,
                  creativityNotifier: widget.creativityNotifier,
              ))
            );
        }),
        _buildNavIcon(Icons.book_outlined, 'Stories', isActive: true),
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
            color: isActive ? const Color(0xFF9FA0CE) : Theme.of(context).iconTheme.color?.withOpacity(0.6),
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
