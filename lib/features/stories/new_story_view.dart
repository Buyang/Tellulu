import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NewStoryView extends StatefulWidget {

  const NewStoryView({
    required this.cast, required this.onWeaveStory, super.key,
    this.isWeaving = false,
  });
  final List<Map<String, dynamic>> cast;
  final Function(Map<String, dynamic>) onWeaveStory;
  final bool isWeaving;

  @override
  State<NewStoryView> createState() => _NewStoryViewState();
}

class _NewStoryViewState extends State<NewStoryView> {
  // Selections
  bool _isAIMagic = true;
  String _readingLevel = 'Preschool';
  String _selectedVibe = 'Magical';
  final Set<int> _selectedCastIndices = {};
  final TextEditingController _specialTouchController = TextEditingController();

  final List<String> _vibes = ['Magical', 'Space', 'Prehistoric', 'Heroes'];
  final Map<String, IconData> _vibeIcons = {
    'Magical': Icons.auto_fix_high,
    'Space': Icons.rocket_launch,
    'Prehistoric': Icons.landscape,
    'Heroes': Icons.security,
  };

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        final titleSize = isSmallScreen ? 24.0 : 32.0; // 32 was original
        final subtitleSize = isSmallScreen ? 14.0 : 16.0;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Center(
              child: Column(
                children: [
                   Text(
                      'NEW STORY',
                      style: GoogleFonts.chewy(fontSize: titleSize, color: Colors.black87),
                    ),
                    Text(
                      "Let's make a tale!",
                      style: GoogleFonts.quicksand(fontSize: subtitleSize, color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
  
              // Magic Toggle
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildToggleBtn('AI Magic', true),
                  const SizedBox(width: 12),
                  _buildToggleBtn('Write Myself', false),
                ],
              ),
              const SizedBox(height: 24),
  
              // Reading Level
              _buildSectionTitle('Who is reading?'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildReadingLevelOption('Toddler', Icons.child_care),
                  _buildReadingLevelOption('Preschool', Icons.face),
                  _buildReadingLevelOption('Big Kid', Icons.school),
                ],
              ),
              const SizedBox(height: 24),
  
              // Vibe Picker
              _buildSectionTitle('Pick a Vibe'),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: _vibes.map(_buildVibeOption).toList(),
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
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
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

  Widget _buildToggleBtn(String label, bool isMagic) {
    final isSelected = _isAIMagic == isMagic;
    final themeColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;
    
    return GestureDetector(
      onTap: () => setState(() => _isAIMagic = isMagic),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF9FA0CE) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFF9FA0CE) : themeColor.withValues(alpha: 0.5), 
            width: 1.5
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.bold, 
            color: isSelected ? Colors.white : themeColor
          ),
        ),
      ),
    );
  }

  Widget _buildReadingLevelOption(String label, IconData icon) {
    final isSelected = _readingLevel == label;
    final themeColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87; // Dark Mode text color

    return GestureDetector(
      onTap: () => setState(() => _readingLevel = label),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? const Color(0xFFE0E7FF) : Theme.of(context).cardColor, // Background varies
              border: Border.all(
                color: isSelected 
                    ? themeColor // Selected border
                    : themeColor.withValues(alpha: 0.3), // Unselected faint border
                width: isSelected ? 2 : 1
              ),
            ),
            child: Icon(
                icon, 
                size: 32, 
                color: isSelected ? Colors.black87 : themeColor // Icon color flips
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12, color: themeColor)),
        ],
      ),
    );
  }

  Widget _buildVibeOption(String label) {
    final isSelected = _selectedVibe == label;
    final themeColor = Theme.of(context).textTheme.bodyLarge?.color ?? Colors.black87;

    return GestureDetector(
      onTap: () => setState(() => _selectedVibe = label),
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
                _vibeIcons[label], 
                size: 32, 
                color: isSelected ? Colors.black87 : themeColor
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12, color: themeColor)),
        ],
      ),
    );
  }
}
