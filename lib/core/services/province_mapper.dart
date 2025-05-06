import 'package:fuzzywuzzy/fuzzywuzzy.dart';
import 'package:roomily/core/services/location_service.dart';
import 'package:flutter/material.dart';
import 'package:diacritic/diacritic.dart';

class ProvinceMapper {
  final LocationService _locationService;
  List<Map<String, dynamic>>? _cachedProvinces;
  
  ProvinceMapper({required LocationService locationService}) 
      : _locationService = locationService;
  
  /// Loads provinces data if not already cached
  Future<List<Map<String, dynamic>>> _getProvinces() async {
    if (_cachedProvinces != null) {
      return _cachedProvinces!;
    }
    
    final provinces = await _locationService.getProvinces();
    _cachedProvinces = provinces;
    return provinces;
  }
  
  /// Normalizes text for better matching by:
  /// 1. Removing diacritics (accents)
  /// 2. Converting to lowercase
  /// 3. Removing common prefixes like "Thành phố", "Tỉnh"
  String _normalizeText(String text) {
    String normalized = removeDiacritics(text.toLowerCase());
    
    // Remove common prefixes
    normalized = normalized.replaceAll('thanh pho ', '');
    normalized = normalized.replaceAll('tinh ', '');
    normalized = normalized.replaceAll('city', '');
    normalized = normalized.replaceAll('province', '');
    
    // Remove additional articles and prepositions
    normalized = normalized.replaceAll(' of ', ' ');
    
    return normalized.trim();
  }
  
  /// Maps a province name from Google Places to the corresponding province in the API
  /// Returns the matched province as a Map, or null if no good match found
  Future<Map<String, dynamic>?> mapProvinceNameToApi(String placeName) async {
    if (placeName.isEmpty) return null;
    
    debugPrint('🔍 ProvinceMapper: Mapping "$placeName" to province API');
    
    try {
      final provinces = await _getProvinces();
      final normalizedPlaceName = _normalizeText(placeName);
      
      // Avoid processing empty or tiny strings
      if (normalizedPlaceName.length < 2) {
        return null;
      }
      
      // Create list of province names and prepare for matching
      final provinceNames = provinces.map((p) => p['name'].toString()).toList();
      
      // Prepare choices with normalized versions for comparison
      final normalizedProvinceNames = provinceNames
          .map((name) => _normalizeText(name))
          .toList();
      
      // Find the best match using token sort ratio
      int bestScore = 0;
      int bestIndex = -1;
      
      for (int i = 0; i < normalizedProvinceNames.length; i++) {
        final score = tokenSortRatio(
          normalizedPlaceName,
          normalizedProvinceNames[i],
        );
        
        if (score > bestScore) {
          bestScore = score;
          bestIndex = i;
        }
      }
      
      // Require at least 60% similarity
      if (bestScore >= 60 && bestIndex >= 0) {
        final matchedName = provinceNames[bestIndex];
        
        debugPrint('✅ ProvinceMapper: Matched "$placeName" to "$matchedName" with score: $bestScore');
        
        // Find the province object with the matched name
        final matchedProvince = provinces.firstWhere(
          (province) => province['name'] == matchedName,
          orElse: () => {},
        );
        
        if (matchedProvince.isNotEmpty) {
          return matchedProvince;
        }
      }
      
      debugPrint('⚠️ ProvinceMapper: No good match found for "$placeName"');
      return null;
    } catch (e) {
      debugPrint('❌ ProvinceMapper: Error mapping province name: $e');
      return null;
    }
  }
  
  /// Gets the province code from a province name
  Future<int?> getProvinceCode(String provinceName) async {
    final matchedProvince = await mapProvinceNameToApi(provinceName);
    return matchedProvince?['code'] as int?;
  }
  
  /// Gets districts for a province based on name (using fuzzy matching)
  Future<List<Map<String, dynamic>>> getDistrictsFromProvinceName(String provinceName) async {
    final provinceCode = await getProvinceCode(provinceName);
    if (provinceCode == null) {
      return [];
    }
    
    return _locationService.getDistricts(provinceCode);
  }
} 