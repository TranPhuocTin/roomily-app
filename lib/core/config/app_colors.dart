import 'package:flutter/material.dart';

class AppColors {
  // Background colors
  static const Color homeBackground = Color(0xFFFCFCFC);

  // Greyscale
  static const Color grey900 = Color(0xFF111827);
  static const Color grey800 = Color(0xFF1F2937);
  static const Color grey700 = Color(0xFF374151);
  static const Color grey600 = Color(0xFF4B5563);
  static const Color grey500 = Color(0xFF6B7280);
  static const Color grey400 = Color(0xFF9CA3AF);
  static const Color grey300 = Color(0xFFD1D5DB);
  static const Color grey200 = Color(0xFFE5E7EB);
  static const Color grey100 = Color(0xFFF5F5F5);

  //Bottom navigation item color
  static const Color bottomNavigationHome = Color(0xFF3D90D7);
  static const Color bottomNavigationHomeSearch = Color(0xFFF44336);
  static const Color bottomNavigationHomeMap = Color(0xFFF7374F);
  static const Color bottomNavigationHomeChat = Color(0xFF1B56FD);
  static const Color bottomNavigationHomeProfile = Color(0xFFFFF085);

  //Landlord bottom navigation item color
  static const Color landlordBottomNavigationDashboard = Color(0xFF9575CD); // Deep Purple
  static const Color landlordBottomNavigationRooms = Color(0xFF7986CB);     // Indigo
  static const Color landlordBottomNavigationSubscription = Color(0xFF64B5F6); // Blue
  static const Color landlordBottomNavigationChat = bottomNavigationHomeChat;  // Reuse
  static const Color landlordBottomNavigationProfile = bottomNavigationHomeProfile; // Reuse

  //Home top gradient container
  static LinearGradient homeTopGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF7EF7FE), Color(0xFFFFFFFF)],
  );

  //Home bottom gradient container
  static LinearGradient bottomLinearGradient(Color color) {
    return LinearGradient(
      begin: Alignment.bottomCenter,
      end: Alignment.topCenter,
      colors: [
        color,
        Colors.white,
      ],
    );
  }

  //Feature container gradient
  static const LinearGradient homeFeatureGradient = LinearGradient(
    begin: Alignment.centerRight,
    end: Alignment.centerLeft,
    colors: [
      Color(0xFF8EA1FF),
      Color(0xFFE0E5FB),
    ],
  );

  //Delevery feature button container gradient
  static LinearGradient deliveryFeatureButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFBCDAF8),
      Color(0xFFEBF3FD).withValues(alpha: 0),
    ],
  );

  //Delivery feature button container gradient
  static LinearGradient findPartnerFeatureButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFFEAF663),
      Color(0xFFEBF3FD).withValues(alpha: 0),
    ],
  );

  //Shop feature button container gradient
  static LinearGradient shopFeatureButtonGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF36D348),
      Color(0xFFEBF3FD).withValues(alpha: 0),
    ],
  );
}
