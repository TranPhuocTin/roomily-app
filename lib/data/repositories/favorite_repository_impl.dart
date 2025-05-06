import 'package:dio/dio.dart';
import 'package:roomily/core/utils/result.dart';

import 'package:roomily/data/models/room.dart';

import '../../core/config/dio_config.dart';
import '../../core/constants/api_constants.dart';
import 'favorite_repository.dart';

class FavoriteRepositoryImpl implements FavoriteRepository {
  final Dio _dio;

  FavoriteRepositoryImpl({Dio? dio})
      : _dio = dio ?? DioConfig.createDio();


  @override
  Future<Result<List<Room>>> getRoomFavorites() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}${ApiConstants.favoriteRoom()}');
      final rooms = (response.data as List).map((e) => Room.fromJson(e)).toList();
      return Success(rooms);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get room favorites');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<bool>> toggleFavoriteRoom(String roomId) async {
    try {
      final response = await _dio.patch('${ApiConstants.baseUrl}${ApiConstants.tooggleRoomFavorite(roomId)}');
      return Success(response.data as bool);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to toggle favorite room');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<int>> getTotalFavoriteCountOfUser() async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}${ApiConstants.userFavoriteCount()}');
      return Success(response.data as int);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get total favorite count of user');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<int>> getTotalFavoriteCountOfRoom(String roomId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}${ApiConstants.roomFavoriteCount(roomId)}');
      return Success(response.data as int);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get total favorite count of room');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<bool>> checkRoomIsFavorite(String roomId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}${ApiConstants.checkRoomFavorite(roomId)}');
      return Success(response.data as bool);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to check if room is favorited');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }
}