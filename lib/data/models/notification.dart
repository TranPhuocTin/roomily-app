import 'package:json_annotation/json_annotation.dart';

part 'notification.g.dart';

@JsonSerializable()
class NotificationModel {
  final String id;
  final String header;
  final String body;
  final bool isRead;
  final String createdAt;
  final String userId;

  NotificationModel({
    required this.id,
    required this.header,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.userId,
  });

  // Chuyển từ JSON sang Object
  factory NotificationModel.fromJson(Map<String, dynamic> json) =>
      _$NotificationModelFromJson(json);

  // Chuyển từ Object sang JSON
  Map<String, dynamic> toJson() => _$NotificationModelToJson(this);
}
