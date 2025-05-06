import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/core/utils/room_status.dart';
import 'package:roomily/core/utils/tag_category.dart';

part 'room.g.dart';

@JsonSerializable()
class Room {
  @JsonKey(includeIfNull: false)
  final String? id;
  final String title;
  final String description;
  final String address;
  // @JsonKey(defaultValue: RoomStatus.AVAILABLE)
  final RoomStatus? status;
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
  @JsonKey(includeIfNull: false, fromJson: _stringToDouble, toJson: _doubleToString)
  final double? deposit;
  @JsonKey(name: 'tags')
  final List<RoomTag> tags;
  final double squareMeters;
  final DateTime createdAt;
  final DateTime updatedAt;

  Room({
    this.id,
    required this.title,
    required this.description,
    required this.address,
    this.status,
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
    required this.createdAt,
    required this.updatedAt,
  });

  factory Room.fromJson(Map<String, dynamic> json) => _$RoomFromJson(json);

  Map<String, dynamic> toJson() => _$RoomToJson(this);
}

@JsonSerializable()
class RoomTag {
  final String id;
  final String name;
  @JsonKey(fromJson: _tagCategoryFromJson)
  final TagCategory category;
  final String? displayName;

  RoomTag({
    required this.id,
    required this.name,
    required this.category,
    this.displayName,
  });

  factory RoomTag.fromJson(Map<String, dynamic> json) => _$RoomTagFromJson(json);

  Map<String, dynamic> toJson() => _$RoomTagToJson(this);
}

// Helper functions for JSON conversion
double? _stringToDouble(String? value) => value != null ? double.tryParse(value) : null;
String? _doubleToString(double? value) => value?.toString();
// Convert TagCategory enum to/from string
TagCategory _tagCategoryFromJson(String category) {
  for(final tagCategory in TagCategory.values) {
    if (tagCategory.name.toUpperCase() == category.toUpperCase()) {
      return tagCategory;
    }
  }
  return TagCategory.BUILDING_FEATURE;
}
