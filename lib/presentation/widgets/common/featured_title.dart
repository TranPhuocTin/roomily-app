import 'package:flutter/material.dart';

class FeaturedTitle extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAllPressed;
  final Color backgroundColor;
  final Color gradientStart;
  final Color gradientEnd;
  final Color shadowColor;
  final Color textColor;
  final String imagePath;

  const FeaturedTitle({
    Key? key,
    required this.title,
    this.onSeeAllPressed,
    this.backgroundColor = Colors.green,
    this.gradientStart = const Color(0xFF4FD860),
    this.gradientEnd = const Color(0xFF9FFF50),
    this.shadowColor = const Color(0xFFFF0000),
    this.textColor = Colors.white,
    this.imagePath = 'assets/icons/featured_section_header.png',
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Left side: Title with flame icon
        Container(
          height: 35,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(10),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [gradientStart, gradientEnd],
            ),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Row(
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
                  VerticalDivider(color: textColor),
                  const SizedBox(width: 20),
                ],
              ),
              Positioned(
                right: -8,
                top: -15,
                child: Image.asset(
                  imagePath,
                ),
              ),
            ],
          ),
        ),

        // Right side: "Xem Thêm" button
        if (onSeeAllPressed != null)
          TextButton(
            onPressed: onSeeAllPressed,
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Row(
              children: [
                Text(
                  'Xem Thêm',
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: gradientEnd,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.play_arrow,
                  size: 16,
                  color: gradientEnd,
                ),
              ],
            ),
          ),
      ],
    );
  }
}
