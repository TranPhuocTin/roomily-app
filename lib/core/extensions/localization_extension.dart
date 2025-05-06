import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter/widgets.dart';

extension LocalizationExt on BuildContext {
  FlutterLocalization get localization => FlutterLocalization.instance;
  
  void changeLanguage(String languageCode) {
    localization.translate(languageCode);
  }
  
  String get currentLanguage => localization.getLanguageName();
  
  String get currentFont => localization.fontFamily ?? 'Roboto';
} 