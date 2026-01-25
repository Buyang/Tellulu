import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/widgets/tellulu_card.dart';
import 'user_profile_page.dart';  // Ensure this import is correct

class SignUpPage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<String> geminiModelNotifier;
  final ValueNotifier<String> stabilityModelNotifier;
  final ValueNotifier<double> creativityNotifier;

  const SignUpPage({
    super.key, 
    required this.themeNotifier,
    required this.geminiModelNotifier,
    required this.stabilityModelNotifier,
    required this.creativityNotifier,
  });

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _goToUserProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => UserProfilePage(
        themeNotifier: widget.themeNotifier,
        geminiModelNotifier: widget.geminiModelNotifier,
        stabilityModelNotifier: widget.stabilityModelNotifier,
        creativityNotifier: widget.creativityNotifier,
        initialName: _nameController.text,
        initialEmail: _emailController.text,
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // whitespace cleanup: removed AppBar
      body: SafeArea(
        child: TelluluCard(
           child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Sign Up',
                style: GoogleFonts.chewy(
                  fontSize: 48,
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
              const SizedBox(height: 16),
                      // Bunny Mascot
                       SizedBox(
                        height: 150,
                        child: Image.asset(
                          'assets/images/bunny_mascot.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Form Fields
                      _buildCustomTextField(label: 'Name', controller: _nameController),
                      const SizedBox(height: 12),
                      _buildCustomTextField(label: 'Email', controller: _emailController),
                      // REMOVED Password Field
                      
                      const SizedBox(height: 24),
                      // Sign Up Button -> Goes to Profile Page
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _goToUserProfile, 
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9FA0CE),
                            foregroundColor: Colors.black87,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                              side: const BorderSide(color: Colors.black87, width: 1.5),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            'Sign Up',
                            style: GoogleFonts.chewy(
                              fontSize: 24, 
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // "Already have an account?" Text (No Link)
                      Text(
                        'Already have an account?',
                        style: GoogleFonts.quicksand(
                          fontSize: 16,
                          fontWeight: FontWeight.bold, // kept bold to match previous style
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Google Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.black87, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/google_logo_clean.png',
                                height: 36, // Reduced size
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Log In with Google',
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Apple Button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.white,
                            side: const BorderSide(color: Colors.black87, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/apple_logo.png',
                                height: 48, // Standard size
                                fit: BoxFit.contain,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Log In with Apple',
                                style: GoogleFonts.quicksand(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required String label, 
    TextEditingController? controller,
    bool obscureText = false
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF9FA0CE),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscureText,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF9FA0CE), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: const BorderSide(color: Color(0xFF9FA0CE), width: 2),
            ),
          ),
          style: GoogleFonts.quicksand(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
