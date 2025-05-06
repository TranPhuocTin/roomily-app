import 'package:roomily/core/models/address_details.dart';
import 'package:roomily/core/services/location_service.dart';
import 'package:roomily/core/services/search_service.dart';
import 'package:roomily/core/services/google_places_service.dart';
import 'package:roomily/data/models/place_details.dart' as google_places;
import 'package:get_it/get_it.dart';

class UserLocationService {
  final LocationService _locationService;
  final SearchService _searchService;
  final GooglePlacesService _googlePlacesService;
  
  // Lưu trữ địa chỉ hiện tại
  AddressDetails? _currentAddress;
  String _currentLocationString = "TP. Hồ Chí Minh";
  bool _isInitialized = false;
  
  UserLocationService({
    LocationService? locationService,
    SearchService? searchService,
    GooglePlacesService? googlePlacesService,
  }) : _locationService = locationService ?? GetIt.instance<LocationService>(),
       _searchService = searchService ?? GetIt.instance<SearchService>(),
       _googlePlacesService = googlePlacesService ?? GetIt.instance<GooglePlacesService>();
  
  // Getter cho địa chỉ hiện tại
  AddressDetails? get currentAddress => _currentAddress;
  
  // Getter cho chuỗi địa chỉ hiện tại
  String get currentLocationString => _currentLocationString;
  
  // Kiểm tra xem service đã được khởi tạo chưa
  bool get isInitialized => _isInitialized;
  
  // Khởi tạo service và lấy địa chỉ hiện tại
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    await updateCurrentLocation();
    _isInitialized = true;
  }
  
  // Cập nhật địa chỉ hiện tại
  Future<void> updateCurrentLocation() async {
    try {
      print('UserLocationService: Đang cập nhật vị trí người dùng...');
      
      // Lấy vị trí hiện tại
      final position = await _locationService.getCurrentPosition();
      if (position == null) {
        print('UserLocationService: Không thể lấy vị trí hiện tại.');
        _useFixedLocation();
        return;
      }
      
      print('UserLocationService: Đã lấy được vị trí: ${position.latitude}, ${position.longitude}');
      
      try {
        // Chỉ gọi reverse geocode một lần từ Google Places API
        final placeDetails = await _googlePlacesService.reverseGeocode(position.latitude, position.longitude);
        
        if (placeDetails != null) {
          print('UserLocationService: Kết quả reverse geocode từ Google: ${placeDetails.formattedAddress}');
          
          // Chuyển đổi địa chỉ thành AddressDetails và lưu tọa độ
          _currentAddress = AddressDetails.fromFullAddress(
            placeDetails.formattedAddress,
            latitude: position.latitude,
            longitude: position.longitude,
          );
          _currentLocationString = _currentAddress!.toShortString();
          return;
        }
        
        // Chỉ khi Google Places API thất bại, mới fallback về SearchService
        print('UserLocationService: Google Places API không trả về kết quả, thử dùng SearchService');
        final locationResult = await _searchService.reverseGeocode(
          position.longitude, 
          position.latitude
        );
        
        if (locationResult == null) {
          print('UserLocationService: Không thể reverse geocode vị trí.');
          _useCoordinatesAsLocation(position.latitude, position.longitude);
          return;
        }
        
        print('UserLocationService: Kết quả reverse geocode: ${locationResult.address}');
        
        // Chuyển đổi địa chỉ thành AddressDetails và lưu tọa độ
        _currentAddress = AddressDetails.fromFullAddress(
          locationResult.address,
          latitude: position.latitude,
          longitude: position.longitude,
        );
        _currentLocationString = _currentAddress!.toShortString();
        
      } catch (e) {
        print('UserLocationService: Lỗi khi reverse geocode: $e');
        _useCoordinatesAsLocation(position.latitude, position.longitude);
      }
    } catch (e) {
      print('UserLocationService: Lỗi khi cập nhật vị trí: $e');
      _useFixedLocation();
    }
  }
  
  void _useCoordinatesAsLocation(double latitude, double longitude) {
    // Kiểm tra xem có phải vị trí ở Việt Nam không
    bool isInVietnam = _isLocationInVietnam(latitude, longitude);

    if (isInVietnam) {
      // Nếu là vị trí ở Việt Nam, hiển thị một địa điểm phổ biến gần đó
      _useVietnameseLocation(latitude, longitude);
    } else if (_isEmulatorDefaultLocation(latitude, longitude)) {
      // Nếu là vị trí mặc định của emulator, sử dụng vị trí mặc định cho Việt Nam
      _useFixedLocation();
    } else {
      // Nếu không, hiển thị tọa độ được làm tròn
      final lat = latitude.toStringAsFixed(4);
      final lng = longitude.toStringAsFixed(4);
      _currentLocationString = "($lat, $lng)";

      // Tạo một AddressDetails giả với tọa độ
      _currentAddress = AddressDetails(
        street: "Vị trí hiện tại",
        fullAddress: "Vị trí ($lat, $lng)",
        latitude: latitude,
        longitude: longitude,
        city: "Unknown",
        district: "Unknown",
        ward: "Unknown",
      );
    }
  }
  
  // Kiểm tra xem có phải vị trí mặc định của emulator không
  bool _isEmulatorDefaultLocation(double latitude, double longitude) {
    // Vị trí mặc định của Google/Android Emulator (Palo Alto, California)
    const defaultLat = 37.4219983;
    const defaultLng = -122.084;

    // Kiểm tra với một khoảng sai số nhỏ
    return (latitude - defaultLat).abs() < 0.1 &&
           (longitude - defaultLng).abs() < 0.1;
  }
  
  // Kiểm tra xem vị trí có nằm trong Việt Nam không
  bool _isLocationInVietnam(double latitude, double longitude) {
    // Phạm vi tọa độ của Việt Nam (xấp xỉ)
    const double minLat = 8.0;
    const double maxLat = 24.0;
    const double minLng = 102.0;
    const double maxLng = 110.0;
    
    return latitude >= minLat && latitude <= maxLat && 
           longitude >= minLng && longitude <= maxLng;
  }
  
  // Sử dụng một vị trí ở Việt Nam dựa trên tọa độ
  void _useVietnameseLocation(double latitude, double longitude) {
    // Xác định thành phố lớn gần nhất
    String city;
    String district = "Unknown";
    String ward = "Unknown";

    // Tọa độ xấp xỉ của các thành phố lớn
    final hanoi = (21.0285, 105.8542);
    final danang = (16.0544, 108.2022);
    final hcmc = (10.8231, 106.6297);
    final cantho = (10.0456, 105.7469);
    final haiphong = (20.8449, 106.6880);

    // Tính khoảng cách đến các thành phố lớn
    final distToHanoi = _calculateDistance(latitude, longitude, hanoi.$1, hanoi.$2);
    final distToDanang = _calculateDistance(latitude, longitude, danang.$1, danang.$2);
    final distToHCMC = _calculateDistance(latitude, longitude, hcmc.$1, hcmc.$2);
    final distToCantho = _calculateDistance(latitude, longitude, cantho.$1, cantho.$2);
    final distToHaiphong = _calculateDistance(latitude, longitude, haiphong.$1, haiphong.$2);

    // Chọn thành phố gần nhất
    if (distToHanoi <= distToDanang && distToHanoi <= distToHCMC && 
        distToHanoi <= distToCantho && distToHanoi <= distToHaiphong) {
      city = "Ha Noi";
      _currentLocationString = "Hà Nội";
      if (distToHanoi < 0.1) {
        district = "Ba Dinh";
      }
    } else if (distToDanang <= distToHanoi && distToDanang <= distToHCMC && 
               distToDanang <= distToCantho && distToDanang <= distToHaiphong) {
      city = "Da Nang";
      _currentLocationString = "Đà Nẵng";
      if (distToDanang < 0.1) {
        district = "Hai Chau";
      }
    } else if (distToHaiphong <= distToHanoi && distToHaiphong <= distToHCMC && 
               distToHaiphong <= distToCantho && distToHaiphong <= distToDanang) {
      city = "Hai Phong";
      _currentLocationString = "Hải Phòng";
      if (distToHaiphong < 0.1) {
        district = "Hong Bang";
      }
    } else if (distToCantho <= distToHanoi && distToCantho <= distToHCMC && 
               distToCantho <= distToHaiphong && distToCantho <= distToDanang) {
      city = "Can Tho";
      _currentLocationString = "Cần Thơ";
      if (distToCantho < 0.1) {
        district = "Ninh Kieu";
      }
    } else {
      city = "Ho Chi Minh";
      _currentLocationString = "TP. Hồ Chí Minh";
      if (distToHCMC < 0.1) {
        district = "District 1";
      }
    }

    // Tạo một AddressDetails giả với tọa độ
    _currentAddress = AddressDetails(
      city: city,  // Lưu tên không dấu để filter
      district: district,
      ward: ward,
      fullAddress: _currentLocationString,
      latitude: latitude,
      longitude: longitude,
    );
  }
  
  // Tính khoảng cách giữa hai tọa độ (công thức Haversine đơn giản hóa)
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    final dLat = (lat2 - lat1).abs();
    final dLon = (lon2 - lon1).abs();
    return dLat + dLon; // Đơn giản hóa, không cần tính chính xác
  }
  
  // Sử dụng một vị trí cố định khi không thể lấy được vị trí thực
  void _useFixedLocation() {
    _currentLocationString = "TP. Hồ Chí Minh";
    
    // Tạo một AddressDetails giả với tọa độ mặc định của TP.HCM
    _currentAddress = AddressDetails(
      city: "Ho Chi Minh",  // Lưu tên không dấu để filter
      district: "District 1",
      ward: "Ben Nghe",
      country: "Việt Nam",
      fullAddress: "Thành phố Hồ Chí Minh, Việt Nam",
      latitude: 10.8231,
      longitude: 106.6297,
    );
  }

  // Lấy thông tin filter từ địa chỉ hiện tại
  Map<String, String?> getLocationFilterParams() {
    if (_currentAddress != null) {
      final params = _currentAddress!.getFilterParams();
      
      // Định dạng lại tên thành phố để viết hoa chữ cái đầu mỗi từ
      if (params['city'] != null) {
        final cityName = params['city']!;
        // Tách mỗi từ trong tên thành phố và viết hoa chữ cái đầu mỗi từ
        final words = cityName.split(' ');
        final capitalizedWords = words.map((word) {
          if (word.isNotEmpty) {
            return word[0].toUpperCase() + word.substring(1).toLowerCase();
          }
          return word;
        }).toList();
        params['city'] = capitalizedWords.join(' ');
      }
      
      return params;
    }
    
    // Giá trị mặc định nếu không có địa chỉ
    return {
      'city': 'Ho Chi Minh',
      'district': null,
      'ward': null,
    };
  }

  // Cập nhật thông tin filter thủ công
  void updateLocationFilter({String? city, String? district, String? ward}) {
    if (_currentAddress != null) {
      // Tạo một AddressDetails mới với thông tin cập nhật
      _currentAddress = AddressDetails(
        street: _currentAddress!.street,
        ward: ward ?? _currentAddress!.ward,
        district: district ?? _currentAddress!.district,
        city: city ?? _currentAddress!.city,
        country: _currentAddress!.country,
        fullAddress: _currentAddress!.fullAddress,
        latitude: _currentAddress!.latitude,
        longitude: _currentAddress!.longitude,
      );
      
      // Cập nhật chuỗi hiển thị
      _currentLocationString = _currentAddress!.toShortString();
    } else {
      // Tạo một AddressDetails mới nếu chưa có
      _currentAddress = AddressDetails(
        city: city ?? 'Ho Chi Minh',
        district: district,
        ward: ward,
        country: 'Việt Nam',
        latitude: 10.8231,
        longitude: 106.6297,
      );
      
      _currentLocationString = _currentAddress!.toShortString();
    }
  }
} 