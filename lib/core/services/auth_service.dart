import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:roomily/core/services/secure_storage_service.dart';
import 'package:roomily/data/repositories/auth_repository.dart';
import 'package:roomily/data/models/login_request.dart';
import 'package:roomily/data/models/register_request.dart';
import 'package:get_it/get_it.dart';
import 'package:dio/dio.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/data/repositories/favorite_repository.dart';
import 'package:roomily/data/repositories/chat_room_repository.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/repositories/review_repository.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/data/repositories/favorite_repository_impl.dart';
import 'package:roomily/data/repositories/chat_room_repository_impl.dart';
import 'package:roomily/data/repositories/room_repository_impl.dart';
import 'package:roomily/data/repositories/review_repository_impl.dart';
import 'package:roomily/data/repositories/room_image_repository_impl.dart';
import 'package:roomily/core/cache/cache.dart';
import 'package:roomily/data/repositories/find_partner_repository.dart';
import 'package:roomily/data/repositories/find_partner_repository_impl.dart';

/// Service quản lý trạng thái xác thực trung tâm
/// Là nguồn thông tin xác thực duy nhất cho toàn bộ ứng dụng
class AuthService {
  final AuthRepository _authRepository;
  final SecureStorageService _secureStorage;
  
  // Lưu trữ trạng thái xác thực hiện tại
  bool _isAuthenticated = false;
  String? _userId;
  String? _token;
  List<String> _roles = [];
  bool _isLandlord = false;
  String? _username;
  
  // Stream controllers để thông báo các thay đổi trạng thái
  final _authStateController = StreamController<bool>.broadcast();
  final _userDataController = StreamController<Map<String, dynamic>>.broadcast();
  
  // Stream để các thành phần có thể lắng nghe
  Stream<bool> get authStateChanges => _authStateController.stream;
  Stream<Map<String, dynamic>> get userDataChanges => _userDataController.stream;
  
  // Getters cho trạng thái xác thực
  bool get isAuthenticated => _isAuthenticated;
  String? get userId => _userId;
  String? get token => _token;
  List<String> get roles => _roles;
  bool get isLandlord => _isLandlord;
  String? get username => _username;
  
  AuthService(this._authRepository, this._secureStorage) {
    // Khởi tạo trạng thái từ storage khi service được tạo
    _loadAuthState();
  }
  
  /// Đăng ký người dùng mới
  Future<bool> register(RegisterRequest request) async {
    try {
      if (kDebugMode) {
        print('🔒 [AuthService] Đang đăng ký người dùng mới: ${request.username}');
      }
      
      // Delegate to repository
      final success = await _authRepository.register(request);
      
      if (success) {
        if (kDebugMode) {
          print('✅ [AuthService] Đăng ký thành công cho user: ${request.username}');
        }
      } else {
        if (kDebugMode) {
          print('❌ [AuthService] Đăng ký thất bại cho user: ${request.username}');
        }
      }
      
      return success;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthService] Đăng ký thất bại: $e');
      }
      return false;
    }
  }
  
  /// Đăng nhập người dùng
  Future<bool> login(String usernameOrEmail, String password) async {
    try {
      // Clear trạng thái hiện tại
      await _clearAuthState();
      
      if (kDebugMode) {
        print('🔒 [AuthService] Đang đăng nhập với $usernameOrEmail');
      }
      
      // Login thông qua repository
      final response = await _authRepository.login(
        LoginRequest(usernameOrEmail: usernameOrEmail, password: password)
      );
      
      if (kDebugMode) {
        print('✅ [AuthService] Đăng nhập thành công cho user: ${response.username}');
      }
      
      // Lưu trạng thái mới
      await _updateAuthState(
        userId: response.userId,
        token: response.accessToken,
        roles: response.role,
        isLandlord: _checkIsLandlord(response.role),
        username: response.username,
      );
      
      // Khởi tạo lại Dio với token mới
      await _reinitializeDio(response.accessToken);
      
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthService] Đăng nhập thất bại: $e');
      }
      await _clearAuthState();
      return false;
    }
  }
  
  /// Đăng xuất người dùng
  Future<void> logout() async {
    if (kDebugMode) {
      print('🔒 [AuthService] Đang đăng xuất...');
    }

    try {
      // 1. Clear auth state first to ensure all references to old user are gone
      await _clearAuthState();
      
      // 2. Clear Dio instance and its interceptors
      if (GetIt.I.isRegistered<Dio>()) {
        final dio = GetIt.I<Dio>();
        dio.interceptors.clear();
        GetIt.I.unregister<Dio>();
      }
      
      // 3. Create new Dio instance without token
      await _reinitializeDio(null);
      
      // 4. Call logout API (with new clean Dio instance)
      await _authRepository.logout();
      
      // 5. Force reinitialize ALL repositories to ensure no cached state
      await _reinitializeAllRepositories();
      
      if (kDebugMode) {
        print('✅ [AuthService] Đăng xuất thành công');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthService] Lỗi trong quá trình đăng xuất: $e');
      }
      rethrow;
    }
  }
  
  /// Kiểm tra trạng thái xác thực
  Future<bool> checkAuthState() async {
    if (kDebugMode) {
      print('🔍 [AuthService] Kiểm tra trạng thái xác thực');
    }
    // Đọc lại từ secure storage để đảm bảo cập nhật
    await _loadAuthState();
    return _isAuthenticated;
  }
  
  /// Tải trạng thái xác thực từ secure storage
  Future<void> _loadAuthState() async {
    try {
      final token = await _secureStorage.getToken();
      final userId = await _secureStorage.getUserId();
      final roles = await _secureStorage.getRoles();
      final username = await _secureStorage.getUsername();
      
      if (kDebugMode) {
        print('🔍 [AuthService] Đã đọc từ secure storage - Token: ${token != null}, UserId: $userId');
      }
      
      if (token != null && userId != null) {
        await _updateAuthState(
          userId: userId,
          token: token,
          roles: roles,
          isLandlord: _checkIsLandlord(roles),
          username: username,
        );
        
        // Khởi tạo lại Dio với token đã lưu
        await _reinitializeDio(token);
      } else {
        await _clearAuthState();
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthService] Lỗi khi tải trạng thái xác thực: $e');
      }
      await _clearAuthState();
    }
  }
  
  /// Cập nhật trạng thái xác thực
  Future<void> _updateAuthState({
    required String userId, 
    required String token,
    required List<String> roles,
    required bool isLandlord,
    String? username,
  }) async {
    // Cập nhật biến nội bộ
    _isAuthenticated = true;
    _userId = userId;
    _token = token;
    _roles = roles;
    _isLandlord = isLandlord;
    _username = username;
    
    // Lưu vào secure storage
    await _secureStorage.saveToken(token);
    await _secureStorage.saveUserId(userId);
    await _secureStorage.saveRoles(roles);
    if (username != null) {
      await _secureStorage.saveUsername(username);
    }
    
    // Thông báo cho các listeners
    _authStateController.add(true);
    _userDataController.add({
      'userId': userId,
      'roles': roles,
      'isLandlord': isLandlord,
      'username': username,
    });
    
    if (kDebugMode) {
      print('✅ [AuthService] Trạng thái xác thực đã cập nhật - userId: $userId, roles: $roles');
    }
  }
  
  /// Xóa trạng thái xác thực
  Future<void> _clearAuthState() async {
    // Xóa biến nội bộ
    _isAuthenticated = false;
    _userId = null;
    _token = null;
    _roles = [];
    _isLandlord = false;
    _username = null;
    
    // Xóa từ secure storage
    await _secureStorage.clearAuthData();
    
    // Thông báo cho các listeners
    _authStateController.add(false);
    _userDataController.add({
      'userId': null,
      'roles': [],
      'isLandlord': false,
      'username': null,
    });
    
    if (kDebugMode) {
      print('🔄 [AuthService] Trạng thái xác thực đã được xóa');
    }
  }
  
  /// Kiểm tra role landlord
  bool _checkIsLandlord(List<String> roles) {
    const String ROLE_LANDLORD = "ROLE_LANDLORD";
    
    // Kiểm tra chuẩn xác
    if (roles.contains(ROLE_LANDLORD)) {
      return true;
    }
    
    // Kiểm tra case-insensitive
    final String landlordLower = ROLE_LANDLORD.toLowerCase();
    for (final role in roles) {
      if (role.toLowerCase() == landlordLower) {
        return true;
      }
    }
    
    // Kiểm tra nếu role chỉ chứa "LANDLORD" không có prefix
    for (final role in roles) {
      if (role.toLowerCase() == "landlord") {
        return true;
      }
    }
    
    // Kiểm tra nếu role có chứa "landlord" bất kỳ đâu
    for (final role in roles) {
      if (role.toLowerCase().contains("landlord")) {
        return true;
      }
    }
    
    return false;
  }
  
  /// Khởi tạo lại Dio với token mới
  Future<void> _reinitializeDio(String? token) async {
    try {
      if (kDebugMode) {
        print('🔄 [AuthService] Đang khởi tạo lại Dio với ${token != null ? "token mới" : "không có token"}...');
      }
      
      // Tạo Dio mới với token
      final dio = DioConfig.createDio();
      
      // Đảm bảo token được thêm vào header nếu có
      if (token != null && token.isNotEmpty) {
        dio.options.headers['Authorization'] = 'Bearer $token';
      } else {
        // Xóa token nếu có
        dio.options.headers.remove('Authorization');
      }
      
      // Lấy GetIt instance
      final getIt = GetIt.instance;
      
      // Unregister Dio cũ nếu có
      if (getIt.isRegistered<Dio>()) {
        getIt.unregister<Dio>();
      }
      
      // Đăng ký Dio mới
      getIt.registerLazySingleton<Dio>(() => dio);
      
      // Khởi tạo lại các repository
      await _reinitializeRepositories();
      
      if (kDebugMode) {
        print('✅ [AuthService] Đã khởi tạo lại Dio ${token != null ? "với token mới" : "không có token"} thành công');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthService] Lỗi khi khởi tạo lại Dio: $e');
      }
    }
  }
  
  /// Khởi tạo lại các repository sau khi Dio được khởi tạo lại
  Future<void> _reinitializeRepositories() async {
    try {
      if (kDebugMode) {
        print('🔄 [AuthService] Đang khởi tạo lại các repository...');
      }
      
      // Lấy GetIt instance
      final getIt = GetIt.instance;
      
      // Lấy Dio mới
      final dio = getIt<Dio>();
      
      // Danh sách các repository cần khởi tạo lại
      // Chỉ khởi tạo lại các repository đã được đăng ký trước đó
      if (getIt.isRegistered<FavoriteRepository>()) {
        getIt.unregister<FavoriteRepository>();
        getIt.registerLazySingleton<FavoriteRepository>(() => FavoriteRepositoryImpl(dio: dio));
        if (kDebugMode) {
          print('✅ [AuthService] Đã khởi tạo lại FavoriteRepository');
        }
      }
      
      if (getIt.isRegistered<ChatRoomRepository>()) {
        getIt.unregister<ChatRoomRepository>();
        getIt.registerLazySingleton<ChatRoomRepository>(() => ChatRoomRepositoryImpl(dio: dio));
        if (kDebugMode) {
          print('✅ [AuthService] Đã khởi tạo lại ChatRoomRepository');
        }
      }
      
      if (getIt.isRegistered<RoomRepository>()) {
        getIt.unregister<RoomRepository>();
        // RoomRepository cần thêm tham số cache
        final cache = getIt.isRegistered<Cache>() ? getIt<Cache>() : null;
        getIt.registerLazySingleton<RoomRepository>(() => RoomRepositoryImpl(dio: dio, cache: cache));
        if (kDebugMode) {
          print('✅ [AuthService] Đã khởi tạo lại RoomRepository');
        }
      }
      
      if (getIt.isRegistered<ReviewRepository>()) {
        getIt.unregister<ReviewRepository>();
        getIt.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(dio: dio));
        if (kDebugMode) {
          print('✅ [AuthService] Đã khởi tạo lại ReviewRepository');
        }
      }
      
      // Khởi tạo lại FindPartnerRepository
      if (getIt.isRegistered<FindPartnerRepository>()) {
        getIt.unregister<FindPartnerRepository>();
        getIt.registerLazySingleton<FindPartnerRepository>(() => FindPartnerRepositoryImpl(dio: dio));
        if (kDebugMode) {
          print('✅ [AuthService] Đã khởi tạo lại FindPartnerRepository');
        }
      }
      
      // Tiếp tục với các repository khác...
      if (kDebugMode) {
        print('✅ [AuthService] Đã khởi tạo lại tất cả repository');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthService] Lỗi khi khởi tạo lại repositories: $e');
      }
    }
  }
  
  /// Khởi tạo lại TẤT CẢ các repository, bất kể có được đăng ký trước đó hay không
  Future<void> _reinitializeAllRepositories() async {
    try {
      if (kDebugMode) {
        print('🔄 [AuthService] Đang khởi tạo lại tất cả các repository và services...');
      }
      
      // Lấy GetIt instance
      final getIt = GetIt.instance;
      
      // Lấy Dio mới
      final dio = getIt<Dio>();
      
      // Reset các repository quan trọng dù đã đăng ký hay chưa
      // FavoriteRepository
      if (getIt.isRegistered<FavoriteRepository>()) {
        getIt.unregister<FavoriteRepository>();
      }
      getIt.registerLazySingleton<FavoriteRepository>(() => FavoriteRepositoryImpl(dio: dio));
      
      // ChatRoomRepository
      if (getIt.isRegistered<ChatRoomRepository>()) {
        getIt.unregister<ChatRoomRepository>();
      }
      getIt.registerLazySingleton<ChatRoomRepository>(() => ChatRoomRepositoryImpl(dio: dio));
      
      // RoomRepository
      if (getIt.isRegistered<RoomRepository>()) {
        getIt.unregister<RoomRepository>();
      }
      final cache = getIt.isRegistered<Cache>() ? getIt<Cache>() : null;
      getIt.registerLazySingleton<RoomRepository>(() => RoomRepositoryImpl(dio: dio, cache: cache));
      
      // ReviewRepository
      if (getIt.isRegistered<ReviewRepository>()) {
        getIt.unregister<ReviewRepository>();
      }
      getIt.registerLazySingleton<ReviewRepository>(() => ReviewRepositoryImpl(dio: dio));
      
      // RoomImageRepository
      if (getIt.isRegistered<RoomImageRepository>()) {
        getIt.unregister<RoomImageRepository>();
      }
      getIt.registerLazySingleton<RoomImageRepository>(() => RoomImageRepositoryImpl(dio: dio));
      
      // FindPartnerRepository
      if (getIt.isRegistered<FindPartnerRepository>()) {
        getIt.unregister<FindPartnerRepository>();
      }
      getIt.registerLazySingleton<FindPartnerRepository>(() => FindPartnerRepositoryImpl(dio: dio));
      
      // Clear any caches to ensure fresh state
      if (getIt.isRegistered<Cache>() && cache != null) {
        await cache.clear();
      }
      
      if (kDebugMode) {
        print('✅ [AuthService] Đã khởi tạo lại tất cả các repository và xóa cache');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ [AuthService] Lỗi khi khởi tạo lại các repository: $e');
      }
    }
  }
  
  void dispose() {
    _authStateController.close();
    _userDataController.close();
  }
} 