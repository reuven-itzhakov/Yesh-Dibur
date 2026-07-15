import 'package:freezed_annotation/freezed_annotation.dart';

part 'thread_model.freezed.dart';
part 'thread_model.g.dart';

@freezed
class ThreadModel with _$ThreadModel {
  const factory ThreadModel({
    required String id,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'author_name') required String authorName,
    @JsonKey(name: 'author_avatar') String? authorAvatar,
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'group_name') required String groupName,
    @JsonKey(name: 'group_cover') String? groupCover,
    required String content,
    @JsonKey(name: 'bg_type') required String bgType, // 'image' או 'color'
    @JsonKey(name: 'bg_value') required String bgValue,
    @Default(0) @JsonKey(name: 'likes_count') int likesCount,
    @Default(0) @JsonKey(name: 'comments_count') int commentsCount,
    @Default(false) @JsonKey(name: 'is_liked_by_me') bool isLikedByMe,
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ThreadModel;

  factory ThreadModel.fromJson(Map<String, dynamic> json) => 
      _$ThreadModelFromJson(json);
}