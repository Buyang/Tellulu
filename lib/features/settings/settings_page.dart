import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tellulu/common/widgets/tellulu_card.dart';
import 'package:tellulu/features/auth/user_profile_page.dart';
import 'package:tellulu/features/home/home_page.dart';
import 'package:tellulu/providers/service_providers.dart';
import 'package:tellulu/providers/settings_providers.dart';

// Health Indicator Widget
class ModelHealthIndicator extends ConsumerStatefulWidget {

  const ModelHealthIndicator({
    required this.checkHealth, required this.model, super.key,
  });
  final Future<bool> Function() checkHealth;
  final String model;

  @override
  ConsumerState<ModelHealthIndicator> createState() => _ModelHealthIndicatorState();
}

class _ModelHealthIndicatorState extends ConsumerState<ModelHealthIndicator> {
  bool? _isHealthy;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _verify();
  }
  
  @override
  void didUpdateWidget(ModelHealthIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.model != widget.model) {
      _verify();
    }
  }

  Future<void> _verify() async {
    setState(() {
      _isLoading = true;
      _isHealthy = null;
    });
    final result = await widget.checkHealth();
    if (mounted) {
      setState(() {
        _isLoading = false;
        _isHealthy = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 16, height: 16, 
        child: CircularProgressIndicator(strokeWidth: 2)
      );
    }
    if (_isHealthy ?? false) {
      return const Icon(Icons.check_circle, color: Colors.green, size: 20);
    }
    if (_isHealthy == false) {
      return const Icon(Icons.error, color: Colors.red, size: 20);
    }
    return const SizedBox.shrink();
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final creativity = ref.watch(creativityProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
             final isSmallScreen = constraints.maxWidth < 600;
       
             final maxWidth = isSmallScreen ? 400.0 : 600.0;
             final sectionTitleSize = isSmallScreen ? 18.0 : 24.0;

             return Center(
              child: TelluluCard(
                maxWidth: maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back Button + Centered Title
                    Stack(
                      alignment: Alignment.center,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF9FA0CE)),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                        Text(
                          'Settings',
                          style: GoogleFonts.chewy(
                            fontSize: 28.0,
                            color: const Color(0xFF9FA0CE),
                            shadows: [
                              const Shadow(
                                offset: Offset(1.5, 1.5),
                                color: Colors.black26,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                const SizedBox(height: 16),
                
                // Profile Section
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Color(0xFFFFF9E6),
                    child: Icon(Icons.person, color: Color(0xFF9FA0CE)),
                  ),
                  title: Text(
                    'Profile',
                     style: GoogleFonts.quicksand(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                     ),
                  ),
                  subtitle: Text(
                    'Update name, email & address',
                     style: GoogleFonts.quicksand(fontSize: 12),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () {
                     // Navigate to Profile Edit Page
                     Navigator.push(
                       context,
                       MaterialPageRoute<void>(builder: (context) => const UserProfilePage(isEditMode: true)),
                     );
                  },
                ),
                const Divider(),

                // Dark Mode Switch
                SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  value: themeMode.value == ThemeMode.dark,
                  onChanged: (value) {
                    unawaited(ref.read(themeModeProvider.notifier).toggle());
                  },
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF9E6),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.black87),
                    ),
                    child: const Icon(Icons.dark_mode, color: Colors.black87),
                  ),
                  activeThumbColor: const Color(0xFF9FA0CE),
                ),
                const SizedBox(height: 24),
                
                // Manage AI Section
                Text(
                  'Manage AI',
                  style: GoogleFonts.chewy(
                    fontSize: sectionTitleSize,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Divider(),
                
                // Creativity / Consistency Slider
                ListTile(
                  title: Text('Creativity Level', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                  subtitle: Text('Consistency vs. Imagination', style: GoogleFonts.quicksand(fontSize: 12)),
                ),
                Column(
                  children: [
                    Slider(
                      value: 1.0 - (creativity.value ?? 0.35), // Invert for UI
                      min: 0.1,
                      max: 0.9,
                      divisions: 8,
                      label: ((1.0 - (creativity.value ?? 0.35)) * 10).round().toString(),
                      activeColor: const Color(0xFF9FA0CE),
                      onChanged: (double newValue) {
                         unawaited(ref.read(creativityProvider.notifier).setLevel(1.0 - newValue));
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Wild!', style: GoogleFonts.quicksand(fontSize: 10)),
                          Text('Predictable', style: GoogleFonts.quicksand(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // AI Model Selector  
                ListTile(
                  title: Text('AI Model', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                  subtitle: Text('Select text generation model', style: GoogleFonts.quicksand(fontSize: 12)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: DropdownButtonFormField<String>(
                    initialValue: ref.watch(geminiModelProvider).value ?? 'gemini-2.0-flash',
                    decoration: InputDecoration(
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      filled: true,
                      fillColor: Theme.of(context).brightness == Brightness.dark
                          ? const Color(0xFF2C2C2C)
                          : const Color(0xFFF5F5F5),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'gemini-2.0-flash', child: Text('Gemini 2.0 Flash')),
                      DropdownMenuItem(value: 'gemini-2.0-flash-exp', child: Text('Gemini 2.0 Flash (Exp)')),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        unawaited(ref.read(geminiModelProvider.notifier).setModel(value));
                      }
                    },
                  ),
                ),
                const SizedBox(height: 24),

                // HELP & SUPPORT Section
                Text(
                  'Help & Support',
                  style: GoogleFonts.chewy(
                    fontSize: sectionTitleSize,
                    color: Theme.of(context).textTheme.bodyLarge?.color,
                  ),
                ),
                const Divider(),

                // Help / Learn More
                ListTile(
                  leading: const Icon(Icons.help_outline, color: Color(0xFF9FA0CE)),
                  title: Text('Help & Info', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(context: context, builder: (c) => const _HelpDialog());
                  },
                ),

                // Recover Data (unified)
                ListTile(
                  leading: const Icon(Icons.restore, color: Color(0xFF9FA0CE)),
                  title: Text('Recover Data', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                  subtitle: Text('Restore characters or sync from cloud', style: GoogleFonts.quicksand(fontSize: 10)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    showDialog(context: context, builder: (c) => _RecoverDataDialog(ref: ref));
                  },
                ),

                // Terms of Service
                ListTile(
                  leading: const Icon(Icons.description_outlined, color: Color(0xFF9FA0CE)),
                  title: Text('Terms of Service', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                     showDialog(context: context, builder: (c) => const _TermsDialog());
                  },
                ),
                const Divider(),

                // Sign Out
                ListTile(
                  leading: const Icon(Icons.logout_outlined, color: Colors.redAccent),
                  title: Text('Sign Out', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, color: Colors.redAccent)),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.redAccent),
                  onTap: () => _showSignOutDialog(context, ref),
                ),
                const Divider(),
                
                 const SizedBox(height: 24),
    
                  // Version Info
                  Center(
                    child: Text(
                      'Version 1.2.0 · Feb 2026',
                      style: GoogleFonts.quicksand(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                 const SizedBox(height: 16),

                 // System Status (Bottom)
                 _buildServiceStatus(ref, context),
                 const SizedBox(height: 24),
              ],
            ),
          ),
        );
       }
      ),
      ),
    );
  }


  void _showSignOutDialog(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Sign Out?', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to sign out and return to the login screen?', style: GoogleFonts.quicksand()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context); // Close dialog
              await FirebaseAuth.instance.signOut();
              if (context.mounted) {
                await ref.read(storageServiceProvider).init(); // Switch to guest box
              }
              if (context.mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const HomePage()),
                  (route) => false,
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, foregroundColor: Colors.white),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceStatus(WidgetRef ref, BuildContext context) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      final cardColor = isDark ? const Color(0xFF2C2C2C) : Colors.white;
      final borderColor = isDark ? Colors.grey[800]! : const Color(0xFFE0E0E0);
      final textColor = Theme.of(context).textTheme.bodyMedium?.color;

      return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
              ]
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                   Row(
                     children: [
                       const Icon(Icons.monitor_heart_outlined, size: 16, color: Colors.grey),
                       const SizedBox(width: 8),
                       Text('System Status', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14, color: textColor)),
                     ],
                   ),
                   const Divider(height: 16),
                   // Gemini Health
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Text Engine (Gemini)', style: GoogleFonts.quicksand(fontSize: 12, color: textColor)),
                       ModelHealthIndicator(
                         model: 'gemini-2.0-flash',
                         checkHealth: () => ref.read(geminiServiceProvider).verifyModelHealth('gemini-2.0-flash'),
                       ),
                     ],
                   ),
                   const SizedBox(height: 8),
                   // Stability Health
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Image Engine (Stability)', style: GoogleFonts.quicksand(fontSize: 12, color: textColor)),
                       ModelHealthIndicator(
                         model: 'stable-diffusion-xl-1024-v1-0',
                         checkHealth: () => ref.read(stabilityServiceProvider).verifyModelHealth('stable-diffusion-xl-1024-v1-0'),
                       ),
                     ],
                   ),
                   const SizedBox(height: 8),
                   // Proxy Status
                   Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                       Text('Connection Mode', style: GoogleFonts.quicksand(fontSize: 12, color: textColor)),
                       if (ref.read(stabilityServiceProvider).isUsingProxy)
                          Row(
                            children: [
                              Text('Secure Proxy', style: GoogleFonts.quicksand(fontSize: 10, color: Colors.green, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.cloud_done, color: Colors.green, size: 14),
                            ],
                          )
                       else
                          Row(
                            children: [
                              Text('Direct API', style: GoogleFonts.quicksand(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold)),
                              const SizedBox(width: 4),
                              const Icon(Icons.link, color: Colors.blue, size: 14),
                            ],
                          ),
                     ],
                   ),
                   const SizedBox(height: 8),
                   Text('Env: ${const bool.fromEnvironment('dart.vm.product') ? 'Release' : 'Debug'}', style: GoogleFonts.sourceCodePro(fontSize: 10, color: Colors.grey)),
              ],
          ),
      );
  }
}

class _HelpDialog extends StatelessWidget {
  const _HelpDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Help & Info', style: GoogleFonts.chewy(fontSize: 24, color: const Color(0xFF9FA0CE))),
      content: SingleChildScrollView(
        child: Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             mainAxisSize: MainAxisSize.min,
             children: [
               _buildSection('AI Powered By', [
                 '• Text Generation: Google Gemini AI (gemini-2.0-flash)',
                 '• Image Generation: Stability AI SDXL (stable-diffusion-xl-1024-v1-0)',
               ]),
               const SizedBox(height: 16),
               _buildSection('Content Safety', [
                 'Our Content Safety Engine acts as a shield for your family.',
                 '• Strictly G-Rated content only.',
                 '• Filters out violence, adult themes, and scary imagery.',
                 '• Universal Negative Prompts ensure safe visual generation.',
               ]),
               const SizedBox(height: 16),
               _buildSection('Creativity Level', [
                 'Control how much freedom the AI has:',
                 '• Wild! → More artistic surprises & variation.',
                 '• Predictable → Strictly follows your prompts & keeps characters consistent.',
               ]),
               const SizedBox(height: 16),
               _buildSection('Avatar Style Mapping', [
                  'Your selected Avatar Style controls the book\'s art:',
                  '• 3D Model → Pixar/Claymation style',
                  '• Anime → Studio Ghibli inspired',
                  '• Cinematic → Dramatic lighting & 8k detail',
                  '• Claymation → Tactile Aardman-style',
                  '• Comic Book → Bold lines & halftone patterns',
                  '• Digital Art → Smooth concept art',
                  '• Fantasy Art → Magical RPG effects',
                  '• Line Art → Clean coloring book style',
                  '• Low Poly → Cute geometric 3D assets',
                  '• Origami → Folded paper texture',
                  '• Photographic → High realism',
                  '• Pixel Art → Retro 16-bit style',
               ]),
             ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Close', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }

  Widget _buildSection(String title, List<String> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 8),
        ...items.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Text(item, style: GoogleFonts.quicksand(fontSize: 14)),
        )),
      ],
    );
  }
}

class _TermsDialog extends StatelessWidget {
  const _TermsDialog();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Terms of Service', style: GoogleFonts.chewy(fontSize: 24, color: const Color(0xFF9FA0CE))),
      content: SingleChildScrollView(
         child: Column(
           mainAxisSize: MainAxisSize.min,
           crossAxisAlignment: CrossAxisAlignment.start,
           children: [
             Text(
               'Content Ownership',
               style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 16),
             ),
             const SizedBox(height: 8),
             Text(
               'You, the User, are the sole owner of all stories and characters created within Tellulu.',
               style: GoogleFonts.quicksand(fontSize: 14),
             ),
             const SizedBox(height: 16),
             Text(
               '• You own the generated text.',
               style: GoogleFonts.quicksand(fontSize: 14),
             ),
             Text(
               '• You own the generated images.',
               style: GoogleFonts.quicksand(fontSize: 14),
             ),
             Text(
               '• Tellulu does not claim ownership over your creations.',
               style: GoogleFonts.quicksand(fontSize: 14),
             ),
           ],
         ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('I Agree', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}

/// Guided Recover Data dialog.
/// Replaces the three separate Rescue/Force Sync/Inspect actions with a
/// single entry point offering clear choices with appropriate warnings.
class _RecoverDataDialog extends StatefulWidget {
  final WidgetRef ref;
  const _RecoverDataDialog({required this.ref});

  @override
  State<_RecoverDataDialog> createState() => _RecoverDataDialogState();
}

class _RecoverDataDialogState extends State<_RecoverDataDialog> {
  bool _loading = false;
  String? _report;
  String? _reportTitle;

  Future<void> _runAction(String title, Future<String> Function() action) async {
    setState(() { _loading = true; _reportTitle = title; });
    try {
      final result = await action();
      if (mounted) setState(() { _report = result; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _report = '❌ Failed: $e'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show report if available
    if (_report != null) {
      return AlertDialog(
        title: Text(_reportTitle ?? 'Report', style: GoogleFonts.chewy(fontSize: 24, color: const Color(0xFF9FA0CE))),
        content: SingleChildScrollView(
          child: Text(_report!, style: GoogleFonts.sourceCodePro(fontSize: 12)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
        ],
      );
    }

    // Show loading
    if (_loading) {
      return AlertDialog(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('$_reportTitle...', style: GoogleFonts.quicksand()),
          ],
        ),
      );
    }

    // Show menu
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.restore, color: Color(0xFF9FA0CE)),
          const SizedBox(width: 8),
          Text('Recover Data', style: GoogleFonts.chewy(fontSize: 24, color: const Color(0xFF9FA0CE))),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'What would you like to recover?',
            style: GoogleFonts.quicksand(fontSize: 14, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // Option 1: Safe character rescue
          _buildOption(
            icon: Icons.face,
            color: Colors.orangeAccent,
            title: 'My Characters',
            subtitle: 'Safely merges cloud characters into your local data. Nothing is deleted.',
            onTap: () => _runAction(
              'Character Rescue',
              () => widget.ref.read(storageServiceProvider).rescueCast(),
            ),
          ),
          const SizedBox(height: 8),

          // Option 2: Full sync with warning
          _buildOption(
            icon: Icons.cloud_sync,
            color: Colors.blue,
            title: 'All Stories & Settings',
            subtitle: 'Downloads everything from the cloud.',
            warning: 'Local changes that haven\'t synced may be replaced.',
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: Text('Are you sure?', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                  content: Text(
                    'This will replace your local stories with the cloud version. '
                    'Any edits you made offline that haven\'t been saved to the cloud will be lost.',
                    style: GoogleFonts.quicksand(),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed: () => Navigator.pop(c, true),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      child: const Text('Sync Now'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                _runAction('Cloud Sync', () => widget.ref.read(storageServiceProvider).syncWithCloud());
              }
            },
          ),
          const SizedBox(height: 8),

          // Option 3: Read-only inspection
          _buildOption(
            icon: Icons.search,
            color: Colors.purple,
            title: 'Check Cloud Status',
            subtitle: 'See what\'s stored in the cloud without changing anything.',
            onTap: () => _runAction(
              'Cloud Status',
              () => widget.ref.read(storageServiceProvider).inspectCloudData(),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
      ],
    );
  }

  Widget _buildOption({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    String? warning,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: GoogleFonts.quicksand(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: GoogleFonts.quicksand(fontSize: 11, color: Colors.grey[600])),
                    if (warning != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded, size: 12, color: Colors.amber),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(warning, style: GoogleFonts.quicksand(fontSize: 10, color: Colors.amber[700], fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }
}
