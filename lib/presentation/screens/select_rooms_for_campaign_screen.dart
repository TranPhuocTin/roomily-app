import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SelectRoomsForCampaignScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? preselectedRooms;
  final String? campaignId;

  const SelectRoomsForCampaignScreen({
    Key? key,
    this.preselectedRooms,
    this.campaignId,
  }) : super(key: key);

  @override
  State<SelectRoomsForCampaignScreen> createState() => _SelectRoomsForCampaignScreenState();
}

class _SelectRoomsForCampaignScreenState extends State<SelectRoomsForCampaignScreen> {
  // App color scheme
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
  final Color backgroundColor = const Color(0xFFF8FAFF);
  final Color cardColor = Colors.white;
  final Color textPrimaryColor = const Color(0xFF1A2237);
  final Color textSecondaryColor = const Color(0xFF8798AD);

  late List<Map<String, dynamic>> _rooms;
  bool _isLoading = true;
  
  // Mock data for rooms
  final List<Map<String, dynamic>> _mockRooms = [
    {
      "id": "room1",
      "name": "Phòng trọ Tam Kỳ",
      "price": 2500000,
      "address": "123 Tam Kỳ, Quang Nam",
      "isSelected": false,
      "image": "https://images.unsplash.com/photo-1522708323590-d24dbb6b0267",
    },
    {
      "id": "room2",
      "name": "Phòng trọ Hòa Vang",
      "price": 3000000,
      "address": "45 Hòa Vang, Đà Nẵng",
      "isSelected": false,
      "image": "https://images.unsplash.com/photo-1560448204-e02f11c3d0e2",
    },
    {
      "id": "room3",
      "name": "Phòng trọ Green Home",
      "price": 2800000,
      "address": "78 Nguyễn Văn Linh, Đà Nẵng",
      "isSelected": false,
      "image": "https://images.unsplash.com/photo-1493809842364-78817add7ffb",
    },
  ];

  @override
  void initState() {
    super.initState();
    
    // Initialize rooms list with mock data
    _rooms = List.from(_mockRooms);
    
    // Apply preselected rooms if available
    if (widget.preselectedRooms != null && widget.preselectedRooms!.isNotEmpty) {
      for (var preselectedRoom in widget.preselectedRooms!) {
        final index = _rooms.indexWhere((room) => room['id'] == preselectedRoom['id']);
        if (index != -1) {
          _rooms[index]['isSelected'] = true;
        }
      }
    }
    
    // Simulate loading data
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildGradientAppBar(),
      body: _isLoading 
          ? _buildLoadingState() 
          : _buildRoomsList(),
      bottomNavigationBar: _buildBottomBar(),
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
                  const Text(
                    'Chọn phòng để quảng cáo',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // Search icon button
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.search,
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

  Widget _buildLoadingState() {
    return Center(
      child: CircularProgressIndicator(
        color: primaryColor,
      ),
    );
  }

  Widget _buildRoomsList() {
    return Column(
      children: [
        // Information box
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF5F8FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDFE6F0)),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 20, color: primaryColor),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Chọn phòng bạn muốn quảng cáo. Phòng được chọn sẽ hiển thị ưu tiên trong kết quả tìm kiếm.',
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondaryColor,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Rooms list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _rooms.length,
            itemBuilder: (context, index) {
              return _buildRoomItem(_rooms[index], index);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRoomItem(Map<String, dynamic> room, int index) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: room['isSelected'] ? primaryColor : Colors.transparent,
          width: room['isSelected'] ? 2 : 0,
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() {
            _rooms[index]['isSelected'] = !_rooms[index]['isSelected'];
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  room['image'],
                  width: 70,
                  height: 70,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 70,
                      height: 70,
                      color: Colors.grey[200],
                      child: const Icon(Icons.image_not_supported),
                    );
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room['name'],
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: textPrimaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      room['address'],
                      style: TextStyle(
                        fontSize: 12,
                        color: textSecondaryColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      currencyFormatter.format(room['price']),
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: room['isSelected'] ? primaryColor : const Color(0xFFEFF3FA),
                  border: Border.all(
                    color: room['isSelected'] ? Colors.transparent : const Color(0xFFDFE6F0),
                  ),
                ),
                child: room['isSelected']
                    ? const Icon(Icons.check, color: Colors.white, size: 16)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    final selectedCount = _rooms.where((room) => room['isSelected']).length;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Phòng đã chọn',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '$selectedCount phòng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: textPrimaryColor,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: selectedCount > 0 ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                disabledBackgroundColor: Colors.grey[300],
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, size: 18),
                  const SizedBox(width: 8),
                  const Text(
                    'Xác nhận',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmSelection() {
    // Return selected rooms to previous screen
    final selectedRooms = _rooms.where((room) => room['isSelected']).toList();
    Navigator.pop(context, selectedRooms);
  }
} 