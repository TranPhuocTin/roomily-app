import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/core/utils/room_type.dart';

part 'budget_plan_preference.g.dart';

@JsonSerializable()
class BudgetPlanPreference {
  final String roomType;
  final String city;
  final String? district;
  final String? ward;
  final int? monthlySalary;
  final int? maxBudget;
  final List<String>? mustHaveTagIds;
  final List<String>? niceToHaveTagIds;

  BudgetPlanPreference({
    required this.roomType,
    required this.city,
    required this.district,
    this.ward,
    required this.monthlySalary,
    required this.maxBudget,
    required this.mustHaveTagIds,
    required this.niceToHaveTagIds,
  });

  factory BudgetPlanPreference.fromJson(Map<String, dynamic> json) {
    // Handle null roomType by providing a default value
    String roomTypeValue = json['roomType'] as String? ?? RoomType.APARTMENT.name;
    
    return BudgetPlanPreference(
      roomType: roomTypeValue,
      city: json['city'] as String,
      district: json['district'] as String?,
      ward: json['ward'] as String?,
      monthlySalary: json['monthlySalary'] as int?,
      maxBudget: json['maxBudget'] as int?,
      mustHaveTagIds: (json['mustHaveTagIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      niceToHaveTagIds: (json['niceToHaveTagIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => _$BudgetPlanPreferenceToJson(this);
} 