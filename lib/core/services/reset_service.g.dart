// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reset_service.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(resetService)
const resetServiceProvider = ResetServiceProvider._();

final class ResetServiceProvider
    extends $FunctionalProvider<ResetService, ResetService, ResetService>
    with $Provider<ResetService> {
  const ResetServiceProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'resetServiceProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$resetServiceHash();

  @$internal
  @override
  $ProviderElement<ResetService> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ResetService create(Ref ref) {
    return resetService(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ResetService value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ResetService>(value),
    );
  }
}

String _$resetServiceHash() => r'7fff122263e71d274f2cd34873706d62de65a543';
