import 'package:shared_preferences/shared_preferences.dart';

class IntroPreference {
  static const String _hasSeenIntroKey = 'has_seen_intro';

  // Đánh dấu đã xem intro
  static Future<void> setIntroSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hasSeenIntroKey, true);
  }

  // Kiểm tra xem đã xem intro chưa
  static Future<bool> hasSeenIntro() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_hasSeenIntroKey) ?? false;
  }

  // Reset trạng thái xem intro (để test)
  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_hasSeenIntroKey);
  }
} 