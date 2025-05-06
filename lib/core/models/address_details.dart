class AddressDetails {
  final String? street;      // Tên đường
  final String? ward;        // Phường/Xã
  final String? district;    // Quận/Huyện
  final String? city;        // Thành phố/Tỉnh
  final String? country;     // Quốc gia
  final String? fullAddress; // Địa chỉ đầy đủ
  final double? latitude;    // Vĩ độ
  final double? longitude;   // Kinh độ

  AddressDetails({
    this.street,
    this.ward,
    this.district,
    this.city,
    this.country,
    this.fullAddress,
    this.latitude,
    this.longitude,
  });

  // Tạo từ chuỗi địa chỉ đầy đủ
  factory AddressDetails.fromFullAddress(String address, {double? latitude, double? longitude}) {
    List<String> parts = address.split(', ').where((part) => 
      !part.contains("Unnamed") &&
      !part.contains("Unknown")
    ).toList();

    String? street, ward, district, city, country;
    String? postalCode;
    
    // Xử lý từng phần của địa chỉ
    for (String part in parts) {
      // Kiểm tra nếu là mã bưu điện (chỉ chứa số và chuỗi dài 5-6 ký tự)
      if (RegExp(r'^\d{5,6}$').hasMatch(part)) {
        postalCode = part;
        continue;
      }
      
      // Xử lý phường/xã
      if (part.contains('Phường') || part.contains('Xã') || 
          part.contains('Thị trấn')) {
        ward = part;
      } 
      // Xử lý quận/huyện
      else if (part.contains('Quận') || part.contains('Huyện') || 
              part.contains('Thị xã')) {
        district = part;
      } 
      // Xử lý thành phố/tỉnh
      else if (part.contains('Thành phố') || part.contains('Tỉnh') || 
              part == 'Hà Nội' || part == 'TP. Hồ Chí Minh' || 
              part == 'Đà Nẵng' || part == 'Cần Thơ' || part == 'Hải Phòng') {
        city = part;
      } 
      // Xử lý đường/phố
      else if (part.contains('Đường') || part.contains('đường') || 
              part.contains('Phố') || part.contains('phố')) {
        street = part;
      } 
      // Xử lý quốc gia
      else if (part == 'Việt Nam') {
        country = part;
      } 
      // Kiểm tra mã bưu điện có ghép với tên thành phố không
      else if (part.contains(RegExp(r'\d{5,6}$'))) {
        // Tách mã bưu điện ra khỏi tên thành phố
        final matches = RegExp(r'(.*?)\s+(\d{5,6})$').firstMatch(part);
        if (matches != null && matches.groupCount >= 2) {
          final cityName = matches.group(1);
          postalCode = matches.group(2);
          if (cityName != null && cityName.isNotEmpty) {
            city = cityName;
          }
        } else {
          // Nếu không tách được thì giữ nguyên
          if (city == null) {
            city = part;
          }
        }
      }
      // Nếu chưa có street, giả định phần này là tên đường
      else if (street == null) {
        street = part;
      }
    }

    // Nếu không tìm thấy các thành phần, gán các phần cuối của địa chỉ
    if (parts.length >= 4 && district == null && city == null) {
      if (parts[parts.length - 1] == 'Việt Nam') {
        city = parts[parts.length - 2];
        district = parts[parts.length - 3];
      } else {
        city = parts[parts.length - 1];
        district = parts[parts.length - 2];
      }
    }

    // Chuẩn hóa tên thành phố
    if (city != null) {
      // Loại bỏ tiền tố "Thành phố" nếu cần
      if (city.startsWith('Thành phố ')) {
        city = city.substring('Thành phố '.length);
      }
      // Chuẩn hóa tên TP.HCM
      if (city == 'Hồ Chí Minh' || city == 'TP. Hồ Chí Minh' || city == 'TP.HCM') {
        city = 'Ho Chi Minh';
      }
      // Chuẩn hóa tên Hà Nội
      else if (city == 'Hà Nội') {
        city = 'Ha Noi';
      }
      // Chuẩn hóa tên Đà Nẵng
      else if (city == 'Đà Nẵng') {
        city = 'Da Nang';
      } else {
        // Chuẩn hóa các tên thành phố khác
        city = _normalizeVietnameseName(city);
      }
    }
    
    // Chuẩn hóa tên quận/huyện
    if (district != null) {
      // Loại bỏ dấu và chuyển sang định dạng chuẩn cho filter
      district = _normalizeVietnameseName(district);
    }
    
    // Chuẩn hóa tên phường/xã
    if (ward != null) {
      // Loại bỏ dấu và chuyển sang định dạng chuẩn cho filter
      ward = _normalizeVietnameseName(ward);
    }

    return AddressDetails(
      street: street,
      ward: ward,
      district: district,
      city: city,
      country: country,
      fullAddress: parts.join(', '),
      latitude: latitude,
      longitude: longitude,
    );
  }

  // Tạo chuỗi địa chỉ ngắn gọn cho header
  String toShortString() {
    // Hiển thị thành phố một cách rõ ràng
    if (city != null) {
      // Xử lý TP. Hồ Chí Minh
      if (city == 'Ho Chi Minh' || city == 'Thành phố Hồ Chí Minh') {
        return 'TP. Hồ Chí Minh';
      }
      // Xử lý Hà Nội
      else if (city == 'Ha Noi' || city == 'Hà Nội') {
        return 'Hà Nội';
      }
      // Xử lý Đà Nẵng
      else if (city == 'Da Nang' || city == 'Đà Nẵng') {
        return 'Đà Nẵng';
      }
      // Các thành phố khác
      else {
        // Thêm lại dấu nếu có thể
        String displayCity = _restoreVietnameseDiacritics(city!);
        if (district != null) {
          String displayDistrict = _restoreVietnameseDiacritics(district!);
          return '$displayDistrict, $displayCity';
        }
        return displayCity;
      }
    }
    
    // Fallback nếu không có thành phố
    if (district != null) {
      return _restoreVietnameseDiacritics(district!);
    }
    
    // Nếu có địa chỉ đầy đủ, hiển thị rút gọn
    if (fullAddress != null && fullAddress!.isNotEmpty) {
      List<String> parts = fullAddress!.split(', ');
      if (parts.length > 1) {
        return parts.take(2).join(', ');
      }
      return fullAddress!;
    }
    
    return 'Không xác định';
  }

  // Tạo chuỗi địa chỉ đầy đủ
  String toFullString() {
    List<String> addressParts = [];
    
    if (street != null) addressParts.add(street!);
    if (ward != null) addressParts.add(ward!);
    if (district != null) addressParts.add(district!);
    if (city != null) addressParts.add(city!);
    if (country != null) addressParts.add(country!);

    return addressParts.join(', ');
  }

  // Lấy thông tin filter - chỉ trả về city không dấu
  Map<String, String?> getFilterParams() {
    String? cityValue = city;
    
    // Đảm bảo tách mã bưu điện khỏi tên thành phố
    if (cityValue != null && cityValue.contains(RegExp(r'\d{5,6}$'))) {
      // Tách mã bưu điện ra khỏi tên thành phố
      final matches = RegExp(r'(.*?)\s+(\d{5,6})$').firstMatch(cityValue);
      if (matches != null && matches.groupCount >= 2) {
        final cityName = matches.group(1);
        if (cityName != null && cityName.isNotEmpty) {
          cityValue = cityName;
        }
      }
    }
    
    // Chuyển đổi từ tên không dấu sang tên có dấu
    if (cityValue != null) {
      cityValue = _restoreVietnameseDiacritics(cityValue);
    }
    
    return {
      'city': cityValue,  // city đã được khôi phục dấu
      'district': null,  // Không gửi district
      'ward': null,  // Không gửi ward
    };
  }

  // Hàm chuẩn hóa tên tiếng Việt
  static String _normalizeVietnameseName(String name) {
    // Loại bỏ các tiền tố như "Quận", "Huyện", "Phường", "Xã"
    final prefixes = ['Quận ', 'Huyện ', 'Phường ', 'Xã ', 'Thị trấn ', 'Thành phố ', 'Tỉnh '];
    for (final prefix in prefixes) {
      if (name.startsWith(prefix)) {
        name = name.substring(prefix.length);
        break;
      }
    }
    
    // Loại bỏ dấu tiếng Việt
    name = _removeDiacritics(name);
    
    return name;
  }

  // Hàm loại bỏ dấu tiếng Việt
  static String _removeDiacritics(String text) {
    final vietnamese = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
    final latin = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
    
    String result = text.toLowerCase();
    for (int i = 0; i < vietnamese.length; i++) {
      result = result.replaceAll(vietnamese[i], latin[i]);
    }
    
    return result;
  }

  // Khôi phục dấu tiếng Việt cho các thành phố lớn
  static String _restoreVietnameseDiacritics(String text) {
    Map<String, String> cityMap = {
      'ho chi minh': 'TP. Hồ Chí Minh',
      'ha noi': 'Hà Nội',
      'da nang': 'Đà Nẵng',
      'can tho': 'Cần Thơ',
      'hai phong': 'Hải Phòng',
      'bien hoa': 'Biên Hòa',
      'nha trang': 'Nha Trang',
      'hue': 'Huế',
      'hai duong': 'Hải Dương',
      'qui nhon': 'Qui Nhơn',
      'quang ngai': 'Quảng Ngãi',
      'vung tau': 'Vũng Tàu',
      'buon ma thuot': 'Buôn Ma Thuột',
      'vinh': 'Vinh',
      'pleiku': 'Pleiku',
      'long xuyen': 'Long Xuyên',
      'thai nguyen': 'Thái Nguyên',
      'thanh hoa': 'Thanh Hóa',
      'ca mau': 'Cà Mau',
      'vinh long': 'Vĩnh Long',
      'quan 1': 'Quận 1',
      'quan 2': 'Quận 2',
      'quan 3': 'Quận 3',
      'quan 4': 'Quận 4',
      'quan 5': 'Quận 5',
      'quan 6': 'Quận 6',
      'quan 7': 'Quận 7',
      'quan 8': 'Quận 8',
      'quan 9': 'Quận 9',
      'quan 10': 'Quận 10',
      'quan 11': 'Quận 11',
      'quan 12': 'Quận 12',
      'quan binh thanh': 'Quận Bình Thạnh',
      'quan tan binh': 'Quận Tân Bình',
      'quan phu nhuan': 'Quận Phú Nhuận',
      'quan thu duc': 'Quận Thủ Đức',
      'quan 12': 'Quận 12',
      'quan go vap': 'Quận Gò Vấp',
      'quan binh tan': 'Quận Bình Tân',
    };
    
    String lowerText = text.toLowerCase();
    
    // Thử tìm kết quả trong map
    if (cityMap.containsKey(lowerText)) {
      return cityMap[lowerText]!;
    }
    
    // Nếu không tìm thấy, giữ nguyên chuỗi
    return text;
  }
} 