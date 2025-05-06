import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:roomily/presentation/screens/chat_room_screen.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/core/utils/room_status.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/secure_storage_service.dart';
import 'package:roomily/core/services/notification_service.dart';
import 'package:roomily/presentation/screens/notification_screen.dart';
import 'package:roomily/presentation/widgets/common/landlord_bottom_navigation_bar.dart';
import 'package:roomily/presentation/screens/add_room_screen_v2.dart';
import 'package:roomily/presentation/screens/landlord_tenant_management_screen.dart';
import 'package:roomily/presentation/widgets/landlord/upcoming_payments_widget.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_cubit.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:roomily/data/repositories/room_repository_impl.dart';
import 'package:roomily/presentation/widgets/landlord/view_room_requests_widget.dart';
import 'package:roomily/presentation/screens/landlord_campaign_screen.dart';
import 'package:roomily/presentation/screens/payment_screen.dart';
import 'package:roomily/data/blocs/payment/payment_cubit.dart';
import 'package:roomily/data/repositories/payment_repository.dart';
import 'package:roomily/data/repositories/payment_repository_impl.dart';
import 'package:roomily/data/blocs/wallet/wallet_cubit.dart';
import 'package:roomily/data/blocs/wallet/wallet_state.dart';
import 'package:roomily/data/repositories/wallet_repository.dart';
import 'package:roomily/data/models/withdraw_info_create.dart';

import '../../data/blocs/auth/auth_cubit.dart';
import '../../data/blocs/landlord/landlord_rooms_cubit.dart';
import '../../data/blocs/landlord/landlord_rooms_state.dart';
import '../../data/blocs/user/user_cubit.dart';
import '../../data/blocs/user/user_state.dart';
import '../../data/blocs/notification/notification_cubit.dart';
import '../../data/blocs/notification/notification_state.dart';

class LandlordDashboardScreen extends StatefulWidget {
  const LandlordDashboardScreen({Key? key}) : super(key: key);

  @override
  State<LandlordDashboardScreen> createState() => _LandlordDashboardScreenState();
}

class _LandlordDashboardScreenState extends State<LandlordDashboardScreen> with SingleTickerProviderStateMixin {
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  late final RentedRoomCubit _rentedRoomCubit;
  String? _userId;
  double _lastKnownBalance = 0; // Add this class variable to cache the balance
  
  // App color scheme
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  final Color backgroundColor = const Color(0xFFF8FAFF);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF1A2237);
  final Color textSecondaryColor = const Color(0xFF8798AD);
  final Color accentGreen = const Color(0xFF00C897);
  final Color accentOrange = const Color(0xFFFF9500);
  final Color accentRed = const Color(0xFFFF456C);
  final Color accentPurple = const Color(0xFF7F5BFF);

  @override
  void initState() {
    super.initState();
    _rentedRoomCubit = RentedRoomCubit(
      rentedRoomRepository: RentedRoomRepositoryImpl(),
      roomRepository: RoomRepositoryImpl(),
    );
    _loadLandlordRooms();
    // Load user information
    context.read<UserCubit>().getUserInfo();
  }
  
  @override
  void dispose() {
    _rentedRoomCubit.close();
    super.dispose();
  }

  Future<void> _loadLandlordRooms() async {
    try {
      // Thời gian chờ nhỏ để đảm bảo tất cả services đã được khởi tạo
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (!mounted) return;
      
      // Get current user ID from Auth state or secure storage
      final authCubit = context.read<AuthCubit>();
      final userCubit = context.read<LandlordRoomsCubit>();
      final userId = authCubit.state.userId;
      _userId = userId; // Lưu userId để sử dụng sau này
      
      if (userId != null && userId.isNotEmpty) {
        debugPrint('🏠 Loading rooms for landlord ID: $userId');
        // Sử dụng phương thức retry mới với 3 lần thử
        userCubit.retryGetLandlordRooms(userId, retries: 3);
        
        // Load rented rooms for upcoming payments
        _rentedRoomCubit.getRentedRoomsByLandlordId(userId);
      } else {
        // Fallback to secure storage if AuthCubit doesn't have the userId
        final secureStorage = GetIt.I<SecureStorageService>();
        final storageUserId = await secureStorage.getUserId();
        _userId = storageUserId; // Lưu userId để sử dụng sau này
        
        if (storageUserId != null && storageUserId.isNotEmpty && mounted) {
          debugPrint('🏠 Loading rooms for landlord ID from storage: $storageUserId');
          userCubit.retryGetLandlordRooms(storageUserId, retries: 3);
          
          // Load rented rooms for upcoming payments
          _rentedRoomCubit.getRentedRoomsByLandlordId(storageUserId);
        } else {
          debugPrint('⚠️ UserId không có sẵn, sẽ thử lại sau 1 giây');
          
          // Thử lại một lần nữa sau 1 giây
          await Future.delayed(const Duration(seconds: 1));
          _retryLoadingRooms();
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading landlord rooms: $e');
      // Thử lại sau 1 giây nếu có lỗi
      await Future.delayed(const Duration(seconds: 1));
      _retryLoadingRooms();
    }
  }
  
  // Phương thức thử lại tải dữ liệu
  Future<void> _retryLoadingRooms() async {
    try {
      final secureStorage = GetIt.I<SecureStorageService>();
      final userId = await secureStorage.getUserId();
      _userId = userId; // Lưu userId để sử dụng sau này
      
      if (userId != null && userId.isNotEmpty) {
        debugPrint('🔄 Retrying loading rooms for landlord ID: $userId');
        if (mounted) {
          context.read<LandlordRoomsCubit>().retryGetLandlordRooms(userId, retries: 3);
          
          // Load rented rooms for upcoming payments
          _rentedRoomCubit.getRentedRoomsByLandlordId(userId);
        }
      } else {
        debugPrint('❌ Unable to get landlord ID after retry, cannot load rooms');
        // Hiển thị thông báo lỗi nếu cần
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể tải dữ liệu. Vui lòng thử lại sau.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error in retry loading landlord rooms: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // Truyền widget tab trang chủ vào LandlordBottomNavigationBar
    return BlocProvider.value(
      value: _rentedRoomCubit,
      child: LandlordBottomNavigationBar(
        homeTabWidget: buildHomeTab(),
      ),
    );
  }

  // Hàm buildHomeTab được gọi khi hiển thị tab Home của LandlordBottomNavigationBar
  Widget buildHomeTab() {
    return Scaffold(
      backgroundColor: backgroundColor,
      body: CustomScrollView(
        slivers: [
          // _buildAppBar(),
          _buildDashboardStats(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Text(
                'Thao tác nhanh',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
            ),
          ),
          _buildQuickActions(),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap ViewRoomRequestsWidget
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: const ViewRoomRequestsWidget(maxRequests: 1  ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Wrap UpcomingPaymentsWidget
                  Container(
                    decoration: BoxDecoration(
                      color: cardColor,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: UpcomingPaymentsWidget(
                      userId: _userId,
                      maxPayments: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // _buildRecentReviews(),
        ],
      ),
    );
  }

  // SliverAppBar _buildAppBar() {
  //   return SliverAppBar(
  //     pinned: true,
  //     floating: true,
  //     expandedHeight: 10,
  //     elevation: 0,
  //     backgroundColor: Colors.transparent,
  //     systemOverlayStyle: SystemUiOverlayStyle.light,
  //     flexibleSpace: Container(
  //       decoration: BoxDecoration(
  //         gradient: LinearGradient(
  //           begin: Alignment.topLeft,
  //           end: Alignment.bottomRight,
  //           colors: [primaryColor, secondaryColor],
  //         ),
  //         boxShadow: [
  //           BoxShadow(
  //             color: primaryColor.withOpacity(0.3),
  //             blurRadius: 20,
  //             offset: const Offset(0, 4),
  //           ),
  //         ],
  //       ),
  //       child: const FlexibleSpaceBar(
  //         title: Text(
  //           'Quản lý chủ nhà',
  //           style: TextStyle(
  //             fontSize: 20,
  //             fontWeight: FontWeight.bold,
  //           ),
  //         ),
  //         centerTitle: false,
  //         titlePadding: EdgeInsets.only(left: 20),
  //       ),
  //     ),
  //     actions: [
  //       Stack(
  //         children: [
  //           Container(
  //             margin: const EdgeInsets.only(right: 8, top: 8),
  //             decoration: BoxDecoration(
  //               color: Colors.white.withOpacity(0.2),
  //               borderRadius: BorderRadius.circular(12),
  //             ),
  //             child: IconButton(
  //               icon: const Icon(Icons.notifications_outlined, color: Colors.white),
  //               onPressed: () {
  //                 // Điều hướng đến trang thông báo
  //                 Navigator.push(
  //                   context,
  //                   MaterialPageRoute(builder: (context) => const NotificationScreen()),
  //                 );
  //               },
  //             ),
  //           ),
  //           Positioned(
  //             right: 10,
  //             top: 10,
  //             child: Container(
  //               padding: const EdgeInsets.all(6),
  //               decoration: BoxDecoration(
  //                 color: accentRed,
  //                 shape: BoxShape.circle,
  //                 border: Border.all(color: Colors.white, width: 1.5),
  //               ),
  //               child: const Text(
  //                 '5',
  //                 style: TextStyle(
  //                   color: Colors.white,
  //                   fontSize: 10,
  //                   fontWeight: FontWeight.bold,
  //                 ),
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       Container(
  //         margin: const EdgeInsets.only(right: 16, top: 8),
  //         decoration: BoxDecoration(
  //           color: Colors.white.withOpacity(0.2),
  //           borderRadius: BorderRadius.circular(12),
  //         ),
  //         child: IconButton(
  //           icon: const Icon(Icons.search, color: Colors.white),
  //           onPressed: () {
  //             // Show search functionality
  //           },
  //         ),
  //       ),
  //     ],
  //   );
  // }

  SliverToBoxAdapter _buildDashboardStats() {
    return SliverToBoxAdapter(
      child: BlocBuilder<LandlordRoomsCubit, LandlordRoomsState>(
        builder: (context, state) {
          int totalRooms = 0;
          int rentedRooms = 0;
          int availableRooms = 0;

          if (state is LandlordRoomsLoaded) {
            final rooms = state.rooms;
            totalRooms = rooms.length;
            rentedRooms = rooms.where((room) => room.status == RoomStatus.RENTED).length;
            availableRooms = rooms.where((room) => room.status == RoomStatus.AVAILABLE).length;
          }

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(0, 60, 0, 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [primaryColor, secondaryColor],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              children: [
                // Add notification button at the top right
                Padding(
                  padding: const EdgeInsets.only(right: 16, bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const NotificationScreen()),
                          );
                        },
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.notifications_outlined,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                            Builder(
                              builder: (context) {
                                try {
                                  // Thử lấy NotificationService từ GetIt
                                  final notificationService = GetIt.I<NotificationService>();
                                  
                                  return BlocProvider.value(
                                    value: notificationService.notificationCubit,
                                    child: BlocBuilder<NotificationCubit, NotificationState>(
                                      builder: (context, state) {
                                        if (state.unreadCount > 0) {
                                          return Positioned(
                                            right: -5,
                                            top: -5,
                                            child: Container(
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: accentRed,
                                                shape: BoxShape.circle,
                                                border: Border.all(color: Colors.white, width: 1.5),
                                              ),
                                              constraints: const BoxConstraints(
                                                minWidth: 18,
                                                minHeight: 18,
                                              ),
                                              child: Center(
                                                child: Text(
                                                  state.unreadCount > 99 ? '99+' : '${state.unreadCount}',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ),
                                            ),
                                          );
                                        } else {
                                          return const SizedBox.shrink();
                                        }
                                      },
                                    ),
                                  );
                                } catch (e) {
                                  // Fallback khi NotificationService chưa được đăng ký hoặc khởi tạo
                                  debugPrint('Không thể lấy NotificationService: $e');
                                  return const SizedBox.shrink();
                                }
                              },
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Ví của bạn',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                // Display balance from UserCubit
                BlocBuilder<UserCubit, UserInfoState>(
                  builder: (context, state) {
                    if (state is UserInfoLoaded) {
                      _lastKnownBalance = state.user.balance; // Update the cached value
                    }
                    
                    return Column(
                      children: [
                        Text(
                          currencyFormatter.format(_lastKnownBalance),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Enhanced withdraw button
                        GestureDetector(
                          onTap: () => _showWithdrawOptionsDialog(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.white, Colors.white.withOpacity(0.9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: primaryColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.account_balance_wallet,
                                    color: primaryColor,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Rút tiền',
                                  style: TextStyle(
                                    color: primaryColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.arrow_forward_ios_rounded,
                                  color: primaryColor,
                                  size: 12,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Tháng ${DateTime.now().month}/${DateTime.now().year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildStatCard(
                        title: 'Phòng trọ',
                        value: totalRooms.toString(),
                        icon: Icons.home_outlined,
                        color1: const Color(0xFF845BFF),
                        color2: const Color(0xFF5363FF),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: 'Đã thuê',
                        value: rentedRooms.toString(),
                        icon: Icons.check_circle_outline,
                        color1: const Color(0xFF00C897),
                        color2: const Color(0xFF00A48C),
                      ),
                      const SizedBox(width: 12),
                      _buildStatCard(
                        title: 'Còn trống',
                        value: availableRooms.toString(),
                        icon: Icons.door_front_door_outlined,
                        color1: const Color(0xFFFF9500),
                        color2: const Color(0xFFFF7425),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color1,
    required Color color2,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color1, color2],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: textSecondaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildQuickActions() {
    return SliverToBoxAdapter(
      child: Container(
        height: 120,
        margin: const EdgeInsets.symmetric(horizontal: 15),
        child: Row(
          children: [
            _buildActionButton(
              label: 'Thêm phòng',
              icon: Icons.add_home,
              color1: const Color(0xFF7F5BFF),
              color2: const Color(0xFF6B3BFD),
              onTap: () {
                // Navigate to add room page
                Navigator.push(
                  context, 
                  MaterialPageRoute(builder: (context) => const AddRoomScreenV2()),
                ).then((value) {
                  if(value == true) {
                    if(!mounted) return;
                    _loadLandlordRooms();
                  }
                },);
              },
            ),
            _buildActionButton(
              label: 'Chiến dịch',
              icon: Icons.campaign,
              color1: primaryColor,
              color2: secondaryColor,
              onTap: () {
                // Navigate to campaign screen
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LandlordCampaignScreen()),
                ).then((value) async {
                  if(!mounted) return;
                  final userCubit = context.read<UserCubit>();
                  await userCubit.getUserInfo();
                },);
              },
            ),
            _buildActionButton(
              label: 'Quản lý thuê',
              icon: Icons.people_alt_outlined,
              color1: const Color(0xFFFF9500),
              color2: const Color(0xFFFF7425),
              onTap: () {
                // Navigate to tenant management
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LandlordTenantManagementScreen()),
                );
              },
            ),
            _buildActionButton(
              label: 'Nộp tiền',
              icon: Icons.payments_rounded,
              color1: const Color(0xFF00C897),
              color2: const Color(0xFF00A48C),
              onTap: () {
                // Navigate to payment screen for depositing to wallet
                Navigator.of(context).push(
                  MaterialPageRoute(
                    fullscreenDialog: true,
                    builder: (context) => BlocProvider(
                      create: (context) => PaymentCubit(
                        paymentRepository: PaymentRepositoryImpl(),
                      ),
                      child: const PaymentScreen(
                        isLandlordDashboard: true,
                        inAppWallet: true,
                      ),
                    ),
                  ),
                ).then((result) async {
                  // If payment was completed successfully, refresh user info
                  print('Payment result: $result');
                  if (result == true && context.mounted) {
                    final userCubit = context.read<UserCubit>();
                    await userCubit.getUserInfo();
                  }
                });
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color1,
    required Color color2,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color1, color2],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: color1.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: textPrimaryColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildRecentReviews() {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Đánh giá gần đây',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: textPrimaryColor,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.visibility_outlined, size: 14, color: primaryColor),
                      const SizedBox(width: 4),
                      Text(
                        'Xem tất cả',
                        style: TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  children: [
                    _buildReviewItem(
                      userName: 'Hoàng Minh Tuấn',
                      roomName: 'Phòng Tam Kỳ',
                      rating: 4,
                      comment: 'Phòng sạch sẽ, thoáng mát, chủ trọ thân thiện.',
                      time: '2 ngày trước',
                      avatarUrl: 'https://randomuser.me/api/portraits/men/55.jpg',
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Divider(),
                    ),
                    _buildReviewItem(
                      userName: 'Lê Thị Hồng',
                      roomName: 'Phòng Hòa Vang',
                      rating: 5,
                      comment: 'Vị trí tốt, gần siêu thị và trường học. Rất tiện lợi!',
                      time: '1 tuần trước',
                      avatarUrl: 'https://randomuser.me/api/portraits/women/22.jpg',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewItem({
    required String userName,
    required String roomName,
    required int rating,
    required String comment,
    required String time,
    required String avatarUrl,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 48,
                width: 48,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Image.network(
                    avatarUrl,
                    fit: BoxFit.cover,
                    width: 48,
                    height: 48,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textPrimaryColor,
                      ),
                    ),
                    Text(
                      roomName,
                      style: TextStyle(
                        color: textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFB323), Color(0xFFFA8E22)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            comment,
            style: TextStyle(
              fontSize: 14,
              color: textPrimaryColor.withOpacity(0.8),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: textSecondaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    time,
                    style: TextStyle(
                      color: textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // Show reply options
                },
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Phản hồi',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced method to show withdraw options dialog
  void _showWithdrawOptionsDialog(BuildContext context) {
    // Create WalletCubit instance if needed
    final walletCubit = WalletCubit(
      walletRepository: WalletRepositoryImpl(),
    );
    
    // Show dialog with loading state initially
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => BlocProvider.value(
        value: walletCubit,
        child: BlocConsumer<WalletCubit, WalletState>(
          listener: (context, state) {
            if (state is WithdrawInfoFailure) {
              // If failed to get withdraw info, show create withdraw form
              Navigator.of(dialogContext).pop();
              _showCreateWithdrawInfoDialog(context, walletCubit);
            } else if (state is WithdrawInfoSuccess) {
              // If withdraw info found, show withdraw money dialog
              Navigator.of(dialogContext).pop();
              _showWithdrawMoneyDialog(context, walletCubit, state.withdrawInfo);
            }
          },
          builder: (context, state) {
            if (state is WithdrawInfoLoading) {
              return Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 8,
                backgroundColor: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        height: 60,
                        width: 60,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                          strokeWidth: 3,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Đang tải thông tin rút tiền...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
            // Return a placeholder; the listener will handle navigation
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: const Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
    
    // Trigger loading withdraw info
    walletCubit.getWithdrawInfo();
  }

  // Enhanced dialog to create withdrawal information
  void _showCreateWithdrawInfoDialog(BuildContext context, WalletCubit walletCubit) {
    final bankNameController = TextEditingController();
    final accountNumberController = TextEditingController();
    final accountNameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: walletCubit,
        child: BlocConsumer<WalletCubit, WalletState>(
          listener: (context, state) {
            if (state is WithdrawInfoCreateSuccess) {
              // If creation successful, get the withdraw info again
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Thông tin tài khoản đã được lưu'),
                  backgroundColor: accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              Navigator.of(dialogContext).pop();
              // Load withdraw info again after creating
              walletCubit.getWithdrawInfo();
            } else if (state is WithdrawInfoCreateFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi: ${state.errorMessage}'),
                  backgroundColor: accentRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.account_balance,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Thêm tài khoản ngân hàng',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Vui lòng nhập thông tin tài khoản ngân hàng để rút tiền',
                      style: TextStyle(
                        fontSize: 14,
                        color: textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: formKey,
                      child: Column(
                        children: [
                          // Bank name field
                          TextFormField(
                            controller: bankNameController,
                            decoration: InputDecoration(
                              labelText: 'Tên ngân hàng',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              prefixIcon: Icon(Icons.account_balance, color: primaryColor),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập tên ngân hàng';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Account number field
                          TextFormField(
                            controller: accountNumberController,
                            decoration: InputDecoration(
                              labelText: 'Số tài khoản',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              prefixIcon: Icon(Icons.credit_card, color: primaryColor),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập số tài khoản';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Account name field
                          TextFormField(
                            controller: accountNameController,
                            decoration: InputDecoration(
                              labelText: 'Tên chủ tài khoản',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: Colors.grey.shade300),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor, width: 2),
                              ),
                              prefixIcon: Icon(Icons.person, color: primaryColor),
                              filled: true,
                              fillColor: Colors.grey.shade50,
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) {
                                return 'Vui lòng nhập tên chủ tài khoản';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: textSecondaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Hủy', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: state is WithdrawInfoCreateLoading
                            ? null
                            : () {
                              if (formKey.currentState!.validate()) {
                                final withdrawInfoCreate = WithdrawInfoCreate(
                                  bankName: bankNameController.text.trim(),
                                  accountNumber: accountNumberController.text.trim(),
                                  accountName: accountNameController.text.trim(),
                                );
                                walletCubit.createWithdrawInfo(withdrawInfoCreate);
                              }
                            },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: state is WithdrawInfoCreateLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Lưu', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // Enhanced dialog to withdraw money
  void _showWithdrawMoneyDialog(BuildContext context, WalletCubit walletCubit, withdrawInfo) {
    final amountController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    
    showDialog(
      context: context,
      builder: (dialogContext) => BlocProvider.value(
        value: walletCubit,
        child: BlocConsumer<WalletCubit, WalletState>(
          listener: (context, state) {
            if (state is WithdrawMoneySuccess) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Yêu cầu rút tiền đã được gửi'),
                  backgroundColor: accentGreen,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
              Navigator.of(dialogContext).pop();
              
              // Refresh user info to update balance
              if (context.mounted) {
                context.read<UserCubit>().getUserInfo();
              }
            } else if (state is WithdrawMoneyFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lỗi: ${state.errorMessage}'),
                  backgroundColor: accentRed,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
          },
          builder: (context, state) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 8,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.monetization_on,
                            color: primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(
                          'Rút tiền',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    // Bank account info card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Số dư khả dụng:',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: textSecondaryColor,
                                ),
                              ),
                              Text(
                                currencyFormatter.format(_lastKnownBalance),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: accentGreen,
                                ),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            children: [
                              Icon(Icons.account_balance, size: 18, color: textSecondaryColor),
                              const SizedBox(width: 8),
                              Text(
                                withdrawInfo.bankName,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.credit_card, size: 18, color: textSecondaryColor),
                              const SizedBox(width: 8),
                              Text(
                                withdrawInfo.accountNumber,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.person, size: 18, color: textSecondaryColor),
                              const SizedBox(width: 8),
                              Text(
                                withdrawInfo.accountName,
                                style: TextStyle(
                                  fontSize: 15,
                                  color: textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Form(
                      key: formKey,
                      child: TextFormField(
                        controller: amountController,
                        decoration: InputDecoration(
                          labelText: 'Số tiền muốn rút',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: primaryColor, width: 2),
                          ),
                          prefixIcon: Icon(Icons.money, color: primaryColor),
                          suffixText: 'VND',
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          hintText: 'Nhập số tiền cần rút',
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập số tiền';
                          }
                          
                          double? amount = double.tryParse(value);
                          if (amount == null) {
                            return 'Số tiền không hợp lệ';
                          }
                          
                          if (amount <= 0) {
                            return 'Số tiền phải lớn hơn 0';
                          }
                          
                          if (amount > _lastKnownBalance) {
                            return 'Số tiền vượt quá số dư hiện tại';
                          }
                          
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(dialogContext),
                          style: TextButton.styleFrom(
                            foregroundColor: textSecondaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          ),
                          child: const Text('Hủy', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: state is WithdrawMoneyLoading
                            ? null
                            : () {
                                if (formKey.currentState!.validate()) {
                                  double amount = double.parse(amountController.text);
                                  walletCubit.withdrawMoney(amount);
                                }
                              },
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: primaryColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: state is WithdrawMoneyLoading
                            ? SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text('Rút tiền', style: TextStyle(fontSize: 16)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}