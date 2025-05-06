import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:diacritic/diacritic.dart';

class LocationService {
  final Dio _dio = Dio();
  final String _baseUrl = 'https://provinces.open-api.vn/api';
  
  // Lưu trữ vị trí cuối cùng để tránh phải lấy lại nếu đã có
  Position? _lastKnownPosition;
  // Thời gian tối đa để lấy vị trí (ms)
  static const int _locationTimeout = 5000;

  // Kiểm tra và yêu cầu quyền truy cập vị trí
  Future<bool> _checkLocationPermission() async {
    // Kiểm tra quyền truy cập vị trí
    final status = await Permission.location.status;
    
    if (status.isGranted) {
      return true;
    }
    
    // Nếu chưa có quyền, yêu cầu quyền
    final result = await Permission.location.request();
    return result.isGranted;
  }

  // Lấy vị trí hiện tại
  Future<Position?> getCurrentPosition() async {
    try {
      // Nếu đã có vị trí gần đây (trong vòng 1 phút), trả về luôn
      if (_lastKnownPosition != null) {
        final now = DateTime.now();
        final positionTime = _lastKnownPosition!.timestamp ?? DateTime.now();
        final difference = now.difference(positionTime);
        
        // Nếu vị trí lấy được trong vòng 1 phút, trả về luôn
        if (difference.inSeconds < 60) {
          return _lastKnownPosition;
        }
      }
      
      // Kiểm tra quyền truy cập vị trí
      final hasPermission = await _checkLocationPermission();
      if (!hasPermission) {
        return null;
      }
      
      // Kiểm tra xem dịch vụ vị trí có được bật không
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) {
        // Yêu cầu người dùng bật dịch vụ vị trí
        await Geolocator.openLocationSettings();
        return null;
      }
      
      // Lấy vị trí với timeout
      _lastKnownPosition = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: Duration(milliseconds: _locationTimeout),
      ).catchError((error) {
        // Nếu timeout, thử lấy vị trí cuối cùng đã biết
        return Geolocator.getLastKnownPosition();
      });
      
      return _lastKnownPosition;
    } catch (e) {
      print('Lỗi khi lấy vị trí: $e');
      return null;
    }
  }

  // Lấy danh sách tỉnh/thành phố
  Future<List<Map<String, dynamic>>> getProvinces() async {
    try {
      final response = await _dio.get('$_baseUrl/p/');
      if (response.statusCode == 200) {
        final provinces = List<Map<String, dynamic>>.from(response.data);

        for (var province in provinces) {
          String name = province['name'] as String;

          if (name.startsWith('Thành phố ')) {
            name = name.replaceFirst('Thành phố ', '');
          }

          if (name.startsWith('Tỉnh ')) {
            name = name.replaceFirst('Tỉnh ', '');
          }

          province['original_name'] = province['name'];
          province['name'] = name;
        }

        // Sắp xếp không dấu để đúng quy tắc tiếng Việt
        provinces.sort((a, b) =>
            removeDiacritics(a['name'] as String)
                .compareTo(removeDiacritics(b['name'] as String)));

        return provinces;
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching provinces: $e');
      return [];
    }
  }



  // Lấy danh sách quận/huyện theo mã tỉnh/thành phố
  Future<List<Map<String, dynamic>>> getDistricts(int provinceCode) async {
    try {
      final response = await _dio.get('$_baseUrl/p/$provinceCode?depth=2');
      if (response.statusCode == 200 && response.data['districts'] != null) {
        return List<Map<String, dynamic>>.from(response.data['districts']);
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching districts: $e');
      return [];
    }
  }
  
  // Lấy mã tỉnh/thành phố từ tên
  Future<int?> getProvinceCode(String provinceName) async {
    try {
      final provinces = await getProvinces();
      final province = provinces.firstWhere(
        (p) => p['name'].toString().toLowerCase() == provinceName.toLowerCase(),
        orElse: () => {'code': null},
      );
      return province['code'] as int?;
    } catch (e) {
      debugPrint('Error getting province code: $e');
      return null;
    }
  }
  
  // Lấy danh sách phường/xã theo mã quận/huyện
  Future<List<Map<String, dynamic>>> getWards(int districtCode) async {
    debugPrint('🔍 Fetching wards for district code: $districtCode');
    try {
      final response = await _dio.get('$_baseUrl/d/$districtCode?depth=2');
      if (response.statusCode == 200) {
        debugPrint('✅ API response received for district $districtCode');
        if (response.data['wards'] != null) {
          final wards = List<Map<String, dynamic>>.from(response.data['wards']);
          debugPrint('✅ Found ${wards.length} wards for district $districtCode');
          return wards;
        } else {
          debugPrint('⚠️ Response does not contain "wards" field: ${response.data}');
          return [];
        }
      } else {
        debugPrint('⚠️ API returned status code ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error fetching wards: $e');
      return [];
    }
  }
} 