import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tellulu/common/widgets/tellulu_card.dart';
import 'package:tellulu/features/auth/user_profile_page.dart';  // Ensure this import is correct

class SignUpPage extends StatefulWidget {

  const SignUpPage({super.key});

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
      MaterialPageRoute<void>(builder: (context) => UserProfilePage(
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
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            final isShortScreen = constraints.maxHeight < 800; // Check for shorter screens
            
            // Dynamic sizing
            final titleSize = isSmallScreen ? 36.0 : 48.0;
            final mascotHeight = isShortScreen ? 100.0 : (isSmallScreen ? 120.0 : 150.0);
            final labelSize = isSmallScreen ? 14.0 : 16.0;
            final buttonTextSize = isSmallScreen ? 20.0 : 24.0;
            final verticalSpacing = isShortScreen ? 12.0 : 24.0;
            final logoSize = isSmallScreen ? 28.0 : 36.0;
            final socialButtonTextSize = isSmallScreen ? 16.0 : 18.0;

            return TelluluCard(
             maxWidth: isSmallScreen ? 400 : 500,
             child: SingleChildScrollView( // Ensure scrollability on very small screens
               child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Sign Up',
                    style: GoogleFonts.chewy(
                      fontSize: titleSize,
                      color: const Color(0xFF9FA0CE),
                       shadows: [
                        const Shadow(
                           offset: Offset(1.5, 1.5),
                           color: Colors.black26,
                        ),
                      ]
                    ),
                  ),
                  SizedBox(height: isShortScreen ? 8 : 16),
                          // Bunny Mascot
                           SizedBox(
                            height: mascotHeight,
                            child: Image.asset(
                              'assets/images/bunny_mascot.png',
                              fit: BoxFit.contain,
                            ),
                          ),
                          SizedBox(height: verticalSpacing),
                          // Form Fields
                          _buildCustomTextField(label: 'Name', controller: _nameController, labelSize: labelSize),
                          const SizedBox(height: 12),
                          _buildCustomTextField(label: 'Email', controller: _emailController, labelSize: labelSize),
                          
                          SizedBox(height: verticalSpacing),
                          // Sign Up Button -> Goes to Profile Page
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _goToUserProfile, 
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF9FA0CE),
                                foregroundColor: Colors.black87,
                                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                  side: const BorderSide(color: Colors.black87, width: 1.5),
                                ),
                                elevation: 0,
                              ),
                              child: Text(
                                'Sign Up',
                                style: GoogleFonts.chewy(
                                  fontSize: buttonTextSize, 
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
                              fontSize: isSmallScreen ? 14 : 16,
                              fontWeight: FontWeight.bold, // kept bold to match previous style
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Google Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () {},
                              style: OutlinedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16, horizontal: 24),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.black87, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Image.asset(
                                      'assets/images/google_logo_clean.png',
                                      height: logoSize, 
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Text(
                                    'Login with Google',
                                    style: GoogleFonts.quicksand(
                                      fontSize: socialButtonTextSize,
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
                                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16, horizontal: 24),
                                backgroundColor: Colors.white,
                                side: const BorderSide(color: Colors.black87, width: 1.5),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Align(
                                    alignment: Alignment.centerLeft,
                                    child: Image.asset(
                                      'assets/images/apple_logo.png',
                                      height: logoSize, // Same size as Google
                                      fit: BoxFit.contain,
                                    ),
                                  ),
                                  Text(
                                    'Login with Apple',
                                    style: GoogleFonts.quicksand(
                                      fontSize: socialButtonTextSize,
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
            );
          }
        ),
      ),
    );
  }

  Widget _buildCustomTextField({
    required String label, 
    TextEditingController? controller,
    bool obscureText = false,
    double labelSize = 16.0,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.quicksand(
            fontSize: labelSize,
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
