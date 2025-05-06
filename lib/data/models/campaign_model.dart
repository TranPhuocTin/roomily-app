import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/data/models/campaign_statistics_model.dart';
import 'package:roomily/data/models/promoted_room_model.dart';

part 'campaign_model.g.dart';

@JsonSerializable(explicitToJson: true)
class CampaignModel {
  final String id;
  final String name;
  final String status;
  final String pricingModel; // CPC or CPM
  final double budget;
  final double spentAmount;
  final double dailyBudget;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime startDate;
  @JsonKey(fromJson: _dateTimeFromJson, toJson: _dateTimeToJson)
  final DateTime endDate;
  final String userId;
  final List<PromotedRoomModel>? promotedRooms;
  final CampaignStatisticsModel? statistics;

  CampaignModel({
    required this.id,
    required this.name,
    required this.status,
    required this.pricingModel,
    required this.budget,
    required this.spentAmount,
    required this.dailyBudget,
    required this.startDate,
    required this.endDate,
    required this.userId,
    this.promotedRooms,
    this.statistics,
  });

  factory CampaignModel.fromJson(Map<String, dynamic> json) =>
      _$CampaignModelFromJson(json);

  Map<String, dynamic> toJson() => _$CampaignModelToJson(this);
}

// Hàm chuyển đổi DateTime từ định dạng mảng hoặc chuỗi
DateTime _dateTimeFromJson(dynamic dateValue) {
  if (dateValue is List) {
    // API trả về dạng [year, month, day, hour, minute, second, nanosecond]
    return DateTime(
      dateValue[0],
      dateValue[1],
      dateValue[2],
      dateValue.length > 3 ? dateValue[3] : 0,
      dateValue.length > 4 ? dateValue[4] : 0,
      dateValue.length > 5 ? dateValue[5] : 0,
      dateValue.length > 6 ? (dateValue[6] ~/ 1000000) : 0, // convert nano to milli
    );
  } else if (dateValue is String) {
    // Xử lý trường hợp chuỗi nếu API thay đổi
    return DateTime.parse(dateValue);
  } else {
    throw FormatException('Format not supported for date: $dateValue');
  }
}

// Chuyển DateTime thành ISO 8601
String _dateTimeToJson(DateTime dateTime) => dateTime.toIso8601String(); 