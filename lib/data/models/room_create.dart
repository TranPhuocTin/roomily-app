import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/core/utils/room_status.dart';

part 'room_create.g.dart';

@JsonSerializable()
class RoomCreate {
  @JsonKey(includeIfNull: false)
  final String? id;
  final String title;
  final String description;
  final String address;
  // @JsonKey(defaultValue: RoomStatus.AVAILABLE)
  // final RoomStatus? status;
  final double price;
  final double? latitude;
  final double? longitude;
  final String city;
  final String district;
  final String ward;
  final double electricPrice;
  final double waterPrice;
  final String type;
  @JsonKey(includeIfNull: false)
  final String? nearbyAmenities;
  final int maxPeople;
  @JsonKey(includeIfNull: false)
  final String? landlordId;
  final double? deposit;
  @JsonKey(name: 'tagIds')
  final List<String> tags;
  final double squareMeters;
  // final DateTime createdAt;
  // final DateTime updatedAt;
  // final bool subscribed;

  RoomCreate({
    this.id,
    required this.title,
    required this.description,
    required this.address,
    // this.status,
    required this.price,
    this.latitude,
    this.longitude,
    required this.city,
    required this.district,
    required this.ward,
    required this.electricPrice,
    required this.waterPrice,
    required this.type,
    this.nearbyAmenities,
    required this.maxPeople,
    this.landlordId,
    this.deposit,
    required this.tags,
    required this.squareMeters,
    // required this.createdAt,
    // required this.updatedAt,
    // this.subscribed = false,
  });

  factory RoomCreate.fromJson(Map<String, dynamic> json) => _$RoomCreateFromJson(json);

  Map<String, dynamic> toJson() => _$RoomCreateToJson(this);
}
