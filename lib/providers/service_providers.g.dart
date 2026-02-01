// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'service_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(geminiService)
final geminiServiceProvider = GeminiServiceProvider._();

final class GeminiServiceProvider
    extends $FunctionalProvider<GeminiService, GeminiService, GeminiService>
    with $Provider<GeminiService> {
  GeminiServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'geminiServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$geminiServiceHash();

  @$internal
  @override
  $ProviderElement<GeminiService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GeminiService create(Ref ref) {
    return geminiService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GeminiService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GeminiService>(value),
    );
  }
}

String _$geminiServiceHash() => r'ca2b4dbb22488b3725082bbfd870eb966f54f2ff';

@ProviderFor(stabilityService)
final stabilityServiceProvider = StabilityServiceProvider._();

final class StabilityServiceProvider
    extends
        $FunctionalProvider<
          StabilityService,
          StabilityService,
          StabilityService
        >
    with $Provider<StabilityService> {
  StabilityServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'stabilityServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$stabilityServiceHash();

  @$internal
  @override
  $ProviderElement<StabilityService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StabilityService create(Ref ref) {
    return stabilityService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StabilityService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StabilityService>(value),
    );
  }
}

String _$stabilityServiceHash() => r'918cfd80c70f254057bffd01d1f79e447002e4e4';
