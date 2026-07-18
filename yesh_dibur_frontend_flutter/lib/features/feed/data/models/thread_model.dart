import 'package:freezed_annotation/freezed_annotation.dart';

part 'thread_model.freezed.dart';
part 'thread_model.g.dart';

@freezed
class ThreadModel with _$ThreadModel {
  const factory ThreadModel({
    required String id,
    @JsonKey(name: 'author_id') required String authorId,
    @JsonKey(name: 'author_name') @Default('משתמש אנונימי') String authorName,
    @JsonKey(name: 'author_image') String? authorAvatar, // תוקן ל-author_image
    @JsonKey(name: 'group_id') required String groupId,
    @JsonKey(name: 'group_name') @Default('קבוצה') String groupName, // ערך דיפולטיבי מונע קריסה
    @JsonKey(name: 'group_cover') String? groupCover,
    required String content,
    @JsonKey(name: 'bg_type') required String bgType,
    @JsonKey(name: 'bg_value') required String bgValue,
    @Default(0) @JsonKey(name: 'likes_count') int likesCount,
    @Default(0) @JsonKey(name: 'comments_count') int commentsCount,
    @Default(false) @JsonKey(name: 'is_liked') bool isLikedByMe, // תוקן ל-is_liked
    @JsonKey(name: 'created_at') required DateTime createdAt,
  }) = _ThreadModel;

  factory ThreadModel.fromJson(Map<String, dynamic> json) => 
      _$ThreadModelFromJson(json);
}