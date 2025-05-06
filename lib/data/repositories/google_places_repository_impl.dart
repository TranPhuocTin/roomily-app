import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/data/models/place_autocomplete_result.dart';
import 'package:roomily/data/models/place_details.dart';
import 'package:roomily/data/repositories/google_places_repository.dart';

class GooglePlacesRepositoryImpl implements GooglePlacesRepository {
  final Dio _dio;
  final String _apiKey;
  
  GooglePlacesRepositoryImpl({required String apiKey})
      : _apiKey = apiKey,
        _dio = Dio() {
    debugPrint('GooglePlacesRepositoryImpl được khởi tạo với API key: ${_apiKey.substring(0, 5)}...');
    
    _dio.interceptors.add(LogInterceptor(
      requestBody: true,
      responseBody: true,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));
  }
  
  @override
  Future<List<PlaceAutocompleteResult>> getPlaceAutocomplete(String input) async {
    if (input.isEmpty) return [];
    
    debugPrint('🔍 Gọi Places Autocomplete API với input: $input');
    final queryParams = {
      'input': input,
      'key': _apiKey,
      'language': 'vi',
      'components': 'country:vn',
      'types': 'geocode|establishment'
    };
    
    try {
      final response = await _dio.get(
        ApiConstants.autoCompletePlace(),
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final status = response.data['status'] as String? ?? '';
        
        if (status != 'OK' && status != 'ZERO_RESULTS') {
          debugPrint('⚠️ Google Places API trả về lỗi: $status');
          return [];
        }
        
        final predictions = (response.data['predictions'] as List<dynamic>?) ?? [];
        return predictions
            .map((prediction) => PlaceAutocompleteResult.fromJson(prediction as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi Places Autocomplete API: $e');
      return [];
    }
  }
  
  @override
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;
    
    final queryParams = {
      'place_id': placeId,
      'key': _apiKey,
      'language': 'vi',
      'fields': 'place_id,name,formatted_address,geometry',
    };
    
    try {
      final response = await _dio.get(
        ApiConstants.placeDetail(),
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final status = response.data['status'] as String? ?? '';
        
        if (status != 'OK') {
          debugPrint('⚠️ Google Places API trả về lỗi: $status');
          return null;
        }
        
        return PlaceDetails.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi Places Details API: $e');
      return null;
    }
  }
  
  @override
  Future<PlaceDetails?> reverseGeocode(double latitude, double longitude) async {
    debugPrint('🔍 Gọi Reverse Geocoding API với vị trí: $latitude, $longitude');
    
    final String baseUrl = 'https://maps.googleapis.com/maps/api/geocode/json';
    final queryParams = {
      'latlng': '$latitude,$longitude',
      'key': _apiKey,
      'language': 'vi',
      'result_type': 'street_address|route|political',
    };
    
    try {
      final response = await _dio.get(
        baseUrl,
        queryParameters: queryParams,
      );
      
      if (response.statusCode == 200) {
        final status = response.data['status'] as String? ?? '';
        
        if (status != 'OK') {
          debugPrint('⚠️ Google Geocoding API trả về lỗi: $status');
          return null;
        }
        
        final results = (response.data['results'] as List<dynamic>?) ?? [];
        if (results.isEmpty) {
          debugPrint('⚠️ Không có kết quả reverse geocoding');
          return null;
        }
        
        // Lấy kết quả đầu tiên
        final firstResult = results.first as Map<String, dynamic>;
        
        // Tạo đối tượng PlaceDetails từ kết quả geocoding
        return PlaceDetails(
          placeId: firstResult['place_id'] ?? '',
          name: _extractAddressComponent(firstResult, 'route') ?? 
                _extractAddressComponent(firstResult, 'neighborhood') ?? 
                'Vị trí hiện tại',
          formattedAddress: firstResult['formatted_address'] ?? '',
          latitude: latitude,
          longitude: longitude,
        );
      }
      return null;
    } catch (e) {
      debugPrint('❌ Lỗi khi gọi Reverse Geocoding API: $e');
      return null;
    }
  }
  
  // Helper method để trích xuất thành phần địa chỉ từ kết quả của Google Geocoding API
  String? _extractAddressComponent(Map<String, dynamic> result, String type) {
    final components = (result['address_components'] as List<dynamic>?) ?? [];
    for (final component in components) {
      final types = (component['types'] as List<dynamic>?) ?? [];
      if (types.contains(type)) {
        return component['long_name'] as String?;
      }
    }
    return null;
  }
} 