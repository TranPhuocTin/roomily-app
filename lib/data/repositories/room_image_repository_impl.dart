import 'package:dio/dio.dart';
import 'package:roomily/core/cache/cache.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/room_image.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';

import '../../core/config/dio_config.dart';
import '../../core/constants/api_constants.dart';

class RoomImageRepositoryImpl extends RoomImageRepository {
  final Dio _dio;

  RoomImageRepositoryImpl({Cache? cache, Dio? dio})
      : _dio = DioConfig.createDio();

  @override
  Future<Result<void>> deleteRoomImage(
      String roomId, List<String> imageIds) async {
    try {
      final response = await _dio.delete(ApiConstants.deleteRoomImage(roomId),
          data: imageIds);
      if (response.statusCode == 200) {
        return Success('Room image deleted successfully');
      }
      return Failure('Failed to delete room image');
      return Success('Room image deleted successfully');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to delete room image');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<List<String>>> getRoomImageUrls(String roomId) async {
    try {
      final response = await _dio.get(ApiConstants.roomImageUrls(roomId));
      final imageUrls = response.data as List<String>;
      return Success(imageUrls);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get room image urls');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  //Contain more information than getRoomImagesUrls
  @override
  Future<Result<List<RoomImage>>> getRoomImages(String roomId) async {
    try {
      // final response = await _dio.get(ApiConstants.roomImages('3b183933-2ced-5ce4-182c-2de527da9f12'));
      final response = await _dio.get(ApiConstants.roomImages(roomId));
      final roomImages =
          (response.data as List).map((e) => RoomImage.fromJson(e)).toList();
      return Success(roomImages);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get room images');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<void>> postRoomImage(
      String roomId, List<MultipartFile> imageFiles) async {
    try {
      // Create form data
      final formData = FormData();
      
      // Add each image file to the form data
      for (var i = 0; i < imageFiles.length; i++) {
        formData.files.add(MapEntry('images', imageFiles[i]));
      }
      
      final response = await _dio.post(
        ApiConstants.postRoomImage(roomId),
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
      
      if (response.statusCode == 200) {
        return Success('Room image posted successfully');
      }
      return Failure('Failed to post room image');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to post room image');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  
}

final mockRoomImages = [
  RoomImage(
    id: '1',
    name: 'Living Room',
    url: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    roomId: '1',
    createdAt: '2024-02-21T12:00:00Z',
  ),
  RoomImage(
    id: '2',
    name: 'Kitchen',
    url: 'https://images.unsplash.com/photo-1560448204-603b3fc33ddc?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    roomId: '1',
    createdAt: '2024-02-21T12:00:00Z',
  ),
  RoomImage(
    id: '3',
    name: 'Bedroom',
    url: 'https://images.unsplash.com/photo-1484154218962-a197022b5858?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    roomId: '1',
    createdAt: '2024-02-21T12:00:00Z',
  ),
  RoomImage(
    id: '4',
    name: 'Bathroom',
    url: 'https://images.unsplash.com/photo-1560185127-6ed189bf02f4?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    roomId: '1',
    createdAt: '2024-02-21T12:00:00Z',
  ),
  RoomImage(
    id: '5',
    name: 'Balcony',
    url: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    roomId: '1',
    createdAt: '2024-02-21T12:00:00Z',
  ),
  RoomImage(
    id: '6',
    name: 'Dining Area',
    url: 'https://images.unsplash.com/photo-1598928636135-d146006ff4be?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    roomId: '1',
    createdAt: '2024-02-21T12:00:00Z',
  ),
  RoomImage(
    id: '7',
    name: 'Study Room',
    url: 'https://images.unsplash.com/photo-1598928636175-702c8b84e8bb?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    roomId: '1',
    createdAt: '2024-02-21T12:00:00Z',
  ),
  RoomImage(
    id: '8',
    name: 'Hallway',
    url: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    roomId: '1',
    createdAt: '2024-02-21T12:00:00Z',
  ),
  RoomImage(
    id: '9',
    name: 'Entrance',
    url: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    roomId: '1',
    createdAt: '2024-02-21T12:00:00Z',
  ),
  RoomImage(
    id: '10',
    name: 'View',
    url: 'https://images.unsplash.com/photo-1598928506311-c55ded91a20c?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
    roomId: '1',
    createdAt: '2024-02-21T12:00:00Z',
  ),
];