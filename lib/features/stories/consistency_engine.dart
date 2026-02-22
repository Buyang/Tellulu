import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoryStyle {
  StoryStyle({
    required this.name,
    required this.positivePrompt,
    required this.negativePrompt,
    this.stylePreset = 'digital-art',
    this.cfgScaleAdjustment = 0.0,
    this.iconName,
  });

  final String name;
  final String positivePrompt;
  final String negativePrompt;
  final String stylePreset;
  final double cfgScaleAdjustment;
  final String? iconName;

}

/// The Engine that enforces visual consistency rules.
class ConsistencyEngine {
  
  // Singleton
  static final ConsistencyEngine _instance = ConsistencyEngine._internal();
  factory ConsistencyEngine() => _instance;
  ConsistencyEngine._internal();
  
  // 1. Custom Vibes Cache
  final Map<String, StoryStyle> _customStyles = {};

  // Universal Negative Prompt - The "Safety Net" for anatomy AND content safety
  static const String _universalNegativePrompt = 'nsfw, nudity, violence, blood, gore, flesh, veins, meat, raw meat, scary face, screaming face, evil face, zombie, undead, monster, nightmare, grimace, disgust, scary, horror, disturbing, weapons, guns, bikini, underwear, alcohol, smoking, drugs, ugly, deformed, noisy, blurry, low contrast, text, 3d, distortion, extra limbs, extra fingers, missing fingers, missing limbs, fused fingers, too many fingers, long neck, mutated hands, poorly drawn hands, poorly drawn face, mutation, bad anatomy, bad proportions, cloned face, disfigured, gross proportions, malformed limbs, three legs, three feet, extra legs, extra feet, fused feet, missing legs, missing feet, mutated body, mutated limbs, bad feet, poor feet';

  // 2. Core Vibes (Content/Atmosphere) - Visible in "Pick a Vibe"
  final Map<String, StoryStyle> _vibes = {
    'Magical': StoryStyle(
      name: 'Magical',
      positivePrompt: 'whimsical watercolor, soft lighting, vibrant pastel colors, detailed texture, storybook illustration, cute, enchanting',
      negativePrompt: '$_universalNegativePrompt, photorealistic, dark, gritty, scary, 3d render, vector art',
      stylePreset: 'digital-art', 
    ),
    'Space': StoryStyle(
      name: 'Space',
      positivePrompt: 'bright sci-fi digital art, glowing stars, nebulae, cute futuristic technology, soft edges, vibrant colors, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, dark sci-fi, horror, gritty, rusty, industrial, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Prehistoric': StoryStyle(
      name: 'Prehistoric',
      positivePrompt: 'lush prehistoric jungle, vibrant greens, cute dinosaurs, soft sunlight, detailed foliage, watercolor style, adventure',
      negativePrompt: '$_universalNegativePrompt, modern architecture, cars, buildings, scary monsters, blood, violence, dark, gloomy, photorealistic, 3d render',
      stylePreset: 'digital-art',
    ),
    'Heroes': StoryStyle(
      name: 'Heroes',
      positivePrompt: 'epic comic book style, bold lines, dynamic poses, bright primary colors, heroic atmosphere, energetic, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, violence, blood, scary, dark, gritty, noir, sketch, rough',
      stylePreset: 'comic-book', 
    ),
    'Underwater': StoryStyle(
      name: 'Underwater',
      positivePrompt: 'vibrant underwater scene, coral reef, tropical fish, sunlight rays through water, bubbles, colorful ocean, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, dark ocean, deep sea horror, scary fish, murky water, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Pirate': StoryStyle(
      name: 'Pirate',
      positivePrompt: 'colorful pirate adventure, treasure map, wooden ship, tropical island, bright sunny ocean, fun swashbuckling, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, dark pirate, blood, violence, skulls, scary, gritty, realistic violence',
      stylePreset: 'digital-art',
    ),
    'Medieval': StoryStyle(
      name: 'Medieval',
      positivePrompt: 'colorful medieval fantasy, stone castle, rolling green hills, bright banners, friendly knights, dragons, enchanted forest, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, dark fantasy, blood, violence, war, death, scary, gritty, photorealistic',
      stylePreset: 'fantasy-art',
    ),
    'Superhero': StoryStyle(
      name: 'Superhero',
      positivePrompt: 'bright superhero comic art, dynamic action poses, bold colors, cityscape, heroic energy, cape flowing, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, violence, blood, dark, gritty, noir, villains, destruction, scary',
      stylePreset: 'comic-book',
    ),
    'Jungle': StoryStyle(
      name: 'Jungle',
      positivePrompt: 'lush tropical jungle, colorful parrots, friendly animals, dappled sunlight, giant leaves, adventure, vibrant greens, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, dark jungle, scary animals, snakes, spiders, danger, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Arctic': StoryStyle(
      name: 'Arctic',
      positivePrompt: 'sparkling arctic landscape, northern lights, cute penguins, polar bears, snow-covered mountains, icy blue sky, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, blizzard, freezing danger, harsh cold, dark, scary, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Detective': StoryStyle(
      name: 'Detective',
      positivePrompt: 'kid-friendly mystery scene, magnifying glass, clue trail, cozy town, bright detective adventure, colorful, storybook',
      negativePrompt: '$_universalNegativePrompt, noir, dark, scary, crime scene, violence, guns, blood, gritty',
      stylePreset: 'digital-art',
    ),
    'Fairy Tale': StoryStyle(
      name: 'Fairy Tale',
      positivePrompt: 'enchanted fairy tale, magical forest, castles in clouds, glowing mushrooms, sparkles, pastel colors, whimsical, dreamy, storybook',
      negativePrompt: '$_universalNegativePrompt, dark fairy tale, scary, horror, gritty, photorealistic, modern',
      stylePreset: 'digital-art',
    ),
    'Western': StoryStyle(
      name: 'Western',
      positivePrompt: 'colorful wild west, desert canyon, cacti, friendly horses, sunny ranch, cowboy adventure, warm golden light, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, guns, violence, outlaws, dark western, saloon, alcohol, gritty, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Dinosaur': StoryStyle(
      name: 'Dinosaur',
      positivePrompt: 'cute friendly dinosaurs, lush prehistoric valley, volcanos in background, bright colorful vegetation, adventure, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, scary dinosaurs, teeth, blood, violence, dark, gritty, photorealistic, Jurassic Park',
      stylePreset: 'digital-art',
    ),
    'Robot': StoryStyle(
      name: 'Robot',
      positivePrompt: 'cute robots, futuristic city, glowing circuits, friendly machines, bright neon colors, clean technology, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, terminator, scary robot, dystopia, dark, gritty, destruction, war, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Sports': StoryStyle(
      name: 'Sports',
      positivePrompt: 'bright sports field, energetic action, colorful uniforms, cheering crowd, sunny day, teamwork, vibrant, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, injury, violence, blood, aggressive, dark, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Cooking': StoryStyle(
      name: 'Cooking',
      positivePrompt: 'warm cozy kitchen, colorful ingredients, delicious food, baking fun, bright apron, steaming pots, vibrant, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, fire, danger, knives, burns, mess, dark, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Safari': StoryStyle(
      name: 'Safari',
      positivePrompt: 'sunny african savanna, friendly elephants, giraffes, zebras, golden grasslands, acacia trees, adventure, vibrant, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, hunting, danger, predators, dark, scary animals, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Camping': StoryStyle(
      name: 'Camping',
      positivePrompt: 'cozy campsite, glowing campfire, starry night sky, pine trees, tent, marshmallows, warm lantern light, nature adventure, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, bear attack, danger, dark forest, scary, lost, horror, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Winter': StoryStyle(
      name: 'Winter',
      positivePrompt: 'sparkling winter wonderland, gentle snowfall, snowman, cozy mittens, warm scarves, icicles, soft blue and white, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, blizzard, freezing, danger, harsh, dark, scary, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Beach': StoryStyle(
      name: 'Beach',
      positivePrompt: 'sunny tropical beach, turquoise water, sandcastle, palm trees, seashells, colorful beach umbrella, bright warm light, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, sharks, drowning, danger, dark ocean, storm, scary, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Halloween': StoryStyle(
      name: 'Halloween',
      positivePrompt: 'fun kid-friendly halloween, cute pumpkins, friendly ghosts, candy, costumes, purple and orange sky, trick or treat, whimsical',
      negativePrompt: '$_universalNegativePrompt, real horror, scary, blood, gore, zombies, skeletons, dark horror, terrifying, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Circus': StoryStyle(
      name: 'Circus',
      positivePrompt: 'colorful circus big top tent, juggling, acrobats, bright spotlights, red and gold stripes, confetti, fun performance, kid-friendly',
      negativePrompt: '$_universalNegativePrompt, scary clowns, creepy, dark circus, horror, fire danger, photorealistic',
      stylePreset: 'digital-art',
    ),
    'Pop-up': StoryStyle(
      name: 'Pop-up Book',
      positivePrompt: 'pop-up book, layered paper cutouts, 3d papercraft, depth of field, vibrant colors, open book page',
      negativePrompt: '$_universalNegativePrompt, flat, 2d, drawing, painting, sketch, photorealistic',
      stylePreset: 'origami', 
      cfgScaleAdjustment: 4.0,
      iconName: 'layers', // Pop-up layers
    ),
  };

  // 3. Visual Styles (Rendering) - Hidden from Vibe Picker, used by Avatar
  final Map<String, StoryStyle> _visualStyles = {
    'Comic Book': StoryStyle(
      name: 'Comic Book',
      positivePrompt: 'comic book art, bold outlines, halftone dots, cel shading, vibrant flat colors',
      negativePrompt: '$_universalNegativePrompt, photorealistic, 3d render, sketch, watercolor, messy, gradient, soft shading',
      stylePreset: 'comic-book',
      cfgScaleAdjustment: 3.0,
    ),
    'Fantasy Art': StoryStyle(
      name: 'Fantasy Art',
      positivePrompt: 'fantasy digital painting, magical glowing light, intricate details, vibrant jewel tones',
      negativePrompt: '$_universalNegativePrompt, photograph, modern, sci-fi, sketch, simple, minimalist, flat colors',
      stylePreset: 'fantasy-art',
      cfgScaleAdjustment: 2.0,
    ),
    '3D Model': StoryStyle(
      name: '3D Model',
      positivePrompt: '3d render, Pixar style, smooth plastic, soft lighting, depth of field',
      negativePrompt: '$_universalNegativePrompt, flat 2d, sketch, painting, hand drawn, rough, photorealistic',
      stylePreset: '3d-model',
      cfgScaleAdjustment: 3.0,
    ),
    'Anime': StoryStyle(
      name: 'Anime',
      positivePrompt: 'anime style, Studio Ghibli, cel shaded, expressive eyes, vibrant colors',
      negativePrompt: '$_universalNegativePrompt, 3d render, photorealistic, western cartoon, sketch, rough',
      stylePreset: 'anime',
      cfgScaleAdjustment: 3.0,
    ),
    'Line Art': StoryStyle(
      name: 'Line Art',
      positivePrompt: 'clean line art, black ink on white, thick lines, coloring book, no shading',
      negativePrompt: '$_universalNegativePrompt, color, 3d, photorealistic, painting, gradient, shading, messy',
      stylePreset: 'line-art',
      cfgScaleAdjustment: 4.0,
    ),
    'Pixel Art': StoryStyle(
      name: 'Pixel Art',
      positivePrompt: 'pixel art, 16-bit retro, visible pixels, dithering, limited palette',
      negativePrompt: '$_universalNegativePrompt, smooth, anti-aliased, vector, 3d, photorealistic, blur, high resolution',
      stylePreset: 'pixel-art',
      cfgScaleAdjustment: 5.0,
    ),
    'Cinematic': StoryStyle(
      name: 'Cinematic',
      positivePrompt: 'cinematic film still, volumetric lighting, shallow depth of field, color graded, 35mm',
      negativePrompt: '$_universalNegativePrompt, cartoon, sketch, flat colors, illustration, drawing, painting, anime, low quality, amateur',
      stylePreset: 'cinematic',
      cfgScaleAdjustment: 4.0, // Total: 11.0 - Strong cinematic enforcement
    ),
    'Photographic': StoryStyle(
      name: 'Photographic',
      positivePrompt: 'RAW photo, DSLR, sharp focus, natural lighting, film grain',
      negativePrompt: '$_universalNegativePrompt, cartoon, sketch, painting, drawing, illustration, rendering, cgi, 3d, anime, digital art, watercolor, oil painting, concept art, comic, cel shading, storybook, flat colors, vector',
      stylePreset: 'photographic',
      cfgScaleAdjustment: 5.0, // Total: 12.0 - Strong prompt adherence for realism
    ),
    'Digital Art': StoryStyle(
      name: 'Digital Art',
      positivePrompt: 'digital painting, concept art, smooth strokes, vibrant colors, highly detailed',
      negativePrompt: '$_universalNegativePrompt, photograph, 3d render, sketch, rough, pixel art',
      stylePreset: 'digital-art',
      cfgScaleAdjustment: 2.0,
    ),
    'Claymation': StoryStyle(
      name: 'Claymation',
      positivePrompt: 'claymation stop motion, plasticine, Aardman style, fingerprint texture, miniature set',
      negativePrompt: '$_universalNegativePrompt, 3d render, glossy smooth, painting, drawing, 2d, flat',
      stylePreset: 'craft-clay',
      cfgScaleAdjustment: 4.0,
    ),
    'Low Poly': StoryStyle(
      name: 'Low Poly',
      positivePrompt: 'low poly 3d, geometric triangles, minimal, pastel colors, isometric',
      negativePrompt: '$_universalNegativePrompt, high detail, smooth, photorealistic, rounded, organic, painting',
      stylePreset: 'low-poly',
      cfgScaleAdjustment: 4.0,
    ),
    'Origami': StoryStyle(
      name: 'Origami',
      positivePrompt: 'origami paper craft, folded paper, crisp geometric folds, paper texture',
      negativePrompt: '$_universalNegativePrompt, 3d render, smooth, painting, drawing, fabric, cloth',
      stylePreset: 'origami',
      cfgScaleAdjustment: 4.0,
    ),
  };

  StoryStyle? getStyle(String vibe) {
    // Normalize to Sentence Case for consistency or just check loose matches
    // But our keys are "Photographic", "Space", etc.
    // Let's iterate keys to find case-insensitive match.
    
    // 1. Check Core Vibes
    final vibeKey = _vibes.keys.firstWhere(
      (k) => k.toLowerCase() == vibe.toLowerCase(), orElse: () => ''
    );
    if (vibeKey.isNotEmpty) return _vibes[vibeKey]!;
    
    // 2. Check Visual Styles (Backward compatibility or explicit lookup)
    final visualKey = _visualStyles.keys.firstWhere(
      (k) => k.toLowerCase() == vibe.toLowerCase(), orElse: () => ''
    );
    if (visualKey.isNotEmpty) return _visualStyles[visualKey]!;

    // 3. Check Custom Vibes
    final customKey = _customStyles.keys.firstWhere(
      (k) => k.toLowerCase() == vibe.toLowerCase(), orElse: () => ''
    );
    if (customKey.isNotEmpty) return _customStyles[customKey]!;
    
    // 4. No Match - Return NULL to signal failure (No Silent Fallback)
    return null;
  }

  // --- Persistence Logic ---

  Future<void> loadCustomStyles() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString('custom_vibes_engine');
    if (jsonStr != null) {
      try {
        final Map<String, dynamic> decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
        _customStyles.clear();
        decoded.forEach((key, value) {
          final map = value as Map<String, dynamic>;
          _customStyles[key] = StoryStyle(
            name: map['name'],
            positivePrompt: map['positivePrompt'],
            negativePrompt: map['negativePrompt'],
            stylePreset: map['stylePreset'] ?? 'digital-art',
            cfgScaleAdjustment: map['cfgScaleAdjustment'] ?? 0.0,
            iconName: map['iconName'],
          );
        });
      } catch (e) {
        debugPrint('ConsistencyEngine: Error loading custom styles: $e');
      }
    }
  }

  Future<void> saveCustomStyles() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> output = {};
    _customStyles.forEach((key, style) {
      output[key] = {
        'name': style.name,
        'positivePrompt': style.positivePrompt,
        'negativePrompt': style.negativePrompt,
        'stylePreset': style.stylePreset,
        'cfgScaleAdjustment': style.cfgScaleAdjustment,
        'iconName': style.iconName,
      };
    });
    await prefs.setString('custom_vibes_engine', jsonEncode(output));
  }
  
  Future<void> registerCustomStyle(StoryStyle style) async {
    _customStyles[style.name] = style;
    await saveCustomStyles();
  }

  Future<void> removeCustomStyle(String name) async {
      _customStyles.remove(name);
      await saveCustomStyles();
  }

  /// Get list of AVAILABLE VIBES (Atmospheres) only.
  /// Does NOT return pure visual styles (like '3D Model') to keep the UI clean.
  List<String> getAvailableVibes() {
    return [..._vibes.keys, ..._customStyles.keys];
  }
}
