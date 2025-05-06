import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import 'package:roomily/data/repositories/google_places_repository.dart';
import 'package:roomily/data/models/place_details.dart' as google_places;
import 'package:get_it/get_it.dart';

class SearchResult {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final String placeType;
  final Map<String, dynamic>? matchCode;

  SearchResult({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.placeType,
    this.matchCode,
  });

  // Tạo từ kết quả Google Places Autocomplete
  factory SearchResult.fromGooglePlaceAutocomplete(Map<String, dynamic> result, google_places.PlaceDetails details) {
    return SearchResult(
      id: result['place_id'] ?? '',
      name: result['structured_formatting']?['main_text'] ?? result['description'] ?? '',
      address: result['description'] ?? '',
      latitude: details.latitude,
      longitude: details.longitude,
      placeType: 'address', // Google Places không cung cấp loại địa điểm chi tiết như Mapbox
    );
  }

  // Tạo từ Google Place Details
  factory SearchResult.fromGooglePlaceDetails(google_places.PlaceDetails details) {
    return SearchResult(
      id: details.placeId,
      name: details.name,
      address: details.formattedAddress,
      latitude: details.latitude,
      longitude: details.longitude,
      placeType: 'address',
    );
  }

  // Giữ phương thức từ JSON cho khả năng tương thích ngược
  factory SearchResult.fromJson(Map<String, dynamic> json) {
    final geometry = json['geometry'] as Map<String, dynamic>? ?? {};
    final coordinates = geometry['coordinates'] as List<dynamic>? ?? [];
    final properties = json['properties'] as Map<String, dynamic>? ?? {};
    
    String placeType = properties['feature_type'] ?? '';
    String name = properties['name'] ?? '';
    String detailedAddress = properties['full_address'] ?? '';

    return SearchResult(
      id: json['id'] as String? ?? '',
      name: name,
      address: detailedAddress,
      longitude: coordinates.isNotEmpty ? (coordinates[0] as num).toDouble() : 0.0,
      latitude: coordinates.length > 1 ? (coordinates[1] as num).toDouble() : 0.0,
      placeType: placeType,
      matchCode: properties['match_code'] as Map<String, dynamic>?,
    );
  }
}

class SearchService {
  final Dio _dio = Dio();
  final String _accessToken;
  final GooglePlacesRepository _googlePlacesRepository;

  SearchService({required String accessToken})
      : _accessToken = accessToken,
        _googlePlacesRepository = GetIt.instance<GooglePlacesRepository>();

  Future<List<SearchResult>> searchPlaces(String query) async {
    try {
      if (query.isEmpty) return [];

      // Sử dụng Google Places API để tìm kiếm
      final autocompleteResults = await _googlePlacesRepository.getPlaceAutocomplete(query);
      final results = <SearchResult>[];

      // Lấy chi tiết cho từng kết quả tìm kiếm
      for (var result in autocompleteResults) {
        try {
          final details = await _googlePlacesRepository.getPlaceDetails(result.placeId);
          if (details != null) {
            results.add(SearchResult.fromGooglePlaceDetails(details));
          }
        } catch (e) {
          debugPrint('Lỗi khi lấy chi tiết địa điểm: $e');
        }
      }

      return results;
    } catch (e) {
      debugPrint('Lỗi khi tìm kiếm địa điểm: $e');
      return [];
    }
  }

  // Tìm kiếm có cấu trúc để tìm địa chỉ chính xác hơn
  Future<List<SearchResult>> searchStructured({
    String? houseNumber,
    String? street,
    String? neighborhood,
    String? district,
    String? place,
    String? region,
  }) async {
    try {
      // Tạo chuỗi truy vấn từ các phần địa chỉ
      final List<String> addressParts = [];
      if (houseNumber != null) addressParts.add(houseNumber);
      if (street != null) addressParts.add(street);
      if (neighborhood != null) addressParts.add(neighborhood);
      if (district != null) addressParts.add(district);
      if (place != null) addressParts.add(place);
      if (region != null) addressParts.add(region);
      
      final String query = addressParts.join(', ');
      if (query.isEmpty) return [];
      
      // Sử dụng tìm kiếm thông thường với chuỗi truy vấn đã tạo
      return await searchPlaces(query);
    } catch (e) {
      debugPrint('Lỗi khi tìm kiếm địa điểm có cấu trúc: $e');
      return [];
    }
  }

  Future<SearchResult?> getPlaceDetails(String placeId) async {
    try {
      final details = await _googlePlacesRepository.getPlaceDetails(placeId);
      if (details != null) {
        return SearchResult.fromGooglePlaceDetails(details);
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khi lấy chi tiết địa điểm: $e');
      return null;
    }
  }

  // Reverse geocoding sử dụng Google Places API
  Future<SearchResult?> reverseGeocode(double longitude, double latitude) async {
    try {
      // Sử dụng Google Places API để reverse geocode - chú ý thứ tự lat,lng
      final result = await _googlePlacesRepository.reverseGeocode(latitude, longitude);
      if (result != null) {
        return SearchResult.fromGooglePlaceDetails(result);
      }
      return null;
    } catch (e) {
      debugPrint('Lỗi khi reverse geocoding: $e');
      return null;
    }
  }
} 