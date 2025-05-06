import 'package:flutter/material.dart';
import 'dart:math' show pi;

class AnimatedRectangle extends StatelessWidget {
  final Animation<Offset>? slideAnimation;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final Color startColor;
  final Color endColor;
  final double width;
  final double height;
  final bool useProportionalPosition;

  const AnimatedRectangle({
    super.key,
    this.slideAnimation,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.startColor = const Color(0xFFCDF0F9),
    this.endColor = const Color(0xFFF2FFFD),
    this.width = 600,
    this.height = 70,
    this.useProportionalPosition = false,
  }) : assert(
          (left != null || right != null) && (top != null || bottom != null),
          'Either (left or right) and (top or bottom) must be provided',
        );

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate positions based on screen size if using proportional positioning
    final calculatedTop = useProportionalPosition && top != null 
        ? top! * screenSize.height 
        : top;
    
    final calculatedBottom = useProportionalPosition && bottom != null 
        ? bottom! * screenSize.height 
        : bottom;
    
    final calculatedLeft = useProportionalPosition && left != null 
        ? left! * screenSize.width 
        : left;
    
    final calculatedRight = useProportionalPosition && right != null 
        ? right! * screenSize.width 
        : right;
    
    final calculatedWidth = useProportionalPosition 
        ? width * screenSize.width 
        : width;
    
    final calculatedHeight = useProportionalPosition 
        ? height * screenSize.height 
        : height;

    return Positioned(
      top: calculatedTop,
      bottom: calculatedBottom,
      left: calculatedLeft,
      right: calculatedRight,
      child: SlideTransition(
        position: slideAnimation ?? const AlwaysStoppedAnimation(Offset(0, 0)),
        child: Transform.rotate(
          angle: -35 * pi / 180, // Đổi thành -45 độ để hướng từ dưới lên
          child: Container(
            width: calculatedWidth,
            height: calculatedHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [startColor, endColor],
                begin: Alignment.bottomLeft, // Đổi điểm bắt đầu gradient
                end: Alignment.topRight, // Đổi điểm kết thúc gradient
              ),
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 