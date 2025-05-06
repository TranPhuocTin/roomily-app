import 'package:flutter/material.dart';

class TitleBar extends StatelessWidget {
  final String imagePath;
  final String title;
  final bool isReversed;
  final Color gradientStart;
  final Color gradientEnd;
  final Color shadowColor;

  const TitleBar({
    Key? key,
    required this.imagePath,
    required this.title,
    this.isReversed = false,
    this.gradientStart = const Color(0xFFAEC3A6),
    this.gradientEnd = const Color(0xFFA4FD7E),
    this.shadowColor = const Color(0xFF14EF43),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final iconSize = screenWidth * 0.15; // 15% của chiều rộng màn hình
    final titleFontSize = screenWidth * 0.06; // 6% của chiều rộng màn hình

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [gradientStart.withValues(alpha: 0.5), gradientEnd],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: 1,
                offset: const Offset(0, 0),
              ),
            ],
          ),
          child: Row(
            children: [
              // Phần bên trái
              SizedBox(width: isReversed ? 50 : iconSize),
              
              // Phần giữa với title
              Expanded(
                child: Center(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: titleFontSize,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),

              // Phần bên phải
              SizedBox(width: isReversed ? iconSize : 50),
            ],
          ),
        ),

        // Icon chính của title bar
        Positioned(
          top: -10,
          left: isReversed ? null : -10,
          right: isReversed ? -10 : null,
          bottom: -10,
          child: Image.asset(
            imagePath,
            height: 80,
            width: 80,
            fit: BoxFit.contain,
          ),
        ),

        // Icon filter
        Positioned(
          top: 0,
          bottom: 0,
          right: isReversed ? null : 15,
          left: isReversed ? 15 : null,
          child: Center(
            child: Image.asset(
              'assets/icons/search_filter_icon.png',
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ],
    );
  }
}
