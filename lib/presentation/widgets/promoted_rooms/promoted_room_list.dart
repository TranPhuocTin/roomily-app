import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/data/models/promoted_room_model.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/blocs/promoted_rooms/promoted_rooms_cubit.dart';
import 'package:roomily/data/blocs/promoted_rooms/promoted_rooms_state.dart';
import 'package:roomily/data/blocs/campaigns/campaigns_cubit.dart';
import 'package:roomily/data/blocs/campaigns/campaigns_state.dart';

class PromotedRoomList extends StatefulWidget {
  final String campaignId;
  final String pricingModel;
  
  const PromotedRoomList({
    Key? key,
    required this.campaignId,
    this.pricingModel = 'CPC',
  }) : super(key: key);

  @override
  State<PromotedRoomList> createState() => _PromotedRoomListState();
}

class _PromotedRoomListState extends State<PromotedRoomList> {
  // Repository để lấy thông tin chi tiết phòng
  final RoomRepository _roomRepository = GetIt.instance<RoomRepository>();
  
  // Map lưu trữ thông tin chi tiết của phòng
  final Map<String, Room> _roomDetailsCache = {};
  
  @override
  void initState() {
    super.initState();
    context.read<PromotedRoomsCubit>().fetchPromotedRooms(widget.campaignId);
  }
  
  // Method to reload data from outside
  void reloadData() {
    if (mounted) {
      context.read<PromotedRoomsCubit>().fetchPromotedRooms(widget.campaignId);
    }
  }
  
  // Phương thức lấy thông tin chi tiết của phòng
  Future<Room?> _fetchRoomDetails(String roomId) async {
    // Kiểm tra xem đã có thông tin phòng trong cache chưa
    if (_roomDetailsCache.containsKey(roomId)) {
      return _roomDetailsCache[roomId];
    }
    
    // Nếu chưa có, gọi API để lấy thông tin
    final result = await _roomRepository.getRoom(roomId);
    
    return result.when(
      success: (room) {
        // Lưu vào cache để sử dụng sau này
        _roomDetailsCache[roomId] = room;
        return room;
      },
      failure: (_) => null,
    );
  }

  @override
  Widget build(BuildContext context) {
    // App color scheme
    final Color primaryColor = const Color(0xFF0075FF);
    final Color secondaryColor = const Color(0xFF00D1FF);
    final Color backgroundColor = const Color(0xFFF8FAFF);
    final Color cardColor = Colors.white;
    final Color textPrimaryColor = const Color(0xFF1A2237);
    final Color textSecondaryColor = const Color(0xFF8798AD);
    
    return BlocBuilder<PromotedRoomsCubit, PromotedRoomsState>(
      builder: (context, state) {
        if (state is PromotedRoomsLoading) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        } else if (state is PromotedRoomsError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.error_outline,
                  size: 60,
                  color: Colors.red[300],
                ),
                const SizedBox(height: 16),
                Text(
                  'Đã xảy ra lỗi',
                  style: TextStyle(
                    fontSize: 18,
                    color: textPrimaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    state.message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    context.read<PromotedRoomsCubit>().fetchPromotedRooms(widget.campaignId);
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Thử lại'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else if (state is PromotedRoomsLoaded) {
          final promotedRooms = state.promotedRooms;
          
          if (promotedRooms.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShaderMask(
                    shaderCallback: (bounds) {
                      return LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [primaryColor, secondaryColor],
                      ).createShader(bounds);
                    },
                    child: Icon(
                      Icons.hotel,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Chưa có phòng nào được quảng cáo',
                    style: TextStyle(
                      fontSize: 18,
                      color: textPrimaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bạn chưa thêm phòng nào vào chiến dịch này',
                    style: TextStyle(
                      fontSize: 14,
                      color: textSecondaryColor,
                    ),
                  ),
                ],
              ),
            );
          }
          
          return ListView.builder(
            itemCount: promotedRooms.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final room = promotedRooms[index];
              return _buildPromotedRoomCard(context, room);
            },
          );
        } else {
          return const SizedBox();
        }
      },
    );
  }

  Widget _buildPromotedRoomCard(BuildContext context, PromotedRoomModel promotedRoom) {
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    final Color primaryColor = const Color(0xFF0075FF);
    final Color textPrimaryColor = const Color(0xFF1A2237);
    final Color textSecondaryColor = const Color(0xFF8798AD);
    
    // Sử dụng FutureBuilder để lấy và hiển thị thông tin chi tiết phòng
    return FutureBuilder<Room?>(
      future: _fetchRoomDetails(promotedRoom.roomId),
      builder: (context, snapshot) {
        // Fallback values nếu không thể lấy thông tin phòng
        String roomTitle = 'Phòng #${promotedRoom.roomId.substring(0, promotedRoom.roomId.length > 6 ? 6 : promotedRoom.roomId.length)}';
        String roomAddress = 'ID: ${promotedRoom.roomId}';
        double roomPrice = 0;
        String roomType = '';
        
        // Nếu có dữ liệu, sử dụng thông tin chi tiết
        if (snapshot.hasData && snapshot.data != null) {
          final roomDetails = snapshot.data!;
          roomTitle = roomDetails.title;
          roomAddress = roomDetails.address;
          roomPrice = roomDetails.price;
          roomType = roomDetails.type;
        }
        
        // Sử dụng pricing model từ widget
        final String pricingModel = widget.pricingModel;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Icon(Icons.home, size: 32, color: Colors.grey[400]),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            roomTitle,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: textPrimaryColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            roomAddress,
                            style: TextStyle(
                              fontSize: 14,
                              color: textSecondaryColor,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (snapshot.hasData && snapshot.data != null)
                            Text(
                              currencyFormatter.format(roomPrice),
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          const SizedBox(height: 8),
                          // Chỉ hiển thị giá thầu nếu là CPC
                          if (pricingModel == 'CPC' && promotedRoom.bid != null)
                            GestureDetector(
                              onTap: () => _showUpdateBidDialog(context, promotedRoom),
                              child: Row(
                                children: [
                                  Text(
                                    'Giá thầu: ${currencyFormatter.format(promotedRoom.bid)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Icon(
                                    Icons.edit_outlined,
                                    size: 16,
                                    color: primaryColor,
                                  ),
                                ],
                              ),
                            )
                          else
                            Text(
                              'Hiển thị theo CPM',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: primaryColor,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // Add delete button
                    IconButton(
                      onPressed: () => _showDeleteConfirmation(context, promotedRoom),
                      icon: const Icon(Icons.delete_outline, color: Color(0xFFFF456C)),
                      tooltip: 'Xóa phòng khỏi chiến dịch',
                    ),
                  ],
                ),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildStatusChip(promotedRoom.status),
                    // Hiển thị loại phòng nếu có
                    if (snapshot.hasData && snapshot.data != null && roomType.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEEF2FA),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          roomType,
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor;
    String statusText;
    IconData statusIcon;
    
    switch (status.toUpperCase()) {
      case 'ACTIVE':
        chipColor = const Color(0xFF00C897);
        statusText = 'Đang hoạt động';
        statusIcon = Icons.check_circle;
        break;
      case 'PAUSED':
        chipColor = const Color(0xFFFF9500);
        statusText = 'Tạm dừng';
        statusIcon = Icons.pause_circle_outline;
        break;
      case 'PENDING':
        chipColor = const Color(0xFF0075FF);
        statusText = 'Đang xử lý';
        statusIcon = Icons.pending_outlined;
        break;
      case 'REJECTED':
        chipColor = const Color(0xFFFF456C);
        statusText = 'Bị từ chối';
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        chipColor = const Color(0xFF8798AD);
        statusText = 'Không xác định';
        statusIcon = Icons.help_outline;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statusIcon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            statusText,
            style: TextStyle(
              color: chipColor,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
  
  // Add deletion confirmation dialog
  void _showDeleteConfirmation(BuildContext context, PromotedRoomModel promotedRoom) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa phòng này khỏi chiến dịch quảng cáo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              // Gọi hàm xóa phòng
              context.read<PromotedRoomsCubit>().deletePromotedRoom(promotedRoom.id, widget.campaignId);
            },
            child: const Text(
              'Xóa',
              style: TextStyle(color: Color(0xFFFF456C)),
            ),
          ),
        ],
      ),
    );
  }
  
  // Add update bid dialog
  void _showUpdateBidDialog(BuildContext context, PromotedRoomModel promotedRoom) {
    final bidController = TextEditingController(text: promotedRoom.bid?.toString() ?? "0");
    final formKey = GlobalKey<FormState>();
    final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
    
    // Sử dụng pricing model từ widget
    final String pricingModel = widget.pricingModel;
    
    // Nếu là CPM thì không cho phép cập nhật giá thầu
    if (pricingModel == 'CPM') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể cập nhật giá thầu cho chiến dịch CPM'),
          backgroundColor: Color(0xFFFF456C),
        ),
      );
      return;
    }
    
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Cập nhật giá thầu'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: bidController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Giá thầu mới',
                  hintText: 'Nhập giá thầu mới',
                  prefixIcon: Icon(Icons.monetization_on_outlined),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá thầu';
                  }
                  final bid = double.tryParse(value);
                  if (bid == null || bid <= 0) {
                    return 'Giá thầu phải là số dương';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Giá thầu hiện tại: ${currencyFormatter.format(promotedRoom.bid ?? 0)}',
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF8798AD),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(dialogContext);
                final newBid = double.parse(bidController.text);
                // Cập nhật giá thầu
                context.read<PromotedRoomsCubit>().updatePromotedRoom(
                  promotedRoom.id,
                  newBid,
                  widget.campaignId,
                );
              }
            },
            child: const Text('Cập nhật'),
          ),
        ],
      ),
    );
  }
} 