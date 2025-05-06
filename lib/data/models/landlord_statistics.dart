class LandlordStatistics {
  final double responseRate;
  final int totalChatRooms;
  final int respondedChatRooms;
  final double averageResponseTimeInMinutes;
  final int totalRentedRooms;

  LandlordStatistics({
    required this.responseRate,
    required this.totalChatRooms,
    required this.respondedChatRooms,
    required this.averageResponseTimeInMinutes,
    required this.totalRentedRooms,
  });

  factory LandlordStatistics.fromJson(Map<String, dynamic> json) {
    return LandlordStatistics(
      responseRate: json['responseRate']?.toDouble() ?? 0.0,
      totalChatRooms: json['totalChatRooms'] ?? 0,
      respondedChatRooms: json['respondedChatRooms'] ?? 0,
      averageResponseTimeInMinutes: json['averageResponseTimeInMinutes']?.toDouble() ?? 0.0,
      totalRentedRooms: json['totalRentedRooms'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'responseRate': responseRate,
      'totalChatRooms': totalChatRooms,
      'respondedChatRooms': respondedChatRooms,
      'averageResponseTimeInMinutes': averageResponseTimeInMinutes,
      'totalRentedRooms': totalRentedRooms,
    };
  }
} 