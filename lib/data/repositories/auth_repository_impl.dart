import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/services/secure_storage_service.dart';
import 'package:roomily/data/models/login_request.dart';
import 'package:roomily/data/models/login_response.dart';
import 'package:roomily/data/models/register_request.dart';
import 'package:roomily/data/repositories/auth_repository.dart';


class AuthRepositoryImpl implements AuthRepository {
  final Dio dio;
  final SecureStorageService secureStorage;

  AuthRepositoryImpl({
    required this.dio,
    required this.secureStorage,
  });

  @override
  Future<LoginResponse> login(LoginRequest loginRequest) async {
    try {
      final response = await dio.post(
        ApiConstants.baseUrl + ApiConstants.login(),
        data: loginRequest.toJson(),
      );

      final loginResponse = LoginResponse.fromJson(response.data);

      if (kDebugMode) {
        print('🔐 [AuthRepository] Login response: ${loginResponse.username}');
        print('🔐 [AuthRepository] User roles: ${loginResponse.role.join(", ")}');
      } 

      // Save auth data
      await saveUserToken(loginResponse.accessToken);
      await saveUserRole(loginResponse.role);
      await saveUserId(loginResponse.userId);
      await saveUsername(loginResponse.username);

      return loginResponse;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthRepository] Login error: $e');
      }

      if (e is DioException) {
        // Handle specific API errors
        if (e.response?.statusCode == 401) {
          throw Exception('Tên đăng nhập hoặc mật khẩu không đúng');
        } else if (e.response?.statusCode == 403) {
          throw Exception('Tài khoản bị khóa hoặc không có quyền truy cập');
        }
      }
      throw Exception('Đăng nhập thất bại: ${e.toString()}');
    }
  }

  @override
  Future<bool> register(RegisterRequest registerRequest) async {
    try {
      if (kDebugMode) {
        print('🔐 [AuthRepository] Registering new user: ${registerRequest.username}');
      }

      final response = await dio.post(
        ApiConstants.baseUrl + ApiConstants.register(),
        data: registerRequest.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('✅ [AuthRepository] Registration successful');
        }
        return true;
      } else {
        if (kDebugMode) {
          print('❌ [AuthRepository] Registration failed: ${response.statusCode}');
        }
        return false;
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthRepository] Registration error: $e');
      }

      if (e is DioException) {
        // Handle specific API errors
        if (e.response?.statusCode == 400) {
          throw Exception('Thông tin đăng ký không hợp lệ hoặc đã tồn tại');
        } else if (e.response?.statusCode == 409) {
          throw Exception('Tên đăng nhập hoặc email đã tồn tại');
        }
      }
      throw Exception('Đăng ký thất bại: ${e.toString()}');
    }
  }

  @override
  Future<void> saveUserToken(String token) async {
    if (kDebugMode) {
      print('🔐 [AuthRepository] Saving token');
    }
    await secureStorage.saveToken(token);
  }

  @override
  Future<void> saveUserRole(List<String> roles) async {
    if (kDebugMode) {
      print('🔐 [AuthRepository] Saving roles: ${roles.join(", ")}');
    }
    await secureStorage.saveRoles(roles);
  }

  @override
  Future<void> saveUserId(String userId) async {
    if (kDebugMode) {
      print('🔐 [AuthRepository] Saving userId: $userId');
    }
    await secureStorage.saveUserId(userId);
  }

  @override
  Future<void> saveUsername(String username) async {
    await secureStorage.saveUsername(username);
  }

  @override
  Future<void> clearAuthData() async {
    if (kDebugMode) {
      print('🔐 [AuthRepository] Clearing auth data');
    }
    await secureStorage.clearAuthData();
  }

  @override
  Future<bool> isAuthenticated() async {
    return await secureStorage.isAuthenticated();
  }

  @override
  Future<List<String>> getUserRoles() async {
    final roles = await secureStorage.getRoles();
    if (kDebugMode) {
      print('🔐 [AuthRepository] Getting user roles: ${roles.join(", ")}');
    }
    return roles;
  }

  @override
  Future<String?> getUserToken() async {
    return await secureStorage.getToken();
  }

  @override
  Future<String?> getUserId() async {
    return await secureStorage.getUserId();
  }

  @override
  Future<String?> getUsername() async {
    return await secureStorage.getUsername();
  }

  @override
  Future<void> logout() async {
    try{
      if (kDebugMode) {
        print('🔐 [AuthRepository] Logging out');
      }
      await dio.post(ApiConstants.logout());
      if(kDebugMode) {
        print('🔐 [AuthRepository] Logout successful');
      }
      // Clear auth data
      if(kDebugMode) {
        print('🔐 [AuthRepository] Clearing auth data after logout');
      }
      await secureStorage.clearAuthData();
      if (kDebugMode) {
        print('🔐 [AuthRepository] Auth data cleared');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthRepository] Logout error: $e');
      }
      throw Exception('Đăng xuất thất bại: ${e.toString()}');
    }

  }
}
