class BudgetPlanRoom {
  final String roomId;
  final String roomTitle;
  final String roomDescription;
  final String roomAddress;
  final double squareMeters;
  final String? imageUrl;
  final String roomType;
  final String city;
  final String district;
  final String ward;
  final double latitude;
  final double longitude;
  final int numberOfTagsMatched;
  final int numberOfTags;
  final double tagSimilarity;

  BudgetPlanRoom({
    required this.roomId,
    required this.roomTitle,
    required this.roomDescription,
    required this.roomAddress,
    required this.squareMeters,
    this.imageUrl,
    required this.roomType,
    required this.city,
    required this.district,
    required this.ward,
    required this.latitude,
    required this.longitude,
    required this.numberOfTagsMatched,
    required this.numberOfTags,
    required this.tagSimilarity,
  });

  factory BudgetPlanRoom.fromJson(Map<String, dynamic> json) {
    return BudgetPlanRoom(
      roomId: json['roomId'] ?? '',
      roomTitle: json['roomTitle'] ?? '',
      roomDescription: json['roomDescription'] ?? '',
      roomAddress: json['roomAddress'] ?? '',
      squareMeters: (json['squareMeters'] ?? 0.0).toDouble(),
      imageUrl: json['imageUrl'],
      roomType: json['roomType'] ?? '',
      city: json['city'] ?? '',
      district: json['district'] ?? '',
      ward: json['ward'] ?? '',
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
      numberOfTagsMatched: json['numberOfTagsMatched'] ?? 0,
      numberOfTags: json['numberOfTags'] ?? 0,
      tagSimilarity: (json['tagSimilarity'] ?? 0.0).toDouble(),
    );
  }
} 