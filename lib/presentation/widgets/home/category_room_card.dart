import 'package:flutter/material.dart';

class CategoryRoomCard extends StatelessWidget {
  final String imagePath;
  final String title;
  final Gradient? gradient;
  final Color? backgroundColor;
  final Color textColor;
  final BorderRadius? borderRadius;
  final Color? decorationColor;
  final VoidCallback? onTap;

  const CategoryRoomCard({
    Key? key,
    required this.imagePath,
    required this.title,
    this.gradient,
    this.backgroundColor,
    this.textColor = Colors.white,
    this.borderRadius,
    this.decorationColor,
    this.onTap,
  }) : assert(gradient != null || backgroundColor != null, 'Either gradient or backgroundColor must be provided'),
       super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine the decoration color based on the background
    final Color circleColor = decorationColor ??
        (backgroundColor != null ?
            backgroundColor!.withOpacity(0.3) :
            Colors.white.withOpacity(0.2));

    return InkWell(
      onTap: onTap,
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      splashColor: Colors.white.withOpacity(0.3),
      highlightColor: Colors.white.withOpacity(0.1),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main card container
          Container(
            width: 160,
            height: 70,
            decoration: BoxDecoration(
              color: backgroundColor,
              gradient: gradient,
              borderRadius: borderRadius ?? BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: gradient?.colors[1] ?? Colors.cyan.shade200,
                  blurRadius: 5,
                  spreadRadius: 1,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(right: 12, left: 90),
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),

          // Decorative circle in top-right corner
          Positioned(
            top: -15,
            right: -15,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: circleColor,
                shape: BoxShape.circle,
              ),
            ),
          ),

          // Room image
          Positioned(
            top: -10,
            left: -5,
            child: Image.asset(
              imagePath,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
            ),
          ),
        ],
      ),
    );
  }
}
