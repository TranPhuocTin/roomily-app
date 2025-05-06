import 'package:flutter/material.dart';
import 'package:roomily/core/config/app_colors.dart';
import 'package:roomily/core/config/text_styles.dart';

class FeatureButtonData {
  final String imagePath;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final Color color;
  final Color iconColor;
  final LinearGradient gradient;

  FeatureButtonData({
    required this.imagePath,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.iconColor,
    required this.gradient,
  });
}

class FeatureButtonsSection extends StatelessWidget {
  final List<FeatureButtonData> features;
  final Function(int)? onFeatureTap;

  const FeatureButtonsSection({
    Key? key,
    required this.features,
    this.onFeatureTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.homeFeatureGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      padding: const EdgeInsets.only(left: 5, right: 5, top: 5, bottom: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Sidebar with text and button
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'TÍNH NĂNG',
                  style: AppTextStyles.bodyMediumSemiBold.copyWith(
                      color: Color(0xFF6D53FF),
                      fontSize: 10
                  ),
                ),
                const SizedBox(height: 10),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF23F938), Color(0xFF99FFA8)], // Gradient colors
                        begin: Alignment.topRight,
                        end: Alignment.topLeft,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          spreadRadius: 2,
                          blurRadius: 5,
                          offset: Offset(0, 3), // Shadow position
                        ),
                      ],
                    ),
                    constraints: BoxConstraints(
                      minWidth: 70,
                      minHeight: 25,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'KHÁM PHÁ',
                      style: AppTextStyles.bodyXSmallBold.copyWith(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Space between sidebar and main section
          const SizedBox(width: 8),
          // Main feature section
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final double buttonWidth = (constraints.maxWidth - 32) / 3;
                  final double iconSize = buttonWidth * 0.4;

                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(
                      features.length,
                          (index) => GestureDetector(
                        onTap: () {
                          if (onFeatureTap != null) {
                            onFeatureTap!(index);
                          }
                        },
                        child: FeatureButton(
                          data: features[index],
                          width: buttonWidth,
                          iconSize: iconSize,
                          gradient: features[index].gradient,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FeatureButton extends StatelessWidget {
  final FeatureButtonData data;
  final double width;
  final double iconSize;
  final LinearGradient gradient;

  const FeatureButton({
    Key? key,
    required this.data,
    required this.width,
    required this.iconSize,
    required this.gradient,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double newIconSize = iconSize * 2;
    return SizedBox(
      width: width,
      height: width * 1.3,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          // Main container with border
          Positioned(
            top: iconSize / 1.5,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                gradient: gradient,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: EdgeInsets.only(
                  top: iconSize + 8,
                  left: 4,
                  right: 4,
                  bottom: 12,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.title,
                        style: TextStyle(
                          color: data.color,
                          fontWeight: FontWeight.bold,
                          fontSize: width * 0.12,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        data.subtitle,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: width * 0.08,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Icon container with image
          Image.asset(
            data.imagePath,
            width: newIconSize,
            height: newIconSize,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Icon(
                data.fallbackIcon,
                color: Colors.white,
                size: newIconSize * 0.6,
              );
            },
          ),
        ],
      ),
    );
  }
}