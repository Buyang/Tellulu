import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tellulu/common/widgets/tellulu_card.dart';
import 'package:tellulu/features/create/character_creation_page.dart';
import 'package:tellulu/features/home/home_page.dart';
import 'package:tellulu/features/settings/settings_page.dart';
import 'package:tellulu/features/stories/new_story_view.dart';
import 'package:tellulu/features/stories/story_result_view.dart';
import 'package:tellulu/features/stories/story_weaver.dart';
import 'package:tellulu/providers/settings_providers.dart';
import 'package:tellulu/services/gemini_service.dart';
import 'package:tellulu/services/stability_service.dart';

class _BookTheme {
  _BookTheme({
    required this.baseColor,
    required this.spineLight,
    required this.spineDark,
    required this.paperColor,
    required this.borderColor,
    required this.textColor,
    required this.icon,
  });
  final Color baseColor;
  final Color spineLight;
  final Color spineDark;
  final Color paperColor;
  final Color borderColor;
  final Color textColor;
  final IconData icon;
}

enum StoriesViewMode { list, create, read }

class StoriesPage extends ConsumerStatefulWidget {
  const StoriesPage({super.key});

  @override
  ConsumerState<StoriesPage> createState() => _StoriesPageState();
}

class _StoriesPageState extends ConsumerState<StoriesPage> {
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

  late final StoryWeaver _storyWeaver;

  @override
  void initState() {
    super.initState();
    final geminiKey = dotenv.env['GEMINI_KEY'] ?? '';
    final stabilityKey = dotenv.env['STABILITY_KEY'] ?? '';
    
    if (geminiKey.isEmpty || stabilityKey.isEmpty) {
      print('WARNING: API Keys are missing! specific features will not work.');
    }

    _geminiService = GeminiService(geminiKey);
    _stabilityService = StabilityService(stabilityKey);
    _storyWeaver = StoryWeaver(geminiService: _geminiService, stabilityService: _stabilityService);
    _loadData();
  }

  Future<void> _handleWeaveStory(Map<String, dynamic> params) async {
    // ignore: avoid_print
    print('DEBUG: _handleWeaveStory started');
    setState(() => _isWeaving = true);

    try {
      final newStory = await _storyWeaver.weave(
        selectedCast: (params['cast'] as List).cast<Map<String, dynamic>>(),
        vibe: params['vibe'] as String,
        readingLevel: params['readingLevel'] as String,
        specialTouch: params['specialTouch'] as String,
        geminiModel: ref.read(geminiModelProvider).value ?? 'gemini-2.0-flash-exp',
        stabilityModel: ref.read(stabilityModelProvider).value ?? 'stable-diffusion-xl-1024-v1-0',
        onProgress: (status) {
             // Optional: Update loading status text in UI if needed (currently just weaving spinner)
             // ignore: avoid_print
             print('Weaving Progress: $status');
        },
      );

      if (!mounted) return;

      if (newStory != null) {
        // Auto-save and Update UI
        setState(() {
           _stories.insert(0, newStory); // Add to top
           _currentStory = newStory;
           _viewMode = StoriesViewMode.read; // Go to result
        });
        await _saveStories();
        if (!mounted) return;
        
        // ignore: avoid_print
        print('DEBUG: Story saved and state updated.');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to weave story. Please try again!')),
        );
      }
    } on Object catch (e, stack) {
      // ignore: avoid_print
      print('Weaving Error: $e');
      // ignore: avoid_print
      print(stack);
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('An error occurred while weaving.')),
          );
       }
    } finally {
      if (mounted) setState(() => _isWeaving = false);
      // ignore: avoid_print
      print('DEBUG: _handleWeaveStory finished');
    }
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Cast
    final String? castJson = prefs.getString('cast_data');
    if (castJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(castJson) as List<dynamic>;
        setState(() {
          _cast = decodedList.map((item) {
            final Map<String, dynamic> castItem = Map<String, dynamic>.from(item as Map);
            if (castItem['imageBase64'] != null) {
              castItem['imageBytes'] = base64Decode(castItem['imageBase64'] as String);
            }
            return castItem;
          }).toList();
        });
      } on Object catch (e) {
            // ignore: avoid_print
        print('Error loading cast: $e');
      }
    }

    // Load Stories
    final String? storiesJson = prefs.getString('stories_data');
    if (storiesJson != null) {
      try {
        final List<dynamic> decodedList = jsonDecode(storiesJson) as List<dynamic>;
        setState(() {
          _stories = decodedList.map((item) => Map<String, dynamic>.from(item as Map)).toList();
        });
      } on Object catch (e) {
            // ignore: avoid_print
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
      final TextEditingController renameController = TextEditingController(text: _stories[index]['title'] as String?);

      showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Story'),
        content: TextField(
          controller: renameController,
          decoration: const InputDecoration(hintText: 'New Title'),
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
              unawaited(_saveStories());
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }



  void _deleteStory(int index) {

      showDialog<void>(
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
              unawaited(_saveStories());
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
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            final headerSize = isSmallScreen ? 18.0 : 24.0;
            
            return TelluluCard( 
              maxWidth: isSmallScreen ? 400 : 700, // Wider for stories grid on large screens
              child: SingleChildScrollView( // Add ScrollView back for the main page wrapper
                child: Column(
                  children: [
                    // Header
                     _buildHeader(context, fontSize: headerSize),
        
                    // Content
                    Padding( // Add some padding around the dynamic content
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: _buildContent(isSmallScreen), // Pass responsive flag
                    ),
                    
                    const SizedBox(height: 16),
        
                    // Bottom Nav
                    if (_viewMode == StoriesViewMode.list) _buildBottomNav(isSmallScreen),
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
                unawaited(_saveStories()); // Just trigger save for now if needed
                Navigator.push(
                context,
                MaterialPageRoute<void>(builder: (context) => const SettingsPage()),
              );
            } : null,
          ),
        ],
      );
  }

  Widget _buildContent(bool isSmallScreen) {
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




             _buildStoriesList(isSmallScreen),
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
              unawaited(_saveStories());
            },
          );
        } else {
          return const Center(child: Text('Error loading story'));
        }
    }
  }

  Widget _buildStoriesList(bool isSmallScreen) {
    if (_stories.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'No stories yet!',
              style: GoogleFonts.quicksand(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      shrinkWrap: true, // Important inside SingleChildScrollView
      physics: const NeverScrollableScrollPhysics(), // Scroll handled by parent
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSmallScreen ? 2 : 3,
        childAspectRatio: 0.75, // Book shape
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _stories.length,
      itemBuilder: (context, index) {
        final story = _stories[index];
        final coverBase64 = story['coverBase64'];
        final vibe = story['vibe'] as String? ?? 'Magical'; // Default to Magical if missing
        
        final theme = _getBookTheme(vibe);
        
        return GestureDetector(
          onTap: () {
              setState(() {
                _currentStory = story;
                _viewMode = StoriesViewMode.read;
              });
          },
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.transparent, // Shadow comes from the book itself
            ),
            child: Stack(
              children: [
                 // The Book
                 Container(
                   margin: const EdgeInsets.only(left: 4, bottom: 4), // Lift effects
                   decoration: BoxDecoration(
                     color: theme.baseColor, 
                     borderRadius: const BorderRadius.only(
                       topRight: Radius.circular(6), 
                       bottomRight: Radius.circular(6)
                     ),
                     boxShadow: [
                       BoxShadow(
                         color: Colors.black.withValues(alpha: 0.2), 
                         offset: const Offset(4, 4),  
                         blurRadius: 5
                       )
                     ],
                   ),
                   child: Row(
                     children: [
                        // Spine
                        Container(
                          width: 24,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [theme.spineLight, theme.spineDark, theme.baseColor],
                            ),
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(2),
                              bottomLeft: Radius.circular(2)
                            ),
                            border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.1))),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                                // Spine Icon (Small Badge)
                               Padding(
                                 padding: const EdgeInsets.only(bottom: 12),
                                 child: Icon(theme.icon, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                               ),
                            ],
                          ),
                        ),
                        
                        // Cover Content
                        Expanded(
                          child: Container(
                             decoration: BoxDecoration(
                               color: theme.paperColor, 
                               borderRadius: const BorderRadius.only(
                                  topRight: Radius.circular(6),
                                  bottomRight: Radius.circular(6)
                               ),
                             ),
                             child: Column(
                               crossAxisAlignment: CrossAxisAlignment.stretch,
                               children: [
                                  // Cover Image Area
                                  Expanded(
                                    flex: 4,
                                    child: Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          border: Border.all(color: theme.borderColor, width: 2),
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: coverBase64 != null
                                            ? ClipRRect(
                                              borderRadius: BorderRadius.circular(2),
                                              child: Image.memory(base64Decode(coverBase64 as String), fit: BoxFit.cover),
                                            )
                                          : Center(
                                              child: Icon(theme.icon, size: 32, color: theme.baseColor.withValues(alpha: 0.5)),
                                            ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Title Area
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            (story['title'] as String?) ?? 'Untitled',
                                            textAlign: TextAlign.center,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: GoogleFonts.cinzel( // Classic Storybook font
                                              fontSize: 12, 
                                              fontWeight: FontWeight.bold,
                                              color: theme.textColor
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Container(height: 2, width: 20, color: theme.baseColor.withValues(alpha: 0.5)), // Decoration
                                        ],
                                      ),
                                    ),
                                  ),
                               ],
                             ),
                          ),
                        ),
                     ],
                   ),
                 ),
                 
                 // Actions (Overlay on top right)
                 Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                         _buildIconAction(Icons.edit, () => _renameStory(index)),
                          const SizedBox(width: 4),
                          _buildIconAction(Icons.delete, () => _deleteStory(index), isDestructive: true),
                      ],
                    ),
                 ),
              ],
            ),
          ),
        );
      },
    );
  }

  _BookTheme _getBookTheme(String vibe) {
     switch (vibe) {
       case 'Space':
         return _BookTheme(
           baseColor: const Color(0xFF1A237E), // Deep Blue
           spineLight: const Color(0xFF3949AB),
           spineDark: const Color(0xFF0D47A1),
           paperColor: const Color(0xFFE8EAF6), // Blueish White
           borderColor: const Color(0xFFC5CAE9),
           textColor: const Color(0xFF1A237E),
           icon: Icons.rocket_launch,
         );
       case 'Prehistoric':
         return _BookTheme(
           baseColor: const Color(0xFF33691E), // Deep Green
           spineLight: const Color(0xFF558B2F),
           spineDark: const Color(0xFF1B5E20),
           paperColor: const Color(0xFFF1F8E9), // Greenish White
           borderColor: const Color(0xFFDCEDC8),
           textColor: const Color(0xFF33691E),
           icon: Icons.landscape, // Dino/Nature
         );
       case 'Heroes':
         return _BookTheme(
           baseColor: const Color(0xFFB71C1C), // Deep Red
           spineLight: const Color(0xFFD32F2F),
           spineDark: const Color(0xFF880E4F), // Maroon
           paperColor: const Color(0xFFFFEBEE), // Reddish White
           borderColor: const Color(0xFFFFCDD2),
           textColor: const Color(0xFFB71C1C),
           icon: Icons.security, // Shield
         );
       case 'Magical':
       default:
         return _BookTheme(
           baseColor: const Color(0xFF4A148C), // Deep Purple
           spineLight: const Color(0xFF7B1FA2),
           spineDark: const Color(0xFF311B92),
           paperColor: const Color(0xFFF3E5F5), // Purpleish White
           borderColor: const Color(0xFFE1BEE7),
           textColor: const Color(0xFF4A148C),
           icon: Icons.auto_fix_high, // Wand
         );
     }
  }

  // Helper class for themes


  Widget _buildIconAction(IconData icon, VoidCallback onTap, {bool isDestructive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.black12),
          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(0,1))],
        ),
        child: Icon(icon, size: 14, color: isDestructive ? Colors.redAccent : Colors.black87),
      ),
    );
  }

  Widget _buildBottomNav(bool isSmallScreen) {
    return Row( // Changed from padding+row to just row matching Friends page
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _buildNavIcon(Icons.home_outlined, 'Home', onTap: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute<void>(builder: (context) => const HomePage()),
              (route) => false,
            );
        }),
        _buildNavIcon(Icons.edit_outlined, 'Friends', onTap: () {
            Navigator.pushReplacement(
              context, 
              MaterialPageRoute<void>(builder: (context) => const CharacterCreationPage())
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


