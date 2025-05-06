import 'package:json_annotation/json_annotation.dart';

part 'room_marker_info.g.dart';

@JsonSerializable()
class RoomMarkerInfo {
  final double latitude;
  final double longitude;
  final double price;
  final String type;
  final String id;
  final String? title;
  final String? address;
  final String? thumbnailUrl;
  final int? area;
  final int? bedrooms;

  RoomMarkerInfo({
    required this.latitude,
    required this.longitude,
    required this.price,
    required this.type,
    required this.id,
    this.title,
    this.address,
    this.thumbnailUrl,
    this.area,
    this.bedrooms,
  });

  factory RoomMarkerInfo.fromJson(Map<String, dynamic> json) => 
      _$RoomMarkerInfoFromJson(json);
  
  Map<String, dynamic> toJson() => _$RoomMarkerInfoToJson(this);
} 