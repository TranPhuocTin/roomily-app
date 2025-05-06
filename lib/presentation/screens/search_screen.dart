// import 'package:cached_network_image/cached_network_image.dart';
// import 'package:flutter/material.dart';
// import 'package:roomily/core/config/text_styles.dart';
// import 'package:roomily/presentation/widgets/common/featured_title.dart';
// import 'package:roomily/presentation/widgets/common/room_amenity.dart';
// import 'package:roomily/presentation/widgets/home/header_widget.dart';
// import 'package:roomily/presentation/widgets/home/featured_room_section.dart';
// import 'package:roomily/presentation/widgets/home/room_card.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:get_it/get_it.dart';
// import 'package:roomily/core/services/user_location_service.dart';
// import 'package:roomily/blocs/room_filter/room_filter_cubit.dart';
// import 'package:roomily/data/models/models.dart';
// import 'package:roomily/blocs/home/room_with_images_cubit.dart';
// import 'package:roomily/data/repositories/room_repository.dart';
// import 'package:roomily/data/repositories/room_image_repository.dart';
// import 'package:roomily/core/utils/room_type.dart' as api_room_type;

// import '../widgets/search/featured_room_list.dart';
// import '../widgets/search/title_bar.dart';
// import '../screens/see_all_rooms_screen.dart';

// class SearchScreen extends StatefulWidget {
//   const SearchScreen({super.key});

//   @override
//   State<SearchScreen> createState() => _SearchScreenState();
// }

// class _SearchScreenState extends State<SearchScreen> {
//   late RoomWithImagesCubit _roomWithImagesCubit;
//   late UserLocationService _userLocationService;
//   late RoomRepository _roomRepository;
//   late RoomImageRepository _roomImageRepository;
//   bool _isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     _initServices();
//     _loadRoomTroRooms();
//   }

//   void _initServices() {
//     _userLocationService = GetIt.instance<UserLocationService>();
//     _roomRepository = GetIt.instance<RoomRepository>();
//     _roomImageRepository = GetIt.instance<RoomImageRepository>();
//     _roomWithImagesCubit = RoomWithImagesCubit(
//       roomRepository: _roomRepository,
//       roomImageRepository: _roomImageRepository,
//     );
//   }

//   Future<void> _loadRoomTroRooms() async {
//     final locationParams = _userLocationService.getLocationFilterParams();
//     final city = locationParams['city'] ?? '';
    
//     final filter = RoomFilter(
//       city: city,
//       isSubscribed: true,
//       limit: 10,
//       type: api_room_type.RoomType.ROOM,
//     );
    
//     await _roomWithImagesCubit.loadRoomsWithImages(filter);
    
//     final currentState = _roomWithImagesCubit.state;
//     if (currentState is RoomWithImagesLoaded && currentState.roomsWithImages.isEmpty && city.isNotEmpty) {
//       print('Không tìm thấy phòng ở $city, tìm kiếm phòng ở tất cả các thành phố');
//       final newFilter = RoomFilter(
//         city: '',
//         limit: 10,
//         type: api_room_type.RoomType.ROOM,
//         isSubscribed: true
//       );
//       await _roomWithImagesCubit.loadRoomsWithImages(newFilter);
//     }
//   }

//   @override
//   void dispose() {
//     _roomWithImagesCubit.close();
//     super.dispose();
//   }

//   late List<RoomCardData> _featuredRooms;

//   @override
//   Widget build(BuildContext context) {
//     // Giả lập data từ API - sẽ được thay thế sau
//     final List<Map<String, dynamic>> mockFeaturedRooms = [
//       {
//         'image':
//             'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTC52HaCsGrmoVIF2e4PfWrFH7WT5KvZuWE3w&s',
//         'title': 'CĂN HỘ 2 PHÒNG NGỦ',
//         'address': '09 Phạm Công Trứ',
//         'area': '100',
//         'capacity': '3',
//         'price': 'VNĐ 3.000.000/tháng',
//         'isVip': true,
//       },
//       {
//         'image':
//             'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTC52HaCsGrmoVIF2e4PfWrFH7WT5KvZuWE3w&s',
//         'title': 'CĂN HỘ 2 PHÒNG NGỦ',
//         'address': '09 Phạm Công Trứ',
//         'area': '100',
//         'capacity': '3',
//         'price': 'VNĐ 3.000.000/tháng',
//         'isVip': true,
//       },
//       {
//         'image':
//             'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcTC52HaCsGrmoVIF2e4PfWrFH7WT5KvZuWE3w&s',
//         'title': 'CĂN HỘ 2 PHÒNG NGỦ',
//         'address': '09 Phạm Công Trứ',
//         'area': '100',
//         'capacity': '3',
//         'price': 'VNĐ 3.000.000/tháng',
//         'isVip': true,
//       },
//     ];

//     return Scaffold(
//       body: Stack(
//         clipBehavior: Clip.none,
//         children: [
//           Positioned(
//             right: 0,
//             left: 0,
//             top: 0,
//             child: Image.asset(
//               'assets/images/search_background.jpg',
//               fit: BoxFit.cover,
//             ),
//           ),
//           SafeArea(
//             child: SingleChildScrollView(
//               child: Column(
//                 mainAxisSize: MainAxisSize.max,
//                 children: [
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
//                     child: HeaderWidget(
//                       avatarUrl: '',
//                       onNotificationPressed: () {},
//                       onSearchFieldTap: () {
//                         print('Search field tapped in SearchScreen');
                        
//                         Navigator.push(
//                           context,
//                           MaterialPageRoute(
//                             builder: (context) => BlocProvider(
//                               create: (context) => RoomFilterCubit(),
//                               child: SeeAllRoomsScreen(
//                                 title: 'Tìm kiếm phòng',
//                                 initialFilter: RoomFilter(),
//                               ),
//                             ),
//                           ),
//                         );
//                       },
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 15),
//                     child: TitleBar(
//                       imagePath: 'assets/icons/chung_cu_icon.png',
//                       title: 'CHUNG CƯ',
//                       isReversed: false,
//                     ),
//                   ),
//                   const SizedBox(height: 30),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 15),
//                     child: FeaturedTitle(
//                       title: 'NỔI BẬT',
//                       gradientStart: Color(0xFFF97878),
//                       gradientEnd: Color(0xFFFF6262),
//                       onSeeAllPressed: () {},
//                     ),
//                   ),
//                   const SizedBox(height: 15),
//                   FeaturedRoomsList(rooms: mockFeaturedRooms),
//                   const SizedBox(height: 15),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 15),
//                     child: TitleBar(
//                       imagePath: 'assets/icons/phong_tro_icon.png',
//                       title: 'PHÒNG TRỌ',
//                       isReversed: true,
//                       gradientStart: Color(0xFFAEC3A6).withOpacity(0.5),
//                       gradientEnd: Color(0xFF19DDDF),
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 15),
//                     child: FeaturedTitle(
//                       title: 'NỔI BẬT',
//                       shadowColor: Colors.green,
//                       onSeeAllPressed: _handleSeeAllPressed,
//                     ),
//                   ),
//                   const SizedBox(height: 5),
//                   Padding(
//                     padding: EdgeInsets.symmetric(horizontal: 15),
//                     child: BlocConsumer<RoomWithImagesCubit, RoomWithImagesState>(
//                       bloc: _roomWithImagesCubit,
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
//                                   onPressed: _loadRoomTroRooms,
//                                   child: const Text('Thử lại'),
//                                 ),
//                               ],
//                             ),
//                           );
//                         }

//                         final List<RoomCardData> roomCardData = state is RoomWithImagesLoaded
//                             ? _convertToRoomCardData(state.roomsWithImages)
//                             : [];

//                         return FeaturedRoomsSection(
//                           rooms: roomCardData,
//                           isLoading: _isLoading,
//                           shimmerCount: 3,
//                         );
//                       },
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

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
//         type: RoomType.vip,
//         id: room.id,
//       );
//     }).toList();
//   }

//   void _handleSeeAllPressed() {
//     final initialFilter = RoomFilter(
//       city: _userLocationService.getLocationFilterParams()['city'],
//       type: api_room_type.RoomType.ROOM,
//       isSubscribed: true,
//       limit: 20,
//     );
    
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => SeeAllRoomsScreen(
//           title: 'Phòng trọ',
//           roomType: 'PHÒNG TRỌ',
//           initialFilter: initialFilter,
//         ),
//       ),
//     );
//   }
// }
