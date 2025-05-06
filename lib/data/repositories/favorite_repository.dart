import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/models.dart';

abstract class FavoriteRepository {
  //Get list favorites by room
  Future<Result<List<Room>>> getRoomFavorites();
  //Post favorite by room
  Future<Result<bool>> toggleFavoriteRoom(String roomId);
  //Update favorite by favoriteId
  Future<Result<int>> getTotalFavoriteCountOfUser();
  //Delete favorite by favoriteId
  Future<Result<int>> getTotalFavoriteCountOfRoom(String roomId);
  //Check if room is favorited by user
  Future<Result<bool>> checkRoomIsFavorite(String roomId);
}