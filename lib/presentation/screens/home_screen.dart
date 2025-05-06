import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/config/app_colors.dart';
import 'package:roomily/core/services/user_location_service.dart';
import 'package:roomily/core/services/notification_service.dart';
import 'package:roomily/core/utils/room_type.dart' as api_room_type;
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/repositories/recommendation_repository.dart';
import 'package:roomily/data/repositories/favorite_repository.dart';
import 'package:roomily/presentation/screens/see_all_rooms_screen.dart';
import 'package:roomily/presentation/screens/notification_screen.dart';
import 'package:roomily/presentation/screens/budget_planner_results_screen.dart';
import 'package:roomily/presentation/screens/saved_rooms_screen.dart';
import 'package:roomily/presentation/widgets/home/banner_slider.dart';
import 'package:roomily/presentation/widgets/home/featured_button_section.dart';
import 'package:roomily/presentation/widgets/home/header_widget.dart';
import 'package:roomily/presentation/widgets/home/room_card.dart';
import 'package:roomily/presentation/widgets/common/featured_title.dart';
import 'package:roomily/core/utils/format_utils.dart';
import 'package:get_it/get_it.dart';

import '../../data/blocs/home/recommendation_cubit.dart';
import '../../data/blocs/home/room_with_images_cubit.dart';
import '../../data/blocs/room_filter/room_filter_cubit.dart';
import '../../data/blocs/home/favorite_cubit.dart';
import '../widgets/home/featured_room_section.dart';

class HomeScreen extends StatefulWidget {
  final Color color;

  const HomeScreen({super.key, required this.color});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late List<FeatureButtonData> _features;
  final List<String> _imageUrls = [
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTC52HaCsGrmoVIF2e4PfWrFH7WT5KvZuWE3w&s',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS9lEpIGEtJdmraeiiH-AAL3gnJODSeQWffmwpN32XwRwSoCAw0F3qJz75MjT4oLdJHIsg&usqp=CAU',
    'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTf0TikeQGkw5xHc9AEMiF3xlodNWkbGNIfcj_R_Q83nDVE8iDFRR_ygm72TX3Pg0eH1-U&usqp=CAU',
  ];
  
  // Cubit để lấy dữ liệu phòng được recommend
  late RecommendationCubit _recommendationCubit;
  
  // Service để lấy vị trí người dùng
  late UserLocationService _userLocationService;
  
  // Repository để lấy phòng và hình ảnh
  late RoomRepository _roomRepository;
  late RoomImageRepository _roomImageRepository;
  late RecommendationRepository _recommendationRepository;
  
  // Thêm biến để theo dõi trạng thái loading
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initFeatures();
    
    // Khởi tạo UserLocationService
    _userLocationService = GetIt.instance<UserLocationService>();
    
    // Khởi tạo Repository
    _roomRepository = GetIt.instance<RoomRepository>();
    _roomImageRepository = GetIt.instance<RoomImageRepository>();
    _recommendationRepository = GetIt.instance<RecommendationRepository>();
    
    // Khởi tạo RecommendationCubit
    _recommendationCubit = RecommendationCubit(
      recommendationRepository: _recommendationRepository,
      roomRepository: _roomRepository,
      roomImageRepository: _roomImageRepository,
    );
    
    // Tải danh sách phòng được gợi ý
    _loadRecommendedRooms();
  }
  
  @override
  void dispose() {
    // Đóng cubit khi widget bị hủy
    _recommendationCubit.close();
    super.dispose();
  }
  
  // Tải danh sách phòng được gợi ý từ API
  Future<void> _loadRecommendedRooms() async {
    // Số lượng phòng cần hiển thị cố định là 10
    const int roomCount = 10;
    
    // Tải danh sách phòng được gợi ý
    await _recommendationCubit.loadRecommendedRooms(topK: roomCount, pageSize: roomCount);
  }

  void _initFeatures() {
    _features = [
      FeatureButtonData(
        imagePath: 'assets/icons/budget_planner_icon.png',
        fallbackIcon: Icons.calculate,
        title: 'PHÂN TÍCH',
        subtitle: 'Tính Toán Chi Phí',
        color: Colors.lightGreen[300]!,
        iconColor: Colors.lightGreen[700]!,
        gradient: AppColors.shopFeatureButtonGradient,
      ),
      FeatureButtonData(
        imagePath: 'assets/icons/feature_delivery_icon.png',
        fallbackIcon: Icons.local_shipping,
        title: 'VẬN CHUYỂN',
        subtitle: 'Chuyển Trọ Giá Rẻ',
        color: Colors.blue[300]!,
        iconColor: Colors.blue[700]!,
        gradient: AppColors.deliveryFeatureButtonGradient,
      ),
      FeatureButtonData(
        imagePath: 'assets/icons/feature_find_partner_icon.png',
        fallbackIcon: Icons.handshake,
        title: 'YÊU THÍCH',
        subtitle: 'Phòng Yêu Thích',
        color: Colors.amber[300]!,
        iconColor: Colors.amber[700]!,
        gradient: AppColors.findPartnerFeatureButtonGradient,
      ),
    ];
  }

  void _handleFeatureTap(int index) {
    // Xử lý khi người dùng nhấn vào tính năng
    switch (index) {
      case 0:
        // Xử lý khi nhấn vào vận chuyển
        print('Đã nhấn vào Vận chuyển');
        Navigator.push(
            context,
            MaterialPageRoute(
                builder: (context) => const BudgetPlannerResultsScreen(
                  title: 'Phân Tích Ngân Sách',

                )
            )
        );
        // Navigator.push(context, MaterialPageRoute(builder: (context) => DeliveryScreen()));
        break;
      case 1:
        // Xử lý khi nhấn vào tìm bạn
        print('Đã nhấn vào Tìm bạn');
        // Navigator.push(context, MaterialPageRoute(builder: (context) => FindPartnerScreen()));
        break;
      case 2:
        // Xử lý khi nhấn vào YÊU THÍCH
        print('Đã nhấn vào Yêu thích');
        
        // Lấy FavoriteRepository từ GetIt
        final favoriteRepository = GetIt.instance<FavoriteRepository>();
        
        // Tạo một FavoriteCubit mới với repository
        final favoriteCubit = FavoriteCubit(favoriteRepository);
        
        // Đảm bảo cubit đã load dữ liệu phòng yêu thích
        favoriteCubit.getFavoriteRooms();
        
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SavedRoomsScreen(
              favoriteCubit: favoriteCubit,
            ),
          ),
        );
        break;
    }
  }

  void _handleBannerTap(int index) {
    // Xử lý khi người dùng nhấn vào banner
    print('Đã nhấn vào banner: $index');

    // Ví dụ: Mở trang chi tiết dự án hoặc URL
    switch (index) {
      case 0:
        print('Mở trang chi tiết dự án MEYPEARL HARMONY PHÚ QUỐC');
        // Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailScreen(id: 'meypearl-harmony')));
        break;
      case 1:
        print('Mở trang chi tiết khuyến mãi');
        // Navigator.push(context, MaterialPageRoute(builder: (context) => PromotionScreen()));
        break;
      case 2:
        print('Mở trang đặt lịch tham quan');
        // Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen()));
        break;
    }
  }
  
  // Xử lý khi người dùng nhấn vào "Xem thêm"
  void _handleSeeAllPressed() {
    print("Xem thêm được nhấn!");
    
    // Tạo filter ban đầu dựa trên filter hiện tại
    final initialFilter = RoomFilter(
      city: _userLocationService.getLocationFilterParams()['city'],
      // Sử dụng type null để lấy tất cả các loại phòng
      type: null,
      limit: 20, // Tăng limit lên để hiển thị nhiều phòng hơn
    );
    
    // Điều hướng đến trang xem thêm
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeeAllRoomsScreen(
          title: 'Tất cả phòng',
          roomType: null, // Truyền null để lấy tất cả các loại phòng
          initialFilter: initialFilter,
        ),
      ),
    );
  }

  // Hàm xử lý khi người dùng nhấn vào thẻ loại phòng
  void _handleCategoryCardTap(String type) {
    print('Đã nhấn vào loại phòng: $type');
    
    // Tạo filter ban đầu dựa trên filter hiện tại
    final initialFilter = RoomFilter(
      city: _userLocationService.getLocationFilterParams()['city'],
      // Sử dụng enum RoomType tương ứng
      type: type == 'PHÒNG TRỌ' ? api_room_type.RoomType.ROOM : 
            type == 'CHUNG CƯ' ? api_room_type.RoomType.APARTMENT : null,
      limit: 20, // Tăng limit lên để hiển thị nhiều phòng hơn
    );
    
    // Điều hướng đến trang xem thêm
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SeeAllRoomsScreen(
          title: 'Danh sách $type',
          roomType: type, // Truyền loại phòng
          initialFilter: initialFilter,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _recommendationCubit,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: RefreshIndicator(
          onRefresh: _loadRecommendedRooms,
          child: Stack(
            children: [
              // Gradient background
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Image.asset('assets/images/chat_background.jpg',
                    fit: BoxFit.cover),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    mainAxisSize: MainAxisSize.max,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(10.0),
                        child: HeaderWidget(
                          avatarUrl: 'https://via.placeholder.com/50',
                          searchHint: 'K160 Nguyễn Hoàng...',
                          onNotificationPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider.value(
                                  value: GetIt.I<NotificationService>().notificationCubit,
                                  child: const NotificationScreen(),
                                ),
                              ),
                            );
                          },
                          onSearchResultSelected: (result) {
                            print('Selected location: ${result.name} at ${result.latitude}, ${result.longitude}');
                            // Implement search result handling here
                          },
                          onSearchFieldTap: () {
                            // Navigate to SeeAllRoomScreen when search field is tapped
                            print('Search field tapped in HomeScreen');
                            
                            // Tạo filter ban đầu với city từ vị trí hiện tại
                            final initialFilter = RoomFilter(
                              city: _userLocationService.getLocationFilterParams()['city'],
                              type: null,
                              limit: 20,
                            );
                            
                            // Navigate to SeeAllRoomScreen
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BlocProvider(
                                  create: (context) => RoomFilterCubit(),
                                  child: SeeAllRoomsScreen(
                                    title: 'Tìm kiếm phòng',
                                    initialFilter: initialFilter,
                                  ),
                                ),
                              ),
                            );
                          },
                          isSearch: true,
                        ),
                      ),
                      // Banner Slider - No padding applied
                      BannerSlider(
                        bannerUrls: _imageUrls,
                        height: 150,
                        borderRadius: 20,
                        enableAutoScroll: true,
                        autoScrollDuration: const Duration(seconds: 4),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        indicatorActiveColor: Colors.blue,
                        indicatorInactiveColor: Colors.grey.shade400,
                        viewportFraction: 0.85,
                        onBannerTap: _handleBannerTap,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        child: Column(
                          children: [
                            FeatureButtonsSection(
                              features: _features,
                              onFeatureTap: _handleFeatureTap,
                            ),
                            const SizedBox(height: 20),
                            
                            // Title cho phòng được gợi ý
                            FeaturedTitle(
                              title: "GỢI Ý CHO BẠN",
                              onSeeAllPressed: _handleSeeAllPressed,
                              backgroundColor: Colors.blue,
                              gradientStart: Color(0xFF6C8DFF).withValues(alpha: 0.2),
                              gradientEnd: Color(0xFF6C8DFF),
                              shadowColor: Colors.black,
                              textColor: Colors.white,
                              imagePath: 'assets/icons/featured_section_header.png',
                            ),

                            // Recommended Rooms Section với shimmer loading
                            BlocConsumer<RecommendationCubit, RecommendationState>(
                              listener: (context, state) {
                                setState(() {
                                  _isLoading = state is RecommendationLoading || state is RecommendationInitial;
                                });
                              },
                              builder: (context, state) {
                                if (state is RecommendationError) {
                                  return Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          'Lỗi: ${state.message}',
                                          style: const TextStyle(fontSize: 16, color: Colors.red),
                                        ),
                                        ElevatedButton(
                                          onPressed: _loadRecommendedRooms,
                                          child: const Text('Thử lại'),
                                        ),
                                      ],
                                    ),
                                  );
                                }

                                // Kiểm tra trường hợp đã load xong nhưng không có phòng nào
                                if (state is RecommendationLoaded && state.roomsWithImages.isEmpty) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(vertical: 20),
                                    child: Column(
                                      children: [
                                        Image.asset(
                                          'assets/icons/search_filter_icon.png',
                                          width: 60,
                                          height: 60,
                                          color: Colors.grey,
                                        ),
                                        const SizedBox(height: 12),
                                        const Text(
                                          'Không tìm thấy phòng phù hợp',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Hiện chưa có phòng nào được gợi ý cho bạn (0/${state.total})',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        const SizedBox(height: 16),
                                      
                                      ],
                                    ),
                                  );
                                }

                                final List<RoomCardData> roomCardData;
                                if (state is RecommendationLoaded) {
                                  // Lấy danh sách phòng từ state
                                  final roomsWithImages = state.roomsWithImages;
                                  
                                  // Sử dụng method mới để chuyển đổi từ RoomWithImages sang RoomCardData
                                  // Method này sẽ tự động xử lý việc tạo PromotedRoomCardData cho các phòng được promoted
                                  roomCardData = _recommendationCubit.convertToRoomCardData(roomsWithImages);
                                } else {
                                  roomCardData = [];
                                }

                                return Column(
                                  children: [
                                    FeaturedRoomsSection(
                                      rooms: roomCardData,
                                      isLoading: _isLoading,
                                      shimmerCount: 4,
                                      padding: const EdgeInsets.only(top: 8, bottom: 16),
                                    ),
                                    
                                    // Thêm hiển thị thông tin phân trang nếu có dữ liệu
                                    if (state is RecommendationLoaded && state.roomsWithImages.isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(bottom: 16),
                                        child: Text(
                                          'Hiển thị ${roomCardData.length} phòng gợi ý',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
