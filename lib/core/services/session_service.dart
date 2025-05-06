import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_cubit.dart';
import 'package:roomily/data/blocs/chat_room/direct_chat_room_cubit.dart';
import 'package:roomily/core/cache/cache.dart';
import 'package:roomily/core/cache/image_cache_manager.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/core/services/notification_service.dart';
import 'package:roomily/core/services/user_location_service.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_cubit.dart';
import 'package:roomily/data/repositories/auth_repository.dart';
import 'package:roomily/data/repositories/budget_plan_repository.dart';
import 'package:roomily/data/repositories/chat_room_repository.dart';
import 'package:roomily/data/repositories/chat_room_repository_impl.dart';
import 'package:roomily/data/repositories/favorite_repository.dart';
import 'package:roomily/data/repositories/favorite_repository_impl.dart';
import 'package:roomily/data/repositories/review_repository.dart';
import 'package:roomily/data/repositories/review_repository_impl.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/data/repositories/room_image_repository_impl.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/repositories/room_repository_impl.dart';
import 'package:roomily/core/services/secure_storage_service.dart';

import '../../data/blocs/auth/auth_aware_cubit.dart';
import '../../data/blocs/auth/auth_cubit.dart';
import '../../data/blocs/auth/auth_state.dart';
import '../../data/blocs/chat_room/chat_room_cubit.dart';
import '../../data/blocs/home/room_detail_cubit.dart';
import '../../data/blocs/landlord/landlord_rooms_cubit.dart';
import '../../data/repositories/budget_plan_repository_impl.dart';

/// Service xử lý logic liên quan đến phiên đăng nhập (logout, initialize lại các service)
/// để đảm bảo tất cả tài nguyên được quản lý đúng cách khi đăng nhập/đăng xuất
class SessionService {
  final GetIt _getIt = GetIt.instance;
  bool _isReinitializing = false;
  
  /// Khởi tạo lại tất cả các services sau khi đăng nhập thành công
  Future<void> reinitializeAfterLogin() async {
    // Đảm bảo không gọi lại khi đang trong quá trình reinitialize
    if (_isReinitializing) {
      debugPrint('⚠️ Đang trong quá trình khởi tạo lại, bỏ qua yêu cầu trùng lặp');
      return;
    }
    
    _isReinitializing = true;
    
    try {
      debugPrint('🔄 Bắt đầu khởi tạo lại các services sau khi đăng nhập...');
      
      // Đảm bảo thông tin xác thực đã sẵn sàng
      final authService = _getIt.isRegistered<AuthService>() ? _getIt<AuthService>() : null;
      if (authService != null && !authService.isAuthenticated) {
        debugPrint('⚠️ User chưa được xác thực, kiểm tra lại từ secure storage...');
        await authService.checkAuthState();
      }

      // Khởi tạo lại Dio instance với token mới
      await _reinitializeDio();
      await Future.delayed(const Duration(milliseconds: 100));

      // Khởi tạo lại các repositories
      await _reinitializeRepositories();
      await Future.delayed(const Duration(milliseconds: 100));

      // Khởi tạo lại các services khác
      await _reinitializeOtherServices();

      // Force reset all cubits to ensure they reload fresh data
      await _forceRefreshAllCubits();
      
      debugPrint('✅ Đã khởi tạo lại tất cả services sau khi đăng nhập');
    } catch (e) {
      debugPrint('❌ Lỗi khi khởi tạo lại services: $e');
    } finally {
      _isReinitializing = false;
    }
  }
  
  /// Khởi tạo lại Dio với interceptor xác thực mới
  Future<void> _reinitializeDio() async {
    try {
      debugPrint('🔄 Khởi tạo lại Dio...');
      final dio = DioConfig.createDio();
      
      // Đảm bảo Dio được unregister trước khi đăng ký lại
      if (_getIt.isRegistered<Dio>()) {
        _getIt.unregister<Dio>();
      }
      
      _getIt.registerLazySingleton<Dio>(() => dio);
      debugPrint('✅ Đã khởi tạo lại Dio với token mới');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi khởi tạo lại Dio: $e');
    }
  }
  
  /// Khởi tạo lại tất cả các repositories sau khi Dio đã được khởi tạo lại
  Future<void> _reinitializeRepositories() async {
    try {
      debugPrint('🔄 Khởi tạo lại các repositories...');
      
      // Lấy instance Dio mới
      final dio = _getIt<Dio>();
      
      // Đảm bảo đã có Cache instance
      final cache = _getIt<Cache>();
      
      // Khởi tạo lại tất cả repositories lần lượt với xử lý lỗi cho từng repository
      try {
        _reinitializeRepository<RoomRepository>(
          () => RoomRepositoryImpl(dio: dio, cache: cache)
        );
      } catch (e) {
        debugPrint('⚠️ Lỗi khi khởi tạo lại RoomRepository: $e');
      }
      
      try {
        _reinitializeRepository<ReviewRepository>(
          () => ReviewRepositoryImpl(dio: dio)
        );
      } catch (e) {
        debugPrint('⚠️ Lỗi khi khởi tạo lại ReviewRepository: $e');
      }
      
      try {
        _reinitializeRepository<RoomImageRepository>(
          () => RoomImageRepositoryImpl(dio: dio)
        );
      } catch (e) {
        debugPrint('⚠️ Lỗi khi khởi tạo lại RoomImageRepository: $e');
      }
      
      try {
        _reinitializeRepository<FavoriteRepository>(
          () => FavoriteRepositoryImpl(dio: dio)
        );
      } catch (e) {
        debugPrint('⚠️ Lỗi khi khởi tạo lại FavoriteRepository: $e');
      }
      
      try {
        _reinitializeRepository<ChatRoomRepository>(
          () => ChatRoomRepositoryImpl(dio: dio)
        );

      } catch (e) {
        debugPrint('⚠️ Lỗi khi khởi tạo lại ChatRoomRepository: $e');
      }

      try {
        _reinitializeRepository<BudgetPlanRepository>(
            () => BudgetPlanRepositoryImpl(dio: dio)
        );
      } catch(e) {

      }
      
      // Khởi tạo lại các cubits
      _reinitializeCubits();
      
      debugPrint('✅ Đã khởi tạo lại tất cả repositories');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi khởi tạo lại repositories: $e');
      rethrow;
    }
  }
  
  /// Helper để khởi tạo lại một repository cụ thể
  void _reinitializeRepository<T extends Object>(FactoryFunc<T> factoryFunc) {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
    _getIt.registerLazySingleton<T>(factoryFunc);
    debugPrint('✅ Đã khởi tạo lại $T');
  }
  
  /// Khởi tạo lại các cubits
  void _reinitializeCubits() {
    try {
      debugPrint('🔄 Bắt đầu khởi tạo lại các cubits...');
      
      // First initialize all cubits except ChatRoomCubit
      _initializeNonChatCubits();
      
      // Then initialize ChatRoomCubit with a short delay
      _initializeChatCubit();
      
      debugPrint('✅ Đã khởi tạo lại tất cả cubits');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi khởi tạo lại cubits: $e');
    }
  }
  
  // Initialize all cubits except ChatRoomCubit
  void _initializeNonChatCubits() {
    try {
      // Trước tiên lấy thông tin xác thực
      final userId = _getAuthenticatedUserId();
      final roles = _getAuthenticatedRoles();
      
      if (userId != null) {
        debugPrint('🔒 Reinitializing cubits with authenticated user: $userId, roles: $roles');
      } else {
        debugPrint('⚠️ Reinitializing cubits without authenticated user!');
      }
      
      // Khởi tạo lại RoomDetailCubit
      if (_getIt.isRegistered<RoomDetailCubit>()) {
        _getIt.unregister<RoomDetailCubit>();
        _getIt.registerLazySingleton<RoomDetailCubit>(() => 
          RoomDetailCubit(_getIt<RoomRepository>())
        );
        debugPrint('✅ Đã khởi tạo lại RoomDetailCubit');
      }

      if(_getIt.isRegistered<BudgetPlanCubit>()) {
        _getIt.unregister<BudgetPlanCubit>();
        _getIt.registerLazySingleton<BudgetPlanCubit>(() =>
            BudgetPlanCubit(budgetPlanRepository: _getIt<BudgetPlanRepository>(),)
        );
      }
      // Khởi tạo lại LandlordRoomsCubit
      if (_getIt.isRegistered<LandlordRoomsCubit>()) {
        debugPrint('🏠 Đang khởi tạo lại LandlordRoomsCubit...');
        try {
          _getIt.unregister<LandlordRoomsCubit>();
          _getIt.registerLazySingleton<LandlordRoomsCubit>(() => 
            LandlordRoomsCubit(roomRepository: _getIt<RoomRepository>())
          );
          debugPrint('✅ Đã khởi tạo lại LandlordRoomsCubit thành công');
        } catch (e) {
          debugPrint('❌ Lỗi khi khởi tạo lại LandlordRoomsCubit: $e');
        }
      } else {
        debugPrint('⚠️ LandlordRoomsCubit chưa được đăng ký trước đó');
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi khởi tạo lại non-chat cubits: $e');
    }
  }
  
  // Initialize chat-related cubits with a delay to ensure auth state is ready
  void _initializeChatCubit() {
    // Get authenticated information from the auth repository directly rather than relying on AuthCubit state
    Future.delayed(Duration(milliseconds: 1000), () async {
      try {
        debugPrint('🔄 Getting authenticated user info directly from repository for chat initialization...');
        
        String? userId;
        List<String> roles = [];
        
        // Get auth repository directly if possible
        if (_getIt.isRegistered<AuthRepository>()) {
          final authRepository = _getIt<AuthRepository>();
          userId = await authRepository.getUserId();
          roles = await authRepository.getUserRoles();
          
          debugPrint('📝 Direct auth info from repository - UserId: $userId, Roles: $roles');
        } else {
          debugPrint('⚠️ AuthRepository not available for direct access');
        }
        
        // Fallback to AuthCubit if needed
        if (userId == null && _getIt.isRegistered<AuthCubit>()) {
          final authCubit = _getIt<AuthCubit>();
          final state = authCubit.state;
          if (state.status == AuthStatus.authenticated) {
            userId = state.userId;
            roles = state.roles;
            debugPrint('📝 Fallback auth info from AuthCubit - UserId: $userId, Roles: $roles');
          }
        }
        
        if (userId != null) {
          debugPrint('✅ Got authenticated user ID for chat initialization: $userId, roles: $roles');
        } else {
          debugPrint('⚠️ Warning: Could not get authenticated user ID for chat initialization!');
          // One last attempt: try to get it directly from secure storage
          try {
            if (_getIt.isRegistered<SecureStorageService>()) {
              final secureStorage = _getIt<SecureStorageService>();
              userId = await secureStorage.getUserId();
              roles = await secureStorage.getRoles();
              debugPrint('📝 Emergency auth info from secure storage - UserId: $userId, Roles: $roles');
            }
          } catch (e) {
            debugPrint('❌ Error getting auth info from secure storage: $e');
          }
        }
        
        // Khởi tạo lại ChatRoomCubit WITH THE AUTHENTICATED USER ID
        if (_getIt.isRegistered<ChatRoomCubit>()) {
          _getIt.unregister<ChatRoomCubit>();
          _getIt.registerLazySingleton<ChatRoomCubit>(() => 
            ChatRoomCubit(repository: _getIt<ChatRoomRepository>())
          );
          debugPrint('✅ Đã khởi tạo lại ChatRoomCubit với UserId: $userId');
          
          // Refresh is now handled in ChatRoomCubit constructor if initialUserId is provided
        }
        
        // Khởi tạo lại DirectChatRoomCubit (depends on ChatRoomCubit)
        if (_getIt.isRegistered<DirectChatRoomCubit>()) {
          _getIt.unregister<DirectChatRoomCubit>();
          _getIt.registerLazySingleton<DirectChatRoomCubit>(() => 
            DirectChatRoomCubit(
              repository: _getIt<ChatRoomRepository>(),
              chatRoomCubit: _getIt<ChatRoomCubit>(),
              roomDetailCubit: _getIt<RoomDetailCubit>(),
            )
          );
          debugPrint('✅ Đã khởi tạo lại DirectChatRoomCubit');
        }
        
        debugPrint('✅ Đã hoàn tất khởi tạo lại các chat cubits');
      } catch (e) {
        debugPrint('❌ Lỗi khi khởi tạo lại chat cubits: $e');
      }
    });
  }
  
  // Helper to get authenticated user ID
  String? _getAuthenticatedUserId() {
    try {
      if (_getIt.isRegistered<AuthCubit>()) {
        final authCubit = _getIt<AuthCubit>();
        final state = authCubit.state;
        if (state.status == AuthStatus.authenticated) {
          return state.userId;
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting authenticated user ID: $e');
    }
    return null;
  }
  
  // Helper to get authenticated user roles
  List<String> _getAuthenticatedRoles() {
    try {
      if (_getIt.isRegistered<AuthCubit>()) {
        final authCubit = _getIt<AuthCubit>();
        final state = authCubit.state;
        if (state.status == AuthStatus.authenticated) {
          return state.roles;
        }
      }
    } catch (e) {
      debugPrint('❌ Error getting authenticated user roles: $e');
    }
    return [];
  }
  
  /// Khởi tạo lại NotificationService
  Future<void> _reinitializeNotificationService() async {
    try {
      if (_getIt.isRegistered<NotificationService>()) {
        final notificationService = _getIt<NotificationService>();
        // Khởi tạo NotificationService (không cần kiểm tra isInitialized vì phương thức initialize
        // trong NotificationService đã có kiểm tra và xử lý trùng lặp)
        await notificationService.initialize();
        debugPrint('✅ Đã khởi tạo lại NotificationService');
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi khi khởi tạo lại NotificationService: $e');
    }
  }
  
 
  Future<void> logout() async {
    debugPrint('🔒 Bắt đầu quá trình đăng xuất...');
    
    try {
      // 1. Reset all cubits first to ensure UI states are cleared
      await _resetAllCubits();

      // 2. Dọn dẹp notification service
      await _cleanupNotificationService();
      
      // 3. Dọn dẹp location service
      await _cleanupLocationService();

      // 4. Xóa cache
      await _clearCache();
      
      // 5. Xóa thông tin xác thực (thông qua AuthCubit)
      await _clearAuthData();
      
      debugPrint('✅ Đã đăng xuất thành công');
    } catch (e) {
      debugPrint('❌ Lỗi khi đăng xuất: $e');
      rethrow;
    }
  }

  
  /// Dọn dẹp notification service
  Future<void> _cleanupNotificationService() async {
    try {
      if (_getIt.isRegistered<NotificationService>()) {
        final notificationService = _getIt<NotificationService>();
        notificationService.dispose();
        debugPrint('✅ Đã dọn dẹp NotificationService');
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi khi dọn dẹp NotificationService: $e');
    }
  }
  
  /// Dọn dẹp location service
  Future<void> _cleanupLocationService() async {
    try {
      if (_getIt.isRegistered<UserLocationService>()) {
        final userLocationService = _getIt<UserLocationService>();
        if (userLocationService.isInitialized) {
          debugPrint('✅ Đã dọn dẹp UserLocationService');
        }
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi khi dọn dẹp UserLocationService: $e');
    }
  }
  
  /// Xóa cache
  Future<void> _clearCache() async {
    try {
      // Xóa cache hình ảnh
      if (_getIt.isRegistered<ImageCacheManager>()) {
        await ImageCacheManager.clearCache();
        debugPrint('✅ Đã xóa cache hình ảnh');
      }
      
      if (_getIt.isRegistered<RoomThumbnailCacheManager>()) {
        await RoomThumbnailCacheManager.clearCache();
        debugPrint('✅ Đã xóa cache thumbnail');
      }
      
      if (_getIt.isRegistered<AvatarCacheManager>()) {
        await AvatarCacheManager.clearCache();
        debugPrint('✅ Đã xóa cache avatar');
      }
      
      // Xóa cache dữ liệu
      if (_getIt.isRegistered<Cache>()) {
        await _getIt<Cache>().clear();
        debugPrint('✅ Đã xóa cache dữ liệu');
      }
      
      // Reset Dio
      if (_getIt.isRegistered<Dio>()) {
        final dio = _getIt<Dio>();
        dio.interceptors.clear();
        debugPrint('✅ Đã reset Dio interceptors');
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi khi xóa cache: $e');
    }
  }
  
  /// Xóa thông tin xác thực
  Future<void> _clearAuthData() async {
    try {
      if (_getIt.isRegistered<AuthCubit>()) {
        await _getIt<AuthCubit>().logout();
        debugPrint('✅ Đã xóa thông tin xác thực');
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi khi xóa thông tin xác thực: $e');
      rethrow;
    }
  }

  /// Khởi tạo lại các services khác
  Future<void> _reinitializeOtherServices() async {
    try {
      debugPrint('🔄 Khởi tạo lại các services khác...');
      
      // Khởi tạo lại NotificationService
      await _reinitializeNotificationService();
      
      
      debugPrint('✅ Đã khởi tạo lại các services khác');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi khởi tạo lại các services khác: $e');
    }
  }


  /// Resets all cubits to their initial state
  Future<void> _resetAllCubits() async {
    final getIt = GetIt.instance;
    debugPrint('🔄 Đang reset tất cả cubits...');
    
    try {
      _safeResetCubit<RoomDetailCubit>(getIt);
      _safeResetCubit<ChatRoomCubit>(getIt);
      _safeResetCubit<DirectChatRoomCubit>(getIt);
      _safeResetCubit<LandlordRoomsCubit>(getIt);
      _getIt<RentedRoomCubit>().reset();
      debugPrint('✅ Đã reset tất cả cubits');
    } catch (e) {
      debugPrint('❌ Lỗi khi reset cubits: $e');
    }
  }
  
  /// Safely reset a specific cubit using dynamic calls to avoid compile-time errors
  void _safeResetCubit<T extends Cubit>(GetIt getIt) {
    if (getIt.isRegistered<T>()) {
      try {
        final cubit = getIt<T>();
        debugPrint('🔄 Reset ${T.toString()}');
        
        // First try resetState if it's an AuthAwareCubit
        if (cubit is AuthAwareCubit) {
          cubit.resetState();
          debugPrint('✅ Đã reset ${T.toString()} qua AuthAwareCubit');
          return;
        }
        
        // Try using dynamic to call methods that might exist
        try {
          // Try various methods that might exist on cubits to reset state
          _tryCallMethod(cubit, 'resetState');
          _tryCallMethod(cubit, 'reset');
          _tryCallMethod(cubit, 'clear');
          _tryCallMethod(cubit, 'resetRooms');
          
          debugPrint('✅ Đã reset ${T.toString()} qua dynamic call');
        } catch (e) {
          debugPrint('⚠️ Không thể reset ${T.toString()} qua dynamic call: $e');
        }
      } catch (e) {
        debugPrint('⚠️ Không thể reset ${T.toString()}: $e');
      }
    }
  }
  
  /// Force all relevant cubits to refresh their data after login
  Future<void> _forceRefreshAllCubits() async {
    final getIt = GetIt.instance;
    debugPrint('🔄 Đang buộc tất cả cubits tải lại dữ liệu mới...');
    
    try {
      // Get the current user ID for verification
      final userId = _getAuthenticatedUserId();
      debugPrint('📝 Force refresh với userId: $userId');
      
      // Refresh specific cubits
      _safeRefreshCubit<RoomDetailCubit>(getIt);
      _safeRefreshCubit<ChatRoomCubit>(getIt);
      
      // Refresh LandlordRoomsCubit only if user is a landlord
      final roles = _getAuthenticatedRoles();
      if (roles.any((role) => role.toLowerCase().contains('landlord'))) {
        _safeRefreshCubit<LandlordRoomsCubit>(getIt);
      }
      
      debugPrint('✅ Đã buộc tất cả cubits tải lại dữ liệu mới');
    } catch (e) {
      debugPrint('❌ Lỗi khi buộc làm mới cubits: $e');
    }
  }
  
  /// Safely refresh a specific cubit using dynamic calls to avoid compile-time errors
  void _safeRefreshCubit<T extends Cubit>(GetIt getIt) {
    if (getIt.isRegistered<T>()) {
      try {
        final cubit = getIt<T>();
        debugPrint('🔄 Buộc ${T.toString()} làm mới dữ liệu');
        
        // First try forceRefresh if it's an AuthAwareCubit
        if (cubit is AuthAwareCubit) {
          cubit.forceRefresh();
          debugPrint('✅ Đã refresh ${T.toString()} qua AuthAwareCubit');
          return;
        }
        
        // Try using dynamic to call methods that might exist for refreshing data
        bool methodCalled = false;
        
        // Try various methods that might exist on cubits to refresh data
        methodCalled = _tryCallMethod(cubit, 'forceRefresh') || methodCalled;
        methodCalled = _tryCallMethod(cubit, 'refresh') || methodCalled;
        methodCalled = _tryCallMethod(cubit, 'fetchChatRooms') || methodCalled;
        methodCalled = _tryCallMethod(cubit, 'fetchLandlordRooms') || methodCalled;
        methodCalled = _tryCallMethod(cubit, 'loadData') || methodCalled;
        
        // Call onAuthenticated as a last resort
        if (!methodCalled && cubit is AuthAwareCubit) {
          cubit.onAuthenticated();
          debugPrint('✅ Đã refresh ${T.toString()} qua onAuthenticated');
        }
      } catch (e) {
        debugPrint('⚠️ Không thể refresh ${T.toString()}: $e');
      }
    }
  }
  
  /// Helper method to try calling a method on an object dynamically
  bool _tryCallMethod(dynamic object, String methodName) {
    try {
      // Get instance mirror
      final instance = object;
      
      // Check if method exists using reflection-like approach
      final methods = instance.runtimeType.toString().contains(methodName);
      
      if (methods) {
        // Call the method if it exists
        switch (methodName) {
          case 'resetState':
            instance.resetState();
            break;
          case 'reset':
            instance.reset();
            break;
          case 'clear':
            instance.clear();
            break;
          case 'resetRooms':
            instance.resetRooms();
            break;
          case 'forceRefresh':
            instance.forceRefresh();
            break;
          case 'refresh':
            instance.refresh();
            break;
          case 'fetchChatRooms':
            instance.fetchChatRooms();
            break;
          case 'fetchLandlordRooms':
            instance.fetchLandlordRooms();
            break;
          case 'loadData':
            instance.loadData();
            break;
          default:
            return false;
        }
        debugPrint('✅ Gọi thành công phương thức $methodName');
        return true;
      }
    } catch (e) {
      // Silently ignore if method doesn't exist
      return false;
    }
    return false;
  }
} 