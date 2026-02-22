import 'package:flutter/material.dart';

IconData getMaterialIconByName(String? name) {
  switch (name?.toLowerCase().trim()) {
    // Basic
    case 'auto_awesome': return Icons.auto_awesome;
    case 'star': return Icons.star;
    case 'favorite': return Icons.favorite;
    case 'bolt': return Icons.bolt;
    case 'key': return Icons.key;
    
    // Nature
    case 'forest': return Icons.forest;
    case 'park': return Icons.park;
    case 'landscape': return Icons.landscape;
    case 'wb_sunny': return Icons.wb_sunny;
    case 'nightlight': return Icons.nightlight_round;
    case 'water_drop': return Icons.water_drop;
    case 'local_fire_department': return Icons.local_fire_department;
    case 'cloud': return Icons.cloud;
    case 'terrain': return Icons.terrain;
    
    // Objects
    case 'chair': return Icons.chair;
    case 'bed': return Icons.bed;
    case 'lightbulb': return Icons.lightbulb;
    case 'map': return Icons.map;
    case 'camera_alt': return Icons.camera_alt;
    case 'book': return Icons.book;
    case 'menu_book': return Icons.menu_book;
    
    // Food
    case 'restaurant': return Icons.restaurant;
    case 'local_cafe': return Icons.local_cafe;
    case 'local_pizza': return Icons.local_pizza;
    case 'icecream': return Icons.icecream;
    case 'cake': return Icons.cake;
    case 'lunch_dining': return Icons.lunch_dining;
    case 'kitchen': return Icons.kitchen;
    
    // Animals/Creatures
    case 'pets': return Icons.pets;
    case 'bug_report': return Icons.bug_report;
    
    // Tech/SciFi
    case 'rocket_launch': return Icons.rocket_launch;
    case 'smart_toy': return Icons.smart_toy;
    case 'computer': return Icons.computer;
    case 'memory': return Icons.memory;
    case 'science': return Icons.science;
    case 'precision_manufacturing': return Icons.precision_manufacturing; // Robot arm?
    
    // Fantasy/vibes
    case 'castle': return Icons.castle;
    case 'fort': return Icons.fort; // close enough
    case 'auto_fix_high': return Icons.auto_fix_high; // Magic wand
    case 'palette': return Icons.palette;
    case 'brush': return Icons.brush;
    case 'music_note': return Icons.music_note;
    case 'headphones': return Icons.headphones;
    case 'theater_comedy': return Icons.theater_comedy;
    case 'celebration': return Icons.celebration;
    case 'sailing': return Icons.sailing;
    case 'directions_boat': return Icons.directions_boat;
    case 'waves': return Icons.waves;
    
    // Emotions/Moods
    case 'sentiment_satisfied': return Icons.sentiment_satisfied;
    case 'mood': return Icons.mood;
    case 'face': return Icons.face;
    case 'local_activity': return Icons.local_activity;
    case 'spa': return Icons.spa;
    case 'self_improvement': return Icons.self_improvement;
    
    // Action
    case 'directions_run': return Icons.directions_run;
    case 'sports_soccer': return Icons.sports_soccer;
    case 'hiking': return Icons.hiking;
    
    // Misc
    case 'home': return Icons.home;
    case 'school': return Icons.school;
    case 'business': return Icons.business;
    case 'shopping_bag': return Icons.shopping_bag;
    
    // Mapping commonly matched words to likely icons if Gemini guesses specific names
    case 'tree': return Icons.forest;
    case 'fire': return Icons.local_fire_department;
    case 'water': return Icons.water_drop;
    case 'magic': return Icons.auto_fix_high;
    case 'robot': return Icons.smart_toy;
    case 'space': return Icons.rocket_launch;
    case 'pizza': return Icons.local_pizza;
    case 'food': return Icons.restaurant;
    
    default: return Icons.auto_awesome;
  }
}
