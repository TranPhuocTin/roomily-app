import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/auth_service.dart';

/// Base class cho các cubit cần truy cập thông tin xác thực
abstract class AuthAwareCubit<T> extends Cubit<T> {
  // Subscription theo dõi thay đổi trạng thái xác thực
  StreamSubscription? _authSubscription;
  StreamSubscription? _userDataSubscription;
  
  // Thông tin xác thực
  String? _userId;
  List<String> _roles = [];
  bool _isAuthenticated = false;
  
  // Getters
  String? get userId => _userId;
  List<String> get roles => _roles;
  bool get isAuthenticated => _isAuthenticated;
  
  AuthAwareCubit(T initialState) : super(initialState) {
    // Lấy thông tin xác thực hiện tại khi khởi tạo
    _initializeAuthState();
    
    // Đăng ký lắng nghe thay đổi xác thực
    _subscribeToAuthChanges();
  }
  
  void _initializeAuthState() {
    try {
      if (GetIt.I.isRegistered<AuthService>()) {
        final authService = GetIt.I<AuthService>();
        _isAuthenticated = authService.isAuthenticated;
        _userId = authService.userId;
        _roles = authService.roles;
        
        if (kDebugMode) {
          print('🔄 [${runtimeType}] Khởi tạo trạng thái xác thực - userId: $_userId, isAuthenticated: $_isAuthenticated');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [${runtimeType}] Lỗi khi khởi tạo trạng thái xác thực: $e');
      }
    }
  }
  
  void _subscribeToAuthChanges() {
    try {
      if (GetIt.I.isRegistered<AuthService>()) {
        final authService = GetIt.I<AuthService>();
        
        // Lắng nghe thay đổi trạng thái xác thực
        _authSubscription = authService.authStateChanges.listen((isAuthenticated) {
          final bool wasAuthenticated = _isAuthenticated;
          _isAuthenticated = isAuthenticated;
          
          if (kDebugMode) {
            print('🔄 [${runtimeType}] Trạng thái xác thực thay đổi: $isAuthenticated');
          }
          
          if (isAuthenticated && !wasAuthenticated) {
            _userId = authService.userId;
            _roles = authService.roles;
            onAuthenticated();
          } else if (!isAuthenticated && wasAuthenticated) {
            _userId = null;
            _roles = [];
            onUnauthenticated();
          }
        });
        
        // Lắng nghe thay đổi dữ liệu người dùng
        _userDataSubscription = authService.userDataChanges.listen((userData) {
          final previousUserId = _userId;
          _userId = userData['userId'];
          _roles = userData['roles'] ?? [];
          
          if (_userId != null && _userId != previousUserId) {
            if (kDebugMode) {
              print('🔄 [${runtimeType}] Dữ liệu người dùng thay đổi - userId: $_userId');
            }
            onUserDataChanged(userData);
          }
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [${runtimeType}] Lỗi khi đăng ký lắng nghe thay đổi xác thực: $e');
      }
    }
  }
  
  /// Được gọi khi người dùng được xác thực
  /// Override để xử lý logic cụ thể cho mỗi cubit
  void onAuthenticated() {
    // Implement in subclass
  }
  
  /// Được gọi khi người dùng đăng xuất
  /// Override để xử lý logic cụ thể cho mỗi cubit
  void onUnauthenticated() {
    // Implement in subclass
  }
  
  /// Được gọi khi dữ liệu người dùng thay đổi
  /// Override để xử lý logic cụ thể cho mỗi cubit
  void onUserDataChanged(Map<String, dynamic> userData) {
    // Implement in subclass
  }
  
  /// Reset state của Cubit về trạng thái ban đầu
  /// Được gọi khi người dùng đăng xuất để đảm bảo dữ liệu được xóa sạch
  void resetState() {
    if (kDebugMode) {
      print('🔄 [${runtimeType}] Reset state về trạng thái ban đầu');
    }
    // Mặc định là không làm gì - các lớp con cần override để thực hiện reset cụ thể
    // Lưu ý: KHÔNG thể gọi emit ở đây vì không biết state ban đầu của lớp con
  }
  
  /// Buộc Cubit tải lại dữ liệu mới
  /// Được gọi sau khi đăng nhập để đảm bảo UI hiển thị dữ liệu mới
  void forceRefresh() {
    if (kDebugMode) {
      print('🔄 [${runtimeType}] Buộc tải lại dữ liệu');
    }
    // Mặc định là không làm gì - các lớp con cần override để thực hiện tải lại cụ thể
  }
  
  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _userDataSubscription?.cancel();
    return super.close();
  }
} 