import 'dart:convert';
import 'dart:typed_data';

/// Represents text styling for a story page.
class TextStyleData {
  TextStyleData({
    this.color,
    this.fontSize = 18.0,
    this.fontFamily = 'Quicksand',
  });

  factory TextStyleData.fromJson(Map<String, dynamic> json) {
    return TextStyleData(
      color: json['color'] as int?,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 18.0,
      fontFamily: (json['fontFamily'] as String?) ?? 'Quicksand',
    );
  }

  final int? color;
  final double fontSize;
  final String fontFamily;

  Map<String, dynamic> toJson() => {
    'color': color,
    'fontSize': fontSize,
    'fontFamily': fontFamily,
  };

  TextStyleData copyWith({int? color, double? fontSize, String? fontFamily}) {
    return TextStyleData(
      color: color ?? this.color,
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
    );
  }
}

/// Represents a single page in a story.
class StoryPage {
  StoryPage({
    required this.text,
    this.visualDescription,
    this.visualSetting,
    this.visualCharacters,
    this.image,
    TextStyleData? style,
  }) : style = style ?? TextStyleData();

  factory StoryPage.fromJson(dynamic json) {
    if (json is String) {
      return StoryPage(
        text: json,
        visualDescription: json,
      );
    }
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return StoryPage(
        text: (map['text'] as String?) ?? '',
        visualDescription: map['visual_description'] as String?,
        visualSetting: map['visual_setting'] as String?,
        visualCharacters: map['visual_characters'] as String?,
        image: map['image'] as String?,
        style: map['style'] != null
            ? TextStyleData.fromJson(Map<String, dynamic>.from(map['style'] as Map))
            : null,
      );
    }
    return StoryPage(text: '');
  }

  String text;
  String? visualDescription;
  String? visualSetting;
  String? visualCharacters;
  String? image;
  TextStyleData style;

  Map<String, dynamic> toJson() => {
    'text': text,
    'visual_description': visualDescription,
    'visual_setting': visualSetting,
    'visual_characters': visualCharacters,
    'image': image,
    'style': style.toJson(),
  };
}

/// Represents a character in the cast.
class Character {
  Character({
    required this.name,
    this.role,
    this.description,
    this.style,
    this.imageBase64,
    this.originalImageBase64,
    this.forensicAnalysis,
    this.stabilityPrompt,
    this.color = 0xFFFFF9C4,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      name: (json['name'] as String?) ?? 'Unnamed',
      role: json['role'] as String?,
      description: json['description'] as String?,
      style: json['style'] as String?,
      imageBase64: json['imageBase64'] as String?,
      originalImageBase64: json['originalImageBase64'] as String?,
      forensicAnalysis: json['forensicAnalysis'] as String?,
      stabilityPrompt: json['stabilityPrompt'] as String?,
      color: _parseColor(json['color']),
    );
  }

  String name;
  String? role;
  String? description;
  String? style;
  String? imageBase64;
  String? originalImageBase64;
  String? forensicAnalysis;
  String? stabilityPrompt;
  int color;

  /// Lazily decoded image bytes from base64.
  Uint8List? get imageBytes {
    if (_imageBytes != null) return _imageBytes;
    if (imageBase64 != null) {
      try {
        _imageBytes = base64Decode(imageBase64!);
      } catch (_) {
        // Invalid base64
      }
    }
    return _imageBytes;
  }
  Uint8List? _imageBytes;

  /// Lazily decoded original image bytes.
  Uint8List? get originalImageBytes {
    if (_originalImageBytes != null) return _originalImageBytes;
    if (originalImageBase64 != null) {
      try {
        _originalImageBytes = base64Decode(originalImageBase64!);
      } catch (_) {}
    }
    return _originalImageBytes;
  }
  Uint8List? _originalImageBytes;

  /// Set image bytes and auto-encode to base64.
  set imageBytes(Uint8List? bytes) {
    _imageBytes = bytes;
    imageBase64 = bytes != null ? base64Encode(bytes) : null;
  }

  /// Set original image bytes and auto-encode to base64.
  set originalImageBytes(Uint8List? bytes) {
    _originalImageBytes = bytes;
    originalImageBase64 = bytes != null ? base64Encode(bytes) : null;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'role': role,
    'description': description,
    'style': style,
    'imageBase64': imageBase64,
    'originalImageBase64': originalImageBase64,
    'forensicAnalysis': forensicAnalysis,
    'stabilityPrompt': stabilityPrompt,
    'color': color,
  };

  Character copyWith({
    String? name, String? role, String? description, String? style,
    String? imageBase64, int? color,
  }) {
    return Character(
      name: name ?? this.name,
      role: role ?? this.role,
      description: description ?? this.description,
      style: style ?? this.style,
      imageBase64: imageBase64 ?? this.imageBase64,
      originalImageBase64: originalImageBase64 ?? this.originalImageBase64,
      forensicAnalysis: forensicAnalysis ?? this.forensicAnalysis,
      stabilityPrompt: stabilityPrompt ?? this.stabilityPrompt,
      color: color ?? this.color,
    );
  }

  static int _parseColor(dynamic value) {
    if (value is int) return value;
    if (value is String) return int.tryParse(value) ?? 0xFFFFF9C4;
    return 0xFFFFF9C4;
  }
}

/// Represents a complete story.
class Story {
  Story({
    required this.id,
    required this.title,
    this.vibe = 'Magical',
    this.seed,
    this.coverBase64,
    List<StoryPage>? pages,
    List<Character>? cast,
  })  : pages = pages ?? [],
        cast = cast ?? [];

  factory Story.fromJson(Map<String, dynamic> json) {
    final rawPages = json['pages'] as List<dynamic>? ?? [];
    final rawCast = json['cast'] as List<dynamic>? ?? [];

    return Story(
      id: (json['id'] as String?) ?? DateTime.now().millisecondsSinceEpoch.toString(),
      title: (json['title'] as String?) ?? 'Untitled',
      vibe: (json['vibe'] as String?) ?? 'Magical',
      seed: json['seed'] as int?,
      coverBase64: json['coverBase64'] as String?,
      pages: rawPages.map((p) => StoryPage.fromJson(p)).toList(),
      cast: rawCast.map((c) => Character.fromJson(Map<String, dynamic>.from(c as Map))).toList(),
    );
  }

  String id;
  String title;
  String vibe;
  int? seed;
  String? coverBase64;
  List<StoryPage> pages;
  List<Character> cast;

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'vibe': vibe,
    'seed': seed,
    'coverBase64': coverBase64,
    'pages': pages.map((p) => p.toJson()).toList(),
    'cast': cast.map((c) => c.toJson()).toList(),
  };

  Story copyWith({
    String? title, String? vibe, String? coverBase64,
    List<StoryPage>? pages, List<Character>? cast,
  }) {
    return Story(
      id: id,
      title: title ?? this.title,
      vibe: vibe ?? this.vibe,
      seed: seed,
      coverBase64: coverBase64 ?? this.coverBase64,
      pages: pages ?? this.pages,
      cast: cast ?? this.cast,
    );
  }
}
