import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_cubit.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_state.dart';
import 'package:roomily/data/models/budget_plan_preference.dart';
import 'package:roomily/presentation/screens/budget_plan_preference_screen.dart';


class SpeechBudgetPlanScreen extends StatefulWidget {
  const SpeechBudgetPlanScreen({Key? key}) : super(key: key);

  @override
  State<SpeechBudgetPlanScreen> createState() => _SpeechBudgetPlanScreenState();
}

class _SpeechBudgetPlanScreenState extends State<SpeechBudgetPlanScreen> with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  
  // Text editing controller for manual input
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  
  // For animations
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // For sound level visualization
  double _soundLevel = 0.0;
  
  // For processing state
  bool _isProcessing = false;
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    // Create a looping pulse animation
    _animation = Tween<double>(begin: 1.0, end: 1.5)
      .animate(CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ));
      
    _animationController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        _animationController.forward();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  /// Initialize speech recognition
  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onStatus: _onSpeechStatus,
      onError: (error) => print('Speech error: $error'),
    );
    setState(() {});
  }

  /// Listen for speech input
  void _startListening() async {
    // Save current text if any
    if (_textController.text.isNotEmpty) {
      _lastWords = _textController.text;
    }
    
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 120),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      onSoundLevelChange: _onSoundLevelChange,
      cancelOnError: false,
      listenMode: ListenMode.dictation,
    );
    
    // Start animation
    _animationController.forward();
    
    setState(() {});
  }

  /// Stop listening for speech
  void _stopListening() async {
    await _speechToText.stop();
    _animationController.stop();
    _animationController.reset();
    
    // Update text controller with final speech result
    _textController.text = _lastWords;
    
    setState(() {
      _soundLevel = 0;
    });
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      // Update text field with recognized speech
      _textController.text = result.recognizedWords;
    });
    
    // No longer automatically processing the speech after recognition
  }
  
  /// Process the recognized speech to extract budget preferences
  void _processText() {
    if (_textController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập hoặc nói yêu cầu của bạn'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    
    setState(() {
      _isProcessing = true;
    });
    
    // Use the budget plan cubit to extract preferences
    context.read<BudgetPlanCubit>().extractUserPrompt(_textController.text);
  }
  
  /// Handle sound level changes
  void _onSoundLevelChange(double level) {
    setState(() {
      _soundLevel = level;
    });
  }
  
  /// Handle speech status changes
  void _onSpeechStatus(String status) {
    print('Speech status: $status');
    if (status == 'done' || status == 'notListening') {
      _animationController.stop();
      _animationController.reset();
      setState(() {
        _soundLevel = 0;
      });
    }
  }
  
  /// Reset the state and try again
  void _resetState() {
    setState(() {
      _lastWords = '';
      _isProcessing = false;
      _textController.clear();
    });
  }
  
  /// Navigate to results screen with the preferences
  void _navigateToResults(BudgetPlanPreference preference) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetPlanPreferenceScreen(
          initialPreference: preference,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lập Kế Hoạch Ngân Sách Bằng Giọng Nói'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const BudgetPlanPreferenceScreen(),
                ),
              );
            },
            child: const Text(
              'Bỏ qua',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade700, Colors.blue.shade500],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: BlocListener<BudgetPlanCubit, BudgetPlanState>(
        listener: (context, state) {
          if (state.status == BudgetPlanStatus.success && state.preference != null && _isProcessing) {
            // Navigate to results with the extracted preferences
            _navigateToResults(state.preference!);
          } else if (state.status == BudgetPlanStatus.failure && _isProcessing) {
            // Show an error snackbar
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.errorMessage ?? 'Không thể xử lý yêu cầu của bạn'),
                backgroundColor: Colors.red,
                action: SnackBarAction(
                  label: 'Thử lại',
                  onPressed: _resetState,
                  textColor: Colors.white,
                ),
              ),
            );
            _resetState();
          }
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.blue.shade50, Colors.white],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  
                  // Instructions card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade500, Colors.blue.shade600],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200.withOpacity(0.5),
                          spreadRadius: 2,
                          blurRadius: 7,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.tips_and_updates, color: Colors.white, size: 28),
                        SizedBox(height: 8),
                        Text(
                          'Mô tả yêu cầu phòng của bạn bằng ngôn ngữ tự nhiên.',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Ví dụ: "Tôi muốn tìm phòng ở Quận 2 TP.HCM với ngân sách 8 triệu, thu nhập của tôi 25 triệu mỗi tháng, và tôi cần khu vực yên tĩnh có ban công"',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Text input area with manual edit capability
                  Expanded(
                    child: Column(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.blue.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.grey.shade300,
                                  spreadRadius: 1,
                                  blurRadius: 5,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: _isProcessing 
                              ? Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade500),
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'Đang xử lý yêu cầu của bạn...',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.black87,
                                        fontWeight: FontWeight.w500,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                )
                              : !_speechToText.isListening
                                  ? Container(
                                      width: double.infinity,
                                      child: TextField(
                                        controller: _textController,
                                        focusNode: _focusNode,
                                        decoration: InputDecoration(
                                          hintText: 'Nhập hoặc nói về yêu cầu phòng của bạn...',
                                          hintStyle: TextStyle(color: Colors.grey.shade500),
                                          border: InputBorder.none,
                                          isCollapsed: false,
                                        ),
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black,
                                          height: 1.5,
                                        ),
                                        maxLines: null,
                                        textInputAction: TextInputAction.newline,
                                        keyboardType: TextInputType.multiline,
                                        enabled: !_isProcessing,
                                      ),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      alignment: Alignment.topLeft,
                                      child: SingleChildScrollView(
                                        child: Text(
                                          _lastWords.isEmpty 
                                            ? "Đang lắng nghe..." 
                                            : _lastWords,
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w500,
                                            color: _lastWords.isEmpty ? Colors.grey : Colors.black,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ),
                          ),
                        ),
                        
                        // Submit button
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _processText,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade600,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 3,
                            ),
                            child: const Text(
                              'Gửi Yêu Cầu',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Voice input options - more compact
                  Container(
                    height: 80,
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hoặc sử dụng giọng nói:',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Microphone button with animations
                        AnimatedBuilder(
                          animation: _animation,
                          builder: (context, child) {
                            return GestureDetector(
                              onTap: _isProcessing 
                                ? null 
                                : () {
                                  if (_speechToText.isNotListening) {
                                    _startListening();
                                  } else {
                                    _stopListening();
                                  }
                                },
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: (_speechToText.isListening && !_isProcessing)
                                      ? [
                                          BoxShadow(
                                            color: Colors.blue.shade300.withOpacity(0.5),
                                            spreadRadius: 8 * _animation.value,
                                            blurRadius: 12,
                                          ),
                                        ]
                                      : null,
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Ripple effect for sound level
                                    if (_speechToText.isListening && !_isProcessing)
                                      Container(
                                        width: 60 + (_soundLevel * 2),
                                        height: 60 + (_soundLevel * 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.3),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    
                                    // Secondary pulse circle
                                    if (_speechToText.isListening && !_isProcessing)
                                      Container(
                                        width: 70 * _animation.value,
                                        height: 70 * _animation.value,
                                        decoration: BoxDecoration(
                                          color: Colors.blue.withOpacity(0.2),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                    
                                    // Main button circle
                                    Container(
                                      width: 60,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: _isProcessing 
                                            ? [Colors.grey.shade400, Colors.grey.shade500]
                                            : _speechToText.isListening 
                                              ? [Colors.blue.shade400, Colors.blue.shade700] 
                                              : [Colors.white, Colors.grey.shade100],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            spreadRadius: 1,
                                            blurRadius: 3,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        _isProcessing
                                          ? Icons.hourglass_top
                                          : _speechToText.isListening
                                            ? Icons.mic_off
                                            : Icons.mic,
                                        color: _speechToText.isListening && !_isProcessing
                                          ? Colors.white 
                                          : _isProcessing 
                                            ? Colors.white
                                            : Colors.blue,
                                        size: 30,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  
                  // Voice status text
                  Container(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      _isProcessing
                        ? 'Đang xử lý...'
                        : _speechToText.isListening
                          ? "Nhấn để dừng thu âm"
                          : _speechEnabled
                            ? 'Nhấn để bắt đầu nói'
                            : 'Không thể sử dụng nhận dạng giọng nói',
                      style: TextStyle(
                        fontSize: 14,
                        color: _isProcessing
                          ? Colors.orange
                          : _speechToText.isListening 
                            ? Colors.blue
                            : Colors.grey.shade700,
                        fontWeight: (_speechToText.isListening || _isProcessing) 
                          ? FontWeight.bold 
                          : FontWeight.normal,
                      ),
                    ),
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