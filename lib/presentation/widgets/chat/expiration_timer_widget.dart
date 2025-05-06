import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';

class ExpirationTimerWidget extends StatefulWidget {
  final DateTime expiresAt;

  const ExpirationTimerWidget({
    Key? key,
    required this.expiresAt,
  }) : super(key: key);

  @override
  State<ExpirationTimerWidget> createState() => _ExpirationTimerWidgetState();
}

class _ExpirationTimerWidgetState extends State<ExpirationTimerWidget> {
  String _timeLeft = '';
  Timer? _timer;
  Isolate? _isolate;
  ReceivePort? _receivePort;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() async {
    // Create a receive port for communication with the isolate
    _receivePort = ReceivePort();
    
    // Start the isolate
    _isolate = await Isolate.spawn(
      _timerIsolate,
      _receivePort!.sendPort,
    );

    // Listen for messages from the isolate
    _receivePort!.listen((message) {
      if (message is String) {
        setState(() {
          _timeLeft = message;
        });
      }
    });
  }

  static void _timerIsolate(SendPort sendPort) {
    Timer.periodic(const Duration(seconds: 1), (timer) {
      final now = DateTime.now();
      final expiresAt = DateTime.now().add(const Duration(hours: 24)); // This should be passed from the widget
      
      if (now.isAfter(expiresAt)) {
        sendPort.send('Hết hạn');
        timer.cancel();
        return;
      }

      final difference = expiresAt.difference(now);
      final hours = difference.inHours;
      final minutes = difference.inMinutes % 60;
      final seconds = difference.inSeconds % 60;

      sendPort.send('${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _isolate?.kill();
    _receivePort?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _timeLeft,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: Colors.amber[700],
      ),
    );
  }
} 