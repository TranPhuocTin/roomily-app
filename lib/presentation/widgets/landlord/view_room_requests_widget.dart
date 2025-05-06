import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:roomily/data/blocs/rented_room/rental_requests_cubit.dart';
import 'package:roomily/data/blocs/rented_room/rental_requests_state.dart';
import 'package:roomily/data/blocs/chat_room/chat_room_cubit.dart';
import 'package:roomily/data/models/rental_request.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:roomily/data/repositories/chat_room_repository_impl.dart';
import 'package:roomily/data/blocs/auth/auth_cubit.dart';
import 'package:roomily/data/models/chat_room_info.dart';
import 'package:roomily/presentation/screens/chat_detail_screen_v2.dart';
import 'package:roomily/presentation/screens/view_all_room_requests_screen.dart';

class ViewRoomRequestsWidget extends StatefulWidget {
  final bool showViewAll;
  final int maxRequests; // Maximum number of requests to display

  const ViewRoomRequestsWidget({
    Key? key,
    this.showViewAll = true,
    this.maxRequests = 2, // Default to showing 2 requests
  }) : super(key: key);

  @override
  State<ViewRoomRequestsWidget> createState() => _ViewRoomRequestsWidgetState();
}

class _ViewRoomRequestsWidgetState extends State<ViewRoomRequestsWidget> {
  late final RentalRequestsCubit _rentalRequestsCubit;
  // Không khởi tạo ChatRoomCubit cục bộ nữa mà sẽ lấy từ context
  
  bool _hasAttemptedLoad = false;

  // App color scheme
  final Color primaryColor = const Color(0xFF0075FF);
  final Color secondaryColor = const Color(0xFF00D1FF);
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
    _rentalRequestsCubit = RentalRequestsCubit(
      rentedRoomRepository: RentedRoomRepositoryImpl(),
    );
    
    // Bỏ việc khởi tạo _chatRoomCubit ở đây

    // We'll attempt to load the rental requests after a short delay
    Future.delayed(Duration(milliseconds: 800), _loadRentalRequests);
  }

  @override
  void dispose() {
    _rentalRequestsCubit.close();
    // Bỏ việc đóng _chatRoomCubit ở đây vì không còn sở hữu nó
    super.dispose();
  }

  Future<void> _loadRentalRequests() async {
    // Set flag to indicate we've attempted to load
    _hasAttemptedLoad = true;
    
    debugPrint('🔄 Loading rental requests for landlord');
    await _rentalRequestsCubit.getLandlordRentalRequests();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _rentalRequestsCubit),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildSectionHeader(
              title: 'Yêu cầu xem phòng mới',
              actionText: 'Làm mới',
              onAction: _loadRentalRequests,
              showAction: widget.showViewAll,
            ),
            SizedBox(height: 16),
            BlocBuilder<RentalRequestsCubit, RentalRequestsState>(
              builder: (context, state) {
                // Handle case where we haven't tried to load yet
                if (!_hasAttemptedLoad) {
                  return _buildLoadingState();
                }
                
                // Handle loading state
                if (state is RentalRequestsLoading) {
                  return _buildLoadingState();
                } 
                
                // Handle loaded state with data
                else if (state is RentalRequestsLoaded) {
                  final rentalRequests = state.rentalRequests;
                  
                  // Filter to only show pending requests
                  final pendingRequests = rentalRequests
                      .where((request) => request.status == RentalRequestStatus.PENDING)
                      .toList();
                  
                  if (pendingRequests.isEmpty) {
                    return _buildEmptyState();
                  }
                  
                  // Limit the number of requests to display
                  final displayRequests = pendingRequests.take(widget.maxRequests).toList();
                  
                  return Column(
                    children: displayRequests
                        .map((request) => _buildRequestItem(context, request))
                        .toList(),
                  );
                } 
                
                // Handle error state
                else if (state is RentalRequestsError) {
                  return _buildErrorState(state.error);
                }
                
                // Initial state or unknown state
                return _buildLoadingState();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: _buildRoomRequestShimmer(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work_outlined,
                color: primaryColor,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Không có yêu cầu xem phòng mới',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Khi có yêu cầu xem phòng, bạn sẽ nhận được thông báo',
              style: TextStyle(
                fontSize: 13,
                color: textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(String errorMessage) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: accentRed.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.error_outline, color: accentRed, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải yêu cầu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: textPrimaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: 14,
                color: textSecondaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadRentalRequests,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text('Thử lại'),
            ),
          ],
        ),
      ),
    );
  }
  
  // Tạo shimmer effect cho item yêu cầu xem phòng
  Widget _buildRoomRequestShimmer() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 160,
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Tiêu đề
                        Container(
                          height: 18,
                          width: 180,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        SizedBox(height: 8),
                        // ID phòng
                        Container(
                          height: 14,
                          width: 140,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        SizedBox(height: 8),
                        // Thời gian
                        Container(
                          height: 12,
                          width: 120,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Trạng thái
                  Container(
                    width: 80,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              // Các nút
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Nút nhắn tin
                  Container(
                    width: 90,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Nút từ chối
                  Container(
                    width: 90,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Nút chấp nhận
                  Container(
                    width: 90,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRequestItem(BuildContext context, RentalRequest request) {
    // Format thời gian hết hạn
    final formatter = DateFormat('HH:mm, dd/MM/yyyy');
    final expiresTime = formatter.format(request.expiresAt);
    
    return Container(
      margin: EdgeInsets.only(bottom: 16),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [accentPurple, accentPurple.withOpacity(0.7)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.home_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Yêu cầu thuê phòng', // Should get user name if available
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: textPrimaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildStatusChip(request.status),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 42),
              child: Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 14,
                    color: textSecondaryColor,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Hết hạn: $expiresTime',
                    style: TextStyle(
                      color: textSecondaryColor,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            if (request.status == RentalRequestStatus.PENDING)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Button to chat with the requester
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: 'Nhắn tin',
                    color: primaryColor,
                    onPressed: () {
                      // Navigate to chat with chatRoomId
                      _navigateToChatDetail(context, request);
                    },
                  ),
                  // Button to reject request - use chatRoomId
                  _buildActionButton(
                    icon: Icons.close,
                    label: 'Từ chối',
                    color: accentRed,
                    onPressed: () {
                      _showConfirmationDialog(
                        context,
                        'Từ chối yêu cầu',
                        'Bạn có chắc chắn muốn từ chối yêu cầu này?',
                        () => _rejectRequest(context, request.chatRoomId ?? ''),
                      );
                    },
                  ),
                  // Button to accept request - use chatRoomId
                  _buildActionButton(
                    icon: Icons.check_circle_outline,
                    label: 'Chấp nhận',
                    color: accentGreen,
                    onPressed: () {
                      _showConfirmationDialog(
                        context,
                        'Chấp nhận yêu cầu',
                        'Bạn có chắc chắn muốn chấp nhận yêu cầu này?',
                        () => _acceptRequest(context, request.chatRoomId ?? ''),
                      );
                    },
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          foregroundColor: color,
          backgroundColor: color.withOpacity(0.1),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(0.2)),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required String title,
    required String actionText,
    required VoidCallback onAction,
    required bool showAction,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimaryColor,
          ),
        ),
        if (showAction)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F4FD),
              borderRadius: BorderRadius.circular(20),
            ),
            child: InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(20),
              child: Row(
                children: [
                  Icon(
                    Icons.refresh_outlined,
                    size: 14, 
                    color: primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    actionText,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // Điều hướng đến màn hình ChatDetailScreenV2
  void _navigateToChatDetail(BuildContext context, RentalRequest request) async {
    // Lấy currentUserId và userRole từ AuthCubit
    final authState = context.read<AuthCubit>().state;
    final currentUserId = authState.userId;
    final userRole = authState.isLandlord ? AuthCubit.ROLE_LANDLORD : AuthCubit.ROLE_TENANT;
    
    // Lấy ChatRoomCubit từ context thay vì sử dụng instance cục bộ
    final chatRoomCubit = context.read<ChatRoomCubit>();
    
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể xác định người dùng hiện tại'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Hiển thị dialog loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
        ),
      ),
    );

    try {
      // Sử dụng getChatRoomInfoWithoutNavigation thay vì getChatRoomInfo để tránh auto-push
      await chatRoomCubit.getChatRoomInfoWithoutNavigation(request.chatRoomId ?? '');
      
      // Đóng dialog loading
      if (context.mounted) Navigator.of(context).pop();
      
      // Kiểm tra state sau khi gọi API
      final state = chatRoomCubit.state;
      
      if (state is ChatRoomInfoCached) {
        // Lấy thông tin từ state đã cache
        final chatRoomInfo = state.chatRoomInfo;
        
        // Điều hướng trực tiếp đến ChatDetailScreenV2 với thông tin từ API
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChatDetailScreenV2(
                chatRoomInfo: chatRoomInfo,
                currentUserId: currentUserId,
                userRole: userRole,
              ),
            ),
          );
        }
      } else if (state is ChatRoomInfoError) {
        // Hiển thị thông báo lỗi
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể tải thông tin phòng chat: ${state.message}'),
              backgroundColor: accentRed,
            ),
          );
        }
      } else {
        // Trường hợp không xác định
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Không thể tải thông tin phòng chat. Vui lòng thử lại sau.'),
              backgroundColor: accentOrange,
            ),
          );
        }
      }
    } catch (e) {
      // Đóng dialog loading nếu có lỗi
      if (context.mounted) Navigator.of(context).pop();
      
      // Hiển thị thông báo lỗi
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã xảy ra lỗi: $e'),
            backgroundColor: accentRed,
          ),
        );
      }
    }
  }

  Widget _buildStatusChip(RentalRequestStatus status) {
    late Color color;
    late String label;
    
    switch (status) {
      case RentalRequestStatus.PENDING:
        color = accentOrange;
        label = 'Chờ duyệt';
        break;
      case RentalRequestStatus.APPROVED:
        color = accentGreen;
        label = 'Đã duyệt';
        break;
      case RentalRequestStatus.REJECTED:
        color = accentRed;
        label = 'Từ chối';
        break;
      case RentalRequestStatus.CANCELED:
        color = textSecondaryColor;
        label = 'Đã hủy';
        break;
    }
    
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Future<void> _showConfirmationDialog(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(
            title,
            style: TextStyle(
              color: textPrimaryColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text(
                  message,
                  style: TextStyle(color: textSecondaryColor),
                ),
              ],
            ),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'Hủy',
                style: TextStyle(color: textSecondaryColor),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: Text(
                'Xác nhận',
                style: TextStyle(
                  color: primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                onConfirm();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _acceptRequest(BuildContext context, String chatRoomId) async {
    await _rentalRequestsCubit.acceptRentRequest(chatRoomId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã chấp nhận yêu cầu thuê phòng'),
          backgroundColor: accentGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      // Reload requests after acceptance
      _loadRentalRequests();
    }
  }

  Future<void> _rejectRequest(BuildContext context, String chatRoomId) async {
    await _rentalRequestsCubit.rejectRentRequest(chatRoomId);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã từ chối yêu cầu thuê phòng'),
          backgroundColor: accentRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
      
      // Reload requests after rejection
      _loadRentalRequests();
    }
  }
} 