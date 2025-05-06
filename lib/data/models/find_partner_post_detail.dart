import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/models/user.dart';

part 'find_partner_post_detail.g.dart';

@JsonSerializable(explicitToJson: true)
class FindPartnerPostDetail {
  @JsonKey(name: 'findPartnerPostId')
  final String id;
  final String? description;
  final int currentPeople;
  final int maxPeople;
  final String status;
  final String? chatRoomId;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime createdAt;
  @JsonKey(fromJson: _parseDateTime)
  final DateTime updatedAt;
  @JsonKey(name: 'posterId')
  final String posterUserId;
  final String roomId;
  final List<Participant> participants;
  final String? type;
  final String? rentedRoomId;

  FindPartnerPostDetail({
    required this.id,
    this.description,
    required this.currentPeople,
    required this.maxPeople,
    required this.status,
    this.chatRoomId,
    required this.createdAt,
    required this.updatedAt,
    required this.posterUserId,
    required this.roomId,
    required this.participants,
    this.type,
    this.rentedRoomId,
  });

  factory FindPartnerPostDetail.fromJson(Map<String, dynamic> json) {
    // Handle the case where findPartnerPostId is used instead of id
    if (json.containsKey('findPartnerPostId')) {
      json['id'] = json['findPartnerPostId'];
    }
    
    // Convert participants from the simplified format
    if (json['participants'] is List) {
      json['participants'] = (json['participants'] as List).map((p) => {
        'userId': p['userId'],
        'fullName': p['fullName'],
        'address': p['address'],
        'gender': p['gender'],
      }).toList();
    }
    
    return _$FindPartnerPostDetailFromJson(json);
  }

  Map<String, dynamic> toJson() => _$FindPartnerPostDetailToJson(this);

  // Custom parser for DateTime that handles both string and list formats
  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue is String) {
      return DateTime.parse(dateValue);
    } else if (dateValue is List) {
      return DateTime(
        dateValue[0] as int, // year
        dateValue[1] as int, // month
        dateValue[2] as int, // day
        dateValue[3] as int, // hour
        dateValue[4] as int, // minute
        dateValue[5] as int, // second
        (dateValue[6] as int) ~/ 1000000, // nanosecond to millisecond
      );
    }
    throw FormatException('Invalid date format: $dateValue');
  }
}

@JsonSerializable()
class Participant {
  final String userId;
  final String fullName;
  final String address;
  final String? gender;

  Participant({
    required this.userId,
    required this.fullName,
    required this.address,
    this.gender,
  });

  factory Participant.fromJson(Map<String, dynamic> json) => _$ParticipantFromJson(json);
  Map<String, dynamic> toJson() => _$ParticipantToJson(this);
}

@JsonSerializable()
class UserRole {
  final String id;
  final String name;

  UserRole({
    required this.id,
    required this.name,
  });

  factory UserRole.fromJson(Map<String, dynamic> json) => _$UserRoleFromJson(json);
  Map<String, dynamic> toJson() => _$UserRoleToJson(this);
} 