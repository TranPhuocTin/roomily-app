import 'package:json_annotation/json_annotation.dart';

part 'campaign_create_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CampaignCreateModel {
  final String name;
  final String pricingModel;
  final double? cpmRate;
  final double budget;
  final double dailyBudget;
  final String startDate;
  final String endDate;

  CampaignCreateModel({
    required this.name,
    required this.pricingModel,
    this.cpmRate,
    required this.budget,
    required this.dailyBudget,
    required this.startDate,
    required this.endDate,
  });

  factory CampaignCreateModel.fromJson(Map<String, dynamic> json) =>
      _$CampaignCreateModelFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignCreateModelToJson(this);
} 