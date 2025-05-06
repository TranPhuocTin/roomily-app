import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:get_it/get_it.dart';
import 'package:roomily/data/blocs/chat_room/direct_chat_room_cubit.dart';
import 'package:roomily/core/di/app_dependency_manager.dart';
import 'package:roomily/data/repositories/auth_repository.dart';
import 'package:roomily/presentation/screens/landlord_dashboard_screen.dart';
import 'package:roomily/presentation/screens/sign_in_screen.dart';
import 'package:roomily/presentation/widgets/common/custom_bottom_navigation_bar.dart';

import '../../data/blocs/auth/auth_cubit.dart';
import '../../data/blocs/chat_room/chat_room_cubit.dart';
import 'package:roomily/core/services/push_notification_service.dart';
import 'package:roomily/data/blocs/auth/auth_state.dart';

class SplashScreen extends StatefulWidget {
  final AppDependencyManager? dependencyManager;
  
  const SplashScreen({
    Key? key,
    this.dependencyManager,
  }) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  // Controller cho hiệu ứng dots nhảy
  late AnimationController _dotsController;
  
  bool _isInitialized = false;
  double _progress = 0.0;
  late final AppDependencyManager _dependencyManager;
  
  // Hằng số cho role - chính xác theo giá trị từ server
  static const String ROLE_LANDLORD = "ROLE_LANDLORD";
  
  // Danh sách màu gradient từ xanh lá nhạt sang xanh dương nhạt
  final List<Color> _dotColors = const [
    Color(0xFF8BC34A),  // Xanh lá nhạt
    Color(0xFF4CAF50),  // Xanh lá
    Color(0xFF009688),  // Xanh ngọc
    Color(0xFF00BCD4),  // Xanh cyan
    Color(0xFF03A9F4),  // Xanh dương nhạt
  ];

  @override
  void initState() {
    super.initState();
    _dependencyManager = widget.dependencyManager ?? GetIt.I<AppDependencyManager>();
    _setupAnimations();
    
    // Khởi tạo app sau một delay ngắn để animation có thể bắt đầu
    Future.delayed(const Duration(milliseconds: 300), _initialize);
  }

  void _setupAnimations() {
    // Animation cho fade và scale
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.0, 0.5, curve: Curves.easeIn),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Interval(0.3, 0.8, curve: Curves.easeOutBack),
      ),
    );
    
    // Animation cho dots nhảy
    _dotsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _fadeController.forward();
  }

  Future<void> _initialize() async {
    try {
      // Kiểm tra xem app đã được khởi tạo chưa ở nơi khác
      final bool appAlreadyInitialized = await _checkAppInitialization();
      
      if (appAlreadyInitialized) {
        debugPrint('🚀 Ứng dụng đã được khởi tạo ở nơi khác, chuyển đến kiểm tra xác thực...');
        setState(() {
          _isInitialized = true;
        });
        // Kiểm tra xác thực và điều hướng
        _checkAuthAndNavigate();
        return;
      }

      // Lắng nghe tiến trình khởi tạo
      _dependencyManager.initializationProgress?.listen(
        (progress) {
          setState(() {
            _progress = progress;
          });
        },
        onError: (error) {
          debugPrint('Lỗi trong quá trình khởi tạo: $error');
        },
        onDone: () {
          setState(() {
            _isInitialized = true;
          });
          // Chờ animation kết thúc rồi mới chuyển màn hình
          if (_fadeController.isAnimating) {
            _fadeController.forward().whenComplete(() {
              _checkAuthAndNavigate();
            });
          } else {
            _checkAuthAndNavigate();
          }
        }
      );

      // Không gọi bước khởi tạo cơ bản vì đã được gọi trong main()
      // Bắt đầu phần còn lại của quá trình khởi tạo
      await _dependencyManager.initializeAll();

      // Nếu đã đăng nhập, đăng ký FCM token
      final authCubit = GetIt.I<AuthCubit>();
      if (authCubit.state.status == AuthStatus.authenticated) {
        final pushNotificationService = GetIt.I<PushNotificationService>();
        await pushNotificationService.registerTokenWithServer();
      }
    } catch (e) {
      debugPrint('Error in splash screen initialization: $e');
      // Xử lý lỗi - có thể hiển thị thông báo lỗi
      // Nhưng vẫn cố gắng kiểm tra xác thực
      _checkAuthAndNavigate();
    }
  }
  
  /// Kiểm tra xem ứng dụng đã được khởi tạo chưa
  Future<bool> _checkAppInitialization() async {
    try {
      // Kiểm tra xem có thể truy cập AuthCubit từ GetIt
      // Nếu được thì các dependency cơ bản đã được khởi tạo
      final authCubit = GetIt.I<AuthCubit>();
      return true;
    } catch (e) {
      debugPrint('Chưa khởi tạo các dependency cơ bản: $e');
      return false;
    }
  }

  // Kiểm tra xác thực và điều hướng dựa trên vai trò
  Future<void> _checkAuthAndNavigate() async {
    try {
      // Đảm bảo tất cả các dependencies đã được khởi tạo đầy đủ
      await _ensureFullInitialization();
      
      final authRepository = GetIt.I<AuthRepository>();
      final isAuthenticated = await authRepository.isAuthenticated();
      
      if (!isAuthenticated) {
        // Người dùng chưa đăng nhập, chuyển đến màn hình đăng nhập
        debugPrint('🔒 User not authenticated, navigating to sign in');
        _navigateToSignIn();
        return;
      }
      
      // Lấy thông tin về vai trò người dùng
      final roles = await authRepository.getUserRoles();
      
      // Kiểm tra chi tiết về roles
      debugPrint('👤 Roles type: ${roles.runtimeType}');
      debugPrint('👤 Roles exact value: "$roles"');
      
      // Kiểm tra từng phần tử
      for (int i = 0; i < roles.length; i++) {
        debugPrint('👤 Role[$i]: "${roles[i]}" (length: ${roles[i].length})');
        debugPrint('👤 Role[$i] == ROLE_LANDLORD: ${roles[i] == ROLE_LANDLORD}');
      }
      
      // Kiểm tra role landlord với phương thức linh hoạt
      final isLandlord = _hasLandlordRole(roles);
      final userId = await authRepository.getUserId();
      
      debugPrint('👤 User ID: $userId');
      debugPrint('👤 User roles: ${roles.join(", ")}');
      debugPrint('🏠 Is landlord: $isLandlord');
      debugPrint('🏠 ROLE_LANDLORD constant: $ROLE_LANDLORD');
      
      if (isLandlord) {
        debugPrint('🏠 Navigating to LANDLORD dashboard');
        _navigateToLandlordDashboard();
      } else {
        debugPrint('🏠 Navigating to TENANT home');
        _navigateToTenantHome();
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi kiểm tra xác thực: $e');
      // Có lỗi khi kiểm tra xác thực, chuyển đến màn hình đăng nhập
      _navigateToSignIn();
    }
  }
  
  // Phương thức kiểm tra role landlord linh hoạt hơn
  bool _hasLandlordRole(List<String> roles) {
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

  /// Đảm bảo rằng tất cả các dependencies đã được khởi tạo đầy đủ
  Future<void> _ensureFullInitialization() async {
    try {
      // Kiểm tra xem tất cả các dependencies đã được khởi tạo đầy đủ chưa
      // bằng cách truy cập một số dịch vụ chủ chốt
      if (GetIt.I.isRegistered<AuthCubit>() && 
          GetIt.I.isRegistered<ChatRoomCubit>() &&
          GetIt.I.isRegistered<DirectChatRoomCubit>()) {
        // Các khối chính đã được khởi tạo
        debugPrint('✅ Các dependencies chính đã được khởi tạo đầy đủ');
        return;
      }
      
      // Nếu chưa khởi tạo đủ, tiến hành khởi tạo lại
      debugPrint('⚠️ Cần khởi tạo thêm dependencies, tiến hành khởi tạo đầy đủ...');
      
      // Khởi tạo đầy đủ tất cả dependencies
      await _dependencyManager.initializeAll();
      
      // Kiểm tra lại
      if (!GetIt.I.isRegistered<AuthCubit>() || 
          !GetIt.I.isRegistered<ChatRoomCubit>() ||
          !GetIt.I.isRegistered<DirectChatRoomCubit>()) {
        throw Exception('Không thể khởi tạo đầy đủ các dependencies cần thiết');
      }
      
    } catch (e) {
      debugPrint('❌ Lỗi khi đảm bảo khởi tạo đầy đủ: $e');
      rethrow;
    }
  }

  // Điều hướng đến màn hình đăng nhập
  void _navigateToSignIn() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SignInScreen()),
    );
  }

  // Điều hướng đến màn hình dashboard cho chủ nhà
  void _navigateToLandlordDashboard() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LandlordDashboardScreen()),
    );
  }

  // Điều hướng đến màn hình chính cho người thuê
  void _navigateToTenantHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const CustomBottomNavigationBar()),
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _dotsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/splash_background.jpg',
            fit: BoxFit.cover,
          ),
          
          // Overlay để tăng độ tương phản nếu cần
          Container(
            color: Colors.white.withOpacity(0.3),
          ),
          
          // Logo và loading indicator
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo từ asset
                Image.asset('assets/icons/splash_logo.png'),
                
                const SizedBox(height: 40),
                
                // Hiển thị tiến trình khởi tạo
                if (!_isInitialized) ...[
                  // 5 dots nhảy lên nhảy xuống với màu gradient
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return AnimatedBuilder(
                        animation: _dotsController,
                        builder: (context, child) {
                          final double delayPercent = index * 0.15;
                          final double jumpValue = _calculateJumpValue(
                            _dotsController.value, 
                            delayPercent,
                          );
                          
                          return Container(
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            child: Transform.translate(
                              offset: Offset(0, jumpValue),
                              child: Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: _dotColors[index],
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: _dotColors[index].withOpacity(0.5),
                                      blurRadius: 6,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  // Giữ nguyên phương thức _calculateJumpValue như cũ
  double _calculateJumpValue(double value, double delayPercent) {
    final double adjustedPercent = (value - delayPercent) % 1.0;
    
    // Convert to radians (0 to 2*PI)
    final double radians = adjustedPercent * 2 * math.pi;
    
    // Create a sine wave and scale it to desired jump height
    return math.sin(radians) * -10.0;
  }
}
