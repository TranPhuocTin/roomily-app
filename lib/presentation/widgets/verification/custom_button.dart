import 'package:flutter/material.dart';

import '../../../core/config/text_styles.dart';
import '../../../core/config/app_colors.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? backgroundColor;
  final bool isOutlined;
  final List<Widget>? leadingIcons;
  final double borderRadius;
  final bool useGradient;
  final EdgeInsetsGeometry? margin;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.backgroundColor,
    this.isOutlined = false,
    this.leadingIcons,
    this.borderRadius = 12.0,
    this.useGradient = true,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin ?? const EdgeInsets.symmetric(vertical: 8.0),
      child: isOutlined
          ? _buildOutlinedButton()
          : _buildElevatedButton(),
    );
  }

  Widget _buildOutlinedButton() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          side: BorderSide(
            color: Colors.grey.shade300,
            width: 1.0,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (leadingIcons != null) ...leadingIcons!,
            SizedBox(width: leadingIcons != null ? 12.0 : 0),
            Text(
              text,
              style: AppTextStyles.bodyLargeSemiBold.copyWith(
                color: Colors.grey.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildElevatedButton() {
    final defaultColor = backgroundColor ?? Colors.grey;
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: defaultColor.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: useGradient 
                  ? LinearGradient(
                      colors: [
                        defaultColor,
                        Color.lerp(defaultColor, Colors.white, 0.2) ?? defaultColor,
                      ],
                      begin: Alignment.bottomLeft,
                      end: Alignment.topRight,
                    )
                  : null,
              color: useGradient ? null : defaultColor,
            ),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (leadingIcons != null) ...leadingIcons!,
                  SizedBox(width: leadingIcons != null ? 12.0 : 0),
                  Text(
                    text,
                    style: AppTextStyles.bodyLargeSemiBold.copyWith(
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  if (text == 'Đăng Nhập') ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}