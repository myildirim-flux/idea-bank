// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'folder_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(folderRepository)
const folderRepositoryProvider = FolderRepositoryProvider._();

final class FolderRepositoryProvider
    extends
        $FunctionalProvider<
          AsyncValue<FolderRepository>,
          FolderRepository,
          FutureOr<FolderRepository>
        >
    with $FutureModifier<FolderRepository>, $FutureProvider<FolderRepository> {
  const FolderRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderRepositoryHash();

  @$internal
  @override
  $FutureProviderElement<FolderRepository> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FolderRepository> create(Ref ref) {
    return folderRepository(ref);
  }
}

String _$folderRepositoryHash() => r'4d584d9dcbdcc615b9b1d97a56d9b3180ba5d9b6';

@ProviderFor(SelectedFolderId)
const selectedFolderIdProvider = SelectedFolderIdProvider._();

final class SelectedFolderIdProvider
    extends $NotifierProvider<SelectedFolderId, String> {
  const SelectedFolderIdProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'selectedFolderIdProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$selectedFolderIdHash();

  @$internal
  @override
  SelectedFolderId create() => SelectedFolderId();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$selectedFolderIdHash() => r'4e71279e8a593e18c382f4ebc74798eb927979fb';

abstract class _$SelectedFolderId extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(Folders)
const foldersProvider = FoldersProvider._();

final class FoldersProvider
    extends $AsyncNotifierProvider<Folders, List<Folder>> {
  const FoldersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'foldersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$foldersHash();

  @$internal
  @override
  Folders create() => Folders();
}

String _$foldersHash() => r'f1ce7e2c2e0e085a8d0b570b32167b4f21006027';

abstract class _$Folders extends $AsyncNotifier<List<Folder>> {
  FutureOr<List<Folder>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Folder>>, List<Folder>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Folder>>, List<Folder>>,
              AsyncValue<List<Folder>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
