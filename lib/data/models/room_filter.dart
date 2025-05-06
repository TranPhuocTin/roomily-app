import 'package:json_annotation/json_annotation.dart';
import '../../core/utils/room_type.dart';

part 'room_filter.g.dart';

@JsonSerializable()
class RoomFilter {
  final String? city;
  final String? district;
  final String? ward;
  @JsonKey(fromJson: _roomTypeFromJson, toJson: _roomTypeToJson)
  final RoomType? type;
  final double? minPrice;
  final double? maxPrice;
  final int? minPeople;
  final int? maxPeople;
  @JsonKey(name: 'privotId')
  final String? pivotId;
  final int? limit;
  final String? timestamp;
  final List<String>? tagIds;
  final bool? hasFindPartnerPost;

  RoomFilter({
    this.city,
    this.district,
    this.ward,
    this.type,
    this.minPrice,
    this.maxPrice,
    this.minPeople,
    this.maxPeople,
    this.pivotId,
    this.limit,
    this.timestamp,
    this.tagIds,
    this.hasFindPartnerPost,
  });

  // Factory method to create a filter with default values from the example
  factory RoomFilter.defaultFilter() {
    return RoomFilter(
      city: "",
      district: "",
      ward: "",
      type: RoomType.ROOM,
      minPrice: null,
      maxPrice: null,
      minPeople: 1,
      maxPeople: 4,
      pivotId: null, // Removed specific ID, should be null for initial load
      limit: 20,     // Changed from 1 to 20 to match empty filter
      timestamp: null,
      tagIds: null,
      hasFindPartnerPost: null,
    );
  }

  // Factory method for initial page load (without pagination parameters)
  factory RoomFilter.initialFilter({
    String? city,
    String? district,
    String? ward,
    RoomType? type,
    double? minPrice,
    double? maxPrice,
    int? minPeople,
    int? maxPeople,
    int? limit,
    bool? isSubscribed,
    List<String>? tagIds,
    bool? hasFindPartnerPost,
  }) {
    return RoomFilter(
      city: city,
      district: district,
      ward: ward,
      type: type,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minPeople: minPeople,
      maxPeople: maxPeople,
      pivotId: null, // Explicitly null for initial load
      limit: limit,
      timestamp: null,
      tagIds: tagIds,
      hasFindPartnerPost: hasFindPartnerPost,
    );
  }

  // Factory method for loading more items (with pagination parameters)
  factory RoomFilter.paginationFilter({
    required String pivotId,
    required String timestamp,
    String? city,
    String? district,
    String? ward,
    RoomType? type,
    double? minPrice,
    double? maxPrice,
    int? minPeople,
    int? maxPeople,
    int? limit,
    bool? isSubscribed,
    List<String>? tagIds,
    bool? hasFindPartnerPost,
  }) {
    return RoomFilter(
      city: city,
      district: district,
      ward: ward,
      type: type,
      minPrice: minPrice,
      maxPrice: maxPrice,
      minPeople: minPeople,
      maxPeople: maxPeople,
      pivotId: pivotId, // Required for pagination
      limit: limit,
      timestamp: timestamp,
      tagIds: tagIds,
      hasFindPartnerPost: hasFindPartnerPost,
    );
  }

  // Convert from JSON
  factory RoomFilter.fromJson(Map<String, dynamic> json) => _$RoomFilterFromJson(json);

  // Convert to JSON
  Map<String, dynamic> toJson() => _$RoomFilterToJson(this);

  // Create a copy with modified fields
  RoomFilter copyWith({
    String? city,
    String? district,
    String? ward,
    RoomType? type,
    double? minPrice,
    double? maxPrice,
    int? minPeople,
    int? maxPeople,
    String? pivotId,
    int? limit,
    String? timestamp,
    bool? isSubscribed,
    List<String>? tagIds,
    bool? hasFindPartnerPost,
    Set<String>? nullFields,
  }) {
    // Xử lý các trường cần gán null
    final Set<String> fieldsToNull = nullFields ?? {};
    
    return RoomFilter(
      city: fieldsToNull.contains('city') ? null : (city ?? this.city),
      district: fieldsToNull.contains('district') ? null : (district ?? this.district),
      ward: fieldsToNull.contains('ward') ? null : (ward ?? this.ward),
      type: fieldsToNull.contains('type') ? null : (type ?? this.type),
      minPrice: fieldsToNull.contains('minPrice') ? null : (minPrice ?? this.minPrice),
      maxPrice: fieldsToNull.contains('maxPrice') ? null : (maxPrice ?? this.maxPrice),
      minPeople: fieldsToNull.contains('minPeople') ? null : (minPeople ?? this.minPeople),
      maxPeople: fieldsToNull.contains('maxPeople') ? null : (maxPeople ?? this.maxPeople),
      pivotId: fieldsToNull.contains('pivotId') ? null : (pivotId ?? this.pivotId),
      limit: fieldsToNull.contains('limit') ? null : (limit ?? this.limit),
      timestamp: fieldsToNull.contains('timestamp') ? null : (timestamp ?? this.timestamp),
      tagIds: fieldsToNull.contains('tagIds') ? null : (tagIds ?? this.tagIds),
      hasFindPartnerPost: fieldsToNull.contains('hasFindPartnerPost') ? null : (hasFindPartnerPost ?? this.hasFindPartnerPost),
    );
  }

  // Convert to query string for API
  
  // Override toString() để so sánh chính xác
  @override
  String toString() {
    return 'RoomFilter{city: $city, district: $district, ward: $ward, type: $type, '
           'minPrice: $minPrice, maxPrice: $maxPrice, minPeople: $minPeople, maxPeople: $maxPeople, '
           'tagIds: $tagIds}';
  }
  
  // Override operator == và hashCode để so sánh chính xác
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    
    final RoomFilter otherFilter = other as RoomFilter;
    
    // Xử lý đặc biệt cho type: null và RoomType.ALL được xem là tương đương
    bool typeEquals = false;
    if (type == null && otherFilter.type == null) {
      typeEquals = true;
    } else if (type == null && otherFilter.type == RoomType.ALL) {
      typeEquals = true;
    } else if (type == RoomType.ALL && otherFilter.type == null) {
      typeEquals = true;
    } else {
      typeEquals = type == otherFilter.type;
    }
    
    return city == otherFilter.city &&
           district == otherFilter.district &&
           ward == otherFilter.ward &&
           typeEquals &&
           minPrice == otherFilter.minPrice &&
           maxPrice == otherFilter.maxPrice &&
           minPeople == otherFilter.minPeople &&
           maxPeople == otherFilter.maxPeople &&
           pivotId == otherFilter.pivotId &&
           limit == otherFilter.limit &&
           timestamp == otherFilter.timestamp &&
           hasFindPartnerPost == otherFilter.hasFindPartnerPost &&
           _listEquals(tagIds, otherFilter.tagIds);
  }
  
  @override
  int get hashCode {
    return Object.hash(
      city,
      district,
      ward,
      type,
      minPrice,
      maxPrice,
      minPeople,
      maxPeople,
      pivotId,
      limit,
      timestamp,
      hasFindPartnerPost,
      tagIds != null ? Object.hashAll(tagIds!) : null,
    );
  }
  
  // Helper method để so sánh hai list
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null) return b == null;
    if (b == null || a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
  
  // Helper methods for JSON serialization
  static RoomType? _roomTypeFromJson(String? value) {
    if (value == null || value.isEmpty) return null;
    switch (value) {
      case 'ROOM': return RoomType.ROOM;
      case 'APARTMENT': return RoomType.APARTMENT;
      case 'HOUSE': return RoomType.HOUSE;
      case 'ALL': return RoomType.ALL;
      default: return null;
    }
  }
  
  static String _roomTypeToJson(RoomType? type) {
    if (type == null) return "";
    if (type == RoomType.ALL) return "";
    return type.toString().split('.').last;
  }
}

// Extension cho RoomFilter để thêm các hàm tiện ích
extension RoomFilterExtension on RoomFilter {
  // Chuẩn hóa filter, đảm bảo các giá trị null và mặc định được xử lý nhất quán
  RoomFilter normalize() {
    return RoomFilter(
      city: (city == null || city!.isEmpty) ? null : city,
      district: (district == null || district!.isEmpty) ? null : district,
      ward: (ward == null || ward!.isEmpty) ? null : ward,
      tagIds: (tagIds == null || tagIds!.isEmpty) ? null : tagIds,
      minPrice: minPrice == 0 ? null : minPrice,
      maxPrice: maxPrice == 0 ? null : maxPrice,
      minPeople: minPeople == 0 ? null : minPeople,
      maxPeople: maxPeople == 0 ? null : maxPeople,
      pivotId: pivotId,
      limit: limit,
      timestamp: timestamp,
      type: type == null ? RoomType.ALL : type,
      hasFindPartnerPost: hasFindPartnerPost,
    );
  }

  // Kiểm tra xem filter có active không (có áp dụng bất kỳ điều kiện lọc nào không)
  bool get isActive {
    return (city != null && city!.isNotEmpty) ||
           (district != null && district!.isNotEmpty) ||
           (type != null && type != RoomType.ALL) ||
           minPrice != null ||
           maxPrice != null ||
           minPeople != null ||
           maxPeople != null ||
           hasFindPartnerPost != null ||
           (tagIds != null && tagIds!.isNotEmpty);
  }

  // Tạo filter rỗng (mặc định)
  static RoomFilter empty() {
    return RoomFilter(
      city: null,
      district: null,
      ward: null,
      type: RoomType.ALL,
      minPrice: null,
      maxPrice: null,
      minPeople: null,
      maxPeople: null,
      pivotId: null,
      limit: 20, // Giá trị mặc định cho limit
      timestamp: null,
      tagIds: null,
      hasFindPartnerPost: null,
    );
  }
} 