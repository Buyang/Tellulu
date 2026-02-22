import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tellulu/common/widgets/tellulu_card.dart';
import 'package:tellulu/features/create/character_creation_page.dart';
import 'package:tellulu/providers/service_providers.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _offsetAnimation;
  String? _loadingMessage; // Null means not loading
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _offsetAnimation = Tween<double>(
      begin: 0.95,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    // unawaited(_initGoogleSignIn()); // Removed incompatible init
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Removed incompatible _initGoogleSignIn method



  Future<void> _handleGoogleSignIn() async {
    setState(() => _loadingMessage = "Signing in...");
    try {
      if (kIsWeb) {
        // WEB: Use Firebase Auth Popup directly
        final provider = GoogleAuthProvider();
        provider.addScope('email');
        await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
        // NATIVE: Use GoogleSignIn -> Firebase Credential
        final GoogleSignIn googleSignIn = GoogleSignIn();
        final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
        
        if (googleUser == null) return; // User canceled

        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
      
      // If we got here, we are logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
         await _saveAuthData(user.displayName ?? '', user.email ?? '');
      }
      
      if (mounted) _completeLogin();

    } catch (error) {
      print('Google Sign-In Error: $error');
      if (mounted) _showErrorDialog('Google Sign-In Error', error.toString());
      if (mounted) setState(() => _loadingMessage = null);
    }
  }

  Future<void> _handleAppleSignIn() async {
    setState(() => _loadingMessage = "Signing in...");
    try {
      if (kIsWeb) {
         final provider = OAuthProvider('apple.com');
         provider.addScope('email');
         provider.addScope('name');
         await FirebaseAuth.instance.signInWithPopup(provider);
      } else {
         // Native Apple Sign-In not yet implemented
         ScaffoldMessenger.of(context).showSnackBar(
           const SnackBar(content: Text('Apple Sign-In coming soon! Please use Google for now.')),
         );
         if (mounted) setState(() => _loadingMessage = null);
         return;  
      }
      
      // If we got here, we are logged in
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
         // Apple often hides email/name after first login, so we use what we have or fallbacks
         await _saveAuthData(user.displayName ?? 'Apple User', user.email ?? '');
      }

      if (mounted) _completeLogin();
    } catch (error) {
      print('Apple Sign-In Error: $error');
      if (mounted) _showErrorDialog('Apple Sign-In Error', error.toString());
      if (mounted) setState(() => _loadingMessage = null);
    }
  }
  
  Future<void> _saveAuthData(String name, String email) async {
    final prefs = await SharedPreferences.getInstance();
    if (name.isNotEmpty) await prefs.setString('userName', name);
    if (email.isNotEmpty) await prefs.setString('userEmail', email);
  }

  Future<void> _completeLogin() async {
    if (!mounted) return;
    
    // Cloud Sync (Background)
    // [NEW] Navigate IMMEDIATELY to Friends Page
    if (mounted) {
       Navigator.push(
         context,
         MaterialPageRoute<void>(
           builder: (context) => const CharacterCreationPage(),
         ),
       );
    }
    
    // Trigger sync in background (fire and forget)
    ref.read(storageServiceProvider).syncWithCloud(); 
  }

  void _showErrorDialog(String title, String message) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: SelectableText(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor, 
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 600;
          final titleSize = isSmallScreen ? 36.0 : 48.0;
          final subtitleSize = isSmallScreen ? 16.0 : 20.0;
          final heroHeight = isSmallScreen ? 200.0 : 250.0;
          final bodyTextSize = isSmallScreen ? 18.0 : 24.0;
                  final buttonTextSize = isSmallScreen ? 18.0 : 22.0;
          final logoSize = isSmallScreen ? 24.0 : 32.0; // Smaller logic for login
          
          return TelluluCard(
            maxWidth: isSmallScreen ? 400 : 500,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Tellulu Tales',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.chewy(
                    fontSize: titleSize,
                    fontWeight: FontWeight.normal,
                    color: const Color(0xFF9FA0CE),
                    shadows: [
                      const Shadow(offset: Offset(1.5, 1.5), color: Colors.black26),
                    ]
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Where imagination\ncomes to life',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: subtitleSize,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
                Container(
                  height: heroHeight,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: ScaleTransition(
                      scale: _offsetAnimation, // Using same variable name but it's a double animation now
                      child: Image.asset(
                        'assets/images/hero_illustration.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: isSmallScreen ? 16 : 24),
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
                  'Create personalized, dreamy stories\nthat bring your little one\'s\nimagination to life.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    color: Theme.of(context).textTheme.bodyMedium?.color,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: isSmallScreen ? 24 : 32),
                
                // Login Buttons (Replacing Start Creating)
                
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    children: [
                      if (_loadingMessage != null)
                        Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            children: [
                               const CircularProgressIndicator(color: Color(0xFF9FA0CE)),
                               const SizedBox(height: 16),
                               Text(
                                 _loadingMessage!,
                                 style: GoogleFonts.quicksand(
                                   fontSize: 16,
                                   color: const Color(0xFF9FA0CE),
                                   fontWeight: FontWeight.bold
                                 ),
                               ),
                            ],
                          ),
                        )
                      else ...[
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
                                   child: SvgPicture.asset(
                                     'assets/images/google_logo.svg',
                                     height: logoSize,
                                   ),
                                ),
                                Text(
                                  'Start with Google Login',
                                  style: GoogleFonts.chewy( 
                                    fontSize: buttonTextSize,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF9FA0CE),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        // "Or" Separator
                        Text(
                          'Or',
                          style: GoogleFonts.quicksand(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).textTheme.bodyMedium?.color,
                          ),
                        ),
                        const SizedBox(height: 12),
  
                        // Apple Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _handleAppleSignIn,
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
                                   child: SvgPicture.asset(
                                     'assets/images/apple_logo.svg',
                                     height: logoSize,
                                   ),
                                ),
                                Text(
                                  'Start with Apple Login',
                                  style: GoogleFonts.chewy( 
                                    fontSize: buttonTextSize,
                                    fontWeight: FontWeight.normal,
                                    color: const Color(0xFF9FA0CE),
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
                
                // No Footer (Already have an account? Removed)
                
                // No Footer (Already have an account? Removed)
              ],
            ),
          );
        }
      ),
    );
  }
}
