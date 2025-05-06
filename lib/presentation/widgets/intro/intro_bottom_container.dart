import 'package:flutter/material.dart';
import 'gradient_button.dart';
import '../../../core/localization/app_localization.dart';

class IntroBottomContainer extends StatelessWidget {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final Color backgroundColor;
  final Color buttonGradientStart;
  final Color buttonGradientEnd;
  final VoidCallback? onSkip;
  final VoidCallback? onNext;
  final int currentPage;
  final int totalPages;
  final Animation<Offset> slideAnimation;

  const IntroBottomContainer({
    super.key,
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onButtonPressed,
    required this.backgroundColor,
    required this.buttonGradientStart,
    required this.buttonGradientEnd,
    required this.slideAnimation,
    this.onSkip,
    this.onNext,
    this.currentPage = 0,
    this.totalPages = 3,
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final appLocalization = AppLocalization.of(context);
    
    return Positioned(
      bottom: 0,
      right: 0,
      left: 0,
      child: SlideTransition(
        position: slideAnimation,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(50),
              topLeft: Radius.circular(50),
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                screenSize.width * 0.05, // Responsive horizontal padding
                0,
                screenSize.width * 0.05,
                0
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: screenSize.height * 0.01), // Responsive spacing
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.055, // Responsive font size
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                      fontFamily: 'Baloo 2',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenSize.height * 0.005), // Responsive spacing
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: screenSize.width * 0.04, // Responsive font size
                      color: Colors.black,
                      fontFamily: 'Baloo 2',
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: screenSize.height * 0.02), // Responsive spacing
                  GradientButton(
                    text: buttonText,
                    gradientColor1: buttonGradientStart,
                    gradientColor2: buttonGradientEnd,
                    onPressed: onButtonPressed,
                  ),
                  SizedBox(height: screenSize.height * 0.01), // Responsive spacing
                  
                  // Navigation section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: onSkip,
                        child: Text(
                          appLocalization.translate('intro', 'skip'),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: screenSize.width * 0.04, // Responsive font size
                            fontFamily: 'Baloo 2',
                          ),
                        ),
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: List.generate(
                          totalPages,
                          (index) => Container(
                            width: screenSize.width * 0.02, // Responsive dot size
                            height: screenSize.width * 0.02,
                            margin: EdgeInsets.symmetric(
                              horizontal: screenSize.width * 0.01, // Responsive margin
                            ),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: index == currentPage
                                  ? backgroundColor
                                  : Colors.grey[300],
                            ),
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: onNext,
                        child: Text(
                          appLocalization.translate('intro', 'next'),
                          style: TextStyle(
                            color: backgroundColor,
                            fontSize: screenSize.width * 0.04, // Responsive font size
                            fontFamily: 'Baloo 2',
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 