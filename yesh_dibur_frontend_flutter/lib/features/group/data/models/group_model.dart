import 'package:freezed_annotation/freezed_annotation.dart';

part 'group_model.freezed.dart';
part 'group_model.g.dart';

@freezed
class GroupModel with _$GroupModel {
  const factory GroupModel({
    required String id,
    required String name,
    String? description,
    @JsonKey(name: 'cover_image') String? coverImage,
    @Default(0) @JsonKey(name: 'members_count') int membersCount,
    @Default([]) List<String> interests,
  }) = _GroupModel;

  factory GroupModel.fromJson(Map<String, dynamic> json) => 
      _$GroupModelFromJson(json);
}