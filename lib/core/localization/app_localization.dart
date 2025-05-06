import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:roomily/main.dart';
import 'translations/en_translations.dart';
import 'translations/vi_translations.dart';
import 'translations/ja_translations.dart';

class AppLocalization {
  static const Locale vi = Locale('vi', 'VN');
  static const Locale en = Locale('en', 'US');
  static const Locale ja = Locale('ja', 'JP');

  static const List<Locale> supportedLocales = [
    vi,
    en,
    ja,
  ];

  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = [
    AppLocalizationsDelegate(),
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  final Locale locale;

  AppLocalization(this.locale);

  static AppLocalization of(BuildContext context) {
    return Localizations.of<AppLocalization>(context, AppLocalization)!;
  }

  String get currentLanguage => locale.languageCode;

  static void changeLocale(BuildContext context, Locale newLocale) {
    MyApp.of(context).changeLocale(newLocale);
  }

  String translate(String module, String key) {
    final translations = switch (locale.languageCode) {
      'en' => enTranslations,
      'ja' => jaTranslations,
      _ => viTranslations,
    };
    return translations[module]?[key] ?? key;
  }
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalization> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) {
    return ['en', 'vi', 'ja'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalization> load(Locale locale) async {
    return AppLocalization(locale);
  }

  @override
  bool shouldReload(AppLocalizationsDelegate old) => false;
} 