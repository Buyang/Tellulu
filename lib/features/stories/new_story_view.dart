import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tellulu/common/utils/icon_utils.dart';
import 'package:tellulu/features/stories/consistency_engine.dart';
import 'package:tellulu/providers/service_providers.dart';

class NewStoryView extends ConsumerStatefulWidget {

  const NewStoryView({
    required this.cast, required this.onWeaveStory, super.key,
    this.isWeaving = false,
    this.weavingStatus, // [FIX] Initialize it
  });
  final List<Map<String, dynamic>> cast;
  final Function(Map<String, dynamic>) onWeaveStory;
  final bool isWeaving;
  final String? weavingStatus; // [NEW]

  @override
  ConsumerState<NewStoryView> createState() => _NewStoryViewState();
}

class _NewStoryViewState extends ConsumerState<NewStoryView> {
  String _selectedVibe = 'Magical'; // Default
  final String _readingLevel = 'Preschool'; // Default (UI removed)
  final Set<int> _selectedCastIndices = {};
  final TextEditingController _specialTouchController = TextEditingController();

  List<String> _vibes = [];
  bool _isLoadingVibes = true;
  
  final Map<String, IconData> _vibeIcons = {
    'Magical': Icons.auto_fix_high,
    'Space': Icons.rocket_launch,
    'Prehistoric': Icons.landscape,
    'Heroes': Icons.shield,
    'Underwater': Icons.scuba_diving,
    'Pirate': Icons.sailing,
    'Medieval': Icons.castle,
    'Superhero': Icons.bolt,
    'Jungle': Icons.forest,
    'Arctic': Icons.ac_unit,
    'Detective': Icons.search,
    'Fairy Tale': Icons.menu_book,
    'Western': Icons.star,
    'Dinosaur': Icons.pets,
    'Robot': Icons.smart_toy,
    'Sports': Icons.sports_soccer,
    'Cooking': Icons.restaurant_menu,
    'Safari': Icons.camera_alt,
    'Camping': Icons.local_fire_department,
    'Winter': Icons.snowboarding,
    'Beach': Icons.beach_access,
    'Halloween': Icons.nightlight_round,
    'Circus': Icons.theater_comedy,
  };

  @override
  void initState() {
    super.initState();
    _loadVibes();
  }

  Future<void> _loadVibes() async {
    await ConsistencyEngine().loadCustomStyles();
    setState(() {
      _vibes = ConsistencyEngine().getAvailableVibes();
      _isLoadingVibes = false;
      
      // Ensure selected vibe is valid
      if (!_vibes.contains(_selectedVibe) && _vibes.isNotEmpty) {
        _selectedVibe = _vibes.first;
      }
    });
  }

  Future<void> _handleAddVibe() async {
      final TextEditingController controller = TextEditingController();
      
      final String? newVibe = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Add a New Vibe'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text('(hint: a vibe is about setting context or atmosphere for the story)', style: GoogleFonts.quicksand(fontSize: 14)),
               const SizedBox(height: 12),
               TextField(
                 controller: controller,
                 textCapitalization: TextCapitalization.sentences,
                 decoration: const InputDecoration(
                   border: OutlineInputBorder(),
                   hintText: 'Vibe Name'
                 ),
               ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, controller.text.trim()),
              child: const Text('Create'),
            ),
          ],
        ),
      );

      if (newVibe != null && newVibe.isNotEmpty) {
         try {
            // Show loading
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(content: Text('Asking Gemini to design "$newVibe" vibe...')),
            );

            // 1. Generate Style Rules via Gemini
            final rules = await ref.read(geminiServiceProvider).generateStyleProfile(newVibe);
            
            // 2. Register with Engine
            final style = StoryStyle(
               name: newVibe,
               positivePrompt: rules['positive']!,
               negativePrompt: rules['negative']!,
               stylePreset: 'digital-art', // Default base
               iconName: rules['icon'],
            );
            
            await ConsistencyEngine().registerCustomStyle(style);
            
            // 3. Update UI
            await _loadVibes();
            setState(() {
               _selectedVibe = newVibe;
            });
            
         } catch (e) {
           if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(
               SnackBar(
                 content: Text('Failed to create vibe: $e'),
                 backgroundColor: Colors.red,
                 action: SnackBarAction(
                   label: 'Retry',
                   textColor: Colors.white,
                   onPressed: _handleAddVibe,
                 ),
               ),
             );
           }
         }
      }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ... (Header and other sections remain same) ...
            
            // Vibe Picker (Refactored)
            _buildSectionTitle('Pick a Vibe'),
            const SizedBox(height: 12),
            if (_isLoadingVibes)
               const Center(child: CircularProgressIndicator())
            else
              SizedBox(
                height: 90,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _vibes.length + 1, // +1 for Add Button
                  separatorBuilder: (c, i) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                     if (index == _vibes.length) {
                       return _buildAddVibeButton();
                     }
                     return _buildVibeOption(_vibes[index]);
                  },
                ),
              ),
            const SizedBox(height: 24),
              
              // Cast Selector (New Requirement)
              _buildSectionTitle('Who is in it?'),
              const SizedBox(height: 12),
              if (widget.cast.isEmpty)
                Padding(
                   padding: const EdgeInsets.all(16),
                   child: Text('No cast members yet! Go to Friends to add some.', style: GoogleFonts.quicksand(fontStyle: FontStyle.italic)),
                )
              else
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: widget.cast.length,
                    separatorBuilder: (context, index) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      final char = widget.cast[index];
                      final isSelected = _selectedCastIndices.contains(index);
                      final imageBytes = char['imageBytes'] as Uint8List?;
                      
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedCastIndices.remove(index);
                            } else {
                              _selectedCastIndices.add(index);
                            }
                          });
                        },
                        child: Column(
                          children: [
                            Container(
                              width: 70,
                              height: 70,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected ? const Color(0xFF9FA0CE) : Colors.transparent, 
                                  width: 3
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(2), // Gap between border and avatar
                                child: ClipOval(
                                  child: imageBytes != null
                                    ? Image.memory(imageBytes, fit: BoxFit.cover)
                                    : ColoredBox(
                                      color: Color(char['color'] as int),
                                      child: const Icon(Icons.person, color: Colors.black26),
                                    ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              char['name'] as String,
                              style: GoogleFonts.quicksand(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
  
               const SizedBox(height: 24),
  
              // Special Touch
              _buildSectionTitle('Your Special Touch'),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF9E6),
                  border: Border.all(color: Colors.black87),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(2, 2))],
                ),
                child: TextField(
                  controller: _specialTouchController,
                  style: GoogleFonts.quicksand(color: Colors.black87), // Fix: Force dark text on light background
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'e.g. A dinosaur who loves to bake...',
                    hintStyle: GoogleFonts.quicksand(color: Colors.black38),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Weave Button
              Center(
                child: ElevatedButton(
                  onPressed: widget.isWeaving ? null : _handleWeave,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF9FA0CE),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: const BorderSide(color: Colors.black87, width: 1.5),
                    ),
                    elevation: 4,
                  ),
                  child: widget.isWeaving 
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                      'Weave Story',
                        style: GoogleFonts.chewy(fontSize: 24, fontWeight: FontWeight.normal, letterSpacing: 1.2),
                      ),
                ),
                  ),

              if (widget.isWeaving) ...[
                 const SizedBox(height: 16),
                 Center(
                   child: Text(
                     widget.weavingStatus ?? 'Weaving magic...',
                     style: GoogleFonts.quicksand(
                        fontSize: 14, 
                        color: Colors.black54,
                        fontStyle: FontStyle.italic
                     ),
                     textAlign: TextAlign.center,
                   ),
                 ),
              ],
            ],
          );
      }
    ); // End TelluluCard
  }
  
  void _handleWeave() {
    if (_selectedCastIndices.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick at least one friend to be in the story!')),
      );
      return;
    }
  
    final selectedCast = _selectedCastIndices.map((i) => widget.cast[i]).toList();
    
    widget.onWeaveStory({
      'readingLevel': _readingLevel,
      'vibe': _selectedVibe,
      'cast': selectedCast,
      'specialTouch': _specialTouchController.text,
    });
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge?.color,
      ),
    );
  }



  Widget _buildAddVibeButton() {
     return GestureDetector(
      onTap: _handleAddVibe,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Theme.of(context).cardColor,
              border: Border.all(
                color: Theme.of(context).disabledColor, 
                style: BorderStyle.solid,
                width: 1
              ),
            ),
            child: const Icon(Icons.add, size: 32, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text('Add', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildVibeOption(String label) {
    final isSelected = _selectedVibe == label;
    final themeColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    
    // Resolve Icon: Check static map first, then engine
    IconData icon = _vibeIcons[label] ?? Icons.auto_awesome;
    if (!_vibeIcons.containsKey(label)) {
       final style = ConsistencyEngine().getStyle(label);
       // Use the style's iconName if available, otherwise default
       if (style?.iconName != null) {
          icon = getMaterialIconByName(style!.iconName);
       }
    }

    return GestureDetector(
      onTap: () => setState(() => _selectedVibe = label),
      onLongPress: () {
        // Only allow deleting custom vibes (not in the hardcoded map)
        if (!_vibeIcons.containsKey(label)) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Delete Vibe?'),
              content: Text('Are you sure you want to delete "$label"?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () async {
                    Navigator.pop(context); // Close dialog
                    await ConsistencyEngine().removeCustomStyle(label);
                    await _loadVibes(); // Refresh list
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Deleted "$label"')),
                    );
                  },
                  child: const Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          );
        }
      },
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected ? const Color(0xFFFFF9C4) : Theme.of(context).cardColor,
              border: Border.all(
                color: isSelected ? Colors.black87 : themeColor.withValues(alpha: 0.3), 
                width: isSelected ? 2 : 1
              ),
            ),
            child: Icon(
                icon, 
                size: 32, 
                color: isSelected ? Colors.black87 : themeColor
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            width: 60,
            child: Text(
              label, 
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12, color: themeColor)
            ),
          ),
        ],
      ),
    );
  }
}
