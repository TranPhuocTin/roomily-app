import 'package:flutter/material.dart';

import '../../../core/config/text_styles.dart';
import '../../../core/localization/app_localization.dart';
import '../intro/gradient_button.dart';
import 'custom_button.dart';

class LoginColumn extends StatelessWidget {
  final VoidCallback? onLoginPressed;
  final VoidCallback? onGooglePressed;
  final VoidCallback? onFacebookPressed;
  final VoidCallback? onSignUpPressed;
  final String? buttonText;
  final bool showSocialLogins;
  final double? width;

  const LoginColumn({
    super.key,
    this.onLoginPressed,
    this.onGooglePressed,
    this.onFacebookPressed,
    this.onSignUpPressed,
    this.buttonText,
    this.showSocialLogins = true,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    // Lấy đối tượng localization
    final appLocalization = AppLocalization.of(context);
    
    // Lấy chiều cao màn hình để điều chỉnh padding
    final screenHeight = MediaQuery.of(context).size.height;
    final verticalPadding = screenHeight < 700 ? 8.0 : 16.0;
    
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min, // Giảm thiểu chiều cao
      children: [
        GradientButton(
            width: width,
            text: buttonText ?? appLocalization.translate('auth', 'signIn'),
            onPressed: onLoginPressed ?? () {
              print('Login button pressed but no action provided');
            },
            gradientColor1: Color(0xFF23BFF9),
            gradientColor2: Color(0xFF99E5FF)),
        // Padding(
        //   padding: EdgeInsets.symmetric(vertical: verticalPadding),
        //   child: Text(
        //     appLocalization.translate('auth', 'or'),
        //     style: TextStyle(
        //       color: Colors.grey,
        //       fontSize: 14, // Giảm kích thước font
        //     ),
        //   ),
        // ),
        // if (showSocialLogins) ...[
        //   CustomButton(
        //     text: appLocalization.translate('auth', 'loginWithGoogle'),
        //     onPressed: onGooglePressed,
        //     isOutlined: true,
        //     margin: EdgeInsets.symmetric(vertical: 4), // Giảm margin
        //     leadingIcons: [
        //       Image.asset(
        //         'assets/icons/google_icon.png',
        //         width: 20, // Giảm kích thước icon
        //         height: 20,
        //       ),
        //     ],
        //   ),
        //   // Đã comment Facebook button để tiết kiệm không gian
        // ],
        // Padding(
        //     padding: EdgeInsets.only(top: verticalPadding),
        //     child: Row(
        //       mainAxisAlignment: MainAxisAlignment.center,
        //       children: [
        //         Text(
        //           buttonText == appLocalization.translate('auth', 'signUp')
        //               ? appLocalization.translate('auth', 'haveAccount')
        //               : appLocalization.translate('auth', 'dontHaveAccount'),
        //           style: AppTextStyles.bodyMediumBold, // Sử dụng font nhỏ hơn
        //         ),
        //         TextButton(
        //           onPressed: onSignUpPressed,
        //           style: TextButton.styleFrom(
        //             padding: EdgeInsets.symmetric(horizontal: 4), // Giảm padding
        //           ),
        //           child: Text(
        //             buttonText == appLocalization.translate('auth', 'signUp')
        //                 ? appLocalization.translate('auth', 'signIn')
        //                 : appLocalization.translate('auth', 'signUp'),
        //             style: AppTextStyles.bodyMediumBold
        //                 .copyWith(color: const Color(0xFF28C1FA)),
        //           ),
        //         ),
        //       ],
        //     )),
      ],
    );
  }
}
