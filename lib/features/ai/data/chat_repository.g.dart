// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatRepository)
const chatRepositoryProvider = ChatRepositoryFamily._();

final class ChatRepositoryProvider
    extends $FunctionalProvider<ChatRepository, ChatRepository, ChatRepository>
    with $Provider<ChatRepository> {
  const ChatRepositoryProvider._({
    required ChatRepositoryFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'chatRepositoryProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatRepositoryHash();

  @override
  String toString() {
    return r'chatRepositoryProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<ChatRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ChatRepository create(Ref ref) {
    final argument = this.argument as String?;
    return chatRepository(ref, noteId: argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ChatRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ChatRepository>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ChatRepositoryProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatRepositoryHash() => r'47b172a2c2b771cb73388936bbb008910331ea47';

final class ChatRepositoryFamily extends $Family
    with $FunctionalFamilyOverride<ChatRepository, String?> {
  const ChatRepositoryFamily._()
    : super(
        retry: null,
        name: r'chatRepositoryProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatRepositoryProvider call({String? noteId}) =>
      ChatRepositoryProvider._(argument: noteId, from: this);

  @override
  String toString() => r'chatRepositoryProvider';
}
