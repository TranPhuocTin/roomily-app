import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/utils/result.dart';

class RoomRecommendation {
  final String roomId;
  final double score;
  final bool isPromoted;
  final String? promotedRoomId;

  RoomRecommendation({
    required this.roomId,
    required this.score,
    required this.isPromoted,
    this.promotedRoomId,
  });
}

class PaginatedRecommendations {
  final List<RoomRecommendation> recommendations;
  final int total;
  final int page;
  final int pageSize;
  final int pages;

  PaginatedRecommendations({
    required this.recommendations,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  });

  // Helper method to get just the room IDs if needed
  List<String> get roomIds => recommendations.map((rec) => rec.roomId).toList();
}

abstract class RecommendationRepository {
  /// Lấy danh sách ID phòng được gợi ý cho người dùng với hỗ trợ phân trang
  Future<Result<PaginatedRecommendations>> getRecommendedRoomIds(
    String userId, {
    int? topK,
    int? page,
    int? pageSize,
  });

  Future<Result<PaginatedRecommendations>> getPromotedRooms(
    String userId);
}

class RecommendationRepositoryImpl implements RecommendationRepository {
  final Dio _dio;

  RecommendationRepositoryImpl({Dio? dio}) : _dio = dio ?? Dio();

  @override
  Future<Result<PaginatedRecommendations>> getRecommendedRoomIds(
    String userId, {
    int? topK,
    int? page,
    int? pageSize,
  }) async {
    try {
      debugPrint("🔍 Fetching recommended rooms for user $userId with topK=${topK ?? 'default'}, page=${page ?? 1}, pageSize=${pageSize ?? 10}");
      
      // Xử lý query params
      final queryParams = <String, dynamic>{};
      if (topK != null) {
        queryParams['top_k'] = topK;
      }
      if (page != null) {
        queryParams['page'] = page;
      }
      if (pageSize != null) {
        queryParams['page_size'] = pageSize;
      }
      
      final response = await _dio.get(
        '${ApiConstants.recommendBaseUrl}${ApiConstants.recommendRoomByUserId(userId)}',
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['data'] != null) {
          final responseData = data['data'];
          
          // Xử lý định dạng mới của dữ liệu phòng
          final List<dynamic> roomsDataRaw = responseData['data'] ?? [];
          final List<RoomRecommendation> recommendations = roomsDataRaw.map((item) {
            // Mỗi item là một mảng với 3 hoặc 4 phần tử: [roomId, score, isPromoted, promotedRoomId?]
            final String roomId = item[0].toString();
            final double score = double.parse(item[1].toString());
            final bool isPromoted = item[2] == 1;
            
            // Kiểm tra xem có promotedRoomId hay không
            String? promotedRoomId;
            if (isPromoted && item.length > 3 && item[3] != null) {
              promotedRoomId = item[3].toString();
              debugPrint("🏠 Found promoted room with ID: $roomId, promotedRoomId: $promotedRoomId");
            }
            
            return RoomRecommendation(
              roomId: roomId,
              score: score,
              isPromoted: isPromoted,
              promotedRoomId: promotedRoomId,
            );
          }).toList();
          
          // Trích xuất thông tin phân trang
          final int total = responseData['total'] ?? 0;
          final int currentPage = responseData['page'] ?? 1;
          final int currentPageSize = responseData['page_size'] ?? 10;
          final int totalPages = responseData['pages'] ?? 0;
          
          debugPrint("✅ Found ${recommendations.length} recommended rooms (page $currentPage/$totalPages)");
          
          return Success(PaginatedRecommendations(
            recommendations: recommendations,
            total: total,
            page: currentPage,
            pageSize: currentPageSize,
            pages: totalPages,
          ));
        }
        return Failure('Invalid response format');
      }
      
      return Failure('Failed to get recommended rooms: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint("❌ DioException: ${e.message}");
      return Failure(e.message ?? 'Failed to get recommended rooms');
    } catch (e) {
      debugPrint("❌ Exception: $e");
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<PaginatedRecommendations>> getPromotedRooms(String userId) async {
    try {
      debugPrint("🔍 Fetching promoted rooms for user $userId");
      
      final response = await _dio.get(
        '${ApiConstants.recommendBaseUrl}${ApiConstants.promotedRoomByUserId(userId)}',
      );
      
      if (response.statusCode == 200) {
        final data = response.data;
        if (data != null && data['data'] != null) {
          final responseData = data['data'];
          
          // Xử lý định dạng dữ liệu phòng được promoted
          final List<dynamic> roomsDataRaw = responseData['data'] ?? [];
          final List<RoomRecommendation> recommendations = roomsDataRaw.map((item) {
            // Mỗi item là một mảng với 4 phần tử: [roomId, score, isPromoted, promotedRoomId]
            final String roomId = item[0].toString();
            final double score = double.parse(item[1].toString());
            final bool isPromoted = item[2] == 1;
            
            // Lấy promotedRoomId
            String? promotedRoomId;
            if (isPromoted && item.length > 3 && item[3] != null) {
              promotedRoomId = item[3].toString();
              debugPrint("🏠 Found promoted room with ID: $roomId, promotedRoomId: $promotedRoomId");
            }
            
            return RoomRecommendation(
              roomId: roomId,
              score: score,
              isPromoted: isPromoted,
              promotedRoomId: promotedRoomId,
            );
          }).toList();
          
          // Trích xuất thông tin phân trang
          final int total = responseData['total'] ?? 0;
          final int currentPage = responseData['page'] ?? 1;
          final int currentPageSize = responseData['page_size'] ?? 10;
          final int totalPages = responseData['pages'] ?? 0;
          
          debugPrint("✅ Found ${recommendations.length} promoted rooms (page $currentPage/$totalPages)");
          
          return Success(PaginatedRecommendations(
            recommendations: recommendations,
            total: total,
            page: currentPage,
            pageSize: currentPageSize,
            pages: totalPages,
          ));
        }
        return Failure('Invalid response format');
      }
      
      return Failure('Failed to get promoted rooms: ${response.statusCode}');
    } on DioException catch (e) {
      debugPrint("❌ DioException when fetching promoted rooms: ${e.message}");
      return Failure(e.message ?? 'Failed to get promoted rooms');
    } catch (e) {
      debugPrint("❌ Exception when fetching promoted rooms: $e");
      return Failure('An unexpected error occurred: $e');
    }
  }
} 