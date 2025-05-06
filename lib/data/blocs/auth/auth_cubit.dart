import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/core/services/push_notification_service.dart';
import 'package:roomily/data/models/register_request.dart';

import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _authService;
  final PushNotificationService _pushNotificationService;
  StreamSubscription? _authSubscription;
  StreamSubscription? _userDataSubscription;
  
  // Hằng số role cho landlord - chính xác theo giá trị từ server
  static const String ROLE_LANDLORD = "ROLE_LANDLORD";
  // Hằng số role cho tenant
  static const String ROLE_TENANT = "ROLE_TENANT";
  

  AuthCubit(this._authService, {PushNotificationService? pushNotificationService}) 
      : _pushNotificationService = pushNotificationService ?? GetIt.instance<PushNotificationService>(),
        super(AuthState.initial()) {
    _subscribeToAuthChanges();
    checkAuthenticationStatus();
  }
  
  void _subscribeToAuthChanges() {
    // Đăng ký lắng nghe thay đổi từ AuthService
    _authSubscription = _authService.authStateChanges.listen((isAuthenticated) {
      if (kDebugMode) {
        print('🔄 [AuthCubit] Nhận sự kiện thay đổi xác thực: $isAuthenticated');
      }
      
      if (isAuthenticated) {
        _updateStateWithAuthData();
        // Đăng ký FCM token khi đăng nhập thành công
        _registerFcmToken();
      } else {
        emit(AuthState.initial());
      }
    });
    
    // Lắng nghe thay đổi dữ liệu người dùng
    _userDataSubscription = _authService.userDataChanges.listen((userData) {
      if (kDebugMode) {
        print('🔄 [AuthCubit] Nhận sự kiện thay đổi dữ liệu người dùng');
      }
      
      if (_authService.isAuthenticated) {
        _updateStateWithAuthData();
      }
    });
  }
  
  void _updateStateWithAuthData() {
    emit(AuthState(
      status: AuthStatus.authenticated,
      userId: _authService.userId,
      token: _authService.token,
      roles: _authService.roles,
      username: _authService.username,
      isLandlord: _authService.isLandlord,
      errorMessage: null,
    ));
  }

  Future<void> login(String usernameOrEmail, String password) async {
    try {
      emit(state.copyWith(
        status: AuthStatus.loading,
        errorMessage: null,
      ));

      if (kDebugMode) {
        print('🔄 [AuthCubit] Đang thực hiện đăng nhập...');
      }

      final success = await _authService.login(usernameOrEmail, password);

      if (!success) {
        if (kDebugMode) {
          print('❌ [AuthCubit] Đăng nhập thất bại');
        }

        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Đăng nhập thất bại. Vui lòng kiểm tra thông tin đăng nhập và thử lại.',
        ));
      }
      // Trạng thái sẽ được cập nhật thông qua authStateChanges stream
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthCubit] Lỗi đăng nhập: $e');
      }

      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
  
  Future<bool> register(RegisterRequest request) async {
    try {
      emit(state.copyWith(
        status: AuthStatus.loading,
        errorMessage: null,
      ));

      if (kDebugMode) {
        print('🔄 [AuthCubit] Đang thực hiện đăng ký...');
      }

      final success = await _authService.register(request);

      if (!success) {
        if (kDebugMode) {
          print('❌ [AuthCubit] Đăng ký thất bại');
        }

        emit(state.copyWith(
          status: AuthStatus.error,
          errorMessage: 'Đăng ký thất bại. Vui lòng kiểm tra thông tin và thử lại.',
        ));
        return false;
      }
      
      emit(state.copyWith(status: AuthStatus.initial));
      return true;
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthCubit] Lỗi đăng ký: $e');
      }

      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
      
      return false;
    }
  }
  
  Future<void> logout() async {
    try {
      if (kDebugMode) {
        print('🔄 [AuthCubit] Đang thực hiện đăng xuất...');
      }
      
      await _authService.logout();
      // Trạng thái sẽ được cập nhật thông qua authStateChanges stream
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthCubit] Lỗi đăng xuất: $e');
      }
      
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
  
  Future<void> checkAuthenticationStatus() async {
    try {
      emit(state.copyWith(status: AuthStatus.loading));
      
      if (kDebugMode) {
        print('🔍 [AuthCubit] Kiểm tra trạng thái xác thực...');
      }
      
      final isAuthenticated = await _authService.checkAuthState();
      
      if (!isAuthenticated) {
        if (kDebugMode) {
          print('🔍 [AuthCubit] Chưa xác thực');
        }
        
        emit(AuthState.initial());
      } else {
        if (kDebugMode) {
          print('✅ [AuthCubit] Đã xác thực');
        }
        
        _updateStateWithAuthData();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthCubit] Lỗi kiểm tra trạng thái xác thực: $e');
      }
      
      emit(state.copyWith(
        status: AuthStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }
  
  // Phương thức đăng ký FCM token
  Future<void> _registerFcmToken() async {
    try {
      await _pushNotificationService.registerTokenWithServer();
      if (kDebugMode) {
        print('✅ [AuthCubit] Đã đăng ký FCM token thành công');
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ [AuthCubit] Lỗi khi đăng ký FCM token: $e');
      }
      // Không cần emit state lỗi vì đây chỉ là tính năng phụ
    }
  }
  
  @override
  Future<void> close() {
    _authSubscription?.cancel();
    _userDataSubscription?.cancel();
    return super.close();
  }
}
