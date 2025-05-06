import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/data/models/room.dart';

part 'budget_plan_room_detail.g.dart';

@JsonSerializable()
class BudgetPlanRoomDetail {
  @JsonKey(name: 'roomResponse')
  final Room room;
  final int upFrontCost;
  final int estimatedMonthlyElectricityUsage;
  final int estimatedMonthlyWaterUsage;
  final int wifiCost;
  final bool hasUserMonthlySalary;
  final int monthlySalary;
  final int maxBudget;
  final int baseLineMinRentalCost;
  final int baseLineMaxRentalCost;
  final int baseLineMedianRentalCost;
  final int averageElectricityCost;
  final int averageWaterCost;
  final List<RoomTag> matchedTags;
  final List<RoomTag> unmatchedTags;
  final bool includeWifi;

  BudgetPlanRoomDetail({
    required this.room,
    required this.upFrontCost,
    required this.estimatedMonthlyElectricityUsage,
    required this.estimatedMonthlyWaterUsage,
    required this.wifiCost,
    required this.hasUserMonthlySalary,
    required this.monthlySalary,
    required this.maxBudget,
    required this.baseLineMinRentalCost,
    required this.baseLineMaxRentalCost,
    required this.baseLineMedianRentalCost,
    required this.averageElectricityCost,
    required this.averageWaterCost,
    required this.matchedTags,
    required this.unmatchedTags,
    required this.includeWifi,
  });

  factory BudgetPlanRoomDetail.fromJson(Map<String, dynamic> json) => 
      _$BudgetPlanRoomDetailFromJson(json);
  
  Map<String, dynamic> toJson() => _$BudgetPlanRoomDetailToJson(this);
} 