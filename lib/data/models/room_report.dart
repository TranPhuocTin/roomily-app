import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/core/utils/room_report_type.dart';

part 'room_report.g.dart';

@JsonSerializable()
class RoomReport {
  final String? reporterId;
  final String? roomId;
  final String reason;
  
  @JsonKey(
    fromJson: _typeFromJson,
    toJson: _typeToJson,
  )
  final RoomReportType type;

  RoomReport({
    this.reporterId,
    this.roomId,
    required this.reason,
    required this.type,
  });

  factory RoomReport.fromJson(Map<String, dynamic> json) => _$RoomReportFromJson(json);

  Map<String, dynamic> toJson() => _$RoomReportToJson(this);
  
  static RoomReportType _typeFromJson(String type) {
    return RoomReportType.values.firstWhere(
      (e) => e.toString().split('.').last == type,
      orElse: () => RoomReportType.OTHER,
    );
  }
  
  static String _typeToJson(RoomReportType type) {
    return type.toString().split('.').last;
  }
} 