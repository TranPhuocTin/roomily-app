import 'package:flutter/material.dart';

class AnimatedPositionedImage extends StatelessWidget {
  final String imagePath;
  final Animation<Offset> slideAnimation;
  final double top;
  final double? left;
  final double? right;
  final double? width;
  final double? height;
  final bool useProportionalPosition;
  final bool useProportionalSize;

  const AnimatedPositionedImage({
    super.key,
    required this.imagePath,
    required this.slideAnimation,
    required this.top,
    this.left,
    this.right,
    this.width,
    this.height,
    this.useProportionalPosition = false,
    this.useProportionalSize = false,
  }) : assert(left != null || right != null, 'Either left or right must be provided');

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate positions based on screen size if using proportional positioning
    final calculatedTop = useProportionalPosition ? top * screenSize.height : top;
    final calculatedLeft = useProportionalPosition && left != null ? left! * screenSize.width : left;
    final calculatedRight = useProportionalPosition && right != null ? right! * screenSize.width : right;
    
    // Calculate image size based on screen size if using proportional sizing
    final calculatedWidth = useProportionalSize && width != null ? width! * screenSize.width : width;
    final calculatedHeight = useProportionalSize && height != null ? height! * screenSize.height : height;
    
    // Create image widget with calculated size
    final imageWidget = Image.asset(
      imagePath,
      width: calculatedWidth,
      height: calculatedHeight,
      fit: BoxFit.contain,
    );
    
    // Handle position constraints
    if (left != null && right != null) {
      // If both left and right are specified, prioritize left and ignore right
      return Positioned(
        top: calculatedTop,
        left: calculatedLeft,
        child: SlideTransition(
          position: slideAnimation,
          child: imageWidget,
        ),
      );
    } else if (left != null) {
      // Only left is specified
      return Positioned(
        top: calculatedTop,
        left: calculatedLeft,
        child: SlideTransition(
          position: slideAnimation,
          child: imageWidget,
        ),
      );
    } else {
      // Only right is specified
      return Positioned(
        top: calculatedTop,
        right: calculatedRight,
        child: SlideTransition(
          position: slideAnimation,
          child: imageWidget,
        ),
      );
    }
  }
} 