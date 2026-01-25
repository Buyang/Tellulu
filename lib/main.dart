import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'features/home/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final ValueNotifier<ThemeMode> _themeNotifier = ValueNotifier(ThemeMode.light);
  final ValueNotifier<String> _geminiModelNotifier = ValueNotifier('gemini-2.5-flash');
  final ValueNotifier<String> _stabilityModelNotifier = ValueNotifier('stable-diffusion-xl-1024-v1-0');
  final ValueNotifier<double> _creativityNotifier = ValueNotifier(0.35); // Default image strength

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load Theme
    final isDark = prefs.getBool('isDarkMode') ?? false;
    _themeNotifier.value = isDark ? ThemeMode.dark : ThemeMode.light;
    
    // Load Gemini Model
    final geminiModel = prefs.getString('geminiModel');
    if (geminiModel != null) {
      _geminiModelNotifier.value = geminiModel;
    }
    
    // Load Stability Model
    final stabilityModel = prefs.getString('stabilityModel');
    if (stabilityModel != null) {
      _stabilityModelNotifier.value = stabilityModel;
    }

    // Load Creativity Level
    final creativity = prefs.getDouble('creativityLevel');
    if (creativity != null) {
      _creativityNotifier.value = creativity;
    }

    // Add listeners to save changes
    _themeNotifier.addListener(() {
      prefs.setBool('isDarkMode', _themeNotifier.value == ThemeMode.dark);
    });

    _geminiModelNotifier.addListener(() {
      prefs.setString('geminiModel', _geminiModelNotifier.value);
    });

    _stabilityModelNotifier.addListener(() {
      prefs.setString('stabilityModel', _stabilityModelNotifier.value);
    });

    _creativityNotifier.addListener(() {
      prefs.setDouble('creativityLevel', _creativityNotifier.value);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: _themeNotifier,
      builder: (context, currentMode, _) {
        return MaterialApp(
          title: 'Tellulu Tales',
          debugShowCheckedModeBanner: false,
          themeMode: currentMode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9FA0CE)),
            useMaterial3: true,
            fontFamily: 'Arial',
            scaffoldBackgroundColor: const Color(0xFFFDFCF4),
            cardColor: const Color(0xFFFDFCF4), // Match light background
          ),
          darkTheme: ThemeData(
             colorScheme: ColorScheme.fromSeed(
               seedColor: const Color(0xFF9FA0CE), 
               brightness: Brightness.dark
             ),
             useMaterial3: true,
             fontFamily: 'Arial',
             scaffoldBackgroundColor: const Color(0xFF1E1E2C),
             cardColor: const Color(0xFF2A2A35), // Slightly lighter for card
          ),
          home: HomePage(
            themeNotifier: _themeNotifier,
            geminiModelNotifier: _geminiModelNotifier,
            stabilityModelNotifier: _stabilityModelNotifier,
            creativityNotifier: _creativityNotifier,
          ),
        );
      },
    );
  }
}
