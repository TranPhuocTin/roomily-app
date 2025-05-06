import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:roomily/core/localization/app_localization.dart';

class LanguagePreference {
  static const String _languageCodeKey = 'language_code';
  static const String _countryCodeKey = 'country_code';
  static const String _hasSelectedLanguageKey = 'has_selected_language';

  // Lưu ngôn ngữ đã chọn
  static Future<void> setLocale(Locale locale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageCodeKey, locale.languageCode);
    await prefs.setString(_countryCodeKey, locale.countryCode ?? '');
    await prefs.setBool(_hasSelectedLanguageKey, true);
  }

  // Lấy ngôn ngữ đã lưu
  static Future<Locale> getLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageCodeKey);
    final countryCode = prefs.getString(_countryCodeKey);

    if (languageCode != null) {
      return Locale(languageCode, countryCode?.isNotEmpty == true ? countryCode : null);
    }

    // Mặc định là tiếng Việt
    return AppLocalization.vi;
  }

  // Kiểm tra xem người dùng đã chọn ngôn ngữ chưa
  static Future<bool> hasSelectedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSelectedLanguageKey) ?? false;
  }

  // Đặt lại trạng thái chọn ngôn ngữ (để test)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageCodeKey);
    await prefs.remove(_countryCodeKey);
    await prefs.remove(_hasSelectedLanguageKey);
  }
}