import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/auth_service.dart';

class AuthTokenInterceptor extends Interceptor {
  final List<String> _publicEndpoints = [
    'auth/login',
    'auth/register',
    'auth/forgot-password'
  ];

  // Kiểm tra xem endpoint có yêu cầu xác thực hay không
  bool _requiresAuthentication(String path) {
    return !_publicEndpoints.any((endpoint) => path.contains(endpoint));
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final bool needsAuth = _requiresAuthentication(options.path);
    
    if (needsAuth) {
      try {
        // Lấy AuthService từ GetIt
        if (GetIt.I.isRegistered<AuthService>()) {
          final authService = GetIt.I<AuthService>();
          
          // Luôn lấy token mới nhất từ AuthService
          final token = authService.token;
          
          if (token != null && token.isNotEmpty) {
            // Xóa token cũ nếu có
            options.headers.remove('Authorization');
            // Thêm token mới vào header
            options.headers['Authorization'] = 'Bearer $token';
            if (kDebugMode) {
              print('🔐 [AuthTokenInterceptor] Đã thêm token mới vào request: ${options.uri}');
            }
          } else {
            if (kDebugMode) {
              print('⚠️ [AuthTokenInterceptor] Yêu cầu API cần xác thực nhưng không có token: ${options.uri}');
            }
          }
        } else {
          if (kDebugMode) {
            print('⚠️ [AuthTokenInterceptor] AuthService chưa được đăng ký trong GetIt');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('❌ [AuthTokenInterceptor] Lỗi khi thêm token: $e');
        }
      }
    } else {
      // Đảm bảo xóa token cho các endpoint không cần xác thực
      options.headers.remove('Authorization');
      if (kDebugMode) {
        print('🔓 [AuthTokenInterceptor] Request không cần token: ${options.uri}');
      }
    }
    
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      if (kDebugMode) {
        print('🚫 [AuthTokenInterceptor] Token không hợp lệ hoặc hết hạn');
      }
      
      // Xử lý logout nếu không phải là request đăng nhập
      if (_requiresAuthentication(err.requestOptions.path)) {
        _handleTokenExpired();
      }
    }
    
    handler.next(err);
  }
  
  void _handleTokenExpired() {
    try {
      if (GetIt.I.isRegistered<AuthService>()) {
        final authService = GetIt.I<AuthService>();
        authService.logout();
        if (kDebugMode) {
          print('🔄 [AuthTokenInterceptor] Đã đăng xuất do token hết hạn');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthTokenInterceptor] Lỗi khi xử lý token hết hạn: $e');
      }
    }
  }
} 