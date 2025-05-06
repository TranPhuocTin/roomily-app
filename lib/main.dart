import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/stomp/stomp_cubit.dart';
import 'package:roomily/core/cache/language_preference.dart';
import 'package:roomily/core/di/app_dependency_manager.dart';
import 'package:roomily/core/localization/app_localization.dart';
import 'package:go_router/go_router.dart';
import 'package:roomily/data/repositories/favorite_repository.dart';
import 'package:roomily/data/repositories/favorite_repository_impl.dart';
import 'package:roomily/data/repositories/review_repository.dart';
import 'package:roomily/data/repositories/review_repository_impl.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/data/repositories/room_image_repository_impl.dart';

import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/repositories/room_repository_impl.dart';
import 'package:roomily/core/cache/cache.dart';
import 'package:roomily/core/cache/image_cache_manager.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/location_service.dart';
import 'package:roomily/core/services/user_location_service.dart';
import 'package:roomily/presentation/screens/splash_screen.dart';
import 'package:roomily/data/blocs/chat_room/direct_chat_room_cubit.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:roomily/data/blocs/contract/contract_cubit.dart';

import 'data/blocs/auth/auth_cubit.dart';
import 'data/blocs/chat_room/chat_room_cubit.dart';
import 'data/blocs/home/favorite_cubit.dart';
import 'data/blocs/home/room_detail_cubit.dart';
import 'data/blocs/home/room_image_cubit.dart';
import 'data/blocs/landlord/landlord_rooms_cubit.dart';
import 'data/blocs/map/map_cubit.dart';
import 'data/blocs/rented_room/rented_room_cubit.dart';
import 'data/blocs/room_filter/room_filter_cubit.dart';
import 'data/blocs/user/user_cubit.dart';
import 'package:roomily/data/repositories/ad_repository.dart';
import 'package:roomily/data/repositories/ad_repository_impl.dart';
import 'package:roomily/presentation/widgets/notification/notification_listener.dart' as notification;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_cubit.dart';

final getIt = GetIt.instance;

// FIXME: You need to pass in your access token via the command line argument
// --dart-define=ACCESS_TOKEN=ADD_YOUR_TOKEN_HERE
// Alternatively you can replace this with your access token directly.
const String ACCESS_TOKEN = String.fromEnvironment("ACCESS_TOKEN");

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  // Khởi tạo Firebase
  await Firebase.initializeApp();
  
  // Tạo và đăng ký AppDependencyManager
  final dependencyManager = AppDependencyManager();
  GetIt.I.registerSingleton<AppDependencyManager>(dependencyManager);
  
  // Khởi tạo các dịch vụ cơ bản
  try {
    debugPrint('🚀 Khởi tạo các dịch vụ cơ bản...');
    await dependencyManager.initializeCore();
    debugPrint('✅ Các dịch vụ cơ bản đã được khởi tạo thành công');
  } catch (e) {
    debugPrint('⚠️ Lỗi khi khởi tạo các dịch vụ cơ bản: $e');
  }
  
  // Đăng ký observer cho BLoC
  Bloc.observer = SimpleBlocObserver();
  
  // Lấy language preference 
  final savedLocale = await LanguagePreference.getLocale();
  final hasSelectedLanguage = await LanguagePreference.hasSelectedLanguage();
  
  // Tiếp tục khởi chạy ứng dụng như bình thường
  runApp(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>(
          create: (context) => getIt<AuthCubit>()..checkAuthenticationStatus(),
        ),
        BlocProvider<FavoriteCubit>(
          create: (context) => FavoriteCubit(getIt<FavoriteRepository>()),
        ),
        BlocProvider<ChatRoomCubit>(
          create: (context) => GetIt.I<ChatRoomCubit>(),
        ),
        BlocProvider<RoomDetailCubit>(
          create: (context) => GetIt.I<RoomDetailCubit>(),
        ),
        BlocProvider<DirectChatRoomCubit>(
          create: (context) => GetIt.I<DirectChatRoomCubit>(),
        ),
        BlocProvider<LandlordRoomsCubit>(
          create: (context) => GetIt.I<LandlordRoomsCubit>(),
        ),
        BlocProvider<RentedRoomCubit>(
          create: (context) => RentedRoomCubit(
            rentedRoomRepository: RentedRoomRepositoryImpl(),
          ),
        ),
        BlocProvider<UserCubit>(
          create: (context) => GetIt.I<UserCubit>(),
        ),
        BlocProvider<ContractCubit>(
          create: (context) => GetIt.I<ContractCubit>(),
        ),
        BlocProvider<BudgetPlanCubit>(
          create: (context) => GetIt.I<BudgetPlanCubit>(),
        ),
      ],
      child: MyApp(
        initialLocale: savedLocale,
        hasSelectedLanguage: hasSelectedLanguage,
        dependencyManager: dependencyManager,
      ),
    ),
  );
}

class MyApp extends StatefulWidget {
  final AppDependencyManager dependencyManager;
  final Locale initialLocale;
  final bool hasSelectedLanguage;

  const MyApp({
    super.key,
    required this.dependencyManager,
    required this.initialLocale,
    required this.hasSelectedLanguage,
  });

  static MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<MyAppState>()!;

  @override
  State<MyApp> createState() => MyAppState();
}

class MyAppState extends State<MyApp> {
  late Locale _locale;
  ThemeMode _themeMode = ThemeMode.light;
  bool _isInitializing = true;

  @override
  void initState() {
    super.initState();
    _locale = widget.initialLocale;
    
    // Hoàn tất việc khởi tạo ứng dụng
    _completeInitialization();
  }
  
  Future<void> _completeInitialization() async {
    try {
      // Hoàn thành việc khởi tạo các dependency còn lại
      await widget.dependencyManager.initializeAll();
      
      // Cập nhật trạng thái đã khởi tạo xong
      if (mounted) {
        setState(() {
          _isInitializing = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi hoàn tất khởi tạo: $e');
    }
  }

  void changeLocale(Locale locale) {
    setState(() {
      _locale = locale;
    });
  }

  void toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<MapCubit>(
          create: (context) => MapCubit(
            locationService: GetIt.I<LocationService>(),
            userLocationService: GetIt.I<UserLocationService>(),
          ),
        ),
        BlocProvider(
          create: (context) => RoomImageCubit(GetIt.I<RoomImageRepository>())
        ),
        BlocProvider<RoomFilterCubit>(
          create: (context) => RoomFilterCubit(),
        ),
      ],
      child: notification.PushNotificationHandler(
        child: MaterialApp(
          title: 'Roomily',
          debugShowCheckedModeBanner: false,
          themeMode: _themeMode,
          navigatorKey: GetIt.I<GlobalKey<NavigatorState>>(),
          theme: ThemeData(
            scaffoldBackgroundColor: Colors.white,
            brightness: Brightness.light,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.white,
              foregroundColor: Colors.black,
            ),
            cardTheme: const CardTheme(
              color: Colors.white,
            ),
            useMaterial3: false,
            primarySwatch: Colors.blue,
          ),
          darkTheme: ThemeData(
            scaffoldBackgroundColor: Colors.black,
            brightness: Brightness.dark,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.black,
              foregroundColor: Colors.white,
            ),
            cardTheme: const CardTheme(
              color: Colors.black,
            ),
            useMaterial3: false,
            primarySwatch: Colors.blue,
          ),
          localizationsDelegates: AppLocalization.localizationsDelegates,
          supportedLocales: AppLocalization.supportedLocales,
          locale: _locale,
          home: SplashScreen(dependencyManager: widget.dependencyManager),
        ),
      ),
    );
  }
}

// SimpleBlocObserver để gỡ lỗi
class SimpleBlocObserver extends BlocObserver {
  @override
  void onEvent(Bloc bloc, Object? event) {
    super.onEvent(bloc, event);
    debugPrint('${bloc.runtimeType} $event');
  }

  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} $error');
    super.onError(bloc, error, stackTrace);
  }

  @override
  void onChange(BlocBase bloc, Change change) {
    super.onChange(bloc, change);
    debugPrint('${bloc.runtimeType} $change');
  }

  @override
  void onTransition(Bloc<dynamic, dynamic> bloc, Transition transition) {
    super.onTransition(bloc, transition);
    debugPrint('${bloc.runtimeType} $transition');
  }
}
