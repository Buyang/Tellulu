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

String _$geminiServiceHash() => r'2ddc7a773f54f197b72e9d012cde990079a6208c';

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

String _$stabilityServiceHash() => r'996e98ef5445516a0ab2fd65175950d35decb37c';

@ProviderFor(storageService)
final storageServiceProvider = StorageServiceProvider._();

final class StorageServiceProvider
    extends $FunctionalProvider<StorageService, StorageService, StorageService>
    with $Provider<StorageService> {
  StorageServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'storageServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$storageServiceHash();

  @$internal
  @override
  $ProviderElement<StorageService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  StorageService create(Ref ref) {
    return storageService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(StorageService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<StorageService>(value),
    );
  }
}

String _$storageServiceHash() => r'62cbe9319bc400f2f78b16bce45d667585b592a2';
