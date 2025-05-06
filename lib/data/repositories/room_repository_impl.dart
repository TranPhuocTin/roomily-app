import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/core/services/secure_storage_service.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/core/utils/string_utils.dart';
import 'package:roomily/data/models/room_create.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/core/cache/cache.dart';
import 'package:roomily/data/models/room_filter.dart';

class RoomRepositoryImpl implements RoomRepository {
  final Dio _dio;
  final Cache _cache;

  RoomRepositoryImpl({Dio? dio, Cache? cache})
    : _dio = dio ?? DioConfig.createDio(),
      _cache = cache ?? InMemoryCache();

  @override
  Future<Result<Room>> getRoom(String roomId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}${ApiConstants.room(roomId)}');
      return Success(Room.fromJson(response.data));
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get room');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<String>> postRoom(RoomCreate room) async {
    try {
      print(room.toJson());
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.postRoom()}',
        options: Options(responseType: ResponseType.plain),
        data: room.toJson(),
      );
      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Room posted successfully with response: ${response.data.toString()}');
        return Success(response.data.toString());
      }

      return Failure('Failed to post room');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to post room');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }


  @override
  Future<Result<List<Room>>> getRoomsWithFilter(RoomFilter filter) async {
    try {
      // Tạo bản sao của filter với các trường chuỗi đã được chuẩn hóa
      final normalizedFilter = RoomFilter(
        city: filter.city,
        district: filter.district,
        ward: filter.ward,
        type: filter.type,
        minPrice: filter.minPrice,
        maxPrice: filter.maxPrice,
        minPeople: filter.minPeople,
        maxPeople: filter.maxPeople,
        pivotId: filter.pivotId,
        limit: filter.limit,
        timestamp: filter.timestamp,
        tagIds: filter.tagIds,
        hasFindPartnerPost: filter.hasFindPartnerPost,
      );
      
      print('Calling API with filter: ${normalizedFilter.toJson()}');
      
      try {
        final response = await _dio.post(
          '${ApiConstants.baseUrl}${ApiConstants.roomFilter()}',
          data: normalizedFilter.toJson(),
          options: Options(
            // Thêm timeout dài hơn cho request này để tránh lỗi timeout
            sendTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            // Bảo đảm header Accept đúng
            headers: {
              'Accept': 'application/json',
            }
          ),
        );
        
        print('API Response status: ${response.statusCode}');
        print('API Response type: ${response.data.runtimeType}');
        
        // Kiểm tra định dạng response chi tiết hơn
        if (response.data == null) {
          print('Response data is null, returning empty list');
          return Success(<Room>[]);
        }
        
        if (response.data is! List) {
          print('Response is not a list: ${response.data}');
          
          // Thử kiểm tra nếu response là Map với danh sách bên trong
          if (response.data is Map && response.data.containsKey('content')) {
            final content = response.data['content'];
            if (content is List) {
              print('Found content list inside response map');
              return Success(content
                  .map((json) => Room.fromJson(json as Map<String, dynamic>))
                  .toList());
            }
          }
          
          // Thử khởi tạo lại Dio và thử lại một lần nữa với request tối giản
          print('Retrying with minimal filter after format error');
          try {
            final minimalFilter = RoomFilter(limit: 10);
            
            // Tạo Dio mới để tránh các interceptor có vấn đề
            final freshDio = Dio(
              BaseOptions(
                baseUrl: ApiConstants.baseUrl,
                connectTimeout: const Duration(milliseconds: 30000),
                receiveTimeout: const Duration(milliseconds: 30000),
                sendTimeout: const Duration(milliseconds: 30000),
                headers: {
                  'Content-Type': 'application/json',
                  'Accept': 'application/json',
                },
              ),
            );
            
            // Thêm token nếu có
            final token = await _getToken();
            if (token != null && token.isNotEmpty) {
              freshDio.options.headers['Authorization'] = 'Bearer $token';
            }
            
            final retryResponse = await freshDio.post(
              ApiConstants.roomFilter(),
              data: minimalFilter.toJson(),
            );
            
            if (retryResponse.data is List) {
              print('Retry successful, got list of ${retryResponse.data.length} rooms');
              final rooms = (retryResponse.data as List)
                  .map((json) => Room.fromJson(json as Map<String, dynamic>))
                  .toList();
              return Success(rooms);
            }
          } catch (retryError) {
            print('Retry request failed: $retryError');
          }
          
          return Failure('Invalid response format: expected a list');
        }

        final rooms = (response.data as List)
            .map((json) => Room.fromJson(json as Map<String, dynamic>))
            .toList();
        
        print('Parsed ${rooms.length} rooms');
        return Success(rooms);
      } on DioException catch (dioError) {
        // Xử lý trường hợp lỗi Dio cụ thể
        print('DioException in getRoomsWithFilter: ${dioError.type} - ${dioError.message}');
        
        // Kiểm tra nếu lỗi là 401 (Unauthorized)
        if (dioError.response?.statusCode == 401) {
          print('Got 401 Unauthorized. Token may be invalid or expired.');
          return Failure('Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.');
        }
        
        return Failure('Error fetching rooms: ${dioError.message}');
      }
    } on DioException catch (e) {
      print('Error getting rooms with filter: $e');
      return Failure('Error fetching rooms: ${e.message}');
    } catch (e) {
      print('Unexpected error getting rooms with filter: $e');
      return Failure('Unexpected error: $e');
    }
  }

  @override
  Future<Result<List<Room>>> getLandlordRooms(String landlordId) async {
    try {
      final response = await _dio.get('${ApiConstants.baseUrl}${ApiConstants.landlordRooms(landlordId)}');
      final rooms = (response.data as List)
          .map((json) => Room.fromJson(json as Map<String, dynamic>))
          .toList();
      return Success(rooms);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get landlord rooms');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  /// Helper method to get current authentication token
  Future<String?> _getToken() async {
    try {
      final GetIt getIt = GetIt.instance;
      if (getIt.isRegistered<SecureStorageService>()) {
        final secureStorage = getIt<SecureStorageService>();
        return await secureStorage.getToken();
      }
      return null;
    } catch (e) {
      print('Error getting token: $e');
      return null;
    }
  }

  @override
  Future<void> deleteRoom(String id) async {
    try {
      await _dio.delete('${ApiConstants.baseUrl}${ApiConstants.room(id)}');
    } on DioException catch (e) {
      print('Error deleting room: $e');
      throw Exception(e.message ?? 'Failed to delete room');
    } catch (e) {
      print('Unexpected error deleting room: $e');
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<List<Room>> getRooms() {
    // TODO: implement getRooms
    throw UnimplementedError();
  }

  @override
  Future<Room> updateRoom(Room room) async {
    try {
      final Map<String, dynamic> updateData = {
        "title": room.title,
        "description": room.description,
        "address": room.address,
        "status": room.status?.name ?? "AVAILABLE",
        "price": room.price.toString(),
        "latitude": room.latitude,
        "longitude": room.longitude,
        "city": room.city,
        "district": room.district,
        "ward": room.ward,
        "electricPrice": room.electricPrice.toString(),
        "waterPrice": room.waterPrice.toString(),
        "type": room.type,
        "maxPeople": room.maxPeople,
        "deposit": room.deposit?.toString(),
        "tags": room.tags.map((tag) => tag.id).toList(),
        "squareMeters": room.squareMeters
      };

      if (room.nearbyAmenities != null) {
        updateData["nearbyAmenities"] = room.nearbyAmenities;
      }

      if (kDebugMode) {
        print('Updating room with data: $updateData');
      }

      final response = await _dio.put(
        '${ApiConstants.baseUrl}${ApiConstants.room(room.id!)}',
        data: updateData,
      );

      if (response.statusCode == 200) {
        return Room.fromJson(response.data);
      }
      
      throw Exception('Failed to update room, status code: ${response.statusCode}');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('Error updating room: $e');
      }
      throw Exception(e.message ?? 'Failed to update room');
    } catch (e) {
      if (kDebugMode) {
        print('Unexpected error updating room: $e');
      }
      throw Exception('An unexpected error occurred: $e');
    }
  }
}
