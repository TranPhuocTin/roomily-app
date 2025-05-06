import 'package:flutter/material.dart';

class ImagePosition {
  final double top;
  final double? left;
  final double? right;

  const ImagePosition({
    required this.top,
    this.left,
    this.right,
  }) : assert(left != null || right != null, 'Either left or right must be provided');
}

class IntroContent {
  final String title;
  final String subtitle;
  final String buttonText;
  final VoidCallback onButtonPressed;
  final String humanImage;
  final String hand1Image;
  final String hand2Image;
  // final String rectangleImage;
  final Color backgroundColor;
  final Color buttonGradientStart;
  final Color buttonGradientEnd;
  final List<RectangleConfig> rectangleConfigs;
  
  // New position configurations
  final ImagePosition humanPosition;
  final ImagePosition hand1Position;
  final ImagePosition hand2Position;
  final bool isHumanBehindBottom;
  final bool isHand2BehindBottom;

  const IntroContent({
    required this.title,
    required this.subtitle,
    required this.buttonText,
    required this.onButtonPressed,
    required this.humanImage,
    required this.hand1Image,
    required this.hand2Image,
    // required this.rectangleImage,
    required this.backgroundColor,
    required this.buttonGradientStart,
    required this.buttonGradientEnd,
    required this.rectangleConfigs,
    required this.humanPosition,
    required this.hand1Position,
    required this.hand2Position,
    this.isHumanBehindBottom = false,
    this.isHand2BehindBottom = false,
  });
}

class RectangleConfig {
  final RectanglePosition position;
  final Color startColor;
  final Color endColor;
  final double width;
  final double height;

  const RectangleConfig({
    required this.position,
    required this.startColor,
    required this.endColor,
    required this.width,
    required this.height,
  });
}

class RectanglePosition {
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;

  const RectanglePosition({
    this.top,
    this.bottom,
    this.left,
    this.right,
  });
} 