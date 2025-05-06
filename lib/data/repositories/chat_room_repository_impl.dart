import 'package:dio/dio.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/chat_room_info.dart';
import 'package:roomily/data/repositories/chat_room_repository.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/data/models/direct_chat_room.dart';
import '../models/chat_room.dart';
import 'package:flutter/foundation.dart';

class ChatRoomRepositoryImpl extends ChatRoomRepository{
  Dio dio;

  ChatRoomRepositoryImpl({Dio? dio}) : dio = dio ?? Dio();

  @override
  Future<Result<List<ChatRoom>>> getChatRooms() async {
    try {
      final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.chatRooms()}');
      // Kiểm tra kiểu dữ liệu trả về
      final data = response.data;
      
      // Xử lý các trường hợp khác nhau của kiểu dữ liệu
      if (data is List) {
        // Trường hợp API trả về một danh sách
        final chatRooms = data.map((e) => ChatRoom.fromJson(e)).toList();
        debugPrint('✅ [ChatRoomRepository] Successfully loaded ${chatRooms.length} chat rooms');
        return Success(chatRooms);
      } else if (data is Map) {
        // Trường hợp API trả về một object với danh sách bên trong
        // Kiểm tra xem có trường data hoặc results không
        if (data.containsKey('data') && data['data'] is List) {
          final chatRooms = (data['data'] as List).map((e) => ChatRoom.fromJson(e)).toList();
          debugPrint('✅ [ChatRoomRepository] Successfully loaded ${chatRooms.length} chat rooms from data field');
          return Success(chatRooms);
        } else if (data.containsKey('results') && data['results'] is List) {
          final chatRooms = (data['results'] as List).map((e) => ChatRoom.fromJson(e)).toList();
          debugPrint('✅ [ChatRoomRepository] Successfully loaded ${chatRooms.length} chat rooms from results field');
          return Success(chatRooms);
        } else {
          // Trường hợp không tìm thấy danh sách trong object
          print('⚠️ [ChatRoomRepository] API Response is Map but does not contain List of chat rooms');
          return Success(<ChatRoom>[]); // Trả về danh sách rỗng
        }
      } else if (data is String) {
        // Trường hợp API trả về một chuỗi
        print('⚠️ [ChatRoomRepository] API Response is String: $data');
        
        // Kiểm tra xem có phải là thông báo lỗi không
        if (data.toLowerCase().contains('error') || 
            data.toLowerCase().contains('unauthorized') ||
            data.toLowerCase().contains('forbidden')) {
          return Failure('Server error: $data');
        }
        
        // Trả về danh sách rỗng nếu không phải lỗi nghiêm trọng
        return Success(<ChatRoom>[]);
      } else {
        // Trường hợp khác không xác định
        print('⚠️ [ChatRoomRepository] Unknown API Response Type: ${data.runtimeType}');
        return Success(<ChatRoom>[]); // Trả về danh sách rỗng
      }
    } on DioException catch (e) {
      debugPrint('❌ [ChatRoomRepository] DioException: ${e.message}');
      
      // Kiểm tra status code của lỗi
      if (e.response?.statusCode == 401) {
        debugPrint('⚠️ [ChatRoomRepository] Unauthorized (401) - Token may be invalid or expired');
        return Failure('Authentication required');
      }
      
      return Failure(e.message ?? 'Failed to get chat rooms');
    } catch (e) {
      print('❌ [ChatRoomRepository] Exception: $e');
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<ChatRoomInfo>> createDirectChatRoom(String roomId) async {
    try {
      final response = await dio.post('${ApiConstants.baseUrl}${ApiConstants.createDirectChatRoom(roomId)}');
      final chatRoomInfo = ChatRoomInfo.fromJson(response.data);
      return Success(chatRoomInfo);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to create direct chat room');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<ChatRoomInfo>> createDirectChatRoomToUser(String userId, {String? findPartnerPostId}) async {
    try {
      // Chuẩn bị URL và tham số query nếu có findPartnerPostId
      final String endpoint = ApiConstants.createDirectChatRoomToUser(userId);
      Map<String, dynamic>? queryParams;
      
      if (findPartnerPostId != null) {
        queryParams = {'findPartnerPostId': findPartnerPostId};
      }
      
      final response = await dio.post(
        '${ApiConstants.baseUrl}$endpoint',
        queryParameters: queryParams,
      );
      
      final chatRoomInfo = ChatRoomInfo.fromJson(response.data);
      return Success(chatRoomInfo);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to create direct chat room to user');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<ChatRoomInfo>> getChatRoomInfo(String chatRoomId) async {
    try {
      final response = await dio.get('${ApiConstants.baseUrl}${ApiConstants.getChatRoomInfo(chatRoomId)}');
      
      // Handle non-Map response
      if (response.data is String) {
        debugPrint('⚠️ [ChatRoomRepository] getChatRoomInfo returned a String instead of JSON: ${response.data}');
        return Failure('Invalid response format');
      }
      
      if (!(response.data is Map<String, dynamic>)) {
        debugPrint('⚠️ [ChatRoomRepository] getChatRoomInfo returned unexpected type: ${response.data.runtimeType}');
        return Failure('Unexpected response format');
      }
      
      final chatRoomInfo = ChatRoomInfo.fromJson(response.data);
      return Success(chatRoomInfo);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get chat room info');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }
}