class RegisterRequest {
  final String username;
  final String password;
  final String fullName;
  final String address;
  final String email;
  final String phone;
  final bool gender;
  final bool landlord;

  RegisterRequest({
    required this.username,
    required this.password,
    required this.fullName,
    required this.address,
    required this.email,
    required this.phone,
    required this.gender,
    required this.landlord,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'fullName': fullName,
      'address': address,
      'email': email,
      'phone': phone,
      'gender': gender,
      'landlord': landlord,
    };
  }
} 