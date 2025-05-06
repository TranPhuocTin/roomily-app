import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/core/utils/bill_status.dart';

part 'bill_log.g.dart';

@JsonSerializable()
class BillLog {
  final String id;
  final String fromDate;
  final String toDate;
  final int? electricity;
  final int? water;
  final int? electricityBill;
  final int? waterBill;
  final String? electricityImageUrl;
  final String? waterImageUrl;
  final double rentalCost;
  final bool rentalCostPaid;
  
  @JsonKey(
    fromJson: _billStatusFromJson,
  )
  final BillStatus billStatus;
  
  final String createdAt;
  final String roomId;
  final String rentedRoomId;

  BillLog({
    required this.id,
    required this.fromDate,
    required this.toDate,
    this.electricity,
    this.water,
    this.electricityBill,
    this.waterBill,
    this.electricityImageUrl,
    this.waterImageUrl,
    required this.rentalCost,
    required this.billStatus,
    required this.createdAt,
    required this.roomId,
    required this.rentedRoomId,
    this.rentalCostPaid = false,
  });

  factory BillLog.fromJson(Map<String, dynamic> json) => _$BillLogFromJson(json);
  Map<String, dynamic> toJson() => _$BillLogToJson(this);
  
  // Factory constructor for empty bill log
  factory BillLog.empty() {
    final now = DateTime.now();
    final formattedDate = "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
    
    return BillLog(
      id: 'empty-${DateTime.now().millisecondsSinceEpoch}',
      fromDate: formattedDate,
      toDate: formattedDate,
      rentalCost: 0,
      billStatus: BillStatus.MISSING,
      createdAt: formattedDate,
      roomId: 'empty',
      rentedRoomId: 'empty',
    );
  }
  
  // Conversion methods for BillStatus enum
  static BillStatus _billStatusFromJson(String status) {
    for (var value in BillStatus.values) {
      if (value.name == status) {
        return value;
      }
    }
    return BillStatus.MISSING;
  }

} 