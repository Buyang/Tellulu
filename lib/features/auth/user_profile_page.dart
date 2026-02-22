import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:tellulu/common/widgets/tellulu_card.dart';
import 'package:tellulu/features/auth/web_auth.dart' as web_auth;
import 'package:tellulu/features/create/character_creation_page.dart';
import 'package:tellulu/providers/service_providers.dart'; // [NEW]

class UserProfilePage extends ConsumerStatefulWidget {

  const UserProfilePage({
    this.initialName = '', 
    this.initialEmail = '', 
    this.isEditMode = false,
    super.key,
  });

  final String initialName;
  final String initialEmail;
  final bool isEditMode;

  @override
  ConsumerState<UserProfilePage> createState() => _UserProfilePageState();
}

class _UserProfilePageState extends ConsumerState<UserProfilePage> {


  late TextEditingController _nameController;
  late TextEditingController _emailController;
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();

  // GoogleSignIn is now a singleton accessed via instance

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    unawaited(_loadSavedData());
    // unawaited(_initGoogleSignIn()); // Removed
  }

  Future<void> _loadSavedData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      if (_nameController.text.isEmpty) {
        _nameController.text = prefs.getString('userName') ?? '';
      }
      if (_emailController.text.isEmpty) {
        _emailController.text = prefs.getString('userEmail') ?? '';
      }
      _addressController.text = prefs.getString('userAddress') ?? '';
      _mobileController.text = prefs.getString('userMobile') ?? '';
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', _nameController.text);
    await prefs.setString('userEmail', _emailController.text);
    await prefs.setString('userAddress', _addressController.text);
    await prefs.setString('userMobile', _mobileController.text);
  }
  
  // Flag to track initialization (though GoogleSignIn tracks it internally, 
  // we want to initiate it early).
  // Removed incompatible _initGoogleSignIn method



  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignIn() async {
    print('Google Sign-In Button Pressed');
    try {
      String? name;
      String? email;

      if (kIsWeb) {
         // WEB: Use Firebase Auth Popup
         final provider = GoogleAuthProvider();
         provider.addScope('email');
         final userCredential = await FirebaseAuth.instance.signInWithPopup(provider);
         name = userCredential.user?.displayName;
         email = userCredential.user?.email;
      } else {
         // Mobile Flow with Firebase
         final GoogleSignIn googleSignIn = GoogleSignIn();
         final GoogleSignInAccount? account = await googleSignIn.signIn();
         if (account == null) return;
         
         final GoogleSignInAuthentication googleAuth = await account.authentication;
         final OAuthCredential credential = GoogleAuthProvider.credential(
           accessToken: googleAuth.accessToken,
           idToken: googleAuth.idToken,
         );
         final userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
         name = userCredential.user?.displayName;
         email = userCredential.user?.email;
      }

      if (email != null) {
        setState(() {
          _nameController.text = name ?? _nameController.text;
          _emailController.text = email!;
        });
        
        // Auto-save and proceed after successful login
        await _saveData();
        // [FIX] Force Storage Re-init to switch to user-scoped box
        if (mounted) {
           await ref.read(storageServiceProvider).init();
        }
        if (mounted) _completeSignUp();
      }

    } catch (error) {
      print('Google Sign-In Error: $error');
      if (mounted) _showErrorDialog('Google Sign-In Error', error.toString());
    }
  }

  Future<void> _handleAppleSignIn() async {
    try {
      String? name;
      String? email;

      if (kIsWeb) {
         // Use manual web implementation
         // REPLACE with your actual Service ID and Redirect URI
         final result = await web_auth.signInWithApple(
            clientId: 'com.tellulu.tellulu.service', 
            redirectUri: 'https://tellulu.web.app/__/auth/handler',
         );
         if (result != null) {
            name = result['name'];
            email = result['email'];
         } else {
            return; // Cancelled or failed
         }
      } else {
        // Mobile implementation
        final credential = await SignInWithApple.getAppleIDCredential(
          scopes: [
            AppleIDAuthorizationScopes.email,
            AppleIDAuthorizationScopes.fullName,
          ],
          webAuthenticationOptions: WebAuthenticationOptions(
            clientId: 'com.tellulu.tellulu.service',
            redirectUri: Uri.parse('https://tellulu.web.app/__/auth/handler'),
          ),
        );

        if (credential.givenName != null || credential.familyName != null) {
          name = '${credential.givenName ?? ''} ${credential.familyName ?? ''}'.trim();
        }
        email = credential.email;
      }

      if (name != null && name.isNotEmpty) {
           setState(() {
             _nameController.text = name!;
           });
      }
      
      if (email != null) {
         setState(() {
           _emailController.text = email!;
         });
      }

      unawaited(_saveData());

      if (mounted) _completeSignUp();

    } catch (error) {
      print('Apple Sign-In Error: $error');
      if (mounted) _showErrorDialog('Apple Sign-In Error', error.toString());
    }
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SelectableText(message), // Selectable so user can copy it
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }


  Future<void> _completeSignUp() async {
    // Always save before navigating
    await _saveData();

    if (!mounted) return;

    // Navigate to Character Creation (or Home)
    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (context) => const CharacterCreationPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // No AppBar as requested for previous page, keeping consistence
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isSmallScreen = constraints.maxWidth < 600;
            // Dynamic sizing
            final titleSize = isSmallScreen ? 36.0 : 48.0;
            final labelSize = isSmallScreen ? 14.0 : 16.0;
            final logoSize = isSmallScreen ? 28.0 : 36.0;
            final buttonTextSize = isSmallScreen ? 16.0 : 18.0;

            return SingleChildScrollView(
              child: TelluluCard(
                maxWidth: isSmallScreen ? 400 : 500,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isSmallScreen && widget.isEditMode ? 'Edit Profile' : 'Profile',
                      style: GoogleFonts.chewy(
                        fontSize: titleSize,
                        color: const Color(0xFF9FA0CE),
                        shadows: [
                          const Shadow(
                            offset: Offset(1.5, 1.5),
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
                      labelSize: labelSize,
                    ),
                    const SizedBox(height: 12),
                    _buildCustomTextField(
                      label: 'Email', 
                      controller: _emailController,
                      labelSize: labelSize,
                    ),
                    const SizedBox(height: 12),
                    _buildCustomTextField(
                      label: 'Home Address', 
                      controller: _addressController,
                      hint: 'Enter your home address',
                      labelSize: labelSize,
                    ),
                    const SizedBox(height: 12),
                    _buildCustomTextField(
                      label: 'Mobile Number', 
                      controller: _mobileController,
                      hint: 'Enter your mobile number',
                      labelSize: labelSize,
                    ),
                    
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF9FA0CE), thickness: 1),
                    const SizedBox(height: 24),
                    
                    const SizedBox(height: 24),
                    const Divider(color: Color(0xFF9FA0CE), thickness: 1),
                    const SizedBox(height: 24),
                    
                    if (widget.isEditMode) ...[
                       SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () async {
                            await _saveData();
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Profile Saved')),
                              );
                              Navigator.pop(context);
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF9FA0CE),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            'Save Changes',
                            style: GoogleFonts.quicksand(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF9FA0CE),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      Text(
                        'Complete Sign Up with:',
                        style: GoogleFonts.quicksand(
                          fontSize: labelSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.black54,
                        ),
                      ),
                      const SizedBox(height: 16),
  
                        // Google Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _handleGoogleSignIn,
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
                                    fontSize: buttonTextSize,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
  
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: _handleAppleSignIn,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16, horizontal: 24), // Added horiz padding
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
                                  height: logoSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              Text(
                                'Login with Apple',
                                style: GoogleFonts.quicksand(
                                  fontSize: buttonTextSize,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
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
    String? hint,
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
