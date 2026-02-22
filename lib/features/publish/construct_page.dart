import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tellulu/features/publish/finalize_page.dart';

class ConstructPage extends StatefulWidget {
  const ConstructPage({required this.story, required this.onSave, super.key});

  final Map<String, dynamic> story;
  final void Function(Map<String, dynamic>) onSave;

  @override
  State<ConstructPage> createState() => _ConstructPageState();
}

class _ConstructPageState extends State<ConstructPage> {
  late Map<String, dynamic> _storyData;
  late List<Map<String, dynamic>> _pages;

  @override
  void initState() {
    super.initState();
    _storyData = widget.story;
    final rawPages = _storyData['pages'] as List<dynamic>? ?? [];
    _pages = rawPages.map<Map<String, dynamic>>((p) {
      if (p is Map) return Map<String, dynamic>.from(p);
      if (p is String) return {'type': 'Standard Page', 'text': p, 'image': null};
      return {'type': 'Standard Page', 'text': '', 'image': null};
    }).toList();
  }

  void _addPage(String type) {
    setState(() {
       // Insert at the top (index 0)
        _pages.insert(0, <String, dynamic>{
            'type': type, 
            'text': 'New $type page content...',
            'image': null,
            'style': {
                 'color': Colors.black87.toARGB32(),
                 'fontSize': 18.0,
                 'fontFamily': 'Quicksand'
            }
        });
        _storyData['pages'] = _pages;
    });
    widget.onSave(_storyData);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added $type page to top')));
  }

  String _getPageTitle(int index) {
      final page = _pages[index];
      final String type = page['type'] as String? ?? 'Standard Page';

      final lowerType = type.toLowerCase();
      // Non-numbered pages
      if (lowerType.contains('cover') || 
          lowerType.contains('jacket') || 
          lowerType.contains('foreword') || 
          lowerType.contains('forward') || 
          lowerType.contains('acknowledgement') || 
          lowerType.contains('epilogue') || 
          lowerType.contains('afterword') || 
          lowerType.contains('afterward') || 
          lowerType.contains('endnote') || 
          lowerType.contains('colophon')) {
          return type;
      }

      // Numbered Standard Pages
      int spCount = 0;
      for (int i = 0; i <= index; i++) {
          final p = _pages[i];
          final String t = p['type'] as String? ?? 'Standard Page';
          
          if (!t.toLowerCase().contains('cover') && 
              !t.toLowerCase().contains('jacket') && 
              !t.toLowerCase().contains('foreword') && 
              !t.toLowerCase().contains('forward') && 
              !t.toLowerCase().contains('acknowledgement') && 
              !t.toLowerCase().contains('epilogue') && 
              !t.toLowerCase().contains('afterword') && 
              !t.toLowerCase().contains('afterward') && 
              !t.toLowerCase().contains('endnote') && 
              !t.toLowerCase().contains('colophon')) {
              spCount++;
          }
      }
      return 'Page $spCount';
  }

  void _showEditPage(int index) {
      final page = _pages[index] as Map;
      
      Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (context) => FinalizePage(
                pageData: Map<String, dynamic>.from(page),
                pageTitle: 'Finalize ${_getPageTitle(index)}',
                storyContext: _storyData, // [NEW] Pass context for AI consistency
                onSave: (updatedPage) {
                    setState(() {
                        _pages[index] = updatedPage;
                        _storyData['pages'] = _pages;
                    });
                    widget.onSave(_storyData);
                },
            ),
        ),
      );
  }

  void _deletePage(int index) {
      showDialog<void>(
          context: context,
          builder: (context) => AlertDialog(
              title: const Text('Delete Page?'),
              content: const Text('Are you sure you want to remove this page?'),
              actions: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  TextButton(
                      onPressed: () {
                          setState(() {
                              _pages.removeAt(index);
                              _storyData['pages'] = _pages;
                          });
                          widget.onSave(_storyData);
                          Navigator.pop(context);
                      },
                      child: const Text('Delete', style: TextStyle(color: Colors.red)),
                  ),
              ],
          ),
      );
  }

  void _renamePage(int index) {
    final page = _pages[index];
    // Default to existing title or type if no title set
    final currentTitle = page['title'] as String? ?? page['type'] as String? ?? 'Standard Page';
    final TextEditingController controller = TextEditingController(text: currentTitle);

    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Page'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Page Title', hintText: 'e.g., Chapter 1'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              setState(() {
                final page = Map<String, dynamic>.from(_pages[index]);
                page['title'] = controller.text;
                _pages[index] = page;
                _storyData['pages'] = _pages;
              });
              widget.onSave(_storyData);
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _changePageType(int index) {
      final List<String> types = [
          'Standard Page', 'Book Cover', 'Book Jacket', 'Foreword', 'Dedication', 
          'Table of Contents', 'Prologue', 'Epilogue', 'Afterword', 'About the Author', 'Colophon'
      ];

      showDialog<void>(
          context: context,
          builder: (context) => SimpleDialog(
              title: const Text('Select Page Type'),
              children: types.map((type) => SimpleDialogOption(
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                  child: Text(type, style: GoogleFonts.quicksand(fontSize: 16)),
                  onPressed: () {
                      setState(() {
                          final page = Map<String, dynamic>.from(_pages[index]);
                          page['type'] = type;
                          _pages[index] = page;
                          _storyData['pages'] = _pages;
                      });
                      widget.onSave(_storyData);
                      Navigator.pop(context);
                  },
              )).toList(),
          ),
      );
  }


  @override
  Widget build(BuildContext context) {
    // Determine if we are in dark mode based on theme brightness
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? const Color(0xFF1A1A2E) : Theme.of(context).scaffoldBackgroundColor;
    final navBarColor = isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFDFCF4);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: navBarColor,
        systemNavigationBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: backgroundColor,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
             final isSmallScreen = constraints.maxWidth < 600;
             return Center(
               child: Container(
                 constraints: BoxConstraints(
                   maxWidth: isSmallScreen ? 400 : 700,
                   maxHeight: constraints.maxHeight - 16,
                 ),
                 margin: const EdgeInsets.all(8),
                 decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFF9FA0CE),
                      width: isSmallScreen ? 2.0 : 3.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                 ),
                 padding: EdgeInsets.all(isSmallScreen ? 12.0 : 16.0),
                 child: Column(
                   children: [
                     // Custom Header inside the Card
                     Padding(
                       padding: const EdgeInsets.only(bottom: 16),
                       child: Row(
                         mainAxisAlignment: MainAxisAlignment.spaceBetween,
                         children: [
                           IconButton(
                             icon: const Icon(Icons.arrow_back),
                             onPressed: () => Navigator.pop(context),
                           ),
                           Text(
                             'Construct Book',
                             style: GoogleFonts.chewy(
                               fontSize: 24,
                               color: const Color(0xFF9FA0CE),
                             ),
                           ),
                           IconButton(
                             icon: const Icon(Icons.add_circle, size: 32, color: Color(0xFF9FA0CE)),
                             onPressed: () => _addPage('Standard Page'), // Default add
                             tooltip: 'Add Page to Top',
                           ),
                         ],
                       ),
                     ),
                     
                     // Page List
                     Expanded(
                        child: _pages.isEmpty
                            ? Center(
                                child: Text(
                                    'Start your story construction!\nTap the + button to add a page.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.quicksand(color: Colors.grey),
                                ),
                            )
                            : ReorderableListView.builder(
                                 padding: const EdgeInsets.symmetric(horizontal: 4),
                                 onReorder: (oldIndex, newIndex) {
                                     setState(() {
                                         if (oldIndex < newIndex) {
                                             newIndex -= 1;
                                         }
                                         final item = _pages.removeAt(oldIndex);
                                         _pages.insert(newIndex, item);
                                         _storyData['pages'] = _pages;
                                     });
                                     widget.onSave(_storyData);
                                 },
                                 itemCount: _pages.length,
                                 itemBuilder: (context, index) {
                                     final pageData = _pages[index];
                                     return _buildPageTile(index, pageData);
                                 },
                            ),
                     ),
                   ],
                 ),
               ),
             );
            }
          ),
        ), // SafeArea
      ),
    );
  }

  Widget _buildPageTile(int index, Map<String, dynamic> pageData) {
      final summary = pageData['text'] as String? ?? 'Empty Page';
      final type = pageData['type'] as String? ?? 'Standard Page';
      // If 'title' is set, use it. Otherwise use uppercased type.
      final customTitle = pageData['title'] as String?;
      final displayTitle = customTitle != null && customTitle.isNotEmpty ? customTitle : type.toUpperCase();
      final isCustomTitle = customTitle != null && customTitle.isNotEmpty;

      // Indicator Logic
      String indicator = 'Pg'; // Default 2-letter
      Color indicatorColor = Colors.grey[400]!;
      
      final lowerType = type.toLowerCase();
      
      if (lowerType.contains('cover')) {
          indicator = 'BC'; // Book Cover
          indicatorColor = Colors.orange[300]!;
      } else if (lowerType.contains('jacket')) {
          indicator = 'BJ'; // Book Jacket
          indicatorColor = Colors.purple[300]!;
      } else if (lowerType.contains('foreword') || lowerType.contains('forward')) {
          indicator = 'FW'; // Foreword
          indicatorColor = Colors.blue[300]!;
      } else if (lowerType.contains('acknowledgement')) {
          indicator = 'AC';
          indicatorColor = Colors.cyan[300]!;
      } else if (lowerType.contains('epilogue')) {
          indicator = 'EP';
          indicatorColor = Colors.teal[300]!;
      } else if (lowerType.contains('afterword') || lowerType.contains('afterward')) {
          indicator = 'AW';
          indicatorColor = Colors.green[300]!;
      } else if (lowerType.contains('endnote')) {
          indicator = 'EN';
          indicatorColor = Colors.amber[300]!;
      } else if (lowerType.contains('colophon')) {
          indicator = 'CO';
          indicatorColor = Colors.brown[300]!;
      } else {
          // Standard Page Logic
          indicatorColor = const Color(0xFF9FA0CE); // Tellulu Blue
          
          // Calculate page number
          int spCount = 0;
          for (int i = 0; i <= index; i++) {
              final p = _pages[i];
              final String t = p['type'] as String? ?? 'Standard Page';
              
              // flexible check for "Standard"
              if (!t.toLowerCase().contains('cover') && 
                  !t.toLowerCase().contains('jacket') && 
                  !t.toLowerCase().contains('foreword') && 
                  !t.toLowerCase().contains('forward') && 
                  !t.toLowerCase().contains('acknowledgement') && 
                  !t.toLowerCase().contains('epilogue') && 
                  !t.toLowerCase().contains('afterword') && 
                  !t.toLowerCase().contains('afterward') && 
                  !t.toLowerCase().contains('endnote') && 
                  !t.toLowerCase().contains('colophon')) {
                  spCount++;
              }
          }
          indicator = '$spCount';
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      // Use a Container for styling to avoid ListTile ghosting issues
      return Container(
          key: ValueKey('page_${index}_${type}_${summary.hashCode}_$displayTitle'),
          margin: const EdgeInsets.only(bottom: 8), // Spacing between tiles
          decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black12,
              ),
          ),
          child: ListTile(
              // Remove tileColor and shape from ListTile as Container handles it
              contentPadding: const EdgeInsets.all(8),
              onTap: () => _showEditPage(index),
              leading: Container(
                 width: 40, height: 40,
                 alignment: Alignment.center,
                 decoration: BoxDecoration(
                     color: indicatorColor.withValues(alpha: 0.2), 
                     borderRadius: BorderRadius.circular(8),
                     border: Border.all(color: indicatorColor, width: 2)
                 ),
                 child: Text(
                     indicator,
                     style: GoogleFonts.chewy(
                         fontSize: 20,
                         color: indicatorColor,
                         fontWeight: FontWeight.bold
                     )
                 ),
              ),
              title: Text(
                displayTitle, 
                style: GoogleFonts.quicksand(
                  fontWeight: FontWeight.bold, 
                  fontSize: 12,
                  color: isCustomTitle ? Colors.black87 : Colors.grey[700]
                )
              ),
              subtitle: Text(summary, maxLines: 2, overflow: TextOverflow.ellipsis),
              trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                      IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blueGrey),
                          onPressed: () => _showEditPage(index),
                          tooltip: 'Edit Content',
                      ),
                      PopupMenuButton<String>(
                          icon: const Icon(Icons.more_vert, color: Colors.grey),
                          onSelected: (value) {
                              if (value == 'type') _changePageType(index);
                              if (value == 'title') _renamePage(index);
                              if (value == 'delete') _deletePage(index);
                          },
                          itemBuilder: (context) => [
                              const PopupMenuItem(
                                  value: 'title',
                                  child: Row(children: [Icon(Icons.title, size: 18), SizedBox(width: 8), Text('Rename Page')]),
                              ),
                              const PopupMenuItem(
                                  value: 'type',
                                  child: Row(children: [Icon(Icons.category, size: 18), SizedBox(width: 8), Text('Change Type')]),
                              ),
                              const PopupMenuItem(
                                  value: 'delete',
                                  child: Row(children: [Icon(Icons.delete, color: Colors.red, size: 18), SizedBox(width: 8), Text('Delete Page', style: TextStyle(color: Colors.red))]),
                              ),
                          ],
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.drag_handle, color: Colors.grey),
                  ],
              ),
          ),
      );
  }
}
