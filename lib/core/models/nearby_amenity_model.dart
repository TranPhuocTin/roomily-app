import 'package:flutter/material.dart';
import 'package:roomily/core/utils/tag_category.dart';

class NearbyAmenityModel {
  final String name;
  final double distance;
  final double latitude;
  final double longitude;
  final String displayName;
  final IconData icon;

  NearbyAmenityModel({
    required this.name,
    required this.distance,
    required this.latitude,
    required this.longitude,
    required this.displayName,
    required this.icon,
  });

  // Parse from the string format: "AMENITY_NAME:distance:latitude:longitude"
  static NearbyAmenityModel? fromString(String amenityString) {
    final parts = amenityString.split(':');
    if (parts.length < 4) return null;

    final name = parts[0];
    final distance = double.tryParse(parts[1]) ?? 0.0;
    final latitude = double.tryParse(parts[2]) ?? 0.0;
    final longitude = double.tryParse(parts[3]) ?? 0.0;

    // Get display name and icon for this amenity
    final TagData? tagData = TagDataMap.getTagData(name);
    if (tagData == null) return null;

    return NearbyAmenityModel(
      name: name,
      distance: distance,
      latitude: latitude,
      longitude: longitude,
      displayName: tagData.displayName,
      icon: tagData.icon,
    );
  }

  // Format distance to display
  String get formattedDistance {
    if (distance < 1) {
      return '${(distance * 1000).toStringAsFixed(0)}m';
    } else {
      return '${distance.toStringAsFixed(1)}km';
    }
  }
}

class TagData {
  final String name;
  final TagCategory category;
  final String displayName;
  final IconData icon;

  TagData(this.name, this.category, this.displayName, this.icon);
}

class TagDataMap {
  static final Map<String, TagData> _tagDataMap = {
    "GYM_NEARBY": TagData("GYM_NEARBY", TagCategory.NEARBY_POI, "Phòng Gym", Icons.fitness_center),
    "MARKET_NEARBY": TagData("MARKET_NEARBY", TagCategory.NEARBY_POI, "Chợ", Icons.storefront),
    "SUPERMARKET_NEARBY": TagData("SUPERMARKET_NEARBY", TagCategory.NEARBY_POI, "Siêu thị", Icons.shopping_cart),
    "CONVENIENCE_STORE_NEARBY": TagData("CONVENIENCE_STORE_NEARBY", TagCategory.NEARBY_POI, "Cửa hàng tiện lợi", Icons.local_convenience_store),
    "PARK_NEARBY": TagData("PARK_NEARBY", TagCategory.NEARBY_POI, "Công viên", Icons.park),
    "SCHOOL_NEARBY": TagData("SCHOOL_NEARBY", TagCategory.NEARBY_POI, "Trường học", Icons.school),
    "UNIVERSITY_NEARBY": TagData("UNIVERSITY_NEARBY", TagCategory.NEARBY_POI, "Trường Đại học", Icons.account_balance),
    "HOSPITAL_NEARBY": TagData("HOSPITAL_NEARBY", TagCategory.NEARBY_POI, "Bệnh viện", Icons.local_hospital),
    "BUS_STOP_NEARBY": TagData("BUS_STOP_NEARBY", TagCategory.NEARBY_POI, "Bến xe buýt", Icons.directions_bus),
    "RESTAURANT_NEARBY": TagData("RESTAURANT_NEARBY", TagCategory.NEARBY_POI, "Nhà hàng", Icons.restaurant),
    "CAFE_NEARBY": TagData("CAFE_NEARBY", TagCategory.NEARBY_POI, "Cà phê", Icons.local_cafe),
    "NEAR_BEACH": TagData("NEAR_BEACH", TagCategory.NEARBY_POI, "Biển", Icons.beach_access),
    "NEAR_DOWNTOWN": TagData("NEAR_DOWNTOWN", TagCategory.NEARBY_POI, "Trung tâm thành phố", Icons.location_city),
  };

  static TagData? getTagData(String name) {
    return _tagDataMap[name];
  }
} 