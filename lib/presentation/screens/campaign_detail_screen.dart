import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

class CampaignDetailScreen extends StatefulWidget {
  final String campaignId;
  final String campaignName;

  const CampaignDetailScreen({
    Key? key,
    required this.campaignId,
    required this.campaignName,
  }) : super(key: key);

  @override
  State<CampaignDetailScreen> createState() => _CampaignDetailScreenState();
}

class _CampaignDetailScreenState extends State<CampaignDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  bool _isLoading = true;
  
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

  // Mock data for promoted rooms
  final List<Map<String, dynamic>> _mockPromotedRooms = [
    {
      "id": "promo1",
      "status": "ACTIVE",
      "bid": 25000,
      "adCampaignId": "camp1",
      "roomId": "room1",
      "room": {
        "id": "room1",
        "title": "Phòng trọ đẹp view sông Hàn",
        "description": "Phòng trọ mới xây, view đẹp, gần trung tâm thành phố. Có đầy đủ tiện nghi: điều hòa, nóng lạnh, wifi, giường, tủ, bàn làm việc...",
        "address": "123 Nguyễn Văn Linh, Hải Châu, Đà Nẵng",
        "status": "AVAILABLE",
        "price": 3500000,
        "latitude": 16.047079,
        "longitude": 108.206230,
        "city": "Đà Nẵng",
        "district": "Hải Châu",
        "ward": "Nam Dương",
        "electricPrice": 3500,
        "waterPrice": 15000,
        "type": "STUDIO",
        "nearbyAmenities": "Gần chợ, siêu thị, trường học, bệnh viện",
        "maxPeople": 2,
        "landlordId": "landlord1",
        "deposit": "2 tháng",
        "tags": [
          {
            "id": "tag1",
            "name": "air_conditioner",
            "category": "IN_ROOM_FEATURE",
            "displayName": "Điều hòa"
          },
          {
            "id": "tag2",
            "name": "water_heater",
            "category": "IN_ROOM_FEATURE",
            "displayName": "Nóng lạnh"
          },
          {
            "id": "tag3",
            "name": "wifi",
            "category": "IN_ROOM_FEATURE",
            "displayName": "Wifi"
          }
        ],
        "squareMeters": 25,
        "createdAt": "2024-04-15T08:03:51.650Z",
        "updatedAt": "2024-04-15T08:03:51.650Z",
        "subscribed": true
      }
    },
    {
      "id": "promo2",
      "status": "ACTIVE",
      "bid": 30000,
      "adCampaignId": "camp1",
      "roomId": "room2",
      "room": {
        "id": "room2",
        "title": "Phòng trọ cao cấp gần biển",
        "description": "Phòng trọ cao cấp, view biển, gần bãi biển Mỹ Khê. Có đầy đủ tiện nghi cao cấp: điều hòa, nóng lạnh, wifi, giường, tủ, bàn làm việc, tủ lạnh, máy giặt...",
        "address": "456 Võ Nguyên Giáp, Sơn Trà, Đà Nẵng",
        "status": "AVAILABLE",
        "price": 5000000,
        "latitude": 16.047079,
        "longitude": 108.206230,
        "city": "Đà Nẵng",
        "district": "Sơn Trà",
        "ward": "Mỹ An",
        "electricPrice": 3500,
        "waterPrice": 15000,
        "type": "STUDIO",
        "nearbyAmenities": "Gần biển, trung tâm thương mại, nhà hàng, quán cafe",
        "maxPeople": 2,
        "landlordId": "landlord1",
        "deposit": "2 tháng",
        "tags": [
          {
            "id": "tag1",
            "name": "air_conditioner",
            "category": "IN_ROOM_FEATURE",
            "displayName": "Điều hòa"
          },
          {
            "id": "tag2",
            "name": "water_heater",
            "category": "IN_ROOM_FEATURE",
            "displayName": "Nóng lạnh"
          },
          {
            "id": "tag3",
            "name": "wifi",
            "category": "IN_ROOM_FEATURE",
            "displayName": "Wifi"
          },
          {
            "id": "tag4",
            "name": "refrigerator",
            "category": "IN_ROOM_FEATURE",
            "displayName": "Tủ lạnh"
          },
          {
            "id": "tag5",
            "name": "washing_machine",
            "category": "IN_ROOM_FEATURE",
            "displayName": "Máy giặt"
          }
        ],
        "squareMeters": 30,
        "createdAt": "2024-04-15T08:03:51.650Z",
        "updatedAt": "2024-04-15T08:03:51.650Z",
        "subscribed": true
      }
    }
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Simulate loading data
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildGradientAppBar(),
      body: _isLoading
          ? _buildLoadingState()
          : Column(
              children: [
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPromotedRoomsList(),
                      _buildPerformanceTab(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildGradientAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const BackButton(color: Colors.white),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      widget.campaignName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.more_vert,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [primaryColor, secondaryColor],
          ),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        labelColor: Colors.white,
        unselectedLabelColor: textSecondaryColor,
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Phòng đang quảng cáo'),
          Tab(text: 'Hiệu suất'),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 3,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey[300]!,
          highlightColor: Colors.grey[100]!,
          child: Container(
            height: 200,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPromotedRoomsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mockPromotedRooms.length,
      itemBuilder: (context, index) {
        final promotedRoom = _mockPromotedRooms[index];
        final room = promotedRoom['room'] as Map<String, dynamic>;
        
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room image
              Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [primaryColor.withOpacity(0.7), secondaryColor.withOpacity(0.7)],
                  ),
                ),
                child: Stack(
                  children: [
                    // Placeholder for room image
                    Center(
                      child: Icon(
                        Icons.home_outlined,
                        size: 60,
                        color: Colors.white.withOpacity(0.5),
                      ),
                    ),
                    // Bid amount
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white.withOpacity(0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.attach_money,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              currencyFormatter.format(promotedRoom['bid']),
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Room title and price
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            room['title'],
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          currencyFormatter.format(room['price']),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Location
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 16,
                          color: textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${room['district']}, ${room['city']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Room features
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: (room['tags'] as List)
                          .map<Widget>((tag) => Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: primaryColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: primaryColor.withOpacity(0.2),
                                  ),
                                ),
                                child: Text(
                                  tag['displayName'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: primaryColor,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                    // Action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildActionButton(
                          icon: Icons.edit_outlined,
                          label: 'Chỉnh sửa',
                          color: primaryColor,
                          onPressed: () {
                            // Edit room promotion
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.pause_circle_outline,
                          label: 'Tạm dừng',
                          color: accentOrange,
                          onPressed: () {
                            // Pause promotion
                          },
                        ),
                        _buildActionButton(
                          icon: Icons.remove_circle_outline,
                          label: 'Xóa',
                          color: accentRed,
                          onPressed: () {
                            // Remove from campaign
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPerformanceTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPerformanceCard(
            title: 'Tổng quan',
            icon: Icons.analytics_outlined,
            metrics: [
              {'label': 'Hiển thị', 'value': '2,450', 'icon': Icons.visibility_outlined},
              {'label': 'Nhấp chuột', 'value': '178', 'icon': Icons.touch_app_outlined},
              {'label': 'Tỷ lệ nhấp', 'value': '7.2%', 'icon': Icons.timeline_outlined},
            ],
          ),
          const SizedBox(height: 16),
          _buildPerformanceCard(
            title: 'Chi phí',
            icon: Icons.attach_money_outlined,
            metrics: [
              {'label': 'Tổng chi', 'value': '450,000đ', 'icon': Icons.payments_outlined},
              {'label': 'CPC', 'value': '2,528đ', 'icon': Icons.trending_up_outlined},
              {'label': 'CPM', 'value': '183,673đ', 'icon': Icons.speed_outlined},
            ],
          ),
          const SizedBox(height: 16),
          _buildPerformanceCard(
            title: 'Chuyển đổi',
            icon: Icons.swap_horiz_outlined,
            metrics: [
              {'label': 'Chuyển đổi', 'value': '3', 'icon': Icons.check_circle_outline},
              {'label': 'Tỷ lệ chuyển đổi', 'value': '1.7%', 'icon': Icons.percent_outlined},
              {'label': 'Chi phí/chuyển đổi', 'value': '150,000đ', 'icon': Icons.monetization_on_outlined},
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceCard({
    required String title,
    required IconData icon,
    required List<Map<String, dynamic>> metrics,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: primaryColor, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: metrics.map((metric) => _buildMetricItem(
              icon: metric['icon'],
              value: metric['value'],
              label: metric['label'],
            )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricItem({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: primaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: primaryColor),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: textSecondaryColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
} 