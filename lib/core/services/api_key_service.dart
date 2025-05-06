import 'package:flutter/foundation.dart';

/// Service để quản lý các API key của ứng dụng
class ApiKeyService {
  // Lấy Google Maps API key từ biến môi trường
  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
  );

  // Lấy Access Token từ biến môi trường
  static const String accessToken = String.fromEnvironment(
    'ACCESS_TOKEN',
  );

  // Kiểm tra xem API key có hợp lệ không
  static bool isValidGoogleMapsApiKey() {
    return googleMapsApiKey.isNotEmpty && 
           googleMapsApiKey != 'YOUR_API_KEY_HERE';
  }

  // Kiểm tra xem Access Token có hợp lệ không
  static bool isValidAccessToken() {
    return accessToken.isNotEmpty;
  }

  // Log thông tin API key (chỉ trong debug mode)
  static void logApiKeyInfo() {
    if (kDebugMode) {
      debugPrint('🔑 Google Maps API Key: ${googleMapsApiKey.substring(0, 5)}...');
      debugPrint('🔑 Access Token: ${accessToken.isNotEmpty ? 'Present' : 'Missing'}');
    }
  }
} 