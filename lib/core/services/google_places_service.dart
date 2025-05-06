import 'package:roomily/data/models/place_autocomplete_result.dart';
import 'package:roomily/data/models/place_details.dart';
import 'package:roomily/data/repositories/google_places_repository.dart';
import 'package:flutter/foundation.dart';

class GooglePlacesService {
  final GooglePlacesRepository _repository;
  
  GooglePlacesService({required GooglePlacesRepository repository})
      : _repository = repository;
  
  Future<List<PlaceAutocompleteResult>> getPlaceAutocomplete(String input) async {
    if (input.isEmpty) return [];
    
    debugPrint('🔍 GooglePlacesService: Gọi getPlaceAutocomplete với input: $input');
    
    try {
      final results = await _repository.getPlaceAutocomplete(input);
      debugPrint('✅ GooglePlacesService: Nhận được ${results.length} kết quả');
      return results;
    } catch (e) {
      debugPrint('❌ GooglePlacesService: Lỗi khi tìm kiếm địa điểm: $e');
      return [];
    }
  }
  
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    if (placeId.isEmpty) return null;
    
    debugPrint('🔍 GooglePlacesService: Gọi getPlaceDetails với placeId: $placeId');
    
    try {
      final details = await _repository.getPlaceDetails(placeId);
      if (details != null) {
        debugPrint('✅ GooglePlacesService: Đã lấy được thông tin địa điểm: ${details.name}');
      } else {
        debugPrint('⚠️ GooglePlacesService: Không tìm thấy thông tin cho placeId: $placeId');
      }
      return details;
    } catch (e) {
      debugPrint('❌ GooglePlacesService: Lỗi khi lấy chi tiết địa điểm: $e');
      return null;
    }
  }
  
  // Phương thức để thực hiện reverse geocoding
  Future<PlaceDetails?> reverseGeocode(double latitude, double longitude) async {
    debugPrint('🔍 GooglePlacesService: Gọi reverseGeocode với vị trí: $latitude, $longitude');
    
    try {
      final details = await _repository.reverseGeocode(latitude, longitude);
      if (details != null) {
        debugPrint('✅ GooglePlacesService: Đã lấy được địa chỉ từ vị trí: ${details.formattedAddress}');
      } else {
        debugPrint('⚠️ GooglePlacesService: Không thể lấy địa chỉ từ vị trí: $latitude, $longitude');
      }
      return details;
    } catch (e) {
      debugPrint('❌ GooglePlacesService: Lỗi khi thực hiện reverse geocoding: $e');
      return null;
    }
  }
} 