// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'note_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(noteRepository)
const noteRepositoryProvider = NoteRepositoryProvider._();

final class NoteRepositoryProvider
    extends $FunctionalProvider<NoteRepository, NoteRepository, NoteRepository>
    with $Provider<NoteRepository> {
  const NoteRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteRepositoryHash();

  @$internal
  @override
  $ProviderElement<NoteRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NoteRepository create(Ref ref) {
    return noteRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteRepository>(value),
    );
  }
}

String _$noteRepositoryHash() => r'4b96783cc93ba23e82a8011eeae8486ec7acfe08';

@ProviderFor(folderNotes)
const folderNotesProvider = FolderNotesProvider._();

final class FolderNotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Note>>,
          List<Note>,
          FutureOr<List<Note>>
        >
    with $FutureModifier<List<Note>>, $FutureProvider<List<Note>> {
  const FolderNotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'folderNotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$folderNotesHash();

  @$internal
  @override
  $FutureProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Note>> create(Ref ref) {
    return folderNotes(ref);
  }
}

String _$folderNotesHash() => r'43eedd0ab1fb4302028dc57bcfd03c4f77aa6ea3';

@ProviderFor(allNotes)
const allNotesProvider = AllNotesProvider._();

final class AllNotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Note>>,
          List<Note>,
          FutureOr<List<Note>>
        >
    with $FutureModifier<List<Note>>, $FutureProvider<List<Note>> {
  const AllNotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'allNotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$allNotesHash();

  @$internal
  @override
  $FutureProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Note>> create(Ref ref) {
    return allNotes(ref);
  }
}

String _$allNotesHash() => r'4df61c3cb641149e29b215d89d4f99d8a5f790fa';

@ProviderFor(SearchQuery)
const searchQueryProvider = SearchQueryProvider._();

final class SearchQueryProvider extends $NotifierProvider<SearchQuery, String> {
  const SearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchQueryHash();

  @$internal
  @override
  SearchQuery create() => SearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$searchQueryHash() => r'2c146927785523a0ddf51b23b777a9be4afdc092';

abstract class _$SearchQuery extends $Notifier<String> {
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

@ProviderFor(showSearchResults)
const showSearchResultsProvider = ShowSearchResultsProvider._();

final class ShowSearchResultsProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  const ShowSearchResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showSearchResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showSearchResultsHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return showSearchResults(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showSearchResultsHash() => r'a53082b766ebab67abe273aa1ef6647703a177b4';

@ProviderFor(notes)
const notesProvider = NotesProvider._();

final class NotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Note>>,
          List<Note>,
          FutureOr<List<Note>>
        >
    with $FutureModifier<List<Note>>, $FutureProvider<List<Note>> {
  const NotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notesHash();

  @$internal
  @override
  $FutureProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Note>> create(Ref ref) {
    return notes(ref);
  }
}

String _$notesHash() => r'5f979f545ab2929fc94e0ab7a4f0866b46e58dc8';

@ProviderFor(notesInFolder)
const notesInFolderProvider = NotesInFolderFamily._();

final class NotesInFolderProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Note>>,
          List<Note>,
          FutureOr<List<Note>>
        >
    with $FutureModifier<List<Note>>, $FutureProvider<List<Note>> {
  const NotesInFolderProvider._({
    required NotesInFolderFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'notesInFolderProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$notesInFolderHash();

  @override
  String toString() {
    return r'notesInFolderProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Note>> create(Ref ref) {
    final argument = this.argument as String;
    return notesInFolder(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is NotesInFolderProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$notesInFolderHash() => r'649c01d5f3a48ea7b860c898a4b286f5cb814dde';

final class NotesInFolderFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Note>>, String> {
  const NotesInFolderFamily._()
    : super(
        retry: null,
        name: r'notesInFolderProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  NotesInFolderProvider call(String folderId) =>
      NotesInFolderProvider._(argument: folderId, from: this);

  @override
  String toString() => r'notesInFolderProvider';
}

@ProviderFor(trashedNotes)
const trashedNotesProvider = TrashedNotesProvider._();

final class TrashedNotesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Note>>,
          List<Note>,
          FutureOr<List<Note>>
        >
    with $FutureModifier<List<Note>>, $FutureProvider<List<Note>> {
  const TrashedNotesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'trashedNotesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$trashedNotesHash();

  @$internal
  @override
  $FutureProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Note>> create(Ref ref) {
    return trashedNotes(ref);
  }
}

String _$trashedNotesHash() => r'e944339be3cbc09ba6314ed2fa2d78b95cfbaf1c';

@ProviderFor(NoteNotifier)
const noteProvider = NoteNotifierProvider._();

final class NoteNotifierProvider
    extends $AsyncNotifierProvider<NoteNotifier, List<Note>> {
  const NoteNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteNotifierHash();

  @$internal
  @override
  NoteNotifier create() => NoteNotifier();
}

String _$noteNotifierHash() => r'dd32366d98af5871d77bbe763426ad2ec23bb2ed';

abstract class _$NoteNotifier extends $AsyncNotifier<List<Note>> {
  FutureOr<List<Note>> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<AsyncValue<List<Note>>, List<Note>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<List<Note>>, List<Note>>,
              AsyncValue<List<Note>>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
