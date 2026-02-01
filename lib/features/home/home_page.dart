import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tellulu/common/widgets/tellulu_card.dart';
import 'package:tellulu/features/auth/sign_up_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // Navigation State


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, // Use theme color
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Responsive sizing logic
          final isSmallScreen = constraints.maxWidth < 600;
          final titleSize = isSmallScreen ? 36.0 : 48.0;
          final subtitleSize = isSmallScreen ? 16.0 : 20.0;
          final heroHeight = isSmallScreen ? 200.0 : 250.0;
          final bodyTextSize = isSmallScreen ? 18.0 : 24.0;
          final buttonTextSize = isSmallScreen ? 20.0 : 24.0;
          
          return TelluluCard(
            maxWidth: isSmallScreen ? 400 : 500, // Adjust card width
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Title
                Text(
                  'Tellulu Tales',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.chewy(
                    fontSize: titleSize,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF9FA0CE),
                    shadows: [
                      const Shadow(
                         offset: Offset(1.5, 1.5),
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
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                // Hero Image
                Container(
                  height: heroHeight,
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
                SizedBox(height: isSmallScreen ? 16 : 24),
                // Body Text
                Text(
                  'Turn your little one\ninto a legend.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: bodyTextSize,
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
                SizedBox(height: isSmallScreen ? 24 : 32),
                // Start Creating/Sign Up Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (context) => const SignUpPage()),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF9FA0CE),
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      'Start Creating ->',
                      style: GoogleFonts.chewy(
                        fontSize: buttonTextSize,
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
          );
        }
      ),
    );
  }
}
