import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tellulu/features/home/home_page.dart';
import 'package:tellulu/providers/settings_providers.dart';

void main() async {
  await dotenv.load();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme provider
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Tellulu Tales',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode.value ?? ThemeMode.light,
      builder: (context, child) {
        final mediaQueryData = MediaQuery.of(context);
        final scale = mediaQueryData.textScaler.clamp(minScaleFactor: 1, maxScaleFactor: 1.2);
        return MediaQuery(
          data: mediaQueryData.copyWith(textScaler: scale),
          child: child!,
        );
      },
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF9FA0CE)),
        useMaterial3: true,
        fontFamily: 'Arial',
        scaffoldBackgroundColor: const Color(0xFFFDFCF4),
        cardColor: const Color(0xFFFDFCF4),
      ),
      darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF9FA0CE), 
            brightness: Brightness.dark
          ),
          useMaterial3: true,
          fontFamily: 'Arial',
          scaffoldBackgroundColor: const Color(0xFF1E1E2C),
          cardColor: const Color(0xFF2A2A35),
      ),
      home: const HomePage(),
    );
  }
}
