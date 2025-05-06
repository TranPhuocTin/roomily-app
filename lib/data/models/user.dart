import 'package:json_annotation/json_annotation.dart';

part 'user.g.dart';

@JsonSerializable()
class User {
  final String id;
  final String privateId;
  final String username;
  final String fullName;
  final dynamic gender;
  final String email;
  final String phone;
  final String? profilePicture;
  final String address;
  final double rating;
  final bool isVerified;
  final double balance;

  User({
    required this.id,
    required this.privateId,
    required this.username,
    required this.fullName,
    this.gender,
    required this.email,
    required this.phone,
    this.profilePicture,
    required this.address,
    required this.rating,
    required this.isVerified,
    required this.balance,
  });

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);
  Map<String, dynamic> toJson() => _$UserToJson(this);

  String? getGenderAsString() {
    if (gender == null) return null;
    if (gender is bool) {
      return gender ? 'Nam' : 'Nữ';
    }
    return gender.toString();
  }
}
