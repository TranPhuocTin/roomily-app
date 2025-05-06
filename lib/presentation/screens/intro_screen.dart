import 'package:flutter/material.dart';
import 'dart:math';
import '../widgets/intro/gradient_button.dart';
import '../widgets/intro/intro_bottom_container.dart';
import '../widgets/intro/animated_positioned_image.dart';
import '../widgets/intro/animated_rectangle.dart';
import 'intro_screens/models/intro_content.dart';

// Base widget cho intro screen
class BaseIntroScreen extends StatefulWidget {
  final IntroContent content;
  // final VoidCallback? onSkip;
  final VoidCallback? onNext;
  final int currentPage;
  final int totalPages;

  const BaseIntroScreen({
    super.key,
    required this.content,
    // this.onSkip,
    this.onNext,
    this.currentPage = 0,
    this.totalPages = 3,
  });

  @override
  State<BaseIntroScreen> createState() => _BaseIntroScreenState();
}

class _BaseIntroScreenState extends State<BaseIntroScreen> with TickerProviderStateMixin {
  late AnimationController _handController1;
  late AnimationController _handController2;
  late AnimationController _humanController;
  late AnimationController _bottomContainerController;
  late List<AnimationController> _rectangleControllers;
  late List<Animation<Offset>> _rectangleAnimations;
  late Animation<Offset> _slideAnimation1;
  late Animation<Offset> _slideAnimation2;
  late Animation<Offset> _slideAnimationHuman;
  late Animation<Offset> _slideAnimationBottom;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startAnimations();
  }

  void _initializeAnimations() {
    // Animation cho bàn tay 1 (từ trái vào)
    _handController1 = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation1 = Tween<Offset>(
      begin: const Offset(-2, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _handController1,
      curve: Curves.easeOutCubic,
    ));

    // Animation cho bàn tay 2 (từ phải vào)
    _handController2 = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _slideAnimation2 = Tween<Offset>(
      begin: const Offset(2, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _handController2,
      curve: Curves.easeOutCubic,
    ));

    // Animation cho người ngồi (từ phải qua trái)
    _humanController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _slideAnimationHuman = Tween<Offset>(
      begin: const Offset(2, 0),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _humanController,
      curve: Curves.easeOutQuint,
    ));

    // Animation cho container phía dưới
    _bottomContainerController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );
    _slideAnimationBottom = Tween<Offset>(
      begin: const Offset(0, 1),
      end: const Offset(0, 0),
    ).animate(CurvedAnimation(
      parent: _bottomContainerController,
      curve: Curves.easeOutExpo,
    ));

    // Animation cho các rectangle
    _rectangleControllers = List.generate(
      4,
      (index) => AnimationController(
        duration: const Duration(milliseconds: 750),
        vsync: this,
      ),
    );

    final double angle = 45 * (pi / 180);
    final double distance = 3.0;

    _rectangleAnimations = List.generate(4, (index) {
      final bool isRightSide = index % 2 == 1;
      final double moveX = distance * (isRightSide ? 1 : -1);
      final double moveY = distance * (isRightSide ? 1 : -1);

      return Tween<Offset>(
        begin: Offset(moveX, moveY),
        end: const Offset(0, 0),
      ).animate(CurvedAnimation(
        parent: _rectangleControllers[index],
        curve: Curves.easeOutQuint,
      ));
    });
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 50), () {
      for (var i = 0; i < _rectangleControllers.length; i++) {
        Future.delayed(Duration(milliseconds: i * 75), () {
          _rectangleControllers[i].forward();
        });
      }

      Future.delayed(const Duration(milliseconds: 400), () {
        _handController1.forward();
        Future.delayed(const Duration(milliseconds: 100), () {
          _handController2.forward();
          Future.delayed(const Duration(milliseconds: 100), () {
            _bottomContainerController.forward();
            Future.delayed(const Duration(milliseconds: 100), () {
              _humanController.forward();
            });
          });
        });
      });
    });
  }

  Future<void> _reverseAnimations(VoidCallback onComplete) async {
    try {
      await Future.wait([
        _bottomContainerController.reverse().orCancel,
        _humanController.reverse().orCancel,
        _handController1.reverse().orCancel,
        _handController2.reverse().orCancel,
        ..._rectangleControllers.map((controller) => controller.reverse().orCancel),
      ]);

      if (mounted) {
        onComplete();
      }
    } catch (e) {
      debugPrint('Animation cancelled: $e');
    }
  }

  @override
  void dispose() {
    _handController1.dispose();
    _handController2.dispose();
    _humanController.dispose();
    _bottomContainerController.dispose();
    for (var controller in _rectangleControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(color: widget.content.backgroundColor),

          // Rectangle animations
          _buildRectangles(),

          // Hand1 animation (always on top)
          AnimatedPositionedImage(
            imagePath: widget.content.hand1Image,
            slideAnimation: _slideAnimation1,
            top: widget.content.hand1Position.top,
            left: widget.content.hand1Position.left,
            right: widget.content.hand1Position.right,
          ),

          // Conditionally order human, hand2 and bottom container
          if (widget.content.isHumanBehindBottom && widget.content.isHand2BehindBottom) ...[
            // Human and Hand2 behind
            AnimatedPositionedImage(
              imagePath: widget.content.humanImage,
              slideAnimation: _slideAnimationHuman,
              top: widget.content.humanPosition.top,
              left: widget.content.humanPosition.left,
              right: widget.content.humanPosition.right,
            ),
            AnimatedPositionedImage(
              imagePath: widget.content.hand2Image,
              slideAnimation: _slideAnimation2,
              top: widget.content.hand2Position.top,
              left: widget.content.hand2Position.left,
              right: widget.content.hand2Position.right,
            ),
            // Bottom container in front
            IntroBottomContainer(
              title: widget.content.title,
              subtitle: widget.content.subtitle,
              buttonText: widget.content.buttonText,
              onButtonPressed: widget.content.onButtonPressed,
              backgroundColor: widget.content.backgroundColor,
              buttonGradientStart: widget.content.buttonGradientStart,
              buttonGradientEnd: widget.content.buttonGradientEnd,
              // onSkip: widget.onSkip,
              onNext: widget.onNext == null
                  ? null
                  : () {
                      _reverseAnimations(() {
                        widget.onNext?.call();
                      });
                    },
              currentPage: widget.currentPage,
              totalPages: widget.totalPages,
              slideAnimation: _slideAnimationBottom,
            ),
          ] else if (widget.content.isHumanBehindBottom) ...[
            // Only Human behind
            AnimatedPositionedImage(
              imagePath: widget.content.humanImage,
              slideAnimation: _slideAnimationHuman,
              top: widget.content.humanPosition.top,
              left: widget.content.humanPosition.left,
              right: widget.content.humanPosition.right,
            ),
            IntroBottomContainer(
              title: widget.content.title,
              subtitle: widget.content.subtitle,
              buttonText: widget.content.buttonText,
              onButtonPressed: widget.content.onButtonPressed,
              backgroundColor: widget.content.backgroundColor,
              buttonGradientStart: widget.content.buttonGradientStart,
              buttonGradientEnd: widget.content.buttonGradientEnd,
              // onSkip: widget.onSkip,
              onNext: widget.onNext == null
                  ? null
                  : () {
                      _reverseAnimations(() {
                        widget.onNext?.call();
                      });
                    },
              currentPage: widget.currentPage,
              totalPages: widget.totalPages,
              slideAnimation: _slideAnimationBottom,
            ),
            AnimatedPositionedImage(
              imagePath: widget.content.hand2Image,
              slideAnimation: _slideAnimation2,
              top: widget.content.hand2Position.top,
              left: widget.content.hand2Position.left,
              right: widget.content.hand2Position.right,
            ),
          ] else if (widget.content.isHand2BehindBottom) ...[
            // Only Hand2 behind
            AnimatedPositionedImage(
              imagePath: widget.content.hand2Image,
              slideAnimation: _slideAnimation2,
              top: widget.content.hand2Position.top,
              left: widget.content.hand2Position.left,
              right: widget.content.hand2Position.right,
            ),
            IntroBottomContainer(
              title: widget.content.title,
              subtitle: widget.content.subtitle,
              buttonText: widget.content.buttonText,
              onButtonPressed: widget.content.onButtonPressed,
              backgroundColor: widget.content.backgroundColor,
              buttonGradientStart: widget.content.buttonGradientStart,
              buttonGradientEnd: widget.content.buttonGradientEnd,
              // onSkip: widget.onSkip,
              onNext: widget.onNext == null
                  ? null
                  : () {
                      _reverseAnimations(() {
                        widget.onNext?.call();
                      });
                    },
              currentPage: widget.currentPage,
              totalPages: widget.totalPages,
              slideAnimation: _slideAnimationBottom,
            ),
            AnimatedPositionedImage(
              imagePath: widget.content.humanImage,
              slideAnimation: _slideAnimationHuman,
              top: widget.content.humanPosition.top,
              left: widget.content.humanPosition.left,
              right: widget.content.humanPosition.right,
            ),
          ] else ...[
            // Everything in front of bottom container
            IntroBottomContainer(
              title: widget.content.title,
              subtitle: widget.content.subtitle,
              buttonText: widget.content.buttonText,
              onButtonPressed: widget.content.onButtonPressed,
              backgroundColor: widget.content.backgroundColor,
              buttonGradientStart: widget.content.buttonGradientStart,
              buttonGradientEnd: widget.content.buttonGradientEnd,
              // onSkip: widget.onSkip,
              onNext: widget.onNext == null
                  ? null
                  : () {
                      _reverseAnimations(() {
                        widget.onNext?.call();
                      });
                    },
              currentPage: widget.currentPage,
              totalPages: widget.totalPages,
              slideAnimation: _slideAnimationBottom,
            ),
            AnimatedPositionedImage(
              imagePath: widget.content.humanImage,
              slideAnimation: _slideAnimationHuman,
              top: widget.content.humanPosition.top,
              left: widget.content.humanPosition.left,
              right: widget.content.humanPosition.right,
            ),
            AnimatedPositionedImage(
              imagePath: widget.content.hand2Image,
              slideAnimation: _slideAnimation2,
              top: widget.content.hand2Position.top,
              left: widget.content.hand2Position.left,
              right: widget.content.hand2Position.right,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRectangles() {
    return Stack(
      children: [
        AnimatedRectangle(
          slideAnimation: _rectangleAnimations[0],
          top: -80,
          left: -100,
          startColor: const Color(0xFFCDF0F9),
          endColor: const Color(0xFFF2FFFD),
          width: 600,
          height: 70,
        ),
        AnimatedRectangle(
          slideAnimation: _rectangleAnimations[1],
          top: -60,
          right: -300,
          startColor: const Color(0xFFCDF0F9),
          endColor: const Color(0xFFF2FFFD),
          width: 550,
          height: 65,
        ),
        AnimatedRectangle(
          slideAnimation: _rectangleAnimations[2],
          left: -300,
          bottom: 450,
          startColor: const Color(0xFFCDF0F9),
          endColor: const Color(0xFFF2FFFD),
          width: 500,
          height: 60,
        ),
        AnimatedRectangle(
          slideAnimation: _rectangleAnimations[3],
          right: -300,
          bottom: 500,
          startColor: const Color(0xFFCDF0F9),
          endColor: const Color(0xFFF2FFFD),
          width: 580,
          height: 68,
        ),
      ],
    );
  }
}

