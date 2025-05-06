import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:roomily/core/services/stomp_service.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter/foundation.dart';

// States
abstract class StompState extends Equatable {
  const StompState();

  @override
  List<Object?> get props => [];
}

class StompInitial extends StompState {}

class StompConnecting extends StompState {}

class StompConnected extends StompState {}

class StompDisconnected extends StompState {}

class StompError extends StompState {
  final String message;

  const StompError(this.message);

  @override
  List<Object?> get props => [message];
}

// Cubit
class StompCubit extends Cubit<StompState> {
  final StompService _stompService;
  StreamSubscription? _connectionSubscription;
  final Map<String, StompUnsubscribe> _subscriptions = {};
  final Map<String, List<Function(dynamic)>> _messageHandlers = {};

  StompCubit({required StompService stompService}) 
      : _stompService = stompService,
        super(StompInitial()) {
    _init();
  }

  void _init() {
    emit(StompConnecting());
    
    // Lắng nghe trạng thái kết nối
    _connectionSubscription = _stompService.connectionStatus.listen((connected) {
      if (connected) {
        emit(StompConnected());
        _resubscribeAll(); // Đăng ký lại các subscription khi kết nối lại
      } else {
        emit(StompDisconnected());
      }
    });

    // Kết nối đến STOMP server
    try {
      _stompService.connect();
    } catch (e) {
      debugPrint('Error connecting to STOMP: $e');
      emit(StompError('Không thể kết nối đến máy chủ: $e'));
    }
  }

  // Đăng ký nhận tin nhắn từ một destination
  void subscribe(String destination, Function(dynamic) onMessage) {
    // Lưu handler vào danh sách
    if (!_messageHandlers.containsKey(destination)) {
      _messageHandlers[destination] = [];
    }
    _messageHandlers[destination]!.add(onMessage);

    // Nếu đã kết nối, thực hiện subscribe ngay
    if (_stompService.isConnected && state is StompConnected) {
      _subscribeToDestination(destination);
    }
  }

  // Hủy đăng ký một handler cụ thể
  void unsubscribe(String destination, Function(dynamic)? handler) {
    if (handler != null && _messageHandlers.containsKey(destination)) {
      _messageHandlers[destination]!.remove(handler);
      
      // Nếu không còn handler nào, hủy subscription
      if (_messageHandlers[destination]!.isEmpty) {
        _unsubscribeFromDestination(destination);
      }
    } else if (handler == null) {
      // Hủy tất cả handlers cho destination này
      _unsubscribeFromDestination(destination);
      _messageHandlers.remove(destination);
    }
  }


  // Private method để thực hiện subscribe
  void _subscribeToDestination(String destination) {
    if (_subscriptions.containsKey(destination)) {
      return; // Đã subscribe rồi
    }

    try {
      final subscription = _stompService.subscribe(
        destination,
        (frame) {
          if (frame.body != null && _messageHandlers.containsKey(destination)) {
            // Gọi tất cả các handlers đã đăng ký
            for (var handler in _messageHandlers[destination]!) {
              handler(frame.body);
            }
          }
        },
      );
      _subscriptions[destination] = subscription;
    } catch (e) {
      debugPrint('Error subscribing to $destination: $e');
    }
  }

  // Private method để hủy subscribe
  void _unsubscribeFromDestination(String destination) {
    if (_subscriptions.containsKey(destination)) {
      _subscriptions[destination]?.call();
      _subscriptions.remove(destination);
    }
  }

  // Đăng ký lại tất cả các subscription khi kết nối lại
  void _resubscribeAll() {
    for (var destination in _messageHandlers.keys) {
      if (_messageHandlers[destination]!.isNotEmpty) {
        _subscribeToDestination(destination);
      }
    }
  }

  // Kết nối lại khi bị ngắt kết nối
  void reconnect() {
    if (state is StompDisconnected) {
      emit(StompConnecting());
      try {
        _stompService.connect();
      } catch (e) {
        debugPrint('Error reconnecting to STOMP: $e');
        emit(StompError('Không thể kết nối lại: $e'));
      }
    }
  }

  @override
  Future<void> close() {
    _connectionSubscription?.cancel();
    
    // Hủy tất cả các subscriptions
    for (var unsubscribe in _subscriptions.values) {
      unsubscribe();
    }
    _subscriptions.clear();
    _messageHandlers.clear();
    
    return super.close();
  }
}