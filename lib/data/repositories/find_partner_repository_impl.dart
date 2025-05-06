import 'package:dio/dio.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/find_partner_post.dart';
import 'package:roomily/data/models/find_partner_post_create.dart';
import 'package:roomily/data/models/rental_request.dart';
import 'package:roomily/data/models/find_partner_post_detail.dart';
import 'package:roomily/data/repositories/find_partner_repository.dart';

import '../../core/config/dio_config.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';

class FindPartnerRepositoryImpl extends FindPartnerRepository {
  final Dio _dio;
  
  FindPartnerRepositoryImpl({Dio? dio}) 
      : _dio = dio ?? (GetIt.I.isRegistered<Dio>() 
          ? GetIt.I<Dio>() 
          : DioConfig.createDio());
  
  @override
  Future<void> createFindPartner({required FindPartnerPostCreate findPartnerPostCreate}) async {
    try {
      if (kDebugMode) {
        print('🔍 [FindPartnerRepository] Sending createFindPartner request with headers: ${_dio.options.headers}');
      }
      
      await _dio.post(
        ApiConstants.createFindPartnerPost(),
        data: findPartnerPostCreate.toJson(),
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [FindPartnerRepository] Error creating find partner post: $e');
      }
      throw Exception('Failed to create find partner post: $e');
    }
  }

  @override
  Future<Result<List<FindPartnerPost>>> getFindPartners({required String roomId}) async {
    try {
      final response = await _dio.get(ApiConstants.getFindPartnerPosts(roomId));
      if (response.statusCode == 200) {
        final List<FindPartnerPost> findPartnerPostsList = (response.data as List)
            .map((e) => FindPartnerPost.fromJson(e))
            .toList();
        return Success(findPartnerPostsList);
      } else {
        return Failure('Failed to load find partner posts');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
  
  @override
  Future<Result<bool>> checkUserInFindPartnerPost({required String userId, required String roomId}) async {
    try {
      final response = await _dio.get(ApiConstants.checkUserInFindPartnerPost(userId, roomId));
      if (response.statusCode == 200) {
        return Success(response.data as bool);
      } else {
        return Failure('Failed to check if user is in find partner post');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
  
  @override
  Future<Result<List<FindPartnerPost>>> getActiveFindPartnerPosts() async {
    try {
      final response = await _dio.get(ApiConstants.getActiveFindPartnerPosts());
      if (response.statusCode == 200) {
        final List<FindPartnerPost> findPartnerPostsList = (response.data as List)
            .map((e) => FindPartnerPost.fromJson(e))
            .toList();
        return Success(findPartnerPostsList);
      } else {
        return Failure('Failed to load active find partner posts');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
  
  @override
  Future<Result<RentalRequest>> sendFindPartnerRequest({
    required String findPartnerPostId,
    required String chatRoomId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.requestToJoinFindPartnerPost(),
        data: {
          'findPartnerPostId': findPartnerPostId,
          'chatRoomId': chatRoomId,
        },
      );
      
      if (response.statusCode == 200) {
        return Success(RentalRequest.fromJson(response.data));
      } else {
        return Failure('Failed to send find partner request');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
  
  @override
  Future<Result<bool>> acceptFindPartnerRequest(String chatRoomId) async {
    try {
      final response = await _dio.post(
        ApiConstants.requestToAcceptFindPartnerPost(chatRoomId),
      );
      
      if (response.statusCode == 200) {
        return const Success(true);
      } else {
        return Failure('Failed to accept find partner request');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
  
  @override
  Future<Result<bool>> rejectFindPartnerRequest(String chatRoomId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.requestToRejectFindPartnerPost(chatRoomId),
      );
      
      if (response.statusCode == 200) {
        return const Success(true);
      } else {
        return Failure('Failed to reject find partner request');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
  
  @override
  Future<Result<bool>> cancelFindPartnerRequest(String chatRoomId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.requestToCancelFindPartnerPost(chatRoomId),
      );
      
      if (response.statusCode == 200) {
        return const Success(true);
      } else {
        return Failure('Failed to cancel find partner request');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
  
  @override
  Future<Result<bool>> updateFindPartnerPost({
    required String findPartnerPostId,
    String? description,
    int? maxPeople,
  }) async {
    try {
      final Map<String, dynamic> updateData = {};
      
      // Chỉ thêm các trường không null vào request body
      if (description != null) {
        updateData['description'] = description;
      }
      
      if (maxPeople != null) {
        updateData['maxPeople'] = maxPeople;
      }
      
      final response = await _dio.put(
        ApiConstants.updateFindPartnerPost(findPartnerPostId),
        data: updateData,
      );
      
      // Chỉ cần kiểm tra status code mà không quan tâm đến response body
      if (response.statusCode == 200) {
        return const Success(true);
      } else {
        return Failure('Failed to update find partner post');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
  
  @override
  Future<FindPartnerPostDetail> getFindPartnerPostDetail(String postId) async {
    try {
      final response = await _dio.get(ApiConstants.getFindPartnerPostDetail(postId));
      
      if (response.statusCode == 200) {
        return FindPartnerPostDetail.fromJson(response.data);
      } else {
        throw Exception('Failed to load find partner post detail');
      }
    } catch (e) {
      throw Exception('Error getting find partner post detail: $e');
    }
  }
  
  @override
  Future<Result<bool>> removeParticipant({required String findPartnerPostId, required String userId}) async {
    try {
      final response = await _dio.delete(
        ApiConstants.removeParticipant(findPartnerPostId, userId),
        queryParameters: {
          'participantId': userId
        },
      );
      
      if (response.statusCode == 200) {
        return const Success(true);
      } else {
        return Failure('Failed to remove participant from find partner post');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
  
  @override
  Future<Result<bool>> exitFindPartnerPost(String findPartnerPostId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.exitFindPartnerPost(findPartnerPostId),
      );
      
      if (response.statusCode == 200) {
        return const Success(true);
      } else {
        return Failure('Failed to exit find partner post');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
  
  @override
  Future<Result<bool>> addParticipant({
    required String findPartnerPostId,
    required String privateId,
  }) async {
    try {
      final response = await _dio.post(
        ApiConstants.addParticipant(findPartnerPostId),
        queryParameters: {
          'privateId': privateId
        },
      );
      
      if (response.statusCode == 200) {
        return const Success(true);
      } else {
        return Failure('Failed to add participant to find partner post');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }

  @override
  Future<Result<bool>> deleteFindPartnerPost(String findPartnerPostId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.deleteFindPartnerPost(findPartnerPostId),
      );
      
      if (response.statusCode == 200) {
        return const Success(true);
      } else {
        return Failure('Failed to delete find partner post');
      }
    } catch (e) {
      return Failure('Error: $e');
    }
  }
}