import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/widgets/tellulu_card.dart';

class SettingsPage extends StatelessWidget {
  final ValueNotifier<ThemeMode> themeNotifier;
  final ValueNotifier<String> geminiModelNotifier;
  final ValueNotifier<String> stabilityModelNotifier;
  final ValueNotifier<double> creativityNotifier;

  const SettingsPage({
    super.key, 
    required this.themeNotifier,
    required this.geminiModelNotifier,
    required this.stabilityModelNotifier,
    required this.creativityNotifier,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      // Removed AppBar
      body: SafeArea(
        child: Center( // Center the card on screen
          child: TelluluCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Back Button Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
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
            const SizedBox(height: 24),
            ValueListenableBuilder<ThemeMode>(
              valueListenable: themeNotifier,
              builder: (context, currentMode, child) {
                return SwitchListTile(
                  title: Text(
                    'Dark Mode',
                    style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  value: currentMode == ThemeMode.dark,
                  onChanged: (value) {
                    themeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
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
                  activeColor: const Color(0xFF9FA0CE),
                );
              },
            ),
            const SizedBox(height: 24),
            
            // Manage AI Section
            Text(
              'Manage AI',
              style: GoogleFonts.chewy(
                fontSize: 24,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            const Divider(),
            // Gemini Model Selector
            ListTile(
              title: Text('Gemini Model', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
              subtitle: Text('Text Generation', style: GoogleFonts.quicksand(fontSize: 12)),
              trailing: ValueListenableBuilder<String>(
                valueListenable: geminiModelNotifier,
                builder: (context, currentModel, _) {
                  return DropdownButton<String>(
                    value: currentModel,
                    underline: Container(), // Hide underline
                    style: GoogleFonts.quicksand(color: Theme.of(context).textTheme.bodyLarge?.color),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        geminiModelNotifier.value = newValue;
                      }
                    },
                    items: <String>[
                      'gemini-2.5-flash',
                      'gemini-2.5-pro',
                      'gemini-2.0-flash-exp', 
                      'gemini-2.0-pro-exp',
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
            // Stability Model Selector
            ListTile(
              title: Text('Stability Model', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
              subtitle: Text('Image Generation', style: GoogleFonts.quicksand(fontSize: 12)),
              trailing: ValueListenableBuilder<String>(
                valueListenable: stabilityModelNotifier,
                builder: (context, currentModel, _) {
                  return DropdownButton<String>(
                    value: currentModel,
                    underline: Container(), // Hide underline
                    style: GoogleFonts.quicksand(color: Theme.of(context).textTheme.bodyLarge?.color),
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        stabilityModelNotifier.value = newValue;
                      }
                    },
                    items: <String>[
                      'stable-diffusion-xl-1024-v1-0', 
                      'stable-diffusion-v1-6',
                      'stable-diffusion-3-sd3-medium'
                    ].map<DropdownMenuItem<String>>((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: ConstrainedBox(
                           constraints: const BoxConstraints(maxWidth: 150),
                           child: Text(value, overflow: TextOverflow.ellipsis),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),

            // Creativity / Consistency Slider
            ListTile(
              title: Text('Creativity Level', style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
              subtitle: Text('Consistency vs. Imagination', style: GoogleFonts.quicksand(fontSize: 12)),
            ),
            ValueListenableBuilder<double>(
              valueListenable: creativityNotifier,
              builder: (context, value, _) {
                return Column(
                  children: [
                    Slider(
                      value: value,
                      min: 0.1,
                      max: 0.9,
                      divisions: 8,
                      label: (value * 10).round().toString(),
                      activeColor: const Color(0xFF9FA0CE),
                      onChanged: (double newValue) {
                        creativityNotifier.value = newValue;
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Predictable', style: GoogleFonts.quicksand(fontSize: 10)),
                          Text('Wild!', style: GoogleFonts.quicksand(fontSize: 10)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
      ),
    ),
    );
  }
}
