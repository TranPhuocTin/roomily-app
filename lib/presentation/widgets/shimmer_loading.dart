import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget? child;
  final double? height;
  final double? width;
  final double? borderRadius;

  const ShimmerLoading({
    Key? key, 
    this.child,
    this.height,
    this.width,
    this.borderRadius,
  }) : assert(child != null || (height != null && width != null), 
      'Either child or both height and width must be provided'), 
      super(key: key);

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      enabled: true,
      child: child ?? Container(
        height: height,
        width: width,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius ?? 0),
        ),
      ),
    );
  }
} 