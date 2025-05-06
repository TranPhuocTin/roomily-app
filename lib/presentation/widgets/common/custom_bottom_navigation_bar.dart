import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/config/app_colors.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/presentation/screens/home_screen.dart';
import 'package:roomily/presentation/screens/map_screen_v2.dart';
import 'package:roomily/presentation/screens/chat_room_screen.dart';
import 'package:roomily/presentation/screens/see_all_rooms_screen.dart';
import 'package:roomily/presentation/screens/user_profile_screen.dart';
import 'package:roomily/presentation/widgets/search/filter_bottom_sheet.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../data/blocs/home/favorite_cubit.dart';
import '../../../data/blocs/room_filter/room_filter_cubit.dart';

class CustomNavItem extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool isSelected;
  final String label;
  final Color activeColor;
  final double activeIconSize;
  final double inactiveIconSize;
  final Color inactiveColor;

  const CustomNavItem({
    Key? key,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.isSelected,
    required this.label,
    required this.activeColor,
    this.activeIconSize = 25.0,
    this.inactiveIconSize = 20.0,
    this.inactiveColor = const Color(0xFF9E9E9E),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isSelected) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
            ),
            child: FaIcon(
              activeIcon,
              color: activeColor,
              size: activeIconSize,
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
          ),
          child: FaIcon(
            inactiveIcon,
            color: inactiveColor,
            size: inactiveIconSize,
          ),
        ),
        SizedBox(height: 1),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: inactiveColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

class CustomBottomNavigationBar extends StatefulWidget {
  const CustomBottomNavigationBar({Key? key}) : super(key: key);

  @override
  State<CustomBottomNavigationBar> createState() => _CustomBottomNavigationBarState();
}

class _CustomBottomNavigationBarState extends State<CustomBottomNavigationBar> {
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();
  bool _isFirstTimeOnSearchTab = true;

  // Tạo tham chiếu đến SeeAllRoomsScreen
  late final SeeAllRoomsScreen _seeAllRoomsScreen;

  // Tạo các màn hình một lần và giữ chúng trong bộ nhớ
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    // Khởi tạo SeeAllRoomsScreen với tham số để không load dữ liệu ban đầu
    _seeAllRoomsScreen = SeeAllRoomsScreen(shouldLoadInitialData: false);

    // Khởi tạo các màn hình
    _screens = [
      HomeScreen(color: AppColors.bottomNavigationHome),
      // ModernHomeScreen(),
      // SearchScreen(),
      BlocProvider<RoomFilterCubit>(
        create: (context) => RoomFilterCubit(),
        child: _seeAllRoomsScreen,
      ),
      BlocProvider<RoomFilterCubit>(
        create: (context) => RoomFilterCubit(),
        child: MapScreenV2(),
      ),
      ChatRoomScreen(),
      // LandlordProfileScreen(),
      UserProfileScreen(),
    ];
  }

  final List<Color> _activeColors = [
    AppColors.bottomNavigationHome,
    AppColors.bottomNavigationHomeSearch,
    AppColors.bottomNavigationHomeMap,
    AppColors.bottomNavigationHomeChat,
    AppColors.bottomNavigationHomeProfile,
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: IndexedStack(
        index: _page,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        // margin: EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _activeColors[_page].withOpacity(0.15),
              blurRadius: 3,
              spreadRadius: 0,
              offset: Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          clipBehavior: Clip.none,
          borderRadius: BorderRadius.circular(24),
          child: CurvedNavigationBar(
            key: _bottomNavigationKey,
            backgroundColor: Colors.transparent,
            color: Colors.white,
            height: 56,
            animationDuration: Duration(milliseconds: 400),
            animationCurve: Curves.easeInOut,
            index: _page,
            items: [
              _buildNavItem(0, "Trang Chủ", "home"),
              _buildNavItem(1, "Tìm Kiếm", "search"),
              _buildNavItem(2, "Map", "map"),
              _buildNavItem(3, "Tin Nhắn", "message"),
              _buildNavItem(4, "Cá Nhân", "profile"),
            ],
            onTap: (index) {
              // Nếu tab mới là Profile và tab hiện tại không phải Profile
              final bool isNavigatingToProfile = index == 4 && _page != 4;

              // Kiểm tra xem người dùng đang chuyển đến tab SeeAllRoomsScreen lần đầu tiên không
              final bool isFirstTimeToSearchTab = index == 1 && _isFirstTimeOnSearchTab;

              setState(() {
                _page = index;
              });

              // Nếu chuyển sang tab Profile, cập nhật danh sách yêu thích
              if (isNavigatingToProfile) {
                // Sử dụng Future.microtask để đảm bảo UI cập nhật sau khi tab đã chuyển
                Future.microtask(() {
                  // Kiểm tra nếu có thể truy cập BLoC và cập nhật dữ liệu
                  try {
                    if (context.mounted) {
                      final favoriteCubit = BlocProvider.of<FavoriteCubit>(context, listen: false);
                      favoriteCubit.getFavoriteRooms();
                    }
                  } catch (e) {
                    print('Lỗi khi cập nhật yêu thích: $e');
                  }
                });
              }

              // Hiển thị BottomSheet khi chuyển đến tab SeeAllRoomsScreen lần đầu tiên
              // if (isFirstTimeToSearchTab) {
              //   _isFirstTimeOnSearchTab = false;
              //   // Đảm bảo UI được cập nhật trước khi hiển thị BottomSheet
              //   Future.microtask(() {
              //     if (context.mounted) {
              //       final emptyFilter = RoomFilter.defaultFilter();
              //
              //       // Lấy RoomFilterCubit hiện có từ context của màn hình SeeAllRooms
              //       final filterCubit = BlocProvider.of<RoomFilterCubit>(context, listen: false);
              //
              //       showModalBottomSheet(
              //         context: context,
              //         isScrollControlled: true,
              //         backgroundColor: Colors.transparent,
              //         builder: (bottomSheetContext) {
              //           // Sử dụng BlocProvider.value để chia sẻ cùng một instance
              //           return BlocProvider.value(
              //             value: filterCubit,
              //             child: FilterBottomSheet(
              //               initialFilter: emptyFilter,
              //               onApplyFilter: (filter) {
              //                 // Gọi trực tiếp đến filterCubit đã lấy từ màn hình chính
              //                 filterCubit.loadRooms(customFilter: filter);
              //
              //                 setState(() {
              //                   _page = 1;
              //                 });
              //               },
              //               onClose: () {
              //                 // Gọi trực tiếp đến filterCubit đã lấy từ màn hình chính
              //                 filterCubit.loadRooms(customFilter: emptyFilter);
              //
              //                 setState(() {
              //                   _page = 1;
              //                 });
              //               },
              //             ),
              //           );
              //         },
              //       );
              //     }
              //   });
              // }
            },
            letIndexChange: (index) => true,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String iconName) {
    // Sử dụng Font Awesome Icons thay vì Flutter Icons
    IconData getActiveIcon(String name) {
      switch (name) {
        case 'home':
          return FontAwesomeIcons.houseChimneyUser; // Icon nhà với chỉ dẫn người dùng
        case 'search':
          return FontAwesomeIcons.magnifyingGlass; // Icon tìm kiếm với location
        case 'map':
          return FontAwesomeIcons.solidMap; // Icon bản đồ chi tiết hơn
        case 'message':
          return FontAwesomeIcons.solidCommentDots; // Icon chat với dots
        case 'profile':
          return FontAwesomeIcons.solidUser; // Icon người dùng đặc
        default:
          return FontAwesomeIcons.circleCheck;
      }
    }

    IconData getInactiveIcon(String name) {
      switch (name) {
        case 'home':
          return FontAwesomeIcons.house; // Icon nhà đơn giản
        case 'search':
          return FontAwesomeIcons.magnifyingGlass; // Icon kính lúp đơn giản
        case 'map':
          return FontAwesomeIcons.map; // Icon bản đồ outline
        case 'message':
          return FontAwesomeIcons.commentDots; // Icon chat outline
        case 'profile':
          return FontAwesomeIcons.user; // Icon người dùng outline
        default:
          return FontAwesomeIcons.circle;
      }
    }

    return CustomNavItem(
      activeIcon: getActiveIcon(iconName),
      inactiveIcon: getInactiveIcon(iconName),
      isSelected: _page == index,
      label: label,
      activeColor: _activeColors[index],
    );
  }
}
