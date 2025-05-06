import 'package:json_annotation/json_annotation.dart';

part 'ad_click_request_model.g.dart';

@JsonSerializable()
class AdClickRequestModel {
  final String promotedRoomId;
  final String ipAddress;
  final String userId;

  AdClickRequestModel({
    required this.promotedRoomId,
    required this.ipAddress,
    required this.userId,
  });

  factory AdClickRequestModel.fromJson(Map<String, dynamic> json) => 
      _$AdClickRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$AdClickRequestModelToJson(this);
} 