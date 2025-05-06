import 'package:json_annotation/json_annotation.dart';

part 'ad_impression_request_model.g.dart';

@JsonSerializable()
class AdImpressionRequestModel {
  final List<String> promotedRoomIds;
  final String userId;

  AdImpressionRequestModel({
    required this.promotedRoomIds,
    required this.userId,
  });

  factory AdImpressionRequestModel.fromJson(Map<String, dynamic> json) => 
      _$AdImpressionRequestModelFromJson(json);

  Map<String, dynamic> toJson() => _$AdImpressionRequestModelToJson(this);
}