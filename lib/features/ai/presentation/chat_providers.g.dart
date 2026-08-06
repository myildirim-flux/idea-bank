// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(ChatNotifier)
const chatProvider = ChatNotifierFamily._();

final class ChatNotifierProvider
    extends $AsyncNotifierProvider<ChatNotifier, ChatState> {
  const ChatNotifierProvider._({
    required ChatNotifierFamily super.from,
    required String? super.argument,
  }) : super(
         retry: null,
         name: r'chatProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$chatNotifierHash();

  @override
  String toString() {
    return r'chatProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ChatNotifier create() => ChatNotifier();

  @override
  bool operator ==(Object other) {
    return other is ChatNotifierProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$chatNotifierHash() => r'5cac294793f493207e9c1226c1f5f54037490dbc';

final class ChatNotifierFamily extends $Family
    with
        $ClassFamilyOverride<
          ChatNotifier,
          AsyncValue<ChatState>,
          ChatState,
          FutureOr<ChatState>,
          String?
        > {
  const ChatNotifierFamily._()
    : super(
        retry: null,
        name: r'chatProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ChatNotifierProvider call(String? noteId) =>
      ChatNotifierProvider._(argument: noteId, from: this);

  @override
  String toString() => r'chatProvider';
}

abstract class _$ChatNotifier extends $AsyncNotifier<ChatState> {
  late final _$args = ref.$arg as String?;
  String? get noteId => _$args;

  FutureOr<ChatState> build(String? noteId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<AsyncValue<ChatState>, ChatState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ChatState>, ChatState>,
              AsyncValue<ChatState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
