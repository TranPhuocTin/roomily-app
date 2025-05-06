import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/room_marker_info.dart';
import 'package:roomily/core/utils/format_utils.dart';

import '../../../data/blocs/home/room_image_cubit.dart';
import '../../../data/blocs/home/room_image_state.dart';

class RoomInfoPanel extends StatefulWidget {
  final RoomMarkerInfo room;
  final VoidCallback onDirectionsPressed;
  final VoidCallback onDetailsPressed;

  const RoomInfoPanel({
    super.key,
    required this.room,
    required this.onDirectionsPressed,
    required this.onDetailsPressed,
  });

  @override
  State<RoomInfoPanel> createState() => _RoomInfoPanelState();
}

class _RoomInfoPanelState extends State<RoomInfoPanel> with SingleTickerProviderStateMixin {
  String? _currentRoomId;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _loadRoomImages();
    
    // Thêm animation để panel trượt lên
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );
    
    _animationController.forward();
  }

  @override
  void didUpdateWidget(RoomInfoPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Nếu room ID thay đổi, tải ảnh mới
    if (oldWidget.room.id != widget.room.id) {
      _loadRoomImages();
      // Reset animation
      _animationController.reset();
      _animationController.forward();
    }
  }

  void _loadRoomImages() {
    _currentRoomId = widget.room.id;
    // Tải ảnh cho phòng hiện tại
    context.read<RoomImageCubit>().fetchRoomImages(widget.room.id);
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Định dạng giá phòng trực tiếp với FormatUtils
    final String priceDisplay = FormatUtils.formatCurrency(widget.room.price);
    
    // Xác định màu dựa trên loại phòng
    Color themeColor;
    if (widget.room.type == 'VIP') {
      themeColor = const Color(0xFF7E57C2); // Màu tím
    } else if (widget.room.type == 'GẦN') {
      themeColor = const Color(0xFF26A69A); // Màu xanh lá
    } else {
      themeColor = Theme.of(context).primaryColor; // Màu chính của app
    }

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - _animation.value)),
          child: Opacity(
            opacity: _animation.value,
            child: Container(
              // margin: const EdgeInsets.symmetric(horizontal: 16),
              height: 195,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, -3),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status bar with type indicator
                  Container(
                    height: 4,
                    decoration: BoxDecoration(
                      color: themeColor,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Room image with enhanced shadow
                          SizedBox(
                            width: 100,
                            height: 100,
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: BlocBuilder<RoomImageCubit, RoomImageState>(
                                  builder: (context, state) {
                                    // Chỉ hiển thị ảnh nếu state là RoomImageLoaded và
                                    // phòng trong state khớp với phòng đang xem
                                    if (state is RoomImageLoaded && 
                                        state.images.isNotEmpty && 
                                        (state.roomId == widget.room.id || state.roomId == null)) {
                                      return Stack(
                                        children: [
                                          Image.network(
                                            state.images[0].url,
                                            width: 100,
                                            height: 100,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 100,
                                                height: 100,
                                                color: Colors.grey[200],
                                                child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                                              );
                                            },
                                          ),
                                          // Type badge
                                          if (widget.room.type == 'VIP')
                                            Positioned(
                                              top: 5,
                                              left: 5,
                                              child: Container(
                                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                                decoration: BoxDecoration(
                                                  color: themeColor.withOpacity(0.9),
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                                child: const Text(
                                                  'VIP',
                                                  style: TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                        ],
                                      );
                                    }
                                    return Container(
                                      width: 100,
                                      height: 100,
                                      color: Colors.grey[200],
                                      child: Icon(Icons.home_outlined, size: 40, color: Colors.grey[400]),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Room details with enhanced typography
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  widget.room.title ?? 'Phòng trọ',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    height: 1.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on_outlined, size: 14, color: Colors.grey[600]),
                                    const SizedBox(width: 4),
                                    Expanded(
                                      child: Text(
                                        widget.room.address ?? '',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 13),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                // Price with highlighted background
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: themeColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$priceDisplay/tháng',
                                    style: TextStyle(
                                      color: themeColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                // Room features with icons
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    if (widget.room.area != null) _buildFeatureChip(
                                      Icons.square_foot_outlined,
                                      FormatUtils.formatArea(widget.room.area!),
                                    ),
                                    if (widget.room.bedrooms != null) _buildFeatureChip(
                                      Icons.bedroom_parent_outlined,
                                      '${widget.room.bedrooms} PN',
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Action buttons in a container
                  Container(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.directions, size: 18),
                            label: const Text('Chỉ đường'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: themeColor.withOpacity(0.9),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: widget.onDirectionsPressed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            icon: const Icon(Icons.info_outline, size: 18),
                            label: const Text('Chi tiết'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: themeColor,
                              side: BorderSide(color: themeColor),
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: widget.onDetailsPressed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildFeatureChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 12, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }
}
