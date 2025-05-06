import 'package:flutter/material.dart';
import 'dart:math' as math;

// Widget mới để theo dõi và cập nhật trạng thái chạm
class TouchFeedback extends StatefulWidget {
  final Widget child;
  final Function() onTouchStart;
  final Function() onTouchEnd;
  final bool forceShowEffect;

  const TouchFeedback({
    Key? key,
    required this.child,
    required this.onTouchStart,
    required this.onTouchEnd,
    this.forceShowEffect = false,
  }) : super(key: key);

  @override
  State<TouchFeedback> createState() => _TouchFeedbackState();
}

class _TouchFeedbackState extends State<TouchFeedback> {
  bool _isTouched = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) {
        setState(() {
          _isTouched = true;
        });
        widget.onTouchStart();
      },
      onTapUp: (_) {
        setState(() {
          _isTouched = false;
        });
        widget.onTouchEnd();
      },
      onTapCancel: () {
        setState(() {
          _isTouched = false;
        });
        widget.onTouchEnd();
      },
      onLongPressStart: (_) {
        setState(() {
          _isTouched = true;
        });
        widget.onTouchStart();
      },
      onLongPressEnd: (_) {
        setState(() {
          _isTouched = false;
        });
        widget.onTouchEnd();
      },
      onLongPressCancel: () {
        setState(() {
          _isTouched = false;
        });
        widget.onTouchEnd();
      },
      child: widget.child,
    );
  }
}

class SpeechButton extends StatefulWidget {
  final Function() onListen;
  final Function() onStop;
  final bool isListening;
  final double soundLevel;
  
  const SpeechButton({
    Key? key, 
    required this.onListen,
    required this.onStop,
    required this.isListening,
    this.soundLevel = 0.0,
  }) : super(key: key);

  @override
  State<SpeechButton> createState() => _SpeechButtonState();
}

class _SpeechButtonState extends State<SpeechButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _iconRotateAnimation;
  late Animation<Color?> _iconColorAnimation;
  
  // Thêm biến trạng thái để theo dõi khi nút đang được nhấn
  bool _isPressed = false;
  
  // Thêm biến để mô phỏng soundLevel khi không có dữ liệu thực
  double _simulatedSoundLevel = 0.0;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _iconRotateAnimation = Tween<double>(begin: 0, end: 0.05).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _iconColorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.white.withOpacity(0.7),
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
    
    _animationController.repeat(reverse: true);
    
    // Bắt đầu mô phỏng soundLevel
    _startSoundLevelSimulation();
  }
  
  // Mô phỏng soundLevel khi không có dữ liệu thực
  void _startSoundLevelSimulation() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          if (_isPressed || widget.isListening) {
            // Tạo giá trị ngẫu nhiên từ 1.0 đến 3.0 để mô phỏng âm thanh
            _simulatedSoundLevel = 1.0 + math.Random().nextDouble() * 2.0;
          } else {
            _simulatedSoundLevel = 0.0;
          }
        });
        // Tiếp tục mô phỏng
        _startSoundLevelSimulation();
      }
    });
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Sử dụng isPressed hoặc isListening để hiển thị hiệu ứng
    final bool showEffects = widget.isListening || _isPressed;
    
    // Sử dụng soundLevel thực từ widget nếu đang lắng nghe, hoặc giá trị mô phỏng nếu đang nhấn
    final double effectiveSoundLevel;
    if (widget.isListening && widget.soundLevel > 0) {
      effectiveSoundLevel = widget.soundLevel;
    } else if (_isPressed) {
      effectiveSoundLevel = _simulatedSoundLevel;
    } else {
      effectiveSoundLevel = 0.0;
    }
    
    final maxRippleSize = showEffects ? (effectiveSoundLevel * 2.0).clamp(1.0, 5.0) : 0.0;
    
    // Debug print để xem trạng thái
    debugPrint("SpeechButton build - isListening: ${widget.isListening}, soundLevel: ${widget.soundLevel}, isPressed: $_isPressed, effective: $effectiveSoundLevel");
    
    return TouchFeedback(
      onTouchStart: () {
        debugPrint("TouchFeedback start - setting isPressed to true");
        setState(() {
          _isPressed = true;
        });
        widget.onListen();
      },
      onTouchEnd: () {
        debugPrint("TouchFeedback end - setting isPressed to false");
        setState(() {
          _isPressed = false;
        });
        widget.onStop();
      },
      forceShowEffect: widget.isListening,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: showEffects 
                      ? theme.colorScheme.primary.withOpacity(0.3)
                      : Colors.grey.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 3,
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Pulse ripple effect when listening
                if (showEffects) 
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 100 + maxRippleSize * 10,
                    height: 100 + maxRippleSize * 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                
                // Sound wave animation
                if (showEffects)
                  ...List.generate(3, (index) {
                    final delay = index * 0.2;
                    final animValue = ((_animationController.value + delay) % 1.0);
                    final size = 80 + (animValue * 50);
                    final opacity = (1 - animValue) * 0.5;
                    
                    return Positioned.fill(
                      child: Center(
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.red.withOpacity(opacity),
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                
                // Main button with pulse animation when listening
                Transform.scale(
                  scale: showEffects ? _pulseAnimation.value : 1.0,
                  child: Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: showEffects
                            ? [Colors.redAccent, Colors.red.shade900]
                            : [theme.colorScheme.primary, theme.colorScheme.primary.withBlue(220)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: showEffects
                              ? Colors.red.withOpacity(0.5)
                              : theme.colorScheme.primary.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: Center(
                      child: showEffects
                        ? Transform.rotate(
                            angle: _iconRotateAnimation.value,
                            child: _AnimatedMicIcon(
                              color: _iconColorAnimation.value ?? Colors.white,
                              isListening: showEffects,
                              soundLevel: effectiveSoundLevel,
                            ),
                          )
                        : const Icon(
                            Icons.mic,
                            color: Colors.white,
                            size: 36,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _AnimatedMicIcon extends StatefulWidget {
  final Color color;
  final bool isListening;
  final double soundLevel;
  
  const _AnimatedMicIcon({
    required this.color,
    required this.isListening,
    required this.soundLevel,
  });
  
  @override
  _AnimatedMicIconState createState() => _AnimatedMicIconState();
}

class _AnimatedMicIconState extends State<_AnimatedMicIcon> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;
  
  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _waveController.repeat(reverse: true);
  }
  
  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _waveController,
      builder: (context, child) {
        return CustomPaint(
          size: const Size(36, 36),
          painter: _MicrophonePainter(
            color: widget.color,
            waveProgress: _waveController.value,
            soundLevel: widget.soundLevel,
          ),
        );
      },
    );
  }
}

class _MicrophonePainter extends CustomPainter {
  final Color color;
  final double waveProgress;
  final double soundLevel;
  
  _MicrophonePainter({
    required this.color,
    required this.waveProgress,
    required this.soundLevel,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    
    final micWidth = size.width * 0.5;
    final micHeight = size.height * 0.6;
    final baseWidth = size.width * 0.7;
    final baseHeight = size.height * 0.15;
    
    // Draw microphone body
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height / 2 - baseHeight / 2),
        width: micWidth,
        height: micHeight,
      ),
      Radius.circular(micWidth / 2),
    );
    canvas.drawRRect(bodyRect, paint);
    
    // Draw microphone base
    final baseRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(size.width / 2, size.height - baseHeight / 2),
        width: baseWidth,
        height: baseHeight,
      ),
      Radius.circular(baseHeight / 2),
    );
    canvas.drawRRect(baseRect, paint);
    
    // Connect body to base
    final connectRect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - baseHeight - micHeight * 0.2),
      width: micWidth * 0.3,
      height: micHeight * 0.4,
    );
    canvas.drawRect(connectRect, paint);
    
    // Draw sound waves
    if (soundLevel > 0) {
      final wavePaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      
      final waveCount = 3;
      final waveCenter = Offset(size.width / 2, size.height / 2 - baseHeight / 2);
      
      for (int i = 0; i < waveCount; i++) {
        final waveOffset = i * 0.3;
        final currentProgress = (waveProgress + waveOffset) % 1.0;
        final waveRadius = (micWidth / 2) + (currentProgress * size.width * 0.3);
        final waveOpacity = (1 - currentProgress) * 0.8;
        
        wavePaint.color = color.withOpacity(waveOpacity);
        canvas.drawCircle(waveCenter, waveRadius, wavePaint);
      }
    }
  }
  
  @override
  bool shouldRepaint(_MicrophonePainter oldDelegate) {
    return oldDelegate.waveProgress != waveProgress || 
           oldDelegate.color != color ||
           oldDelegate.soundLevel != soundLevel;
  }
} 