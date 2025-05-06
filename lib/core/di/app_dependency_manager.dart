import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/data/blocs/chat_room/direct_chat_room_cubit.dart';
import 'package:roomily/data/blocs/contract/contract_cubit.dart';
import 'package:roomily/core/cache/cache.dart';
import 'package:roomily/core/cache/image_cache_manager.dart';
import 'package:roomily/core/cache/language_preference.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/core/services/google_places_service.dart';
import 'package:roomily/core/services/location_service.dart';
import 'package:roomily/core/services/marker_service.dart';
import 'package:roomily/core/services/message_handler_service.dart';
import 'package:roomily/core/services/notification_service.dart';
import 'package:roomily/core/services/province_mapper.dart';
import 'package:roomily/core/services/search_service.dart';
import 'package:roomily/core/services/secure_storage_service.dart';
import 'package:roomily/core/services/session_service.dart';
import 'package:roomily/core/services/stomp_service.dart';
import 'package:roomily/core/services/tag_service.dart';
import 'package:roomily/core/services/user_location_service.dart';
import 'package:roomily/data/repositories/auth_repository.dart';
import 'package:roomily/data/repositories/auth_repository_impl.dart';
import 'package:roomily/data/repositories/chat_room_repository.dart';
import 'package:roomily/data/repositories/chat_room_repository_impl.dart';
import 'package:roomily/data/repositories/contract_repository.dart';
import 'package:roomily/data/repositories/contract_repository_impl.dart';
import 'package:roomily/data/repositories/favorite_repository.dart';
import 'package:roomily/data/repositories/favorite_repository_impl.dart';
import 'package:roomily/data/repositories/google_places_repository.dart';
import 'package:roomily/data/repositories/google_places_repository_impl.dart';
import 'package:roomily/data/repositories/rented_room_repository.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:roomily/data/repositories/review_repository.dart';
import 'package:roomily/data/repositories/review_repository_impl.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/data/repositories/room_image_repository_impl.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/repositories/room_repository_impl.dart';
import 'package:roomily/data/repositories/tag_repository.dart';
import 'package:roomily/data/repositories/tag_repository_impl.dart';
import 'package:roomily/data/repositories/user_repository.dart';
import 'package:roomily/data/repositories/user_repository_impl.dart';
import 'package:roomily/data/repositories/recommendation_repository.dart';
import 'package:roomily/data/repositories/find_partner_repository.dart';
import 'package:roomily/data/repositories/find_partner_repository_impl.dart';
import 'package:roomily/data/repositories/landlord_statistics_repository.dart';
import 'package:roomily/data/repositories/landlord_statistics_repository_impl.dart';
import 'package:roomily/data/repositories/ad_repository.dart';
import 'package:roomily/data/repositories/ad_repository_impl.dart';
import 'package:roomily/data/repositories/budget_plan_repository.dart';
import 'package:roomily/data/repositories/budget_plan_repository_impl.dart';
import 'package:roomily/data/repositories/room_report_repository.dart';
import 'package:roomily/data/repositories/room_report_repository_impl.dart';
import 'package:roomily/core/services/api_key_service.dart';

import '../../data/blocs/auth/auth_cubit.dart';
import '../../data/blocs/chat_room/chat_room_cubit.dart';
import '../../data/blocs/home/favorite_cubit.dart';
import '../../data/blocs/home/room_detail_cubit.dart';
import '../../data/blocs/landlord/landlord_rooms_cubit.dart';
import '../../data/blocs/landlord/landlord_statistics_cubit.dart';
import '../../data/blocs/rented_room/rented_room_cubit.dart';
import '../../data/blocs/user/user_cubit.dart';
import 'package:roomily/data/blocs/add_campaign/add_campaign_cubit.dart';
import 'package:roomily/data/blocs/campaigns/campaigns_cubit.dart';
import 'package:roomily/data/blocs/promoted_rooms/promoted_rooms_cubit.dart';
import 'package:roomily/core/services/push_notification_service.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_cubit.dart';
import 'package:roomily/data/blocs/room_report/room_report_cubit.dart';

/// Lớp quản lý dependencies của ứng dụng
/// Tập trung tất cả logic khởi tạo và đăng ký dependencies vào một nơi duy nhất
class AppDependencyManager {
  final GetIt _getIt = GetIt.instance;

  // Stream để theo dõi tiến trình khởi tạo
  StreamController<double>? _initializationProgress;

  Stream<double>? get initializationProgress => _initializationProgress?.stream;

  // Cờ đánh dấu các dependency đã được khởi tạo
  bool _coreInitialized = false;
  bool _fullyInitialized = false;

  /// Khởi tạo các dependencies cơ bản
  /// Sử dụng phương thức này khi cần tạo các dependency cơ bản trước khi render UI
  Future<void> initializeCore() async {
    if (_coreInitialized) {
      debugPrint('🔄 Core dependencies đã được khởi tạo trước đó');
      return;
    }

    debugPrint('🚀 Bắt đầu khởi tạo các dependencies cơ bản...');

    try {
      // Log thông tin API key
      ApiKeyService.logApiKeyInfo();

      // Khởi tạo Dio và các core dependencies
      _registerCoreServices();
      _coreInitialized = true;

      // Khởi tạo AuthService và kiểm tra trạng thái
      await _initAuth();

      debugPrint('✅ Khởi tạo các dependencies cơ bản thành công');
    } catch (e, stackTrace) {
      debugPrint('❌ Lỗi khi khởi tạo dependencies cơ bản: $e');
      debugPrint(stackTrace.toString());
      rethrow;
    }
  }

  /// Khởi tạo tất cả dependencies của ứng dụng
  Future<void> initializeAll() async {
    if (_fullyInitialized) {
      debugPrint('🔄 Ứng dụng đã được khởi tạo đầy đủ trước đó');
      return;
    }

    debugPrint('🚀 Bắt đầu quá trình khởi tạo đầy đủ...');

    // Tạo StreamController mới nếu cần
    _initializationProgress?.close();
    _initializationProgress = StreamController<double>.broadcast();

    try {
      _initializationProgress?.add(0.0);

      // Khởi tạo core nếu chưa được khởi tạo
      if (!_coreInitialized) {
        await initializeCore();
      }
      _initializationProgress?.add(0.3);

      // Đăng ký các repository
      _registerRepositories();
      _initializationProgress?.add(0.5);

      // Đăng ký các service
      _registerServices();
      _initializationProgress?.add(0.7);

      // Đăng ký các BLoC/Cubit
      _registerBlocs();
      _initializationProgress?.add(0.8);

      // Khởi tạo các service cần thiết
      await _initializeServices();
      _initializationProgress?.add(0.9);

      // Tải cài đặt ngôn ngữ
      await _loadSavedLocale();
      _initializationProgress?.add(1.0);

      _fullyInitialized = true;
      debugPrint('✅ Khởi tạo đầy đủ ứng dụng hoàn thành');
    } catch (e, stackTrace) {
      debugPrint('❌ Lỗi khởi tạo ứng dụng: $e');
      debugPrint(stackTrace.toString());
      _initializationProgress?.addError(e);
      rethrow;
    } finally {
      await Future.delayed(const Duration(milliseconds: 500));
      await _initializationProgress?.close();
      _initializationProgress = null;
    }
  }

  /// Đăng ký các dịch vụ cốt lõi
  void _registerCoreServices() {
    // Register a global navigator key for navigation from services
    _registerIfNotExists<GlobalKey<NavigatorState>>(
        () => GlobalKey<NavigatorState>());

    // Đăng ký Dio
    _registerIfNotExists<Dio>(() => DioConfig.createDio());

    // Đăng ký cache managers
    _registerIfNotExists<ImageCacheManager>(() => ImageCacheManager());
    _registerIfNotExists<RoomThumbnailCacheManager>(
        () => RoomThumbnailCacheManager());
    _registerIfNotExists<AvatarCacheManager>(() => AvatarCacheManager());
    _registerIfNotExists<Cache>(() => PersistentCache());

    // Đăng ký secure storage
    _registerIfNotExists<SecureStorageService>(() => SecureStorageService());

    // Đăng ký location services
    _registerIfNotExists<LocationService>(() => LocationService());
    _registerIfNotExists<UserLocationService>(() => UserLocationService());
    _registerIfNotExists<SearchService>(
        () => SearchService(accessToken: ApiKeyService.accessToken));

    // Đăng ký AuthRepository
    _registerIfNotExists<AuthRepository>(() => AuthRepositoryImpl(
          dio: _getIt<Dio>(),
          secureStorage: _getIt<SecureStorageService>(),
        ));

    // Đăng ký RecommendationRepository
    _registerIfNotExists<RecommendationRepository>(
        () => RecommendationRepositoryImpl(dio: _getIt<Dio>()));

    // Đăng ký AuthService
    _registerIfNotExists<AuthService>(() => AuthService(
          _getIt<AuthRepository>(),
          _getIt<SecureStorageService>(),
        ));

    // Firebase Push Notification Service
    _registerIfNotExists<PushNotificationService>(
        () => PushNotificationService());

    // Đăng ký AuthCubit
    _registerIfNotExists<AuthCubit>(() => AuthCubit(
          _getIt<AuthService>(),
          pushNotificationService: _getIt<PushNotificationService>(),
        ));
  }

  /// Đăng ký các repository
  void _registerRepositories() {
    // Google Places
    _registerIfNotExists<GooglePlacesRepository>(
        () => GooglePlacesRepositoryImpl(apiKey: ApiKeyService.googleMapsApiKey));

    // Room và liên quan
    _registerIfNotExists<RoomRepository>(() => RoomRepositoryImpl(
          dio: _getIt<Dio>(),
          cache: _getIt<Cache>(),
        ));
    _registerIfNotExists<BudgetPlanRepository>(
        () => BudgetPlanRepositoryImpl(dio: _getIt<Dio>()));
    _registerIfNotExists<RoomImageRepository>(
        () => RoomImageRepositoryImpl(dio: _getIt<Dio>()));
    _registerIfNotExists<RentedRoomRepository>(
        () => RentedRoomRepositoryImpl(dio: _getIt<Dio>()));

    // Budget Plan
    _registerIfNotExists<BudgetPlanRepository>(
        () => BudgetPlanRepositoryImpl(dio: _getIt<Dio>()));

    // Recommendation
    _registerIfNotExists<RecommendationRepository>(
        () => RecommendationRepositoryImpl(dio: _getIt<Dio>()));

    // Review và Favorite
    _registerIfNotExists<ReviewRepository>(
        () => ReviewRepositoryImpl(dio: _getIt<Dio>()));
    _registerIfNotExists<FavoriteRepository>(
        () => FavoriteRepositoryImpl(dio: _getIt<Dio>()));

    // Chat
    _registerIfNotExists<ChatRoomRepository>(
        () => ChatRoomRepositoryImpl(dio: _getIt<Dio>()));

    // Tags
    _registerIfNotExists<TagRepository>(() => TagRepositoryImpl());

    // User
    _registerIfNotExists<UserRepository>(() => UserRepositoryImpl());

    // Contract
    _registerIfNotExists<ContractRepository>(
        () => ContractRepositoryImpl(dio: _getIt<Dio>()));

    // Landlord statistics repository
    _registerIfNotExists<LandlordStatisticsRepository>(
        () => LandlordStatisticsRepositoryImpl(dio: _getIt<Dio>()));

    // FindPartner repository
    _registerIfNotExists<FindPartnerRepository>(
        () => FindPartnerRepositoryImpl(dio: _getIt<Dio>()));

    // Ad repository
    _registerIfNotExists<AdRepository>(
        () => AdRepositoryImpl(dio: _getIt<Dio>()));

    // Room Report repository
    _registerIfNotExists<RoomReportRepository>(
        () => RoomReportRepositoryImpl(dio: _getIt<Dio>()));
  }

  /// Đăng ký các service
  void _registerServices() {
    // Google Places Service
    _registerIfNotExists<GooglePlacesService>(() =>
        GooglePlacesService(repository: _getIt<GooglePlacesRepository>()));

    // STOMP và Message
    _registerIfNotExists<StompService>(() => StompService());
    _registerIfNotExists<MessageHandlerService>(() => MessageHandlerService());

    // Thông báo
    _registerIfNotExists<NotificationService>(() => NotificationService());

    // Firebase Push Notification Service
    _registerIfNotExists<PushNotificationService>(
        () => PushNotificationService());

    // Session
    _registerIfNotExists<SessionService>(() => SessionService());

    // Tag
    _registerIfNotExists<TagService>(() => TagService());

    // Province Mapper
    _registerIfNotExists<ProvinceMapper>(() => ProvinceMapper(
          locationService: _getIt<LocationService>(),
        ));
  }

  /// Đăng ký các BLoC/Cubit
  void _registerBlocs() {
    // Room related
    _registerIfNotExists<RoomDetailCubit>(
        () => RoomDetailCubit(_getIt<RoomRepository>()));
    _registerIfNotExists<LandlordRoomsCubit>(
        () => LandlordRoomsCubit(roomRepository: _getIt<RoomRepository>()));

    // Chat related
    _registerIfNotExists<ChatRoomCubit>(
        () => ChatRoomCubit(repository: _getIt<ChatRoomRepository>()));
    _registerIfNotExists<DirectChatRoomCubit>(() => DirectChatRoomCubit(
          repository: _getIt<ChatRoomRepository>(),
          chatRoomCubit: _getIt<ChatRoomCubit>(),
          roomDetailCubit: _getIt<RoomDetailCubit>(),
        ));

    // User
    _registerIfNotExists<UserCubit>(
        () => UserCubit(userRepository: _getIt<UserRepository>()));

    // Contract
    _registerIfNotExists<ContractCubit>(
        () => ContractCubit(repository: _getIt<ContractRepository>()));

    // Landlord statistics cubit
    _registerIfNotExists<LandlordStatisticsCubit>(
        () => LandlordStatisticsCubit(_getIt<LandlordStatisticsRepository>()));

    // Rented room
    _registerIfNotExists<RentedRoomCubit>(() =>
        RentedRoomCubit(rentedRoomRepository: _getIt<RentedRoomRepository>()));

    // Add Campaign Cubit
    _registerIfNotExists<AddCampaignCubit>(
        () => AddCampaignCubit(adRepository: _getIt<AdRepository>()));

    // Campaigns Cubit
    _registerIfNotExists<CampaignsCubit>(
        () => CampaignsCubit(adRepository: _getIt<AdRepository>()));

    // Promoted Rooms Cubit
    _registerIfNotExists<PromotedRoomsCubit>(
        () => PromotedRoomsCubit(adRepository: _getIt<AdRepository>()));

    // Budget Plan
    _registerIfNotExists<BudgetPlanCubit>(() =>
        BudgetPlanCubit(budgetPlanRepository: _getIt<BudgetPlanRepository>()));

    // Room Report
    _registerIfNotExists<RoomReportCubit>(
        () => RoomReportCubit(repository: _getIt<RoomReportRepository>()));

  }

  /// Khởi tạo AuthService và kiểm tra trạng thái
  Future<void> _initAuth() async {
    try {
      debugPrint('🔒 Kiểm tra trạng thái xác thực...');
      if (_getIt.isRegistered<AuthService>()) {
        await _getIt<AuthService>().checkAuthState();
        debugPrint('✅ Kiểm tra trạng thái xác thực thành công');
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi khi kiểm tra trạng thái xác thực: $e');
    }
  }

  /// Khởi tạo các service
  Future<void> _initializeServices() async {
    // Khởi tạo STOMP và MessageHandler
    await _setupStompConnection();

    // Khởi tạo NotificationService
    try {
      final notificationService = _getIt<NotificationService>();
      await notificationService.initialize();
      debugPrint('✅ NotificationService đã được khởi tạo thành công');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi khởi tạo NotificationService: $e');
    }

    // Khởi tạo PushNotificationService
    try {
      final pushNotificationService = _getIt<PushNotificationService>();
      await pushNotificationService.initialize();
      debugPrint('✅ PushNotificationService đã được khởi tạo thành công');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi khởi tạo PushNotificationService: $e');
    }

    // Khởi tạo UserLocationService nếu cần
    try {
      final userLocationService = _getIt<UserLocationService>();
      if (!userLocationService.isInitialized) {
        await userLocationService.initialize();
      }
    } catch (e) {
      debugPrint('⚠️ Lỗi khi khởi tạo UserLocationService: $e');
    }
  }

  /// Thiết lập kết nối STOMP
  Future<void> _setupStompConnection() async {
    try {
      // Khởi tạo message handler service
      final messageHandlerService = _getIt<MessageHandlerService>();
      await messageHandlerService.initialize();
      debugPrint(
          '✅ STOMP Connection và MessageHandlerService đã khởi tạo thành công');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi thiết lập kết nối STOMP: $e');
    }
  }

  /// Tải cài đặt ngôn ngữ đã lưu
  Future<void> _loadSavedLocale() async {
    try {
      final savedLocale = await LanguagePreference.getLocale();
      final hasSelectedLanguage =
          await LanguagePreference.hasSelectedLanguage();
      debugPrint(
          '✅ Đã tải cài đặt ngôn ngữ: $savedLocale, đã chọn: $hasSelectedLanguage');
    } catch (e) {
      debugPrint('⚠️ Lỗi khi tải cài đặt ngôn ngữ: $e');
    }
  }

  /// Đăng ký lazy singleton chỉ khi chưa được đăng ký
  void _registerIfNotExists<T extends Object>(FactoryFunc<T> factoryFunc) {
    if (_getIt.isRegistered<T>()) {
      _getIt.get<T>();
      debugPrint('ℹ️ $T đã được đăng ký trước đó');
    } else {
      _getIt.registerLazySingleton<T>(factoryFunc);
      debugPrint('📌 Đăng ký mới $T');
    }
  }

  Future<void> resetAll() async {
    debugPrint('🔄 Bắt đầu reset tất cả dependencies...');

    // Cleanup đặc biệt cho các service nếu cần
    if (_getIt.isRegistered<StompService>()) {
      _getIt<StompService>().disconnect();
    }
    if (_getIt.isRegistered<Cache>()) {
      await _getIt<Cache>().clear();
    }

    _unregisterIfRegistered<AuthCubit>();
    _unregisterIfRegistered<UserCubit>();
    _unregisterIfRegistered<ChatRoomCubit>();
    _unregisterIfRegistered<DirectChatRoomCubit>();
    _unregisterIfRegistered<RentedRoomCubit>();
    _unregisterIfRegistered<FavoriteCubit>();
    _unregisterIfRegistered<RoomDetailCubit>();
    _unregisterIfRegistered<LandlordRoomsCubit>();
    _unregisterIfRegistered<BudgetPlanCubit>();
    _unregisterIfRegistered<ContractCubit>();
    _unregisterIfRegistered<NotificationService>();
    _unregisterIfRegistered<PushNotificationService>();
    _unregisterIfRegistered<MessageHandlerService>();
    _unregisterIfRegistered<StompService>();
    _unregisterIfRegistered<ImageCacheManager>();
    _unregisterIfRegistered<RoomThumbnailCacheManager>();
    _unregisterIfRegistered<AvatarCacheManager>();
    _unregisterIfRegistered<AuthRepository>();
    _unregisterIfRegistered<UserRepository>();
    _unregisterIfRegistered<ChatRoomRepository>();
    _unregisterIfRegistered<RoomRepository>();
    _unregisterIfRegistered<ReviewRepository>();
    _unregisterIfRegistered<RoomImageRepository>();
    _unregisterIfRegistered<FindPartnerRepository>();
    _unregisterIfRegistered<FavoriteRepository>();
    _unregisterIfRegistered<LandlordStatisticsRepository>();
    _unregisterIfRegistered<AdRepository>();
    _unregisterIfRegistered<BudgetPlanRepository>();
    _unregisterIfRegistered<RoomReportRepository>();
    _unregisterIfRegistered<Dio>();

    _fullyInitialized = false;

    debugPrint('✅ Reset tất cả dependencies thành công');
  }

  /// Hủy đăng ký nếu đã đăng ký
  void _unregisterIfRegistered<T extends Object>() {
    if (_getIt.isRegistered<T>()) {
      _getIt.unregister<T>();
    }
  }
}
