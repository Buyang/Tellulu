import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'settings_providers.g.dart';

// -- Persistence Layer --

@Riverpod(keepAlive: true)
Future<SharedPreferences> sharedPreferences(Ref ref) {
  return SharedPreferences.getInstance();
}

// -- Data Models --

enum UserSubscription { free, pro }

// -- Feature Providers --

@riverpod
class UserSubscriptionNotifier extends _$UserSubscriptionNotifier {
  @override
  Future<UserSubscription> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final isPro = prefs.getBool('isPro') ?? false;
    return isPro ? UserSubscription.pro : UserSubscription.free;
  }

  Future<void> toggleSubscription() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final current = state.value ?? UserSubscription.free;
    final next = current == UserSubscription.free ? UserSubscription.pro : UserSubscription.free;
    
    state = AsyncData(next);
    await prefs.setBool('isPro', next == UserSubscription.pro);
  }
}

@riverpod
class ThemeModeNotifier extends _$ThemeModeNotifier {
  @override
  Future<ThemeMode> build() async {
    final prefs = await ref.watch(sharedPreferencesProvider.future);
    final isDark = prefs.getBool('isDarkMode') ?? false;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> toggle() async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    final current = state.value ?? ThemeMode.light;
    final next = current == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    
    // Optimistic update
    state = AsyncData(next);
    await prefs.setBool('isDarkMode', next == ThemeMode.dark);
  }
}

@riverpod
class GeminiModelNotifier extends _$GeminiModelNotifier {
  @override
  Future<String> build() async {
     final prefs = await ref.watch(sharedPreferencesProvider.future);
     final subscription = await ref.watch(userSubscriptionProvider.future);
     
     final model = prefs.getString('geminiModel') ?? 'gemini-2.0-flash';

     // Enforce Free Tier restrictions
     if (subscription == UserSubscription.free && model != 'gemini-2.0-flash') {
         // Silently downgrade if they are on Free but have a Pro model selected
         return 'gemini-2.0-flash';
     }
     return model;
  }

  Future<void> setModel(String model) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = AsyncData(model);
    await prefs.setString('geminiModel', model);
  }
}

@riverpod
class StabilityModelNotifier extends _$StabilityModelNotifier {
   @override
  Future<String> build() async {
     final prefs = await ref.watch(sharedPreferencesProvider.future);
     final subscription = await ref.watch(userSubscriptionProvider.future);
     
     final model = prefs.getString('stabilityModel') ?? 'stable-diffusion-xl-1024-v1-0';
     
     // Enforce Free Tier restrictions
     if (subscription == UserSubscription.free && model != 'stable-diffusion-xl-1024-v1-0') {
         return 'stable-diffusion-xl-1024-v1-0';
     }
     return model;
  }

  Future<void> setModel(String model) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = AsyncData(model);
    await prefs.setString('stabilityModel', model);
  }
}

@riverpod
class CreativityNotifier extends _$CreativityNotifier {
   @override
  Future<double> build() async {
     final prefs = await ref.watch(sharedPreferencesProvider.future);
     return prefs.getDouble('creativityLevel') ?? 0.35;
  }

  Future<void> setLevel(double level) async {
    final prefs = await ref.read(sharedPreferencesProvider.future);
    state = AsyncData(level);
    await prefs.setDouble('creativityLevel', level);
  }
}
