import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/user.dart';
import 'package:roomily/data/repositories/user_repository.dart';

import '../../core/config/dio_config.dart';

class UserRepositoryImpl extends UserRepository {
  final Dio _dio;

  UserRepositoryImpl({Dio? dio}) : _dio = dio ?? GetIt.instance<Dio>();

  @override
  Future<Result<User>> getCurrentUserInfo() async {
    try {
      final result = await _dio.get(ApiConstants.getCurrentUserInfo());

      if (result.statusCode == 200) {
        final user = User.fromJson(result.data);
        return Success(user);
      }

      return Failure('Failed to get user info');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get user info');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<User>> getUserInfo(String userId) async {
    try {
      final result = await _dio.get(ApiConstants.getUser(userId));

      if (result.statusCode == 200) {
        final user = User.fromJson(result.data);
        return Success(user);
      }

      return Failure('Failed to get user info');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to get user info');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> updateUserInfo(User user) async {
    try {
      final _formData = FormData.fromMap({
        'fullName': user.fullName,
        'email': user.email,
        'phone': user.phone,
        'address': user.address,
      });
      final result = await _dio.put(
        ApiConstants.updateUser(),
        data: _formData,
      );

      if (result.statusCode != 200) {
        throw Exception('Failed to update user info');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to update user info');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> updateUserAvatar(String profilePicturePath) async {
    try {
      // Tạo MultipartFile từ đường dẫn file hình ảnh
      final file = await MultipartFile.fromFile(
        profilePicturePath,
        filename: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );
      
      final _formData = FormData.fromMap({
        'profilePicture': file,  // Gửi file thay vì chuỗi
      });
      
      final result = await _dio.put(
        ApiConstants.updateUser(),
        data: _formData,
      );

      if (result.statusCode != 200) {
        throw Exception('Failed to update user avatar');
      }
    } on DioException catch (e) {
      throw Exception(e.message ?? 'Failed to update user avatar');
    } catch (e) {
      throw Exception('An unexpected error occurred: $e');
    }
  }

  @override
  Future<void> registerFcmToken(String userId, String token) async {
    try {
      final url = '${ApiConstants.baseUrl}api/user-devices/register';
      debugPrint('📱 [FCM-Repository] Đang gửi request đăng ký token');
      debugPrint('📱 [FCM-Repository] URL: $url');
      debugPrint('📱 [FCM-Repository] Data: userId=$userId, fcmToken=${token.substring(0, 10)}..., deviceType=${Platform.isAndroid ? 'ANDROID' : 'IOS'}');
      
      final response = await _dio.post(
        url,
        data: {
          'userId': userId,
          'fcmToken': token,
          'deviceType': Platform.isAndroid ? 'ANDROID' : 'IOS',
        },
      );
      debugPrint('📱 [FCM-Repository] Kết quả đăng ký token: ${response.data}');
      
      debugPrint('📱 [FCM-Repository] Kết quả đăng ký token: ${response.statusCode}');
      debugPrint('📱 [FCM-Repository] Response data: ${response.data}');
      debugPrint('📱 [FCM-Repository] FCM token đăng ký thành công cho user $userId');
    } catch (e) {
      debugPrint('📱 [FCM-Repository] ❌ Lỗi khi đăng ký FCM token: $e');
      // Xử lý lỗi nhưng không ném lại ngoại lệ để không
      // làm gián đoạn luồng của ứng dụng
    }
  }
}