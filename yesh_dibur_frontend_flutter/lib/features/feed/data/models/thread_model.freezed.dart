// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'thread_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

ThreadModel _$ThreadModelFromJson(Map<String, dynamic> json) {
  return _ThreadModel.fromJson(json);
}

/// @nodoc
mixin _$ThreadModel {
  String get id => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_id')
  String get authorId => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_name')
  String get authorName => throw _privateConstructorUsedError;
  @JsonKey(name: 'author_image')
  String? get authorAvatar => throw _privateConstructorUsedError; // תוקן ל-author_image
  @JsonKey(name: 'group_id')
  String get groupId => throw _privateConstructorUsedError;
  @JsonKey(name: 'group_name')
  String get groupName => throw _privateConstructorUsedError; // ערך דיפולטיבי מונע קריסה
  @JsonKey(name: 'group_cover')
  String? get groupCover => throw _privateConstructorUsedError;
  String get content => throw _privateConstructorUsedError;
  @JsonKey(name: 'bg_type')
  String get bgType => throw _privateConstructorUsedError;
  @JsonKey(name: 'bg_value')
  String get bgValue => throw _privateConstructorUsedError;
  @JsonKey(name: 'likes_count')
  int get likesCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'comments_count')
  int get commentsCount => throw _privateConstructorUsedError;
  @JsonKey(name: 'is_liked')
  bool get isLikedByMe => throw _privateConstructorUsedError; // תוקן ל-is_liked
  @JsonKey(name: 'created_at')
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this ThreadModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ThreadModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ThreadModelCopyWith<ThreadModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ThreadModelCopyWith<$Res> {
  factory $ThreadModelCopyWith(
    ThreadModel value,
    $Res Function(ThreadModel) then,
  ) = _$ThreadModelCopyWithImpl<$Res, ThreadModel>;
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'author_id') String authorId,
    @JsonKey(name: 'author_name') String authorName,
    @JsonKey(name: 'author_image') String? authorAvatar,
    @JsonKey(name: 'group_id') String groupId,
    @JsonKey(name: 'group_name') String groupName,
    @JsonKey(name: 'group_cover') String? groupCover,
    String content,
    @JsonKey(name: 'bg_type') String bgType,
    @JsonKey(name: 'bg_value') String bgValue,
    @JsonKey(name: 'likes_count') int likesCount,
    @JsonKey(name: 'comments_count') int commentsCount,
    @JsonKey(name: 'is_liked') bool isLikedByMe,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class _$ThreadModelCopyWithImpl<$Res, $Val extends ThreadModel>
    implements $ThreadModelCopyWith<$Res> {
  _$ThreadModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ThreadModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? authorId = null,
    Object? authorName = null,
    Object? authorAvatar = freezed,
    Object? groupId = null,
    Object? groupName = null,
    Object? groupCover = freezed,
    Object? content = null,
    Object? bgType = null,
    Object? bgValue = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? isLikedByMe = null,
    Object? createdAt = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            authorId: null == authorId
                ? _value.authorId
                : authorId // ignore: cast_nullable_to_non_nullable
                      as String,
            authorName: null == authorName
                ? _value.authorName
                : authorName // ignore: cast_nullable_to_non_nullable
                      as String,
            authorAvatar: freezed == authorAvatar
                ? _value.authorAvatar
                : authorAvatar // ignore: cast_nullable_to_non_nullable
                      as String?,
            groupId: null == groupId
                ? _value.groupId
                : groupId // ignore: cast_nullable_to_non_nullable
                      as String,
            groupName: null == groupName
                ? _value.groupName
                : groupName // ignore: cast_nullable_to_non_nullable
                      as String,
            groupCover: freezed == groupCover
                ? _value.groupCover
                : groupCover // ignore: cast_nullable_to_non_nullable
                      as String?,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            bgType: null == bgType
                ? _value.bgType
                : bgType // ignore: cast_nullable_to_non_nullable
                      as String,
            bgValue: null == bgValue
                ? _value.bgValue
                : bgValue // ignore: cast_nullable_to_non_nullable
                      as String,
            likesCount: null == likesCount
                ? _value.likesCount
                : likesCount // ignore: cast_nullable_to_non_nullable
                      as int,
            commentsCount: null == commentsCount
                ? _value.commentsCount
                : commentsCount // ignore: cast_nullable_to_non_nullable
                      as int,
            isLikedByMe: null == isLikedByMe
                ? _value.isLikedByMe
                : isLikedByMe // ignore: cast_nullable_to_non_nullable
                      as bool,
            createdAt: null == createdAt
                ? _value.createdAt
                : createdAt // ignore: cast_nullable_to_non_nullable
                      as DateTime,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$ThreadModelImplCopyWith<$Res>
    implements $ThreadModelCopyWith<$Res> {
  factory _$$ThreadModelImplCopyWith(
    _$ThreadModelImpl value,
    $Res Function(_$ThreadModelImpl) then,
  ) = __$$ThreadModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    @JsonKey(name: 'author_id') String authorId,
    @JsonKey(name: 'author_name') String authorName,
    @JsonKey(name: 'author_image') String? authorAvatar,
    @JsonKey(name: 'group_id') String groupId,
    @JsonKey(name: 'group_name') String groupName,
    @JsonKey(name: 'group_cover') String? groupCover,
    String content,
    @JsonKey(name: 'bg_type') String bgType,
    @JsonKey(name: 'bg_value') String bgValue,
    @JsonKey(name: 'likes_count') int likesCount,
    @JsonKey(name: 'comments_count') int commentsCount,
    @JsonKey(name: 'is_liked') bool isLikedByMe,
    @JsonKey(name: 'created_at') DateTime createdAt,
  });
}

/// @nodoc
class __$$ThreadModelImplCopyWithImpl<$Res>
    extends _$ThreadModelCopyWithImpl<$Res, _$ThreadModelImpl>
    implements _$$ThreadModelImplCopyWith<$Res> {
  __$$ThreadModelImplCopyWithImpl(
    _$ThreadModelImpl _value,
    $Res Function(_$ThreadModelImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of ThreadModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? authorId = null,
    Object? authorName = null,
    Object? authorAvatar = freezed,
    Object? groupId = null,
    Object? groupName = null,
    Object? groupCover = freezed,
    Object? content = null,
    Object? bgType = null,
    Object? bgValue = null,
    Object? likesCount = null,
    Object? commentsCount = null,
    Object? isLikedByMe = null,
    Object? createdAt = null,
  }) {
    return _then(
      _$ThreadModelImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        authorId: null == authorId
            ? _value.authorId
            : authorId // ignore: cast_nullable_to_non_nullable
                  as String,
        authorName: null == authorName
            ? _value.authorName
            : authorName // ignore: cast_nullable_to_non_nullable
                  as String,
        authorAvatar: freezed == authorAvatar
            ? _value.authorAvatar
            : authorAvatar // ignore: cast_nullable_to_non_nullable
                  as String?,
        groupId: null == groupId
            ? _value.groupId
            : groupId // ignore: cast_nullable_to_non_nullable
                  as String,
        groupName: null == groupName
            ? _value.groupName
            : groupName // ignore: cast_nullable_to_non_nullable
                  as String,
        groupCover: freezed == groupCover
            ? _value.groupCover
            : groupCover // ignore: cast_nullable_to_non_nullable
                  as String?,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        bgType: null == bgType
            ? _value.bgType
            : bgType // ignore: cast_nullable_to_non_nullable
                  as String,
        bgValue: null == bgValue
            ? _value.bgValue
            : bgValue // ignore: cast_nullable_to_non_nullable
                  as String,
        likesCount: null == likesCount
            ? _value.likesCount
            : likesCount // ignore: cast_nullable_to_non_nullable
                  as int,
        commentsCount: null == commentsCount
            ? _value.commentsCount
            : commentsCount // ignore: cast_nullable_to_non_nullable
                  as int,
        isLikedByMe: null == isLikedByMe
            ? _value.isLikedByMe
            : isLikedByMe // ignore: cast_nullable_to_non_nullable
                  as bool,
        createdAt: null == createdAt
            ? _value.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$ThreadModelImpl implements _ThreadModel {
  const _$ThreadModelImpl({
    required this.id,
    @JsonKey(name: 'author_id') required this.authorId,
    @JsonKey(name: 'author_name') this.authorName = 'משתמש אנונימי',
    @JsonKey(name: 'author_image') this.authorAvatar,
    @JsonKey(name: 'group_id') required this.groupId,
    @JsonKey(name: 'group_name') this.groupName = 'קבוצה',
    @JsonKey(name: 'group_cover') this.groupCover,
    required this.content,
    @JsonKey(name: 'bg_type') required this.bgType,
    @JsonKey(name: 'bg_value') required this.bgValue,
    @JsonKey(name: 'likes_count') this.likesCount = 0,
    @JsonKey(name: 'comments_count') this.commentsCount = 0,
    @JsonKey(name: 'is_liked') this.isLikedByMe = false,
    @JsonKey(name: 'created_at') required this.createdAt,
  });

  factory _$ThreadModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$ThreadModelImplFromJson(json);

  @override
  final String id;
  @override
  @JsonKey(name: 'author_id')
  final String authorId;
  @override
  @JsonKey(name: 'author_name')
  final String authorName;
  @override
  @JsonKey(name: 'author_image')
  final String? authorAvatar;
  // תוקן ל-author_image
  @override
  @JsonKey(name: 'group_id')
  final String groupId;
  @override
  @JsonKey(name: 'group_name')
  final String groupName;
  // ערך דיפולטיבי מונע קריסה
  @override
  @JsonKey(name: 'group_cover')
  final String? groupCover;
  @override
  final String content;
  @override
  @JsonKey(name: 'bg_type')
  final String bgType;
  @override
  @JsonKey(name: 'bg_value')
  final String bgValue;
  @override
  @JsonKey(name: 'likes_count')
  final int likesCount;
  @override
  @JsonKey(name: 'comments_count')
  final int commentsCount;
  @override
  @JsonKey(name: 'is_liked')
  final bool isLikedByMe;
  // תוקן ל-is_liked
  @override
  @JsonKey(name: 'created_at')
  final DateTime createdAt;

  @override
  String toString() {
    return 'ThreadModel(id: $id, authorId: $authorId, authorName: $authorName, authorAvatar: $authorAvatar, groupId: $groupId, groupName: $groupName, groupCover: $groupCover, content: $content, bgType: $bgType, bgValue: $bgValue, likesCount: $likesCount, commentsCount: $commentsCount, isLikedByMe: $isLikedByMe, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ThreadModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.authorId, authorId) ||
                other.authorId == authorId) &&
            (identical(other.authorName, authorName) ||
                other.authorName == authorName) &&
            (identical(other.authorAvatar, authorAvatar) ||
                other.authorAvatar == authorAvatar) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.groupName, groupName) ||
                other.groupName == groupName) &&
            (identical(other.groupCover, groupCover) ||
                other.groupCover == groupCover) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.bgType, bgType) || other.bgType == bgType) &&
            (identical(other.bgValue, bgValue) || other.bgValue == bgValue) &&
            (identical(other.likesCount, likesCount) ||
                other.likesCount == likesCount) &&
            (identical(other.commentsCount, commentsCount) ||
                other.commentsCount == commentsCount) &&
            (identical(other.isLikedByMe, isLikedByMe) ||
                other.isLikedByMe == isLikedByMe) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    authorId,
    authorName,
    authorAvatar,
    groupId,
    groupName,
    groupCover,
    content,
    bgType,
    bgValue,
    likesCount,
    commentsCount,
    isLikedByMe,
    createdAt,
  );

  /// Create a copy of ThreadModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ThreadModelImplCopyWith<_$ThreadModelImpl> get copyWith =>
      __$$ThreadModelImplCopyWithImpl<_$ThreadModelImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ThreadModelImplToJson(this);
  }
}

abstract class _ThreadModel implements ThreadModel {
  const factory _ThreadModel({
    required final String id,
    @JsonKey(name: 'author_id') required final String authorId,
    @JsonKey(name: 'author_name') final String authorName,
    @JsonKey(name: 'author_image') final String? authorAvatar,
    @JsonKey(name: 'group_id') required final String groupId,
    @JsonKey(name: 'group_name') final String groupName,
    @JsonKey(name: 'group_cover') final String? groupCover,
    required final String content,
    @JsonKey(name: 'bg_type') required final String bgType,
    @JsonKey(name: 'bg_value') required final String bgValue,
    @JsonKey(name: 'likes_count') final int likesCount,
    @JsonKey(name: 'comments_count') final int commentsCount,
    @JsonKey(name: 'is_liked') final bool isLikedByMe,
    @JsonKey(name: 'created_at') required final DateTime createdAt,
  }) = _$ThreadModelImpl;

  factory _ThreadModel.fromJson(Map<String, dynamic> json) =
      _$ThreadModelImpl.fromJson;

  @override
  String get id;
  @override
  @JsonKey(name: 'author_id')
  String get authorId;
  @override
  @JsonKey(name: 'author_name')
  String get authorName;
  @override
  @JsonKey(name: 'author_image')
  String? get authorAvatar; // תוקן ל-author_image
  @override
  @JsonKey(name: 'group_id')
  String get groupId;
  @override
  @JsonKey(name: 'group_name')
  String get groupName; // ערך דיפולטיבי מונע קריסה
  @override
  @JsonKey(name: 'group_cover')
  String? get groupCover;
  @override
  String get content;
  @override
  @JsonKey(name: 'bg_type')
  String get bgType;
  @override
  @JsonKey(name: 'bg_value')
  String get bgValue;
  @override
  @JsonKey(name: 'likes_count')
  int get likesCount;
  @override
  @JsonKey(name: 'comments_count')
  int get commentsCount;
  @override
  @JsonKey(name: 'is_liked')
  bool get isLikedByMe; // תוקן ל-is_liked
  @override
  @JsonKey(name: 'created_at')
  DateTime get createdAt;

  /// Create a copy of ThreadModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ThreadModelImplCopyWith<_$ThreadModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
