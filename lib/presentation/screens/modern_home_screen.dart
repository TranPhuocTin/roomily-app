// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:roomily/blocs/home/room_with_images_cubit.dart';
// import 'package:roomily/blocs/room_filter/room_filter_cubit.dart';
// import 'package:roomily/core/config/app_colors.dart';
// import 'package:roomily/core/services/user_location_service.dart';
// import 'package:roomily/core/services/notification_service.dart';
// import 'package:roomily/core/utils/room_type.dart' as api_room_type;
// import 'package:roomily/data/models/models.dart';
// import 'package:roomily/data/repositories/room_image_repository.dart';
// import 'package:roomily/data/repositories/room_repository.dart';
// import 'package:roomily/presentation/screens/see_all_rooms_screen.dart';
// import 'package:roomily/presentation/screens/notification_screen.dart';
// import 'package:roomily/presentation/widgets/home_v2/modern_banner.dart';
// import 'package:roomily/presentation/widgets/home_v2/modern_category_card.dart';
// import 'package:roomily/presentation/widgets/home_v2/modern_feature_item.dart';
// import 'package:roomily/presentation/widgets/home_v2/modern_header.dart';
// import 'package:roomily/presentation/widgets/home_v2/modern_room_card.dart';
// import 'package:roomily/presentation/widgets/home_v2/modern_section_header.dart';
// import 'package:get_it/get_it.dart';
// import 'package:roomily/core/models/search_location_result.dart';

// class ModernHomeScreen extends StatefulWidget {
//   const ModernHomeScreen({super.key});

//   @override
//   State<ModernHomeScreen> createState() => _ModernHomeScreenState();
// }

// class _ModernHomeScreenState extends State<ModernHomeScreen> {
//   late List<FeatureItemData> _features;
//   final List<String> _imageUrls = [
//     'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTC52HaCsGrmoVIF2e4PfWrFH7WT5KvZuWE3w&s',
//     'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcS9lEpIGEtJdmraeiiH-AAL3gnJODSeQWffmwpN32XwRwSoCAw0F3qJz75MjT4oLdJHIsg&usqp=CAU',
//     'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTf0TikeQGkw5xHc9AEMiF3xlodNWkbGNIfcj_R_Q83nDVE8iDFRR_ygm72TX3Pg0eH1-U&usqp=CAU',
//   ];
  
//   // Cubit để lấy dữ liệu phòng và hình ảnh từ API
//   late RoomWithImagesCubit _roomWithImagesCubit;
  
//   // Service để lấy vị trí người dùng
//   late UserLocationService _userLocationService;
  
//   // Repository để lấy phòng và hình ảnh
//   late RoomRepository _roomRepository;
//   late RoomImageRepository _roomImageRepository;
  
//   // Thêm biến để theo dõi trạng thái loading
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _initFeatures();
    
//     // Khởi tạo UserLocationService
//     _userLocationService = GetIt.instance<UserLocationService>();
    
//     // Khởi tạo Repository
//     _roomRepository = GetIt.instance<RoomRepository>();
//     _roomImageRepository = GetIt.instance<RoomImageRepository>();
    
//     // Khởi tạo RoomWithImagesCubit
//     _roomWithImagesCubit = RoomWithImagesCubit(
//       roomRepository: _roomRepository,
//       roomImageRepository: _roomImageRepository,
//     );
    
//     // Tải danh sách phòng với filter
//     _loadFeaturedRooms();
//   }
  
//   @override
//   void dispose() {
//     // Đóng cubit khi widget bị hủy
//     _roomWithImagesCubit.close();
//     super.dispose();
//   }
  
//   // Tải danh sách phòng nổi bật từ API
//   Future<void> _loadFeaturedRooms() async {
//     // Lấy thành phố hiện tại từ UserLocationService
//     final locationParams = _userLocationService.getLocationFilterParams();
//     final city = locationParams['city'] ?? '';
    
//     // Tạo filter với limit=10 và thành phố hiện tại
//     final filter = RoomFilter(
//       city: city,
//       limit: 10,
//       isSubscribed: true,
//       type: api_room_type.RoomType.ROOM,
//     );
    
//     // Tải danh sách phòng và hình ảnh
//     await _roomWithImagesCubit.loadRoomsWithImages(filter);
    
//     // Kiểm tra kết quả sau khi load xong
//     final currentState = _roomWithImagesCubit.state;
//     if (currentState is RoomWithImagesLoaded && currentState.roomsWithImages.isEmpty && city.isNotEmpty) {
//       // Nếu không có kết quả và đã filter theo city, thử load lại với city rỗng
//       print('Không tìm thấy phòng ở $city, tìm kiếm phòng ở tất cả các thành phố');
//       final newFilter = RoomFilter(
//         city: '',
//         limit: 10,
//         type: api_room_type.RoomType.ROOM,
//       );
//       await _roomWithImagesCubit.loadRoomsWithImages(newFilter);
//     }
//   }

//   void _initFeatures() {
//     _features = [
//       FeatureItemData(
//         title: 'VẬN CHUYỂN',
//         subtitle: 'Chuyển Trọ Giá Rẻ',
//         imagePath: 'assets/icons/feature_delivery_icon.png',
//         fallbackIcon: Icons.local_shipping,
//         backgroundColor: Colors.blue,
//         iconColor: Colors.blue,
//       ),
//       FeatureItemData(
//         title: 'TÌM BẠN',
//         subtitle: 'Tìm Bạn Ở Chung',
//         imagePath: 'assets/icons/feature_find_partner_icon.png',
//         fallbackIcon: Icons.handshake,
//         backgroundColor: Colors.amber,
//         iconColor: Colors.amber,
//       ),
//       FeatureItemData(
//         title: 'TẠP HÓA',
//         subtitle: 'Dụng Cụ Đơn Giản',
//         imagePath: 'assets/icons/feature_shop_icon.png',
//         fallbackIcon: Icons.store,
//         backgroundColor: Colors.green,
//         iconColor: Colors.green,
//       ),
//     ];
//   }

//   void _handleFeatureTap(int index) {
//     // Xử lý khi người dùng nhấn vào tính năng
//     switch (index) {
//       case 0:
//         // Xử lý khi nhấn vào vận chuyển
//         print('Đã nhấn vào Vận chuyển');
//         // Navigator.push(context, MaterialPageRoute(builder: (context) => DeliveryScreen()));
//         break;
//       case 1:
//         // Xử lý khi nhấn vào tìm bạn
//         print('Đã nhấn vào Tìm bạn');
//         // Navigator.push(context, MaterialPageRoute(builder: (context) => FindPartnerScreen()));
//         break;
//       case 2:
//         // Xử lý khi nhấn vào tạp hóa
//         print('Đã nhấn vào Tạp hóa');
//         // Navigator.push(context, MaterialPageRoute(builder: (context) => ShopScreen()));
//         break;
//     }
//   }

//   void _handleBannerTap(int index) {
//     // Xử lý khi người dùng nhấn vào banner
//     print('Đã nhấn vào banner: $index');

//     // Ví dụ: Mở trang chi tiết dự án hoặc URL
//     switch (index) {
//       case 0:
//         print('Mở trang chi tiết dự án MEYPEARL HARMONY PHÚ QUỐC');
//         // Navigator.push(context, MaterialPageRoute(builder: (context) => ProjectDetailScreen(id: 'meypearl-harmony')));
//         break;
//       case 1:
//         print('Mở trang chi tiết khuyến mãi');
//         // Navigator.push(context, MaterialPageRoute(builder: (context) => PromotionScreen()));
//         break;
//       case 2:
//         print('Mở trang đặt lịch tham quan');
//         // Navigator.push(context, MaterialPageRoute(builder: (context) => BookingScreen()));
//         break;
//     }
//   }
  
//   // Chuyển đổi từ Room và RoomImage sang RoomCardData
//   List<RoomCardData> _convertToRoomCardData(List<RoomWithImages> roomsWithImages) {
//     return roomsWithImages.map((item) {
//       final room = item.room;
//       final images = item.images;
      
//       return RoomCardData(
//         imageUrl: images.isNotEmpty ? images.first.url : '',
//         name: room.title,
//         price: '${room.price.toStringAsFixed(0)} đ',
//         address: room.address,
//         squareMeters: room.squareMeters.toInt(),
//         beds: 1,
//         baths: 1,
//         kitchens: 0,
//         type: room.subscribed ? RoomType.vip : RoomType.normal,
//         id: room.id ?? '',
//       );
//     }).toList();
//   }
  
//   // Xử lý khi người dùng nhấn vào "Xem thêm"
//   void _handleSeeAllPressed() {
//     print("Xem thêm được nhấn!");
    
//     // Lấy thành phố hiện tại
//     final locationParams = _userLocationService.getLocationFilterParams();
//     final city = locationParams['city'] ?? '';
    
//     // Tạo filter ban đầu dựa trên filter hiện tại
//     final initialFilter = RoomFilter(
//       city: city,
//       // Sử dụng type null để lấy tất cả các loại phòng
//       type: null,
//       isSubscribed: true,
//       limit: 20, // Tăng limit lên để hiển thị nhiều phòng hơn
//     );
    
//     // Điều hướng đến trang xem thêm
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SeeAllRoomsScreen(
//           title: 'Phòng VIP',
//           roomType: null, // Truyền null để lấy tất cả các loại phòng
//           initialFilter: initialFilter,
//         ),
//       ),
//     );
//   }

//   // Hàm xử lý khi người dùng nhấn vào thẻ loại phòng
//   void _handleCategoryCardTap(String type) {
//     print('Đã nhấn vào loại phòng: $type');
    
//     // Lấy thành phố hiện tại
//     final locationParams = _userLocationService.getLocationFilterParams();
//     final city = locationParams['city'] ?? '';
    
//     // Tạo filter ban đầu dựa trên filter hiện tại
//     final initialFilter = RoomFilter(
//       city: city,
//       // Sử dụng enum RoomType tương ứng
//       type: type == 'PHÒNG TRỌ' ? api_room_type.RoomType.ROOM : 
//             type == 'CHUNG CƯ' ? api_room_type.RoomType.APARTMENT : null,
//       limit: 20, // Tăng limit lên để hiển thị nhiều phòng hơn
//     );
    
//     // Điều hướng đến trang xem thêm
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SeeAllRoomsScreen(
//           title: 'Danh sách $type',
//           roomType: type, // Truyền loại phòng
//           initialFilter: initialFilter,
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: _roomWithImagesCubit,
//       child: Scaffold(
//         backgroundColor: Colors.white,
//         body: RefreshIndicator(
//           onRefresh: _loadFeaturedRooms,
//           child: SafeArea(
//             child: SingleChildScrollView(
//               physics: const AlwaysScrollableScrollPhysics(),
//               child: Padding(
//                 padding: const EdgeInsets.symmetric(horizontal: 16),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     const SizedBox(height: 16),
//                     ModernHeader(
//                       avatarUrl: 'https://via.placeholder.com/50',
//                       searchHint: 'K160 Nguyễn Hoàng...',
//                       onNotificationPressed: () {
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => BlocProvider.value(
//                               value: GetIt.I<NotificationService>().notificationCubit,
//                               child: const NotificationScreen(),
//                             ),
//                           ),
//                         );
//                       },
//                       onSearchResultSelected: (result) {
//                         print('Selected location: ${result.name} at ${result.latitude}, ${result.longitude}');
//                         // Implement search result handling here
//                       },
//                       onSearchFieldTap: () {
//                         // Navigate to SeeAllRoomScreen when search field is tapped
//                         print('Search field tapped in HomeScreen');
                        
//                         // Lấy thành phố hiện tại
//                         final locationParams = _userLocationService.getLocationFilterParams();
//                         final city = locationParams['city'] ?? '';
                        
//                         // Tạo filter ban đầu với city từ vị trí hiện tại
//                         final initialFilter = RoomFilter(
//                           city: city,
//                           type: null,
//                           limit: 20,
//                         );
                        
//                         // Navigate to SeeAllRoomScreen
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => BlocProvider(
//                               create: (context) => RoomFilterCubit(),
//                               child: SeeAllRoomsScreen(
//                                 title: 'Tìm kiếm phòng',
//                                 initialFilter: initialFilter,
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                       isSearch: true,
//                     ),
//                     const SizedBox(height: 24),
//                     ModernBanner(
//                       bannerUrls: _imageUrls,
//                       height: 160,
//                       borderRadius: BorderRadius.circular(16),
//                       enableAutoScroll: true,
//                       indicatorActiveColor: Colors.blue,
//                       indicatorInactiveColor: Colors.grey.shade300,
//                       onBannerTap: _handleBannerTap,
//                     ),
//                     const SizedBox(height: 24),
//                     ModernSectionHeader(
//                       title: 'Dịch vụ',
//                       subtitle: 'Các dịch vụ hỗ trợ người thuê trọ',
//                       accentColor: Colors.blue,
//                     ),
//                     const SizedBox(height: 16),
//                     ModernFeatureSection(
//                       features: _features,
//                       onFeatureTap: _handleFeatureTap,
//                     ),
//                     const SizedBox(height: 24),
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         ModernCategoryCard(
//                           title: 'PHÒNG TRỌ',
//                           imagePath: 'assets/icons/phong_tro_icon.png',
//                           onTap: () => _handleCategoryCardTap('PHÒNG TRỌ'),
//                           backgroundColor: Colors.white,
//                           iconColor: Colors.blue,
//                         ),
//                         ModernCategoryCard(
//                           title: 'CHUNG CƯ',
//                           imagePath: 'assets/icons/chung_cu_icon.png',
//                           onTap: () => _handleCategoryCardTap('CHUNG CƯ'),
//                           backgroundColor: Colors.white,
//                           iconColor: Colors.green,
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 24),
//                     ModernSectionHeader(
//                       title: 'Phòng VIP',
//                       onSeeAllPressed: _handleSeeAllPressed,
//                       accentColor: Colors.red,
//                     ),
//                     const SizedBox(height: 8),
                    
//                     // Phần phòng nổi bật
//                     BlocConsumer<RoomWithImagesCubit, RoomWithImagesState>(
//                       listener: (context, state) {
//                         setState(() {
//                           _isLoading = state is RoomWithImagesLoading || state is RoomWithImagesInitial;
//                         });
//                       },
//                       builder: (context, state) {
//                         if (state is RoomWithImagesError) {
//                           return Center(
//                             child: Column(
//                               mainAxisAlignment: MainAxisAlignment.center,
//                               children: [
//                                 Text(
//                                   'Lỗi: ${state.message}',
//                                   style: const TextStyle(fontSize: 16, color: Colors.red),
//                                 ),
//                                 ElevatedButton(
//                                   onPressed: _loadFeaturedRooms,
//                                   child: const Text('Thử lại'),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }

//                         // Kiểm tra trường hợp đã load xong nhưng không có phòng VIP nào
//                         if (state is RoomWithImagesLoaded && state.roomsWithImages.isEmpty) {
//                           return Container(
//                             padding: const EdgeInsets.symmetric(vertical: 20),
//                             child: Column(
//                               children: [
//                                 Image.asset(
//                                   'assets/icons/search_filter_icon.png',
//                                   width: 60,
//                                   height: 60,
//                                   color: Colors.grey,
//                                 ),
//                                 const SizedBox(height: 12),
//                                 const Text(
//                                   'Không tìm thấy phòng VIP',
//                                   style: TextStyle(
//                                     fontSize: 16,
//                                     fontWeight: FontWeight.bold,
//                                     color: Colors.black87,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 const Text(
//                                   'Hiện chưa có phòng VIP nào trong khu vực này',
//                                   style: TextStyle(
//                                     fontSize: 14,
//                                     color: Colors.grey,
//                                   ),
//                                   textAlign: TextAlign.center,
//                                 ),
//                               ],
//                             ),
//                           );
//                         }

//                         final List<RoomCardData> roomCardData = state is RoomWithImagesLoaded
//                             ? _convertToRoomCardData(state.roomsWithImages)
//                             : [];

//                         return ModernFeaturedRoomSection(
//                           rooms: roomCardData,
//                           isLoading: _isLoading,
//                           shimmerCount: 3,
//                         );
//                       },
//                     ),
//                     const SizedBox(height: 24),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// } 