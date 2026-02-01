import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:tellulu/common/widgets/tellulu_card.dart';
import 'package:tellulu/features/auth/user_profile_page.dart';
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
    final geminiModel = ref.watch(geminiModelProvider);
    final stabilityModel = ref.watch(stabilityModelProvider);
    final creativity = ref.watch(creativityProvider);
    
    // Watch Subscription
    final subscriptionAsync = ref.watch(userSubscriptionProvider);
    final currentSubscription = subscriptionAsync.value ?? UserSubscription.free;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
             final isSmallScreen = constraints.maxWidth < 600;
             final headerSize = isSmallScreen ? 36.0 : 48.0;
             final maxWidth = isSmallScreen ? 400.0 : 600.0;
             final sectionTitleSize = isSmallScreen ? 18.0 : 24.0;

             return Center(
              child: TelluluCard(
                maxWidth: maxWidth,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Back Button Row
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Color(0xFF9FA0CE)),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    Text(
                      'Settings',
                      style: GoogleFonts.chewy(
                        fontSize: headerSize,
                        color: const Color(0xFF9FA0CE),
                         shadows: [
                          const Shadow(
                             offset: Offset(1.5, 1.5),
                             color: Colors.black26,
                          ),
                        ]
                      ),
                    ),
                const SizedBox(height: 24),
                
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
                
                // Subscription Toggle
                SwitchListTile(
                  title: Text(
                    'Tellulu Pro',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: currentSubscription == UserSubscription.pro ? const Color(0xFF9FA0CE) : Theme.of(context).textTheme.bodyLarge?.color,
                    ),
                  ),
                  subtitle: Text(
                    currentSubscription == UserSubscription.pro ? 'Premium Models Unlocked' : 'Upgrade to unlock usage of experimental AI models',
                    style: GoogleFonts.quicksand(fontSize: 12),
                  ),
                  value: currentSubscription == UserSubscription.pro,
                  onChanged: (value) {
                    unawaited(ref.read(userSubscriptionProvider.notifier).toggleSubscription());
                  },
                  secondary: const Icon(Icons.verified, color: Colors.amber),
                  activeThumbColor: const Color(0xFF9FA0CE),
                ),
                const Divider(),

                // Gemini Model Selector
                ListTile(
                  title: Text('Gemini Model', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                  subtitle: Text('Text Generation', style: GoogleFonts.quicksand(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       if (geminiModel.value != null)
                         Padding(
                           padding: const EdgeInsets.only(right: 8),
                           child: ModelHealthIndicator(
                             model: geminiModel.value!,
                             checkHealth: () => ref.read(geminiServiceProvider).verifyModelHealth(geminiModel.value!),
                           ),
                         ),
                      DropdownButton<String>(
                        value: geminiModel.value ?? 'gemini-2.0-flash',
                        underline: Container(), // Hide underline
                        style: GoogleFonts.quicksand(color: Theme.of(context).textTheme.bodyLarge?.color),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                             unawaited(ref.read(geminiModelProvider.notifier).setModel(newValue));
                          }
                        },
                        items: _getGeminiModels(currentSubscription == UserSubscription.pro)
                          .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                // Stability Model Selector
                ListTile(
                  title: Text('Stability Model', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
                  subtitle: Text('Image Generation', style: GoogleFonts.quicksand(fontSize: 12)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                       if (stabilityModel.value != null)
                         Padding(
                           padding: const EdgeInsets.only(right: 8),
                           child: ModelHealthIndicator(
                             model: stabilityModel.value!,
                             checkHealth: () => ref.read(stabilityServiceProvider).verifyModelHealth(stabilityModel.value!),
                           ),
                         ),
                      DropdownButton<String>(
                        value: stabilityModel.value ?? 'stable-diffusion-xl-1024-v1-0',
                        underline: Container(), // Hide underline
                        style: GoogleFonts.quicksand(color: Theme.of(context).textTheme.bodyLarge?.color),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            unawaited(ref.read(stabilityModelProvider.notifier).setModel(newValue));
                          }
                        },
                        items: _getStabilityModels(currentSubscription == UserSubscription.pro)
                          .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: ConstrainedBox(
                               constraints: const BoxConstraints(maxWidth: 150),
                               child: Text(value, overflow: TextOverflow.ellipsis),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
    
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
                const SizedBox(height: 24),
                // Version Info
                 FutureBuilder<PackageInfo>(
                    future: PackageInfo.fromPlatform(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData) {
                        return Center(
                          child: Text(
                            'Version ${snapshot.data!.version}',
                            style: GoogleFonts.quicksand(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                 ),
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

  List<String> _getGeminiModels(bool isPro) {
    if (isPro) {
      return [
        'gemini-2.0-flash', // Stable
        'gemini-1.5-flash', // Legacy
      ];
    }
    return [
       'gemini-2.0-flash', // Stable
    ];
  }

  List<String> _getStabilityModels(bool isPro) {
    if (isPro) {
      return [
        'stable-diffusion-xl-1024-v1-0', 
        'stable-diffusion-v1-6',
        'stable-diffusion-3-sd3-medium'
      ];
    }
    return [
      'stable-diffusion-xl-1024-v1-0',
    ];
  }
}
