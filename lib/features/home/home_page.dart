import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../auth/sign_up_page.dart';
import '../../common/widgets/tellulu_card.dart';

import '../create/character_creation_page.dart';  // Ensure this import exists or add it

class HomePage extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<String> geminiModelNotifier;
  final ValueNotifier<String> stabilityModelNotifier;
  final ValueNotifier<double> creativityNotifier;

  const HomePage({
    super.key, 
    required this.themeNotifier,
    required this.geminiModelNotifier,
    required this.stabilityModelNotifier,
    required this.creativityNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme color
      body: TelluluCard(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title
            Text(
              'Tellulu Tales',
              textAlign: TextAlign.center,
              style: GoogleFonts.chewy(
                fontSize: 48,
                fontWeight: FontWeight.normal,
                color: const Color(0xFF9FA0CE),
                shadows: [
                  const Shadow(
                     offset: Offset(1.5, 1.5),
                     blurRadius: 0,
                     color: Colors.black26,
                  ),
                ]
              ),
            ),
            const SizedBox(height: 8),
                    // Subtitle
                    Text(
                      'Where imagination\ncomes to life',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand( // Rounded sans-serif for subtitle
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Hero Image
                    Container(
                      height: 250, // Slightly taller for the illustration
                      decoration: BoxDecoration(
                        // Removed background color as the image has its own background match
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Image.asset(
                          'assets/images/hero_illustration.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    // Body Text
                    Text(
                      'Turn your little one\ninto a legend.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Create personalized, dreamy stories,\nto make them eewt the toles, and\nhawilly experiences.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.quicksand(
                        fontSize: 14,
                        color: Theme.of(context).textTheme.bodyMedium?.color,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Start Creating/Sign Up Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => SignUpPage(
                              themeNotifier: themeNotifier,
                              geminiModelNotifier: geminiModelNotifier,
                              stabilityModelNotifier: stabilityModelNotifier,
                              creativityNotifier: creativityNotifier,
                            )),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF9FA0CE),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          'Start Creating ->',
                          style: GoogleFonts.chewy(
                            fontSize: 24,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Footer
                    TextButton(
                      onPressed: () {},
                      child: RichText(
                        text: const TextSpan(
                          text: 'Already have an account? ',
                          style: TextStyle(color: Colors.grey),
                          children: [
                            TextSpan(
                              text: 'Log In',
                              style: TextStyle(
                                decoration: TextDecoration.underline,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
