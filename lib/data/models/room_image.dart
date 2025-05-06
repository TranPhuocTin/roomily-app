import 'package:json_annotation/json_annotation.dart';

part 'room_image.g.dart';

@JsonSerializable()
class RoomImage {
  String id;
  String name;
  String url;
  String roomId;
  String createdAt;

  RoomImage({required this.id, required this.name, required this.url, required this.roomId, required this.createdAt});

  factory RoomImage.fromJson(Map<String, dynamic> json) => _$RoomImageFromJson(json);
  Map<String, dynamic> toJson() => _$RoomImageToJson(this);
}



