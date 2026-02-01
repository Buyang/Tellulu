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
     
     final savedModel = prefs.getString('geminiModel') ?? 'gemini-1.5-flash';
     
     // Entitlement Check
     // Force migration from 1.5 Flash (broken/404) or Exp to 2.0 Flash Stable
     if (savedModel == 'gemini-1.5-flash' || savedModel == 'gemini-2.0-flash-exp') {
       return 'gemini-2.0-flash';
     }

     if (subscription == UserSubscription.free) {
       // Free tier allowed valid model: 2.0 Flash
       if (savedModel != 'gemini-2.0-flash') {
          return 'gemini-2.0-flash';
       }
     }
     return savedModel;
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
     
     final savedModel = prefs.getString('stabilityModel') ?? 'stable-diffusion-xl-1024-v1-0';
     
     // Entitlement Check: Free tier only gets basic SDXL
     if (subscription == UserSubscription.free) {
        // Example logic: Free users can only use the default v1-0 engine, or a specific subset.
        // For simplicity, let's say 'stable-diffusion-3-sd3-medium' is Pro only.
        if (savedModel == 'stable-diffusion-3-sd3-medium') {
           return 'stable-diffusion-xl-1024-v1-0';
        }
     }
     return savedModel;
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
