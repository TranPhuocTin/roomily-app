import 'package:flutter/material.dart';
import 'models/intro_content.dart';
import '../../../core/localization/app_localization.dart';
import '../sign_in_screen.dart';
import '../../../core/cache/intro_preference.dart';

class IntroContentConfig {
  // Helper method để tạo danh sách RectangleConfig với màu sắc tùy chỉnh
  static List<RectangleConfig> _createRectangleConfigs({
    required List<Color> startColors,
    required List<Color> endColors,
  }) {
    assert(startColors.length == 4 && endColors.length == 4, 
      'Must provide exactly 4 colors for both start and end colors');

    return [
      RectangleConfig(
        position: RectanglePosition(top: -80, left: -100),
        startColor: startColors[0],
        endColor: endColors[0],
        width: 600,
        height: 70,
      ),
      RectangleConfig(
        position: RectanglePosition(top: -60, right: -300),
        startColor: startColors[1],
        endColor: endColors[1],
        width: 550,
        height: 65,
      ),
      RectangleConfig(
        position: RectanglePosition(bottom: 450, left: -300),
        startColor: startColors[2],
        endColor: endColors[2],
        width: 500,
        height: 60,
      ),
      RectangleConfig(
        position: RectanglePosition(bottom: 500, right: -300),
        startColor: startColors[3],
        endColor: endColors[3],
        width: 580,
        height: 68,
      ),
    ];
  }

  static List<IntroContent> getIntroContents(BuildContext context, {VoidCallback? onLoginPressed}) {
    final appLocalization = AppLocalization.of(context);
    
    // Hàm xử lý sự kiện đăng nhập chung
    void handleLogin() {
      print('Login pressed');
      // Đánh dấu đã xem intro
      IntroPreference.setIntroSeen();
      
      // Chuyển đến màn hình đăng nhập
      if (onLoginPressed != null) {
        onLoginPressed();
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
        );
      }
    }
    
    return [
      // Màn hình 1
      IntroContent(
        title: appLocalization.translate('intro', 'title1'),
        subtitle: appLocalization.translate('intro', 'subtitle1'),
        buttonText: appLocalization.translate('intro', 'buttonText1'),
        onButtonPressed: handleLogin,
        humanImage: 'assets/icons/intro_icon_human_sitting.png',
        hand1Image: 'assets/icons/intro_icon_hand_1.png',
        hand2Image: 'assets/icons/intro_icon_hand_2.png',
        backgroundColor: const Color(0xFFA5F185),
        buttonGradientStart: const Color(0xFF31F923),
        buttonGradientEnd: const Color(0xFF99FFA3),
        humanPosition: ImagePosition(top: 300 , left: 0, right: 0),
        hand1Position: const ImagePosition(top: 40, left: -5),
        hand2Position: const ImagePosition(top: 180, right: -10),
        rectangleConfigs: _createRectangleConfigs(
          startColors: const [
            Color(0xFFCDF0F9),
            Color(0xFFFFF6E5),
            Color(0xFFE8F5FF),
            Color(0xFFFFECEC),
          ],
          endColors: const [
            Color(0xFFF2FFFD),
            Color(0xFFFFE5BC),
            Color(0xFFB1E5FC),
            Color(0xFFFFB1B1),
          ],
        ),
      ),

      // Màn hình 2
      IntroContent(
        title: appLocalization.translate('intro', 'title2'),
        subtitle: appLocalization.translate('intro', 'subtitle2'),
        buttonText: appLocalization.translate('intro', 'buttonText2'),
        onButtonPressed: handleLogin,
        humanImage: 'assets/icons/intro_icon_human_standing.png',
        hand1Image: 'assets/icons/intro_icon_home_1.png',
        hand2Image: 'assets/icons/intro_icon_home_2.png',
        backgroundColor: const Color(0xFF23BFF9),
        buttonGradientStart: const Color(0xFF99E5FF),
        buttonGradientEnd: const Color(0xFF84BBFF),
        humanPosition: const ImagePosition(top: 280, left: 0),
        hand1Position: const ImagePosition(top: 40, left: 50),
        hand2Position: const ImagePosition(top: 390, right: -5),
        isHumanBehindBottom: true,
        rectangleConfigs: _createRectangleConfigs(
          startColors: const [
            Color(0xFFCDF0F9),
            Color(0xFFCDF0F9),
            Color(0xFFCDF0F9),
            Color(0xFFCDF0F9),
          ],
          endColors: const [
            Color(0xFFF2FFFD),
            Color(0xFFF2FFFD),
            Color(0xFFF2FFFD),
            Color(0xFFF2FFFD),
          ],
        ),
      ),

      // Màn hình 3
      IntroContent(
        title: appLocalization.translate('intro', 'title3'),
        subtitle: appLocalization.translate('intro', 'subtitle3'),
        buttonText: appLocalization.translate('intro', 'buttonText3'),
        onButtonPressed: handleLogin,
        humanImage: 'assets/icons/intro_icon_motobike.png',
        hand1Image: 'assets/icons/intro_icon_chair.png',
        hand2Image: 'assets/icons/intro_icon_laudry.png',
        backgroundColor: const Color(0xFFFFB69D),
        buttonGradientStart: const Color(0xFFF97523),
        buttonGradientEnd: const Color(0xFFFFD899),
        humanPosition: const ImagePosition(top: 380 , left: 0),
        hand1Position: const ImagePosition(top: 40, left: 10),
        hand2Position: const ImagePosition(top: 190, right: -5),
        rectangleConfigs: _createRectangleConfigs(
          startColors: const [
            Color(0xFFFFE4D9),
            Color(0xFFFFE4D9),
            Color(0xFFFFE4D9),
            Color(0xFFFFE4D9),
          ],
          endColors: const [
            Color(0xFFFFF6F3),
            Color(0xFFFFF6F3),
            Color(0xFFFFF6F3),
            Color(0xFFFFF6F3),
          ],
        ),
      ),
    ];
  }
}