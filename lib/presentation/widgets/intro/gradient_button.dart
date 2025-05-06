import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final Color gradientColor1;
  final Color gradientColor2;
  final double? width; // Optional width parameter
  final double? height; // Optional height parameter
  final bool useResponsiveSize; // Flag for responsive sizing

  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    required this.gradientColor1,
    required this.gradientColor2,
    this.width, // Optional
    this.height, // Optional
    this.useResponsiveSize = true, // Default to responsive
  });

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    // Calculate responsive dimensions
    final buttonWidth = useResponsiveSize 
        ? width ?? screenSize.width * 0.7 // 70% of screen width by default
        : width ?? 250; // Fixed width if not responsive
        
    final buttonHeight = useResponsiveSize 
        ? height ?? screenSize.height * 0.07 // 7% of screen height by default
        : height ?? 60; // Fixed height if not responsive
    
    final fontSize = useResponsiveSize 
        ? screenSize.width * 0.045 // Responsive font size
        : 18.0; // Fixed font size
        
    final iconSize = useResponsiveSize 
        ? screenSize.width * 0.04 // Responsive icon size
        : 16.0; // Fixed icon size
    
    return Container(
      width: buttonWidth,
      height: buttonHeight,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientColor2, gradientColor1],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(buttonHeight * 0.33), // Responsive border radius
        boxShadow: [
          // Inner glow with gradientColor1
          BoxShadow(
            color: gradientColor1.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          // Outer glow with gradientColor2
          BoxShadow(
            color: gradientColor2.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
          ),
          // Middle glow with interpolation of colors
          BoxShadow(
            color: Color.lerp(gradientColor1, gradientColor2, 0.5)!.withOpacity(0.3),
            blurRadius: 15,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(buttonHeight * 0.5), // Responsive border radius
          ),
          padding: EdgeInsets.zero,
        ),
        child: Stack(
          children: [
            // Text in the center
            Center(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                maxLines: 1,
              ),
            ),
            // Arrow on the right
            Positioned(
              right: buttonWidth * 0.08, // Responsive positioning
              top: 0,
              bottom: 0,
              child: Center(
                child: Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white,
                  size: iconSize,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}