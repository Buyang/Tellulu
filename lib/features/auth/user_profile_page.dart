import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/widgets/tellulu_card.dart';
import '../create/character_creation_page.dart';

class UserProfilePage extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<String> geminiModelNotifier;
  final ValueNotifier<String> stabilityModelNotifier;
  final ValueNotifier<double> creativityNotifier;
  final String initialName;
  final String initialEmail;

  const UserProfilePage({
    super.key,
    required this.themeNotifier,
    required this.geminiModelNotifier,
    required this.stabilityModelNotifier,
    required this.creativityNotifier,
    required this.initialName,
    required this.initialEmail,
  });

  @override
  State<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends State<UserProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  void _completeSignUp() {
    // Navigate to Character Creation (or Home)
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CharacterCreationPage(
          themeNotifier: widget.themeNotifier,
          geminiModelNotifier: widget.geminiModelNotifier,
          stabilityModelNotifier: widget.stabilityModelNotifier,
          creativityNotifier: widget.creativityNotifier,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // No AppBar as requested for previous page, keeping consistence
      body: SafeArea(
        child: SingleChildScrollView(
          child: TelluluCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Profile',
                  style: GoogleFonts.chewy(
                    fontSize: 48,
                    color: const Color(0xFF9FA0CE),
                    shadows: [
                      const Shadow(
                        offset: Offset(1.5, 1.5),
                        blurRadius: 0,
                        color: Colors.black26,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Fields
                _buildCustomTextField(
                  label: 'Name', 
                  controller: _nameController,
                ),
                const SizedBox(height: 12),
                _buildCustomTextField(
                  label: 'Email', 
                  controller: _emailController,
                ),
                const SizedBox(height: 12),
                _buildCustomTextField(
                  label: 'Home Address', 
                  controller: _addressController,
                  hint: 'Enter your home address',
                ),
                const SizedBox(height: 12),
                _buildCustomTextField(
                  label: 'Mobile Number', 
                  controller: _mobileController,
                  hint: 'Enter your mobile number',
                ),
                
                const SizedBox(height: 24),
                const Divider(color: Color(0xFF9FA0CE), thickness: 1),
                const SizedBox(height: 24),
                
                Text(
                  'Complete Sign Up with:',
                  style: GoogleFonts.quicksand(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(height: 16),

                // Google Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _completeSignUp,
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
                          height: 36,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Google',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
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
                    onPressed: _completeSignUp,
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
                          height: 36, 
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Apple',
                          style: GoogleFonts.quicksand(
                            fontSize: 18,
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
      ),
    );
  }

  Widget _buildCustomTextField({
    required String label, 
    TextEditingController? controller,
    String? hint,
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
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.quicksand(color: Colors.black38),
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
