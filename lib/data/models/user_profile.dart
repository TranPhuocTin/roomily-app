class UserProfile {
  final String id;
  final String name;
  final String email;
  final String avatarUrl;
  final String location;
  final String bio;
  final int favoritesCount;
  final int bookingsCount;
  final int reviewsCount;
  final List<SavedRoom> savedRooms;
  final List<Booking> bookings;
  final List<Review> reviews;
  final String phone;
  final bool isLandlord;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.avatarUrl,
    required this.location,
    required this.bio,
    required this.favoritesCount,
    required this.bookingsCount,
    required this.reviewsCount,
    required this.savedRooms,
    required this.bookings,
    required this.reviews,
    required this.phone,
    required this.isLandlord,
  });
}

class SavedRoom {
  final String id;
  final String title;
  final String address;
  final double price;
  final String imageUrl;

  SavedRoom({
    required this.id,
    required this.title,
    required this.address,
    required this.price,
    required this.imageUrl,
  });
}

class Booking {
  final String id;
  final String roomId;
  final String roomTitle;
  final String roomAddress;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String status;

  Booking({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.roomAddress,
    required this.startDate,
    required this.endDate,
    required this.amount,
    required this.status,
  });
}

class Review {
  final String id;
  final String roomId;
  final String roomTitle;
  final double rating;
  final String comment;
  final DateTime createdAt;

  Review({
    required this.id,
    required this.roomId,
    required this.roomTitle,
    required this.rating,
    required this.comment,
    required this.createdAt,
  });
} 