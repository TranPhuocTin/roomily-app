import 'package:json_annotation/json_annotation.dart';
import 'package:intl/intl.dart';

part 'rent_request.g.dart';

@JsonSerializable()
class RentRequest {
  @JsonKey(name: 'roomId')
  final String roomId;
  
  @JsonKey(name: 'chatRoomId')
  final String chatRoomId;
  
  @JsonKey(
    name: 'startDate',
    toJson: _dateToJson,
    fromJson: _dateFromJson
  )
  final DateTime startDate;
  
  @JsonKey(name: 'findPartnerPostId')
  final String? findPartnerPostId;

  RentRequest({
    required this.roomId,
    required this.chatRoomId,
    required this.startDate,
    this.findPartnerPostId,
  });

  factory RentRequest.fromJson(Map<String, dynamic> json) =>
      _$RentRequestFromJson(json);

  Map<String, dynamic> toJson() => _$RentRequestToJson(this);
  
  static String _dateToJson(DateTime date) => DateFormat('yyyy-MM-dd').format(date);
  
  static DateTime _dateFromJson(String date) => DateTime.parse(date);
}