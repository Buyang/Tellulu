import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tellulu/features/create/character_creation_page.dart';
import 'package:tellulu/features/home/home_page.dart';
import 'package:tellulu/features/publish/construct_page.dart';
import 'package:tellulu/features/settings/settings_page.dart';
import 'package:tellulu/features/stories/stories_page.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tellulu/providers/service_providers.dart';
import 'package:tellulu/services/storage_service.dart';

class PublishPage extends ConsumerStatefulWidget {
  const PublishPage({super.key});

  @override
  ConsumerState<PublishPage> createState() => _PublishPageState();
}

class _PublishPageState extends ConsumerState<PublishPage> {
  List<Map<String, dynamic>> _stories = [];
  final Set<int> _selectedIndices = {};
  bool _isSelectionMode = false;
  late final StorageService _storageService;

  @override
  void initState() {
    super.initState();
    _storageService = ref.read(storageServiceProvider);
    _initStorageAndLoad();
  }

  Future<void> _initStorageAndLoad() async {
    await _storageService.init();
    await _loadStories();
  }

  Future<void> _loadStories() async {
    final stories = await _storageService.loadStories();
    if (mounted) {
      setState(() {
        _stories = stories;
      });
    }
  }

  // _saveStories is no longer needed for bulk save, as we save individually
  // via StorageService. But we keep methods that modify stories to use StorageService directly.

  void _toggleSelection(int index) {
    setState(() {
      if (_selectedIndices.contains(index)) {
        _selectedIndices.remove(index);
      } else {
        _selectedIndices.add(index);
      }
      _isSelectionMode = _selectedIndices.isNotEmpty;
    });
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
              final id = _stories[index]['id'] as String;
              setState(() {
                _stories.removeAt(index);
                if (_selectedIndices.contains(index)) _selectedIndices.remove(index);
                _selectedIndices.clear();
                _isSelectionMode = false;
              });
              unawaited(_storageService.deleteStory(id)); // Use StorageService
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _renameStory(int index) {
    final TextEditingController renameController = TextEditingController(text: _stories[index]['title'] as String?);
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Storybook'),
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
              });
              unawaited(_storageService.saveStory(_stories[index])); // Use StorageService
              Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _navigateToConstruct(int index) {
      Navigator.push(
        context,
        MaterialPageRoute<void>(
            builder: (context) => ConstructPage(
                story: _stories[index],
                onSave: (updatedStory) {
                    setState(() {
                        _stories[index] = updatedStory;
                    });
                    unawaited(_storageService.saveStory(updatedStory)); // Use StorageService
                },
            ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
             final isSmallScreen = constraints.maxWidth < 600;
             // Custom Card Layout for Dashboard (Full Height)
             return Center(
               child: Container(
                 constraints: BoxConstraints(
                   maxWidth: isSmallScreen ? 400 : 700,
                   maxHeight: constraints.maxHeight - 32, // Leave some padding
                 ),
                 margin: const EdgeInsets.all(16),
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
                     _buildHeader(context),
                     Expanded(child: _buildContent(isSmallScreen)),
                     if (_isSelectionMode) _buildSelectionBar(),
                     if (!_isSelectionMode) _buildBottomNav(context),
                   ],
                 ),
               ),
             );
          }
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Spacer to balance the settings icon
          const SizedBox(width: 48),
          
          Text(
            'Publishing Studio',
            style: GoogleFonts.chewy(
              fontSize: 24,
              color: const Color(0xFF9FA0CE),
            ),
          ),
          
          IconButton(
             icon: const Icon(Icons.settings_outlined),
             onPressed: () {
                 Navigator.push(
                    context,
                    MaterialPageRoute<void>(builder: (context) => const SettingsPage()),
                 );
             },
          ),
        ],
      ),
    );
  }

  Widget _buildContent(bool isSmallScreen) {
      if (_stories.isEmpty) {
          return Center(
              child: Text(
                  'No stories to publish yet.\nGo create some adventures!',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(color: Colors.grey),
              ),
          );
      }

      return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: isSmallScreen ? 2 : 3,
              childAspectRatio: 0.65, // Taller for actions
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
          ),
          itemCount: _stories.length,
          itemBuilder: (context, index) {
              final story = _stories[index];
              final isSelected = _selectedIndices.contains(index);
              final coverBase64 = story['coverBase64'] as String?;

              return Stack(
                  children: [
                      // Card Body
                      GestureDetector(
                          onTap: () {
                              if (_isSelectionMode) {
                                  _toggleSelection(index);
                              } else {
                                  // Default tap? Maybe preview? Or nothing?
                                  // User request: "select one storybook on the bottom right of the card"
                              }
                          },
                          child: Container(
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: isSelected ? const Color(0xFF9FA0CE) : Colors.black12,
                                      width: isSelected ? 3 : 1,
                                  ),
                                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2,2))],
                              ),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                      Expanded(
                                          child: ClipRRect(
                                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                              child: coverBase64 != null
                                                ? Image.memory(base64Decode(coverBase64), fit: BoxFit.cover)
                                                : Container(color: Colors.grey[200], child: const Icon(Icons.book, color: Colors.grey)),
                                          ),
                                      ),
                                      Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: Text(
                                              (story['title'] as String?) ?? 'Untitled',
                                              textAlign: TextAlign.center,
                                              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 12),
                                              overflow: TextOverflow.ellipsis,
                                          ),
                                      ),
                                  ],
                              ),
                          ),
                      ),
                      
                      // Top Right Actions
                      Positioned(
                          top: 4,
                          right: 4,
                          child: Row(
                              children: [
                                  _actionIcon(Icons.build, () => _navigateToConstruct(index), tooltip: 'Construct'),
                                  const SizedBox(width: 4),
                                  _actionIcon(Icons.edit, () => _renameStory(index), tooltip: 'Rename'),
                                  const SizedBox(width: 4),
                                  _actionIcon(Icons.delete, () => _deleteStory(index), color: Colors.red, tooltip: 'Delete'),
                              ],
                          ),
                      ),
                      
                      // Bottom Right Selection Toggle
                      Positioned(
                          bottom: 4,
                          right: 4,
                          child: GestureDetector(
                              onTap: () => _toggleSelection(index),
                              child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                      color: isSelected ? const Color(0xFF9FA0CE) : Colors.white,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.black26),
                                  ),
                                  child: Icon(
                                      Icons.check,
                                      size: 16,
                                      color: isSelected ? Colors.white : Colors.transparent,
                                  ),
                              ),
                          ),
                      ),
                  ],
              );
          },
      );
  }

  Widget _actionIcon(IconData icon, VoidCallback onTap, {Color color = Colors.black87, String? tooltip}) {
      return GestureDetector(
          onTap: onTap,
          child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  shape: BoxShape.circle,
                  boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 2)],
              ),
              child: Icon(icon, size: 14, color: color),
          ),
      );
  }

  Widget _buildSelectionBar() {
      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: const Color(0xFFE8EAF6),
              border: Border(top: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
          ),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                  _bottomAction(Icons.print, 'Print PDF/X-4'),
                  _bottomAction(Icons.email, 'Email'),
                  _bottomAction(Icons.play_circle_fill, 'Playback'),
                  IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                          setState(() {
                              _selectedIndices.clear();
                              _isSelectionMode = false;
                          });
                      },
                  )
              ],
          ),
      );
  }

  Widget _bottomAction(IconData icon, String label) {
      return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              Icon(icon, color: const Color(0xFF9FA0CE)),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.quicksand(fontSize: 10, fontWeight: FontWeight.bold)),
          ],
      );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavIcon(context, Icons.logout_outlined, 'Log Off', onTap: () => _showLogOffDialog(context)),
          _buildNavIcon(context, Icons.edit_outlined, 'Friends', onTap: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(builder: (context) => const CharacterCreationPage()),
            );
          }),
          _buildNavIcon(context, Icons.book_outlined, 'Stories', onTap: () {
               Navigator.pushReplacement(
              context,
              MaterialPageRoute<void>(builder: (context) => const StoriesPage()),
            );
          }),
          _buildNavIcon(context, Icons.publish, 'Publish', isActive: true),
        ],
      ),
    );
  }

  Widget _buildNavIcon(BuildContext context, IconData icon, String label, {bool isActive = false, VoidCallback? onTap}) {
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
}
