import 'package:flutter/material.dart';
import 'package:roomily/core/cache/language_preference.dart';
import 'package:roomily/core/config/text_styles.dart';
import 'package:roomily/core/localization/app_localization.dart';
import 'package:roomily/presentation/screens/intro_screens/intro_page_view.dart';
import 'package:roomily/presentation/screens/sign_in_screen.dart';
import 'package:roomily/presentation/screens/splash_screen.dart';
import 'package:roomily/presentation/widgets/intro/gradient_button.dart';

class LanguageSelectionScreen extends StatefulWidget {
  const LanguageSelectionScreen({super.key});

  @override
  State<LanguageSelectionScreen> createState() => _LanguageSelectionScreenState();
}

class _LanguageSelectionScreenState extends State<LanguageSelectionScreen> {
  Locale _selectedLocale = AppLocalization.vi; // Mặc định là tiếng Việt

  void _selectLocale(Locale locale) {
    setState(() {
      _selectedLocale = locale;
    });
  }

  void _continueToApp() async {
    await LanguagePreference.setLocale(_selectedLocale);
    if(mounted) {
      AppLocalization.changeLocale(context, _selectedLocale);


      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => IntroPageView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appLocalization = AppLocalization.of(context);
    
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 40),

              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: const Color(0xFF23BFF9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Center(
                    child: Text(
                      "Roomily",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Tiêu đề
              Text(
                appLocalization.translate('language', 'selectLanguage'),
                style: AppTextStyles.heading4,
              ),
              
              const SizedBox(height: 16),
              
              // Mô tả
              Text(
                appLocalization.translate('language', 'languageDescription'),
                style: AppTextStyles.bodyLargeMedium,
              ),
              
              const SizedBox(height: 40),
              
              // Danh sách ngôn ngữ
              _buildLanguageOption(
                AppLocalization.vi,
                appLocalization.translate('language', 'vietnamese'),
                'VI',
              ),
              
              const SizedBox(height: 16),
              
              _buildLanguageOption(
                AppLocalization.en,
                appLocalization.translate('language', 'english'),
                'EN',
              ),
              
              const SizedBox(height: 16),
              
              _buildLanguageOption(
                AppLocalization.ja,
                appLocalization.translate('language', 'japanese'),
                'JA',
              ),
              
              const Spacer(),
              
              // Nút tiếp tục
              GradientButton(
                text: appLocalization.translate('language', 'continueButton'),
                onPressed: _continueToApp,
                gradientColor1: const Color(0xFF23BFF9),
                gradientColor2: const Color(0xFF99E5FF),
              ),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLanguageOption(Locale locale, String languageName, String languageCode) {
    final isSelected = _selectedLocale.languageCode == locale.languageCode;
    
    return GestureDetector(
      onTap: () => _selectLocale(locale),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? const Color(0xFF23BFF9) : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          color: isSelected ? const Color(0xFFE6F7FF) : Colors.white,
        ),
        child: Row(
          children: [
            // Thay thế cờ quốc gia bằng text code
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF23BFF9) : Colors.grey.shade200,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  languageCode,
                  style: TextStyle(
                    color: isSelected ? Colors.white : Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Tên ngôn ngữ
            Text(
              languageName,
              style: AppTextStyles.bodyLargeSemiBold.copyWith(
                color: isSelected ? const Color(0xFF23BFF9) : Colors.black,
              ),
            ),
            
            const Spacer(),
            
            // Icon chọn
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF23BFF9),
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
} 