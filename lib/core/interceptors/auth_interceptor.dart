// import 'package:dio/dio.dart';
// import 'package:flutter/material.dart';
// import 'package:get_it/get_it.dart';
// import 'package:roomily/core/services/secure_storage_service.dart';
//
// import '../../data/blocs/auth/auth_cubit.dart';
//
// /// Interceptor để tự động thêm token xác thực vào header của mỗi request
// class AuthInterceptor extends Interceptor {
//   // Danh sách các endpoint không cần xác thực
//   final List<String> _publicEndpoints = [
//     'auth/login',
//     'auth/register',
//     'auth/forgot-password'
//   ];
//
//   // Kiểm tra xem endpoint có yêu cầu xác thực hay không
//   bool _requiresAuthentication(String path) {
//     return !_publicEndpoints.any((endpoint) => path.contains(endpoint));
//   }
//
//   @override
//   void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
//     final bool needsAuth = _requiresAuthentication(options.path);
//
//     if (needsAuth) {
//       try {
//         // Lấy token từ secure storage với cơ chế retry
//         final secureStorage = GetIt.I<SecureStorageService>();
//         String? token = await _getTokenWithRetry(secureStorage);
//
//         if (token != null && token.isNotEmpty) {
//           // Thêm token vào header
//           options.headers['Authorization'] = 'Bearer $token';
//           debugPrint('🔐 Đã thêm token vào request: ${options.uri}');
//         } else {
//           debugPrint('⚠️ Yêu cầu API cần xác thực nhưng không có token: ${options.uri}');
//
//           // Có thể quay về màn hình đăng nhập ở đây nếu cần
//           // Tuy nhiên, tốt hơn là nên xử lý lỗi 401 trong onError
//         }
//       } catch (e) {
//         debugPrint('❌ Lỗi khi lấy token: $e');
//       }
//     } else {
//       debugPrint('🔓 Request không cần token: ${options.uri}');
//     }
//
//     handler.next(options);
//   }
//
//   /// Cố gắng lấy token với cơ chế thử lại
//   Future<String?> _getTokenWithRetry(SecureStorageService secureStorage, {int maxRetries = 3}) async {
//     String? token;
//     int attempts = 0;
//
//     while (attempts < maxRetries) {
//       token = await secureStorage.getToken();
//
//       if (token != null && token.isNotEmpty) {
//         if (attempts > 0) {
//           debugPrint('✅ Lấy token thành công sau ${attempts + 1} lần thử');
//         }
//         return token;
//       }
//
//       // Chờ một chút trước khi thử lại
//       attempts++;
//       if (attempts < maxRetries) {
//         debugPrint('⏳ Thử lấy token lần ${attempts + 1}/$maxRetries sau 100ms...');
//         await Future.delayed(Duration(milliseconds: 100));
//       }
//     }
//
//     debugPrint('⚠️ Không thể lấy token sau $maxRetries lần thử');
//     return token;
//   }
//
//   @override
//   void onResponse(Response response, ResponseInterceptorHandler handler) {
//     debugPrint('✅ Response [${response.statusCode}] ${response.requestOptions.uri}');
//     handler.next(response);
//   }
//
//   @override
//   void onError(DioException err, ErrorInterceptorHandler handler) {
//     debugPrint('❌ Error [${err.response?.statusCode}] ${err.requestOptions.uri}: ${err.message}');
//
//     // Xử lý lỗi 401 Unauthorized (token hết hạn hoặc không hợp lệ)
//     if (err.response?.statusCode == 401) {
//       debugPrint('🚫 Token không hợp lệ hoặc hết hạn');
//
//       // Nếu là endpoint đăng nhập thì không cần xử lý đặc biệt
//       if (!_requiresAuthentication(err.requestOptions.path)) {
//         debugPrint('👉 Đây là endpoint đăng nhập, trả về lỗi thông thường');
//         return handler.next(err);
//       }
//
//       // Xử lý token hết hạn
//       _handleTokenExpired();
//     }
//
//     return handler.next(err);
//   }
//
//   // Phương thức để xử lý khi token hết hạn
//   void _handleTokenExpired() async {
//     try {
//       final secureStorage = GetIt.I<SecureStorageService>();
//       await secureStorage.clearAuthData();
//       debugPrint('🔄 Đã xóa dữ liệu xác thực, cần đăng nhập lại');
//
//       // Sử dụng AuthCubit để đăng xuất
//       try {
//         final authCubit = GetIt.I<AuthCubit>();
//         authCubit.logout();
//         debugPrint('🔄 Đã đăng xuất qua AuthCubit');
//       } catch (e) {
//         debugPrint('❌ Không thể sử dụng AuthCubit để đăng xuất: $e');
//       }
//
//     } catch (e) {
//       debugPrint('❌ Lỗi khi xử lý token hết hạn: $e');
//     }
//   }
// }