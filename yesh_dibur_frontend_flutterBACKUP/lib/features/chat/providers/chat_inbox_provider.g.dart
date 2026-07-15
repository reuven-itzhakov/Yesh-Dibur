// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_inbox_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatInboxHash() => r'ad47ac3976bd065b8a59de5ba34b9f3760d68a9f';

/// See also [ChatInbox].
@ProviderFor(ChatInbox)
final chatInboxProvider =
    AutoDisposeAsyncNotifierProvider<
      ChatInbox,
      List<ChatConversationModel>
    >.internal(
      ChatInbox.new,
      name: r'chatInboxProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$chatInboxHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$ChatInbox = AutoDisposeAsyncNotifier<List<ChatConversationModel>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
