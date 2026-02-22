import 'dart:convert';
// import 'dart:typed_data'; // Unnecessary (provided by Foundation)
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:tellulu/common/widgets/draggable_resizable.dart';
import 'package:tellulu/providers/service_providers.dart';
import 'package:tellulu/providers/settings_providers.dart';

// ... existing imports ...



// --- Layer Models ---
enum LayerType { image, text }

class Layer {
  String id;
  LayerType type;
  Rect rect;
  bool isLocked;
  
  Layer({required this.id, required this.type, required this.rect, this.isLocked = false});
}

class ImageLayer extends Layer {
  Uint8List? data; // null if placeholder
  ImageLayer({required super.id, required super.rect, this.data}) : super(type: LayerType.image);
}

class TextLayer extends Layer {
  TextEditingController controller;
  UndoHistoryController undoController;
  
  double fontSize;
  Color color;
  Color backgroundColor; 
  String fontFamily;
  
  TextLayer({
      required super.id, 
      required super.rect, 
      required String text,
      this.fontSize = 18.0,
      this.color = Colors.black87,
      this.backgroundColor = Colors.transparent,
      this.fontFamily = 'Quicksand',
  }) : controller = TextEditingController(text: text), 
       undoController = UndoHistoryController(),
       super(type: LayerType.text);
}

// --- Page Widget ---

class FinalizePage extends ConsumerStatefulWidget {
  final Map<String, dynamic>? storyContext;

  const FinalizePage({
    required this.pageData,
    required this.onSave,
    this.pageTitle = 'Page Editor',
    this.storyContext,
    super.key,
  });

  final Map<String, dynamic> pageData;
  final ValueChanged<Map<String, dynamic>> onSave;
  final String pageTitle;

  @override
  ConsumerState<FinalizePage> createState() => _FinalizePageState();
}

class _FinalizePageState extends ConsumerState<FinalizePage> {
  // Layers State
  final List<Layer> _layers = [];
  String? _selectedLayerId;
  bool _isGenerating = false; // Loading state fo AI
  
  // Font Options
  final List<String> _fontFamilies = ['Quicksand', 'Roboto', 'Chewy', 'Lato', 'Oswald', 'Dancing Script'];
  // BG Color Options
  final List<Color> _bgColors = [
      Colors.transparent,
      Colors.white.withValues(alpha: 0.8),
      Colors.black.withValues(alpha: 0.6),
      Colors.redAccent.withValues(alpha: 0.4),
      Colors.blueAccent.withValues(alpha: 0.4),
      Colors.yellowAccent.withValues(alpha: 0.4),
  ];
  
  @override
  void initState() {
    super.initState();
    
    // 1. Initialize Image Layer (Base AI Image)
    Uint8List? initialImageBytes;
     if (widget.pageData['imageBytes'] is Uint8List) {
        initialImageBytes = widget.pageData['imageBytes'];
    } else if (widget.pageData['image'] != null) {
        final imgData = widget.pageData['image'];
        if (imgData is String && imgData.isNotEmpty) {
            try {
                initialImageBytes = base64Decode(imgData);
            } catch (e) {
                print('Error decoding image: $e');
            }
        } else if (imgData is Uint8List) {
            initialImageBytes = imgData;
        }
    }
    
    _layers.add(ImageLayer(
        id: 'img_base', 
        rect: const Rect.fromLTWH(20, 20, 300, 300), 
        data: initialImageBytes
    ));

    // 2. Initialize Text Layer
    final textContent = widget.pageData['text'] as String? ?? '';
    
    // Check for saved styles
    double savedFontSize = 18.0;
    Color savedBg = Colors.transparent;
    String savedFont = 'Quicksand';
    
     if (widget.pageData['style'] != null) {
        final style = widget.pageData['style'] as Map;
        if (style['fontSize'] != null) savedFontSize = style['fontSize'];
        if (style['backgroundColor'] != null) {
            savedBg = Color(style['backgroundColor']);
        } else if (style['isTransparent'] != null) {
            savedBg = style['isTransparent'] == true ? Colors.transparent : Colors.white.withValues(alpha: 0.8);
        }
        if (style['fontFamily'] != null) savedFont = style['fontFamily'];
    }

    _layers.add(TextLayer(
        id: 'txt_main',
        rect: const Rect.fromLTWH(20, 340, 300, 150),
        text: textContent,
        fontSize: savedFontSize,
        backgroundColor: savedBg,
        fontFamily: savedFont,
    ));
  }
  
  TextStyle _getFontStyle(String family, double size, Color color) {
      switch (family) {
          case 'Roboto': return GoogleFonts.roboto(fontSize: size, color: color, fontWeight: FontWeight.normal);
          case 'Chewy': return GoogleFonts.chewy(fontSize: size, color: color);
          case 'Lato': return GoogleFonts.lato(fontSize: size, color: color);
          case 'Oswald': return GoogleFonts.oswald(fontSize: size, color: color);
          case 'Dancing Script': return GoogleFonts.dancingScript(fontSize: size, color: color);
          default: return GoogleFonts.quicksand(fontSize: size, color: color, fontWeight: FontWeight.w600);
      }
  }

  // --- Actions ---

  Future<void> _addImage() async {
    try {
      Uint8List? bytes;

      if (kIsWeb) {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.image,
          allowMultiple: false,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          bytes = result.files.first.bytes;
        }
      } else {
        final picker = ImagePicker();
        final XFile? image = await picker.pickImage(source: ImageSource.gallery);
        if (image != null) {
          bytes = await image.readAsBytes();
        }
      }

      if (bytes != null) {
        setState(() {
          final newId = 'img_${DateTime.now().millisecondsSinceEpoch}';
          _layers.add(ImageLayer(
            id: newId,
            rect: const Rect.fromLTWH(50, 50, 200, 200),
            data: bytes,
          ));
          _selectedLayerId = newId;
        });
      }
    } catch (e) {
      debugPrint('Image Picker Error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load image: $e')),
        );
      }
    }
  }



  void _deleteLayer(String id) {
      if (id == 'img_base') return; 
      setState(() {
          _layers.removeWhere((l) => l.id == id);
          if (_selectedLayerId == id) _selectedLayerId = null;
      });
  }
  
  // Cycle Layer Order (Front/Back)
  void _cycleLayerOrder(Layer layer) {
      if (_layers.length <= 1) return;
      
      setState(() {
          final int index = _layers.indexOf(layer);
          _layers.removeAt(index);
          
          if (index == _layers.length) { // was at end
              _layers.insert(0, layer);
          } else {
              _layers.add(layer);
          }
      });
  }

  // Cycle Background Color (Bottom Left Handle)
  void _cycleBackgroundColor(TextLayer layer) {
      setState(() {
          final currentIndex = _bgColors.indexOf(layer.backgroundColor);
          int nextIndex = 0;
          if (currentIndex != -1) {
              nextIndex = (currentIndex + 1) % _bgColors.length;
          }
          layer.backgroundColor = _bgColors[nextIndex];
      });
  }
  
  // Undo Edit (Top Right Handle)
  void _undoEdit(TextLayer layer) {
     if (layer.undoController.value.canUndo) {
         layer.undoController.undo();
     } else {
         ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nothing to undo'), duration: Duration(seconds: 1)));
     }
  }
  
  // --- AI Generation (Magic Wand) ---
  Future<void> _generateAIImage(ImageLayer layer) async {
      if (_isGenerating) return;

      // 1. Get Text Prompt from main Text Layer
      final TextLayer? textLayer = _layers.firstWhere((l) => l is TextLayer, orElse: () => _layers.last) as TextLayer?;
      final prompt = textLayer?.controller.text.trim();
      
      if (prompt == null || prompt.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify the text box has content to generate an image.')));
          return;
      }
      
      setState(() => _isGenerating = true);
      
      try {
          // 2. Call Stability Service
          final stability = ref.read(stabilityServiceProvider);
          // Get user selected model from settings
          final modelId = await ref.read(stabilityModelProvider.future);
          
          // [NEW] Build Context-Aware Prompt
          String fullPrompt = "Children's storybook illustration. $prompt.";
          
          int? seed;
          if (widget.storyContext != null) {
              final ctx = widget.storyContext!;
              final vibe = ctx['vibe'] as String? ?? 'Magical';
              final castList = (ctx['cast'] as List?)?.cast<Map<String, dynamic>>() ?? [];
              
              // Add Vibe
              fullPrompt += " Style: $vibe watercolor, colorful, highly detailed.";
              
              // Add Cast details if any
              if (castList.isNotEmpty) {
                  final characters = castList.map((c) => "${c['name']} (${c['description']})").join(', ');
                  fullPrompt += " Featuring: $characters.";
              }
              
              // Use Story Seed Key
              seed = ctx['seed'] as int?;
          } else {
             fullPrompt += " Style: Watercolor, colorful.";
          }
          
          // [NEW] Apply User's Sensitivity Level (Creativity)
          // Sensitivity Level stored as 'Creativity Level' (0.0 - 1.0)
          // 0.0 = Low Creativity (High Sensitivity/Consistency) -> CFG 30
          // 1.0 = High Creativity (Low Sensitivity/Consistency) -> CFG 5
          // Default 0.35 -> CFG ~15-20
          
          final creativityLevel = await ref.read(creativityProvider.future);
          
          // Map 0.0-1.0 to CFG 30.0-5.0
          final cfgScale = 30.0 - (creativityLevel * 25.0); 

          print('DEBUG: Magic Wand Prompt: $fullPrompt, Seed: $seed, CFG: $cfgScale');

          final base64Image = await stability.generateImage(
              prompt: fullPrompt, 
              modelId: modelId,
              seed: seed,
              stylePreset: 'digital-art',
              cfgScale: cfgScale, 
          ); 
          
          if (!mounted) return;

          if (base64Image != null) {
               final bytes = base64Decode(base64Image);
               setState(() {
                   layer.data = bytes;
               });
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image generated successfully!')));
          } else {
               ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate image. Please try again.')));
          }
      } catch (e) {
          if (mounted) {
             ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
          }
      } finally {
          setState(() => _isGenerating = false);
      }
  }

  Future<void> _saveData() async {
    // Robustly find layers or defaults
    String textContent = '';
    TextStyle textStyle = GoogleFonts.quicksand();
    Color bgColor = Colors.transparent;
    
    try {
        final textLayer = _layers.firstWhere((l) => l is TextLayer) as TextLayer;
        textContent = textLayer.controller.text;
        textStyle = _getFontStyle(textLayer.fontFamily, textLayer.fontSize, textLayer.color);
        bgColor = textLayer.backgroundColor;
    } catch (e) {
        // No text layer found, use defaults
    }

    Uint8List? imageBytes;
    try {
        final imgLayer = _layers.firstWhere((l) => l is ImageLayer && (l).data != null) as ImageLayer;
        imageBytes = imgLayer.data;
    } catch (e) {
        // No image layer found
    }

    final updatedPage = Map<String, dynamic>.from(widget.pageData);
    updatedPage['text'] = textContent;
    updatedPage['imageBytes'] = imageBytes; 
    updatedPage['style'] = {
        'fontSize': textStyle.fontSize ?? 18.0,
        'backgroundColor': bgColor.toARGB32(),
        'fontFamily': textStyle.fontFamily ?? 'Quicksand',
        'color': textStyle.color?.toARGB32() ?? Colors.black87.toARGB32()
    };
    
    widget.onSave(updatedPage);
  }

  Future<void> _handleSave() async {
      await _saveData();
      if (mounted) Navigator.pop(context);
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    Layer? selectedLayer;
    if (_selectedLayerId != null) {
        try {
            selectedLayer = _layers.firstWhere((l) => l.id == _selectedLayerId);
        } catch (e) {
            _selectedLayerId = null;
        }
    }

    return PopScope(
      canPop: true, // Allow pop, but hook into it
      onPopInvokedWithResult: (didPop, result) {
         if (didPop) {
             // If the system popped the route (Back button, Gesture), we save.
             _saveData();
         }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF1A1A2E), 
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            // Custom back button to ensure explicit save + pop behavior if needed, 
            // though PopScope covers system back. 
            // We'll leave default behavior which triggers PopScope.
            onPressed: () => Navigator.maybePop(context), 
          ),
          iconTheme: const IconThemeData(color: Color(0xFF9FA0CE)),
          title: Text(widget.pageTitle, style: GoogleFonts.chewy(color: const Color(0xFF9FA0CE), fontSize: 24)),
          actions: [
              IconButton(icon: const Icon(Icons.check), onPressed: _handleSave),
          ],
        ),
        body: Stack( // Wrap body in Stack to show Loading Overlay
          children: [
              Column(
                  children: [
                      _buildToolbar(selectedLayer),
          
                      Expanded(
                          child: Center(
                              child: Container(
                                  constraints: const BoxConstraints(maxWidth: 600),
                                  padding: const EdgeInsets.all(4), 
                                  child: AspectRatio(
                                      aspectRatio: 9 / 16, // Taller aspect ratio for mobile 
                                      child: LayoutBuilder(
                                          builder: (context, constraints) {
                                              final canvasSize = Size(constraints.maxWidth, constraints.maxHeight);
                                              return GestureDetector(
                                                  onTap: () => setState(() => _selectedLayerId = null),
                                                  child: Container(
                                                      decoration: BoxDecoration(
                                                          color: Colors.white,
                                                          borderRadius: BorderRadius.circular(8),
                                                          boxShadow: const [BoxShadow(blurRadius: 10, color: Colors.black26)],
                                                      ),
                                                      clipBehavior: Clip.hardEdge,
                                                      child: Stack(
                                                          children: [
                                                              ..._layers.map((layer) => _buildLayer(layer, canvasSize)),
                                                              
                                                              // Metadata
                                                              Positioned(
                                                                  bottom: 8, left: 8,
                                                                  child: Text(
                                                                      '© ${DateTime.now().year} Tellulu', 
                                                                      style: GoogleFonts.quicksand(fontSize: 10, color: Colors.grey[600])
                                                                  ),
                                                              ),
                                                              
                                                              Positioned(
                                                                  bottom: 8, right: 8,
                                                                  child: Text(
                                                                      widget.pageTitle.replaceAll(RegExp(r'[^0-9]'), '') == '' 
                                                                          ? 'Page 1' 
                                                                          : 'Page ${widget.pageTitle.replaceAll(RegExp(r'[^0-9]'), '')}',
                                                                      style: GoogleFonts.quicksand(fontSize: 10, color: Colors.grey[600])
                                                                  ),
                                                              ),
                                                          ],
                                                      ),
                                                  ),
                                              );
                                          }
                                      ),
                                  ),
                              ),
                          ),
                      ),
                  ],
              ),
              
              // Loading Overlay
              if (_isGenerating)
                  Container(
                      color: Colors.black54,
                      child: const Center(
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                  CircularProgressIndicator(color: Colors.purpleAccent),
                                  SizedBox(height: 16),
                                  Text('Weaving magic...', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                              ],
                          ),
                      ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildLayer(Layer layer, Size canvasSize) {
      if (layer is ImageLayer) {
          return DraggableResizable(
              key: ValueKey(layer.id),
              rect: layer.rect,
              constraints: BoxConstraints.loose(canvasSize),
              isSelected: layer.id == _selectedLayerId,
              onUpdate: (r) => setState(() => layer.rect = r),
              // Image Top-Right: Magic Wand (Generate) instead of Delete
              // Delete is available in toolbar
              onDelete: () => _generateAIImage(layer), 
              deleteIcon: Icons.auto_fix_high, // Magic Wand Icon
              // Layer Order Handle (Bottom Left)
              onLayerAction: () => _cycleLayerOrder(layer),
              actionIcon: Icons.layers, 
              child: GestureDetector(
                  onTap: () => setState(() => _selectedLayerId = layer.id),
                  child: Stack(
                      children: [
                          Container(
                              decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  image: layer.data != null 
                                      ? DecorationImage(image: MemoryImage(layer.data!), fit: BoxFit.cover)
                                      : null,
                              ),
                              child: layer.data == null 
                                  ? const Center(child: Icon(Icons.image, color: Colors.grey))
                                  : null,
                          ),
                          if (layer.id == 'img_base' && layer.data != null)
                             Positioned(
                                bottom: 4, right: 4,
                                child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(4)),
                                    child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                            const Icon(Icons.auto_awesome, size: 8, color: Colors.white70),
                                            const SizedBox(width: 2),
                                            Text('Gen by AI', style: GoogleFonts.roboto(fontSize: 8, color: Colors.white)),
                                        ]
                                    ),
                                ),
                             ),
                      ],
                  ),
              ),
          );
      } else if (layer is TextLayer) {
          return DraggableResizable(
              key: ValueKey(layer.id),
              rect: layer.rect,
              constraints: BoxConstraints.loose(canvasSize),
              isSelected: layer.id == _selectedLayerId,
              onUpdate: (r) => setState(() => layer.rect = r),
              // Text Box: Top-Right = Undo, Bottom-Left = BG Cycle
              onDelete: () => _undoEdit(layer),
              deleteIcon: Icons.undo, // Correct icon call
              onLayerAction: () => _cycleBackgroundColor(layer),
              actionIcon: Icons.format_color_fill, // BG Cycle Icon
              child: GestureDetector(
                  onTap: () => setState(() => _selectedLayerId = layer.id),
                  child: Container(
                      decoration: BoxDecoration(
                          color: layer.backgroundColor,
                          border: layer.id == _selectedLayerId 
                              ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.3), width: 1) 
                              : null,
                      ),
                      padding: const EdgeInsets.all(8),
                      child: IgnorePointer(
                          ignoring: layer.id != _selectedLayerId,
                          child: TextField(
                              controller: layer.controller,
                              undoController: layer.undoController, 
                              maxLines: null,
                              expands: true,
                              style: _getFontStyle(layer.fontFamily, layer.fontSize, layer.color),
                              decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  contentPadding: EdgeInsets.zero,
                              ),
                              enabled: true, 
                          ),
                      ),
                  ),
              ),
          );
      }
      return const SizedBox.shrink();
  }

  Widget _buildToolbar(Layer? selectedLayer) {
      return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          color: Colors.black26,
          height: 60,
          child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                       if (selectedLayer == null) ...[
                            _toolBtn(Icons.add_photo_alternate, 'Add Image', _addImage),
                            const SizedBox(width: 20),
                            const Text('Select an item to edit', style: TextStyle(color: Colors.grey, fontSize: 12)),
                       ],

                      if (selectedLayer is TextLayer) ...[
                          const Icon(Icons.text_fields, color: Colors.white54, size: 16),
                          
                          PopupMenuButton<String>(
                             child: Padding(
                                 padding: const EdgeInsets.symmetric(horizontal: 8),
                                 child: Text(selectedLayer.fontFamily, style: const TextStyle(color: Colors.white, fontSize: 12)),
                             ),
                             itemBuilder: (context) => _fontFamilies.map((f) => PopupMenuItem(
                                 value: f, 
                                 child: Text(f, style: GoogleFonts.getFont(f))
                             )).toList(),
                             onSelected: (val) => setState(() => selectedLayer.fontFamily = val),
                          ),
                          
                          const VerticalDivider(color: Colors.white24, indent: 12, endIndent: 12),
                          
                          _toggleBtn(Icons.remove, 'Smaller', false, (_) {
                             setState(() => selectedLayer.fontSize = (selectedLayer.fontSize - 2).clamp(10, 60));
                          }),
                          Text('${selectedLayer.fontSize.toInt()}', style: const TextStyle(color: Colors.white)),
                          _toggleBtn(Icons.add, 'Larger', false, (_) {
                             setState(() => selectedLayer.fontSize = (selectedLayer.fontSize + 2).clamp(10, 60));
                          }),
                          
                           _colorDot(selectedLayer, Colors.black87),
                           _colorDot(selectedLayer, Colors.white),
                           _colorDot(selectedLayer, const Color(0xFF1A1A2E)), 
                           _colorDot(selectedLayer, Colors.redAccent),
                      ],

                      if (selectedLayer is ImageLayer) ...[
                          const Icon(Icons.image, color: Colors.white54, size: 16),
                          const SizedBox(width: 8),
                          Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                const Text('Layer', style: TextStyle(color: Colors.white, fontSize: 14)),
                                 Text(selectedLayer.id.contains('base') ? '(Base)' : '', style: const TextStyle(color: Colors.white30, fontSize: 10)),
                              ]
                          ),
                      ],
                      
                      if (selectedLayer != null) ...[
                          const SizedBox(width: 16),
                          IconButton(
                              icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                              onPressed: () => _deleteLayer(selectedLayer.id),
                              tooltip: 'Remove Layer',
                          ),
                          IconButton(
                              icon: const Icon(Icons.close, color: Colors.white54),
                              onPressed: () => setState(() => _selectedLayerId = null),
                              tooltip: 'Deselect',
                          ),
                      ]
                  ],
              ),
          );
  }

  Widget _toolBtn(IconData icon, String tooltip, VoidCallback onTap) {
      return IconButton(icon: Icon(icon, color: Colors.white70), tooltip: tooltip, onPressed: onTap);
  }
  
  Widget _toggleBtn(IconData icon, String tooltip, bool isActive, ValueChanged<bool> onToggle) {
      return IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
          icon: Icon(icon, color: isActive ? const Color(0xFF9FA0CE) : Colors.grey, size: 20),
          tooltip: tooltip,
          onPressed: () => onToggle(!isActive),
      );
  }
  
  Widget _colorDot(TextLayer layer, Color color) {
      final isSelected = layer.color == color;
      return GestureDetector(
          onTap: () => setState(() => layer.color = color),
          child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 24, height: 24,
              decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isSelected ? Colors.yellowAccent : Colors.white, 
                      width: isSelected ? 2 : 1
                  ),
              ),
          ),
      );
  }
}
