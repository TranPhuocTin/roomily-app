class FormatUtils {
  /// Định dạng tiền tệ Việt Nam
  /// Ví dụ: 3000000 -> 3tr, 3500000 -> 3tr5, 12000000 -> 12tr
  static String formatCurrency(num amount) {
    if (amount < 100000) {
      // Dưới 100k, hiển thị đơn vị nghìn (vd: 50k, 99k)
      return '${(amount / 1000).round()}k';
    }

    // Dùng hàm kiểm tra xem đã ở dạng triệu chưa
    final normalizedAmount = normalizePrice(amount);

    // Nếu là số nguyên (3tr, 5tr, 10tr)
    if (normalizedAmount == normalizedAmount.round()) {
      return '${normalizedAmount.toInt()}tr';
    }

    // Nếu phần thập phân là 0.5 (3tr5, 4tr5)
    if ((normalizedAmount * 10).round() % 10 == 5) {
      return '${normalizedAmount.floor()}tr5';
    }

    // Các trường hợp khác, làm tròn 1 chữ số thập phân
    return '${normalizedAmount.toStringAsFixed(1)}tr';
  }


  /// Định dạng diện tích
  static String formatArea(num area) {
    return '$area m²';
  }
  
  /// Định dạng ngắn gọn cho marker
  /// Trả về chuỗi ngắn gọn nhất để hiển thị trên marker
  static String formatCurrencyForMarker(num amount) {
    // Dùng hàm kiểm tra xem đã ở dạng triệu chưa
    final normalizedAmount = normalizePrice(amount); // amount / 1_000_000

    if (amount < 100000) {
      // Dưới 100 nghìn, hiển thị đơn vị nghìn (vd: 50k, 90k)
      return '${(amount / 1000).round()}k';
    } else if (normalizedAmount < 1) {
      // Dưới 1 triệu, hiển thị theo trăm nghìn (vd: 300k, 500k)
      return '${(normalizedAmount * 10).round()}00k';
    } else if (normalizedAmount < 10) {
      // 1-10 triệu, hiển thị dạng 1tr5, 2tr, 3tr5
      if (normalizedAmount == normalizedAmount.floor()) {
        return '${normalizedAmount.floor()}tr';
      } else if ((normalizedAmount * 10).round() % 10 == 5) {
        return '${normalizedAmount.floor()}tr5';
      } else {
        return '${normalizedAmount.toStringAsFixed(1)}tr';
      }
    } else {
      // Từ 10 triệu trở lên, làm tròn theo triệu
      return '${normalizedAmount.round()}tr';
    }
  }

  
  /// Kiểm tra giá có phải đơn vị VND hay triệu và chuẩn hóa về triệu
  static double normalizePrice(num amount) {
    if (amount == 0) return 0;
    
    // Nếu số lớn hơn 1000, giả định là đơn vị VND -> chuyển về triệu
    if (amount >= 1000) {
      return amount / 1000000;
    }
    
    // Nếu nhỏ hơn 1000, giả định đã ở dạng triệu
    return amount.toDouble();
  }
} 