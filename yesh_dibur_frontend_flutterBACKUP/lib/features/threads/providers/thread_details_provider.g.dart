// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_details_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$threadDetailsHash() => r'1c28ab80b26898a527d78eb3758ec9245f8e13cf';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [threadDetails].
@ProviderFor(threadDetails)
const threadDetailsProvider = ThreadDetailsFamily();

/// See also [threadDetails].
class ThreadDetailsFamily extends Family<AsyncValue<ThreadModel>> {
  /// See also [threadDetails].
  const ThreadDetailsFamily();

  /// See also [threadDetails].
  ThreadDetailsProvider call(String threadId) {
    return ThreadDetailsProvider(threadId);
  }

  @override
  ThreadDetailsProvider getProviderOverride(
    covariant ThreadDetailsProvider provider,
  ) {
    return call(provider.threadId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'threadDetailsProvider';
}

/// See also [threadDetails].
class ThreadDetailsProvider extends AutoDisposeFutureProvider<ThreadModel> {
  /// See also [threadDetails].
  ThreadDetailsProvider(String threadId)
    : this._internal(
        (ref) => threadDetails(ref as ThreadDetailsRef, threadId),
        from: threadDetailsProvider,
        name: r'threadDetailsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$threadDetailsHash,
        dependencies: ThreadDetailsFamily._dependencies,
        allTransitiveDependencies:
            ThreadDetailsFamily._allTransitiveDependencies,
        threadId: threadId,
      );

  ThreadDetailsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.threadId,
  }) : super.internal();

  final String threadId;

  @override
  Override overrideWith(
    FutureOr<ThreadModel> Function(ThreadDetailsRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ThreadDetailsProvider._internal(
        (ref) => create(ref as ThreadDetailsRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        threadId: threadId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ThreadModel> createElement() {
    return _ThreadDetailsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ThreadDetailsProvider && other.threadId == threadId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, threadId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ThreadDetailsRef on AutoDisposeFutureProviderRef<ThreadModel> {
  /// The parameter `threadId` of this provider.
  String get threadId;
}

class _ThreadDetailsProviderElement
    extends AutoDisposeFutureProviderElement<ThreadModel>
    with ThreadDetailsRef {
  _ThreadDetailsProviderElement(super.provider);

  @override
  String get threadId => (origin as ThreadDetailsProvider).threadId;
}

String _$commentsHash() => r'7a0d12ba5e7b012415912792afbb50f6ae572b10';

abstract class _$Comments
    extends BuildlessAutoDisposeAsyncNotifier<List<CommentModel>> {
  late final String threadId;

  FutureOr<List<CommentModel>> build(String threadId);
}

/// See also [Comments].
@ProviderFor(Comments)
const commentsProvider = CommentsFamily();

/// See also [Comments].
class CommentsFamily extends Family<AsyncValue<List<CommentModel>>> {
  /// See also [Comments].
  const CommentsFamily();

  /// See also [Comments].
  CommentsProvider call(String threadId) {
    return CommentsProvider(threadId);
  }

  @override
  CommentsProvider getProviderOverride(covariant CommentsProvider provider) {
    return call(provider.threadId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'commentsProvider';
}

/// See also [Comments].
class CommentsProvider
    extends AutoDisposeAsyncNotifierProviderImpl<Comments, List<CommentModel>> {
  /// See also [Comments].
  CommentsProvider(String threadId)
    : this._internal(
        () => Comments()..threadId = threadId,
        from: commentsProvider,
        name: r'commentsProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$commentsHash,
        dependencies: CommentsFamily._dependencies,
        allTransitiveDependencies: CommentsFamily._allTransitiveDependencies,
        threadId: threadId,
      );

  CommentsProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.threadId,
  }) : super.internal();

  final String threadId;

  @override
  FutureOr<List<CommentModel>> runNotifierBuild(covariant Comments notifier) {
    return notifier.build(threadId);
  }

  @override
  Override overrideWith(Comments Function() create) {
    return ProviderOverride(
      origin: this,
      override: CommentsProvider._internal(
        () => create()..threadId = threadId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        threadId: threadId,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<Comments, List<CommentModel>>
  createElement() {
    return _CommentsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CommentsProvider && other.threadId == threadId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, threadId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin CommentsRef on AutoDisposeAsyncNotifierProviderRef<List<CommentModel>> {
  /// The parameter `threadId` of this provider.
  String get threadId;
}

class _CommentsProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<Comments, List<CommentModel>>
    with CommentsRef {
  _CommentsProviderElement(super.provider);

  @override
  String get threadId => (origin as CommentsProvider).threadId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
