import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/models.dart';

abstract class FavoriteState extends Equatable {
  const FavoriteState();

  @override
  List<Object?> get props => [];
}

class FavoriteInitial extends FavoriteState {}

class FavoriteLoading extends FavoriteState {}

class FavoriteLoaded extends FavoriteState {
  final List<Room> favoriteRooms;
  final bool isFavorite;
  final int userFavoriteCount;
  final int roomFavoriteCount;
  final String? errorMessage;

  const FavoriteLoaded({
    this.favoriteRooms = const [],
    this.isFavorite = false,
    this.userFavoriteCount = 0,
    this.roomFavoriteCount = 0,
    this.errorMessage,
  });

  FavoriteLoaded copyWith({
    List<Room>? favoriteRooms,
    bool? isFavorite,
    int? userFavoriteCount,
    int? roomFavoriteCount,
    String? errorMessage,
  }) {
    return FavoriteLoaded(
      favoriteRooms: favoriteRooms ?? this.favoriteRooms,
      isFavorite: isFavorite ?? this.isFavorite,
      userFavoriteCount: userFavoriteCount ?? this.userFavoriteCount,
      roomFavoriteCount: roomFavoriteCount ?? this.roomFavoriteCount,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [favoriteRooms, isFavorite, userFavoriteCount, roomFavoriteCount, errorMessage];
}

class FavoriteError extends FavoriteState {
  final String message;

  const FavoriteError({required this.message});

  @override
  List<Object> get props => [message];
} 