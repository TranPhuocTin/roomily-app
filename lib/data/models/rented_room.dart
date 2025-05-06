import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/core/utils/rented_room_status.dart';

part 'rented_room.g.dart';

@JsonSerializable()
class RentedRoom {
  final String id;
  final String startDate;
  final String endDate;
  final String? duration;
  @JsonKey(fromJson: _statusFromJson, toJson: _statusToJson)
  final RentedRoomStatus status;
  final String createdAt;
  final String updatedAt;
  final String roomId;
  final String userId;
  final String landlordId;
  final String rentedRoomWallet;
  final String rentalDeposit;
  final String walletDebt;

  RentedRoom({
    required this.id,
    required this.startDate,
    required this.endDate,
    this.duration,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.roomId,
    required this.userId,
    required this.landlordId,
    required this.rentedRoomWallet,
    required this.rentalDeposit,
    required this.walletDebt,
  });

  factory RentedRoom.fromJson(Map<String, dynamic> json) => _$RentedRoomFromJson(json);
  Map<String, dynamic> toJson() => _$RentedRoomToJson(this);
  
  // Conversion methods for RentedRoomStatus enum
  static RentedRoomStatus _statusFromJson(String json) {
    switch (json.toUpperCase()) {
      case 'PENDING':
        return RentedRoomStatus.PENDING;
      case 'DEPOSIT_NOT_PAID':
        return RentedRoomStatus.DEPOSIT_NOT_PAID;
      case 'BILL_MISSING':
        return RentedRoomStatus.BILL_MISSING;
      case 'IN_USE':
      case 'ACTIVE':
        return RentedRoomStatus.IN_USE;
      case 'DEBT':
        return RentedRoomStatus.DEBT;
      case 'CANCELLED':
      case 'CANCELED':
        return RentedRoomStatus.CANCELLED;
      default:
        return RentedRoomStatus.IN_USE;
    }
  }
  
  static String _statusToJson(RentedRoomStatus status) {
    switch (status) {
      case RentedRoomStatus.PENDING:
        return 'PENDING';
      case RentedRoomStatus.DEPOSIT_NOT_PAID:
        return 'DEPOSIT_NOT_PAID';
      case RentedRoomStatus.BILL_MISSING:
        return 'BILL_MISSING';
      case RentedRoomStatus.IN_USE:
        return 'ACTIVE';
      case RentedRoomStatus.DEBT:
        return 'DEBT';
      case RentedRoomStatus.CANCELLED:
        return 'CANCELLED';
    }
  }
}
