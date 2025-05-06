import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:roomily/data/blocs/wallet/wallet_cubit.dart';
import 'package:roomily/data/blocs/wallet/wallet_state.dart';
import 'package:roomily/data/models/user.dart';
import 'package:roomily/data/models/user_profile.dart';
import 'package:roomily/data/models/withdraw_info_create.dart';
import 'package:roomily/data/repositories/favorite_repository.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:roomily/data/repositories/user_repository_impl.dart';
import 'package:roomily/data/repositories/wallet_repository.dart';
import 'package:roomily/presentation/screens/bookings_screen.dart';
import 'package:roomily/presentation/screens/reviews_screen.dart';
import 'package:roomily/presentation/screens/saved_rooms_screen.dart';
import 'package:roomily/presentation/screens/tenant_room_management_screen.dart';
import 'package:roomily/presentation/screens/sign_in_screen.dart';
import 'package:roomily/presentation/screens/view_all_rented_room_screen.dart';
import 'package:roomily/presentation/screens/find_partner_management_screen.dart';
import 'package:roomily/presentation/screens/user_detail_screen.dart';
import 'package:roomily/presentation/screens/wallet_management_screen.dart';
import 'package:roomily/presentation/widgets/common/section_divider.dart';
import 'package:roomily/presentation/widgets/profile/profile_menu_item.dart';
import 'package:roomily/presentation/widgets/profile/profile_stats_bar.dart';
import 'package:roomily/core/services/session_service.dart';

import '../../core/di/app_dependency_manager.dart';
import '../../data/blocs/home/favorite_cubit.dart';
import '../../data/blocs/home/favorite_state.dart';
import '../../data/blocs/user/user_cubit.dart';
import '../../data/blocs/user/user_state.dart';
import '../../data/repositories/rented_room_repository.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with WidgetsBindingObserver, AutomaticKeepAliveClientMixin {
  late ScrollController _scrollController;
  bool _isScrolled = false;
  late UserProfile _mockUserProfile;
  bool _isCurrentlyVisible = false;
  DateTime _lastRefreshTime = DateTime.now();
  late UserCubit _userCubit;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  // App color scheme
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  final Color accentGreen = const Color(0xFF00C897);
  final Color accentRed = const Color(0xFFFF456C);
  final Color textPrimaryColor = const Color(0xFF1A2237);
  final Color textSecondaryColor = const Color(0xFF8798AD);
  
  double _userBalance = 0;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    print('[UserProfileScreen] initState');
    _scrollController = ScrollController();
    _scrollController.addListener(_onScroll);
    _initMockData();
    // Khởi tạo UserCubit
    _userCubit = UserCubit(userRepository: UserRepositoryImpl());
    _userCubit.getUserInfo();

    // Đăng ký observer để theo dõi vòng đời ứng dụng
    WidgetsBinding.instance.addObserver(this);

    // Initialize the favorite count
    Future.microtask(() {
      print('[UserProfileScreen] Initial favorite rooms refresh');
      _refreshFavoriteRooms();
    });

    // Cài đặt để lắng nghe khi app được focus
    WidgetsBinding.instance.addPostFrameCallback((_) {
      print('[UserProfileScreen] Post frame callback');
      // Kiểm tra xem trang này đã hiển thị (visible) chưa
      final state = ModalRoute.of(context)?.isCurrent ?? false;
      _isCurrentlyVisible = state;
      print('[UserProfileScreen] Is visible: $_isCurrentlyVisible');
      // Nếu đang hiển thị, cập nhật dữ liệu
      if (_isCurrentlyVisible) {
        _refreshFavoriteRooms();
      }
    });

    // Get user balance if available from BLoC
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.read<UserCubit>().state is UserInfoLoaded) {
        final state = context.read<UserCubit>().state as UserInfoLoaded;
        setState(() {
          _userBalance = state.user.balance;
        });
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print('[UserProfileScreen] didChangeDependencies');
    // Khi dependencies thay đổi (có thể là khi chuyển tab), cập nhật dữ liệu
    _refreshFavoriteRooms();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    print('[UserProfileScreen] App lifecycle changed: $state');
    // Khi ứng dụng trở lại foreground, cập nhật dữ liệu
    if (state == AppLifecycleState.resumed && _isCurrentlyVisible) {
      print(
          '[UserProfileScreen] App resumed and visible, refreshing favorites');
      _refreshFavoriteRooms();
    }
  }

  void _refreshFavoriteRooms() {
    // Tránh refresh quá nhiều - chỉ refresh nếu đã trôi qua ít nhất 1 giây kể từ lần cuối
    final now = DateTime.now();
    if (now.difference(_lastRefreshTime).inSeconds < 1) {
      print(
          '[UserProfileScreen] Skipping refresh - too soon (${now.difference(_lastRefreshTime).inMilliseconds}ms)');
      return;
    }

    _lastRefreshTime = now;
    print('[UserProfileScreen] Refreshing favorite rooms');
    // Cập nhật danh sách phòng yêu thích
    if (mounted) {
      context.read<FavoriteCubit>().getFavoriteRooms();
    }
  }

  void _initMockData() {
    _mockUserProfile = UserProfile(
      id: '1',
      name: 'Nguyễn Văn A',
      email: 'nguyenvana@example.com',
      avatarUrl:
      'https://images.unsplash.com/photo-1633332755192-727a05c4013d?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=400&q=80',
      location: 'Đà Nẵng, Việt Nam',
      bio: 'Tôi yêu thích khám phá những căn phòng thoải mái và tiện nghi.',
      favoritesCount: 15,
      bookingsCount: 5,
      reviewsCount: 8,
      savedRooms: [
        SavedRoom(
          id: '101',
          title: 'Phòng trọ gần biển',
          address: '123 Nguyễn Văn Linh, Đà Nẵng',
          price: 3000000,
          imageUrl:
          'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
        ),
        SavedRoom(
          id: '102',
          title: 'Căn hộ studio view thành phố',
          address: '456 Trần Phú, Đà Nẵng',
          price: 5000000,
          imageUrl:
          'https://images.unsplash.com/photo-1560448204-603b3fc33ddc?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
        ),
        SavedRoom(
          id: '103',
          title: 'Căn hộ cao cấp gần biển Mỹ Khê',
          address: '789 Võ Nguyên Giáp, Đà Nẵng',
          price: 7000000,
          imageUrl:
          'https://images.unsplash.com/photo-1484154218962-a197022b5858?ixlib=rb-4.0.3&auto=format&fit=crop&w=1200&q=80',
        ),
      ],
      bookings: [
        Booking(
          id: '201',
          roomId: '101',
          roomTitle: 'Phòng trọ gần biển',
          roomAddress: '123 Nguyễn Văn Linh, Đà Nẵng',
          startDate: DateTime.now().subtract(const Duration(days: 30)),
          endDate: DateTime.now().add(const Duration(days: 30)),
          amount: 3000000,
          status: 'Đang thuê',
        ),
        Booking(
          id: '202',
          roomId: '102',
          roomTitle: 'Căn hộ studio view thành phố',
          roomAddress: '456 Trần Phú, Đà Nẵng',
          startDate: DateTime.now().subtract(const Duration(days: 90)),
          endDate: DateTime.now().subtract(const Duration(days: 30)),
          amount: 5000000,
          status: 'Đã hết hạn',
        ),
      ],
      reviews: [
        Review(
          id: '301',
          roomId: '101',
          roomTitle: 'Phòng trọ gần biển',
          rating: 4.5,
          comment: 'Phòng sạch sẽ, thoáng mát, chủ trọ thân thiện.',
          createdAt: DateTime.now().subtract(const Duration(days: 5)),
        ),
        Review(
          id: '302',
          roomId: '102',
          roomTitle: 'Căn hộ studio view thành phố',
          rating: 3.5,
          comment: 'Vị trí đẹp, gần trung tâm, nhưng hơi ồn.',
          createdAt: DateTime.now().subtract(const Duration(days: 50)),
        ),
      ],
      phone: '0123456789',
      isLandlord: false,
    );
  }

  

  @override
  void dispose() {
    print('[UserProfileScreen] dispose');
    _scrollController.dispose();
    _userCubit.close();
    // Hủy đăng ký observer
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 100 && !_isScrolled) {
      setState(() {
        _isScrolled = true;
      });
    } else if (_scrollController.offset <= 100 && _isScrolled) {
      setState(() {
        _isScrolled = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(
        context); // Đảm bảo gọi super.build khi sử dụng AutomaticKeepAliveClientMixin

    // Sử dụng độ trễ ngắn để đảm bảo UI được cập nhật khi tab được chọn
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        print('[UserProfileScreen] Delayed refresh after build');
        _refreshFavoriteRooms();
      }
    });

    return BlocProvider.value(
      value: _userCubit,
      child: Scaffold(
        body: BlocBuilder<UserCubit, UserInfoState>(
          builder: (context, state) {
            if (state is UserInfoLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (state is UserInfoError) {
              return Center(child: Text('Lỗi: ${state.message}'));
            } else if (state is UserInfoLoaded) {
              return _buildUserProfileContent(context, state.user);
            }
            
            // Fallback to loading
            return const Center(child: CircularProgressIndicator());
          },
        ),
      ),
    );
  }

  Widget _buildUserProfileContent(BuildContext context, User user) {
    return Stack(
      children: [
        // Main content
        SafeArea(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // QR Code section
                _buildQRSection(user),

                // Stats bar (favorites, bookings, reviews)
           

                const SectionDivider(),

                // Menu items
                _buildMenuSection(user),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQRSection(User user) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(left: 16, right: 16, top: 20, bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [      
          const SizedBox(height: 20),
          // QR Code
          Center(
            child: Column(
              children: [
                QrImageView(
                  data: user.privateId,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                ),
                const SizedBox(height: 4),
                Text(
                  'Dùng mã này để kết nối với bạn bè',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(User user) {
    final primaryColor = Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Account section
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Tài khoản',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),

        // Profile Section
        ProfileMenuItem(
          icon: Icons.person,
          iconColor: Colors.purple,
          title: 'Thông tin cá nhân',
          subtitle: 'Xem và cập nhật thông tin cá nhân',
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UserDetailScreen(),
              ),
            );
          },
        ),

        // Add wallet management menu item
        BlocBuilder<UserCubit, UserInfoState>(
          builder: (context, state) {
            if (state is UserInfoLoaded) {
              _userBalance = state.user.balance;
            }
            
            return ProfileMenuItem(
              icon: Icons.account_balance_wallet,
              iconColor: Colors.amber,
              title: 'Quản lý ví',
              subtitle: 'Số dư: ${currencyFormatter.format(_userBalance)}',
              onTap: () {
                // Navigate to wallet management screen
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const WalletManagementScreen(),
                  ),
                ).then((_) {
                  // Refresh user info when returning
                  if (mounted) {
                    context.read<UserCubit>().getUserInfo();
                  }
                });
              },
            );
          }
        ),

        // Room Management Section (Only show if user has active bookings)
        if (_mockUserProfile.bookings
            .any((booking) => booking.status == 'Đang thuê'))
          ProfileMenuItem(
            icon: Icons.apartment,
            iconColor: Colors.teal,
            title: 'Quản lý phòng',
            subtitle: 'Thanh toán, hóa đơn và khiếu nại',
            onTap: () {

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ViewAllRentedRoomScreen(),
                  ),
              );
            },
          ),

        // Find Partner Posts Management Section
        ProfileMenuItem(
          icon: Icons.group,
          iconColor: Colors.blue,
          title: 'Tìm bạn ở ghép',
          subtitle: 'Quản lý bài đăng và thành viên nhóm',
          onTap: _navigateToFindPartnerManagement,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              'Mới',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.blue[700],
              ),
            ),
          ),
        ),

        BlocBuilder<FavoriteCubit, FavoriteState>(
          builder: (context, state) {
            int savedRoomsCount = 0;
            if (state is FavoriteLoaded) {
              savedRoomsCount = state.favoriteRooms.length;
              print(
                  '[UserProfileScreen] Menu showing $savedRoomsCount saved rooms');
            }

            return ProfileMenuItem(
              icon: Icons.favorite,
              iconColor: Colors.red,
              title: 'Phòng đã lưu',
              subtitle: '$savedRoomsCount phòng',
              onTap: _navigateToSavedRooms,
              trailing: savedRoomsCount > 0
                  ? Text(
                      '$savedRoomsCount',
                      style: TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            );
          },
        ),
        //
        // ProfileMenuItem(
        //   icon: Icons.home,
        //   iconColor: Colors.green,
        //   title: 'Đang đặt',
        //   subtitle: '${_mockUserProfile.bookings.length} phòng',
        //   onTap: _navigateToBookings,
        // ),

        // ProfileMenuItem(
        //   icon: Icons.star,
        //   iconColor: Colors.amber,
        //   title: 'Đánh giá của bạn',
        //   subtitle: '${_mockUserProfile.reviews.length} đánh giá',
        //   onTap: _navigateToReviews,
        // ),

        const SectionDivider(),

        // Settings section
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
          child: Text(
            'Cài đặt',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
        ),

        ProfileMenuItem(
          icon: Icons.language,
          iconColor: primaryColor,
          title: 'Ngôn ngữ',
          subtitle: 'Tiếng Việt',
          onTap: () {
            // Show language selection dialog
            _showLanguageSelectionDialog();
          },
        ),

        // ProfileMenuItem(
        //   icon: Icons.dark_mode,
        //   iconColor: Colors.indigo,
        //   title: 'Chế độ tối',
        //   onTap: () {},
        //   trailing: Switch(
        //     value: false,
        //     onChanged: (value) {
        //       // Handle theme change
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(
        //           content: Text('Chế độ tối: ${value ? 'Bật' : 'Tắt'}'),
        //           duration: const Duration(seconds: 1),
        //         ),
        //       );
        //     },
        //     activeColor: primaryColor,
        //   ),
        // ),

        // ProfileMenuItem(
        //   icon: Icons.notifications,
        //   iconColor: Colors.orange,
        //   title: 'Thông báo',
        //   onTap: () {},
        //   trailing: Switch(
        //     value: true,
        //     onChanged: (value) {
        //       // Handle notification settings change
        //       ScaffoldMessenger.of(context).showSnackBar(
        //         SnackBar(
        //           content: Text('Thông báo: ${value ? 'Bật' : 'Tắt'}'),
        //           duration: const Duration(seconds: 1),
        //         ),
        //       );
        //     },
        //     activeColor: primaryColor,
        //   ),
        // ),

        // ProfileMenuItem(
        //   icon: Icons.security,
        //   iconColor: Colors.blue,
        //   title: 'Bảo mật & Quyền riêng tư',
        //   onTap: () {
        //     // Navigate to security settings
        //   },
        // ),
        //
        // const SectionDivider(),
        //
        // // Support section
        // Padding(
        //   padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8),
        //   child: Text(
        //     'Hỗ trợ',
        //     style: TextStyle(
        //       fontSize: 14,
        //       fontWeight: FontWeight.bold,
        //       color: Colors.grey[600],
        //     ),
        //   ),
        // ),
        //
        // ProfileMenuItem(
        //   icon: Icons.help_outline,
        //   iconColor: Colors.purple,
        //   title: 'Trung tâm trợ giúp',
        //   onTap: () {
        //     // Navigate to help center
        //   },
        // ),
        //
        // ProfileMenuItem(
        //   icon: Icons.info_outline,
        //   iconColor: Colors.teal,
        //   title: 'Về chúng tôi',
        //   onTap: () {
        //     // Navigate to about page
        //   },
        // ),

        ProfileMenuItem(
          icon: Icons.logout,
          iconColor: Colors.red,
          title: 'Đăng xuất',
          onTap: () {
            // Show confirmation dialog before logout
            _showLogoutConfirmationDialog();
          },
        ),

        const SizedBox(height: 24),
      ],
    );
  }

  void _navigateToSavedRooms() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SavedRoomsScreen(
          favoriteCubit: context.read<FavoriteCubit>(),
        ),
      ),
    );
  }

  void _navigateToBookings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingsScreen(
          bookings: _mockUserProfile.bookings,
        ),
      ),
    );
  }

  void _navigateToReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReviewsScreen(
          reviews: _mockUserProfile.reviews,
        ),
      ),
    );
  }

  void _navigateToFindPartnerManagement() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const FindPartnerManagementScreen(),
      ),
    );
  }

  void _showLanguageSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Chọn ngôn ngữ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildLanguageOption('Tiếng Việt', 'vi'),
              _buildLanguageOption('English', 'en'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Hủy'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLanguageOption(String language, String code) {
    final isSelected = (language == 'Tiếng Việt'); // Default to Vietnamese

    return ListTile(
      title: Text(language),
      trailing: isSelected
          ? Icon(
              Icons.check,
              color: Theme.of(context).primaryColor,
            )
          : null,
      onTap: () {
        // Handle language change
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã chuyển ngôn ngữ sang: $language'),
            duration: const Duration(seconds: 1),
          ),
        );
        Navigator.of(context).pop();
      },
    );
  }

  // Show confirmation dialog before logout
  void _showLogoutConfirmationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc chắn muốn đăng xuất không?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _handleLogout();
            },
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );
  }

  // Handle the logout process
  Future<void> _handleLogout() async {
    try {
      _showLogoutLoading();
      final sessionService = GetIt.I<SessionService>();
      await sessionService.logout();
      await GetIt.I<AppDependencyManager>().resetAll();
      await GetIt.I<AppDependencyManager>().initializeCore();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop(); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi khi đăng xuất: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Hiển thị loading indicator khi đang đăng xuất
  void _showLogoutLoading() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: const [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text('Đang đăng xuất...'),
              ],
            ),
          ),
        );
      },
    );
  }
}
