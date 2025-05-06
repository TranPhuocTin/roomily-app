import 'dart:math';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

class SpeechScreen extends StatefulWidget {
  const SpeechScreen({Key? key}) : super(key: key);

  @override
  State<SpeechScreen> createState() => _SpeechScreenState();
}

class _SpeechScreenState extends State<SpeechScreen> with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  String _lastWords = '';
  double _confidence = 1.0;
  
  // For animations
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // For sound level visualization
  double _soundLevel = 0.0;
  
  @override
  void initState() {
    super.initState();
    _initSpeech();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    
    // Create a looping pulse animation
    _animation = Tween<double>(begin: 1.0, end: 1.3)
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
    // Clear previous text
    setState(() {
      _lastWords = '';
    });
    
    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 4),
      partialResults: true,
      onSoundLevelChange: _onSoundLevelChange,
      cancelOnError: false,
      listenMode: ListenMode.confirmation,
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
    setState(() {
      _soundLevel = 0;
    });
  }

  /// Handle speech recognition results
  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _lastWords = result.recognizedWords;
      if (result.hasConfidenceRating && result.confidence > 0) {
        _confidence = result.confidence;
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Speech to Text'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Colors.white,
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Instructions text
            const Text(
              'Tap the microphone to speak',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            
            // Recognized text display area
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                alignment: Alignment.center,
                child: Text(
                  _lastWords.isEmpty ? 'Speak something...' : _lastWords,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: _lastWords.isEmpty ? 18 : 24,
                    fontWeight: FontWeight.w500,
                    color: _lastWords.isEmpty ? Colors.grey.shade400 : Colors.black,
                  ),
                ),
              ),
            ),
            
            // Microphone button with animations
            Expanded(
              child: Center(
                child: AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return GestureDetector(
                      onTap: () {
                        if (_speechToText.isNotListening) {
                          _startListening();
                        } else {
                          _stopListening();
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: _speechToText.isListening
                              ? [
                                  BoxShadow(
                                    color: Colors.blue.withOpacity(0.3),
                                    spreadRadius: 12 * _animation.value,
                                    blurRadius: 20,
                                  ),
                                ]
                              : null,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Ripple effect for sound level
                            if (_speechToText.isListening)
                              Container(
                                width: 80 + (_soundLevel * 2),
                                height: 80 + (_soundLevel * 2),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.3),
                                  shape: BoxShape.circle,
                                ),
                              ),
                            
                            // Main button circle
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: _speechToText.isListening ? Colors.blue : Colors.grey.shade200,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.mic,
                                color: _speechToText.isListening ? Colors.white : Colors.blue,
                                size: 36,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Helper text
            Container(
              padding: const EdgeInsets.only(bottom: 40),
              child: Text(
                _speechToText.isListening
                    ? "I'm listening..."
                    : _speechEnabled
                        ? 'Tap the microphone to start'
                        : 'Speech recognition not available',
                style: TextStyle(
                  fontSize: 16,
                  color: _speechToText.isListening ? Colors.blue : Colors.grey,
                  fontWeight: _speechToText.isListening ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 