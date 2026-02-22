// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(sharedPreferences)
final sharedPreferencesProvider = SharedPreferencesProvider._();

final class SharedPreferencesProvider
    extends
        $FunctionalProvider<
          AsyncValue<SharedPreferences>,
          SharedPreferences,
          FutureOr<SharedPreferences>
        >
    with
        $FutureModifier<SharedPreferences>,
        $FutureProvider<SharedPreferences> {
  SharedPreferencesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sharedPreferencesProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sharedPreferencesHash();

  @$internal
  @override
  $FutureProviderElement<SharedPreferences> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<SharedPreferences> create(Ref ref) {
    return sharedPreferences(ref);
  }
}

String _$sharedPreferencesHash() => r'48e60558ea6530114ea20ea03e69b9fb339ab129';

@ProviderFor(UserSubscriptionNotifier)
final userSubscriptionProvider = UserSubscriptionNotifierProvider._();

final class UserSubscriptionNotifierProvider
    extends $AsyncNotifierProvider<UserSubscriptionNotifier, UserSubscription> {
  UserSubscriptionNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'userSubscriptionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$userSubscriptionNotifierHash();

  @$internal
  @override
  UserSubscriptionNotifier create() => UserSubscriptionNotifier();
}

String _$userSubscriptionNotifierHash() =>
    r'760981a7a23bd0f329df18e948297f909b5ef05a';

abstract class _$UserSubscriptionNotifier
    extends $AsyncNotifier<UserSubscription> {
  FutureOr<UserSubscription> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<UserSubscription>, UserSubscription>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UserSubscription>, UserSubscription>,
              AsyncValue<UserSubscription>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

final class ThemeModeNotifierProvider
    extends $AsyncNotifierProvider<ThemeModeNotifier, ThemeMode> {
  ThemeModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();
}

String _$themeModeNotifierHash() => r'e39822b9a2622fee2d96205e64aee76506cb44c9';

abstract class _$ThemeModeNotifier extends $AsyncNotifier<ThemeMode> {
  FutureOr<ThemeMode> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ThemeMode>, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ThemeMode>, ThemeMode>,
              AsyncValue<ThemeMode>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(GeminiModelNotifier)
final geminiModelProvider = GeminiModelNotifierProvider._();

final class GeminiModelNotifierProvider
    extends $AsyncNotifierProvider<GeminiModelNotifier, String> {
  GeminiModelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiModelNotifierHash();

  @$internal
  @override
  GeminiModelNotifier create() => GeminiModelNotifier();
}

String _$geminiModelNotifierHash() =>
    r'84b2f5cca6d25ab11a1ea65626d1c4e1e07d9283';

abstract class _$GeminiModelNotifier extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(StabilityModelNotifier)
final stabilityModelProvider = StabilityModelNotifierProvider._();

final class StabilityModelNotifierProvider
    extends $AsyncNotifierProvider<StabilityModelNotifier, String> {
  StabilityModelNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stabilityModelProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stabilityModelNotifierHash();

  @$internal
  @override
  StabilityModelNotifier create() => StabilityModelNotifier();
}

String _$stabilityModelNotifierHash() =>
    r'7dabdf44ec3962499abc050abbd84bd2515572e4';

abstract class _$StabilityModelNotifier extends $AsyncNotifier<String> {
  FutureOr<String> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<String>, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<String>, String>,
              AsyncValue<String>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(CreativityNotifier)
final creativityProvider = CreativityNotifierProvider._();

final class CreativityNotifierProvider
    extends $AsyncNotifierProvider<CreativityNotifier, double> {
  CreativityNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'creativityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$creativityNotifierHash();

  @$internal
  @override
  CreativityNotifier create() => CreativityNotifier();
}

String _$creativityNotifierHash() =>
    r'0731a75d8c1e8172cf8143be6f008c75a64f035c';

abstract class _$CreativityNotifier extends $AsyncNotifier<double> {
  FutureOr<double> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<AsyncValue<double>, double>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<double>, double>,
              AsyncValue<double>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
