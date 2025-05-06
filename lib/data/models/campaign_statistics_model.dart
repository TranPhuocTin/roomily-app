import 'package:json_annotation/json_annotation.dart';

part 'campaign_statistics_model.g.dart';

@JsonSerializable()
class CampaignStatisticsModel {
  final int totalClicks;
  final int totalConversions;
  final double totalSpent;
  final double conversionRate;
  final double costPerClick;
  
  // Các trường không bắt buộc (có thể thiếu trong API)
  @JsonKey(defaultValue: 0)
  final int? totalImpressions;
  @JsonKey(defaultValue: 0.0)
  final double? clickThroughRate;
  @JsonKey(defaultValue: 0.0)
  final double? costPerMille;

  CampaignStatisticsModel({
    required this.totalClicks,
    required this.totalConversions,
    required this.totalSpent,
    required this.conversionRate,
    required this.costPerClick,
    this.totalImpressions,
    this.clickThroughRate,
    this.costPerMille,
  });

  factory CampaignStatisticsModel.fromJson(Map<String, dynamic> json) =>
      _$CampaignStatisticsModelFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignStatisticsModelToJson(this);
} 