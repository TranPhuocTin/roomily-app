import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:roomily/core/config/app_colors.dart';
import 'package:roomily/presentation/screens/landlord_room_management_screen.dart';
import 'package:roomily/presentation/screens/chat_room_screen.dart';
import 'package:roomily/presentation/screens/landlord_profile_screen.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class LandlordNavItem extends StatelessWidget {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final bool isSelected;
  final String label;
  final Color activeColor;
  final Color inactiveColor;
  final double activeIconSize;
  final double inactiveIconSize;

  const LandlordNavItem({
    Key? key,
    required this.activeIcon,
    required this.inactiveIcon,
    required this.isSelected,
    required this.label,
    required this.activeColor,
    this.inactiveColor = const Color(0xFF9E9E9E),
    this.activeIconSize = 25.0,
    this.inactiveIconSize = 20.0,
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
              size: activeIconSize,
              color: activeColor,
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
            size: inactiveIconSize,
            color: inactiveColor,
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

class LandlordBottomNavigationBar extends StatefulWidget {
  final Widget homeTabWidget;
  
  const LandlordBottomNavigationBar({
    Key? key, 
    required this.homeTabWidget,
  }) : super(key: key);

  @override
  State<LandlordBottomNavigationBar> createState() => _LandlordBottomNavigationBarState();
}

class _LandlordBottomNavigationBarState extends State<LandlordBottomNavigationBar> {
  int _page = 0;
  final GlobalKey<CurvedNavigationBarState> _bottomNavigationKey = GlobalKey();

  late final List<Widget> _screens;
  
  @override
  void initState() {
    super.initState();
    // Tạo các màn hình một lần và giữ chúng trong bộ nhớ
    _screens = [
      widget.homeTabWidget,
      LandlordRoomManagementScreen(),
      ChatRoomScreen(),
      LandlordProfileScreen(),
    ];
  }

  // Cập nhật bảng màu sắc phù hợp với theme mới
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  
  // Định nghĩa màu gradient cho từng tab
  final List<List<Color>> _tabGradients = [
    [const Color(0xFF0075FF), const Color(0xFF0095FF)], // Trang chủ
    [const Color(0xFF00B2FF), const Color(0xFF00D1FF)], // Phòng
    [const Color(0xFF0064DD), const Color(0xFF0091FF)], // Tin nhắn
    [const Color(0xFF0047B3), const Color(0xFF0075FF)], // Cá nhân
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1,
              offset: Offset(0, 2),
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
              _buildNavItem(1, "Phòng", "room"),
              _buildNavItem(2, "Tin Nhắn", "message"),
              _buildNavItem(3, "Cá Nhân", "profile"),
            ],
            onTap: (index) {
              setState(() {
                _page = index;
              });
            },
            letIndexChange: (index) => true,
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, String label, String iconName) {
    // Sử dụng Font Awesome Icons
    IconData getActiveIcon(String name) {
      switch (name) {
        case 'home':
          return FontAwesomeIcons.houseChimneyWindow; // Icon nhà hiện đại hơn
        case 'room':
          return FontAwesomeIcons.solidBuilding; // Icon tòa nhà chi tiết hơn

        case 'message':
          return FontAwesomeIcons.solidCommentDots; // Icon chat với dots thêm chi tiết
        case 'profile':
          return FontAwesomeIcons.solidUser; // Icon user đặc
        default:
          return FontAwesomeIcons.circleCheck;
      }
    }
    
    IconData getInactiveIcon(String name) {
      switch (name) {
        case 'home':
          return FontAwesomeIcons.house; // Phiên bản outline của nhà
        case 'room':
          return FontAwesomeIcons.buildingUser; // Phiên bản outline của tòa nhà
        case 'message':
          return FontAwesomeIcons.commentDots; // Phiên bản outline của chat
        case 'profile':
          return FontAwesomeIcons.user; // Phiên bản outline của user
        default:
          return FontAwesomeIcons.circle;
      }
    }
    
    // Tạo gradient color cho tab được chọn
    final activeGradient = _tabGradients[index];
    final activeColor = activeGradient[0]; // Sử dụng màu đầu tiên trong gradient
    
    return LandlordNavItem(
      activeIcon: getActiveIcon(iconName),
      inactiveIcon: getInactiveIcon(iconName),
      isSelected: _page == index,
      label: label,
      activeColor: activeColor,
      inactiveColor: const Color(0xFF9E9E9E), // Màu xám đậm cho icon không hoạt động
    );
  }
} 