import 'package:json_annotation/json_annotation.dart';

part 'promoted_room_model.g.dart';

@JsonSerializable()
class PromotedRoomModel {
  final String id;
  final String status;
  final double? bid;
  final String adCampaignId;
  final String roomId;

  PromotedRoomModel({
    required this.id,
    required this.status,
    this.bid,
    required this.adCampaignId,
    required this.roomId,
  });

  factory PromotedRoomModel.fromJson(Map<String, dynamic> json) =>
      _$PromotedRoomModelFromJson(json);

  Map<String, dynamic> toJson() => _$PromotedRoomModelToJson(this);
} 