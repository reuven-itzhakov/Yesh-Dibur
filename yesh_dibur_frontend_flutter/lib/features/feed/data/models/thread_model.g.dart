// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'thread_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ThreadModelImpl _$$ThreadModelImplFromJson(Map<String, dynamic> json) =>
    _$ThreadModelImpl(
      id: json['id'] as String,
      authorId: json['author_id'] as String,
      authorName: json['author_name'] as String? ?? 'משתמש אנונימי',
      authorAvatar: json['author_image'] as String?,
      groupId: json['group_id'] as String,
      groupName: json['group_name'] as String? ?? 'קבוצה',
      groupCover: json['group_cover'] as String?,
      content: json['content'] as String,
      bgType: json['bg_type'] as String,
      bgValue: json['bg_value'] as String,
      likesCount: (json['likes_count'] as num?)?.toInt() ?? 0,
      commentsCount: (json['comments_count'] as num?)?.toInt() ?? 0,
      isLikedByMe: json['is_liked'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );

Map<String, dynamic> _$$ThreadModelImplToJson(_$ThreadModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'author_id': instance.authorId,
      'author_name': instance.authorName,
      'author_image': instance.authorAvatar,
      'group_id': instance.groupId,
      'group_name': instance.groupName,
      'group_cover': instance.groupCover,
      'content': instance.content,
      'bg_type': instance.bgType,
      'bg_value': instance.bgValue,
      'likes_count': instance.likesCount,
      'comments_count': instance.commentsCount,
      'is_liked': instance.isLikedByMe,
      'created_at': instance.createdAt.toIso8601String(),
    };
