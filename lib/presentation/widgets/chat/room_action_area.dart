import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/chat_room_info.dart';
import 'package:roomily/data/models/rental_request.dart';
import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
import 'package:roomily/presentation/widgets/chat/expiration_timer_widget.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/presentation/screens/contract_viewer_screen.dart';
import 'package:roomily/data/repositories/find_partner_repository_impl.dart';
import 'package:roomily/data/models/find_partner_post_detail.dart';

import '../../../data/blocs/find_partner/find_partner_post_detail_cubit.dart';
import '../../../data/blocs/rented_room/rent_request_cubit.dart';
import '../../../data/blocs/rented_room/rent_request_state.dart';

class RoomActionArea extends StatefulWidget {
  final ChatRoomInfo chatRoomInfo;
  final bool isLandlord;
  final String? currentUserId;
  final VoidCallback onInfoRefreshed;

  const RoomActionArea({
    Key? key,
    required this.chatRoomInfo,
    required this.isLandlord,
    this.currentUserId,
    required this.onInfoRefreshed,
  }) : super(key: key);

  @override
  State<RoomActionArea> createState() => _RoomActionAreaState();
}

class _RoomActionAreaState extends State<RoomActionArea> {
  late final RentRequestCubit _rentRequestCubit;
  late final FindPartnerPostDetailCubit _findPartnerPostDetailCubit;
  bool _isPostOwner = false;
  bool _isCheckingPostOwner = false;
  
  @override
  void initState() {
    super.initState();
    _rentRequestCubit = RentRequestCubit(
      rentedRoomRepository: RentedRoomRepositoryImpl(dio: DioConfig.createDio()),
    );
    _findPartnerPostDetailCubit = FindPartnerPostDetailCubit(
      findPartnerRepository: FindPartnerRepositoryImpl(dio: DioConfig.createDio()),
    );

    // Kiểm tra nếu có findPartnerPostId thì lấy thông tin post
    if (widget.chatRoomInfo.findPartnerPostId != null && 
        widget.chatRoomInfo.findPartnerPostId!.isNotEmpty) {
      _checkPostOwnership();
    }
  }

  @override
  void dispose() {
    _rentRequestCubit.close();
    _findPartnerPostDetailCubit.close();
    super.dispose();
  }

  Future<void> _checkPostOwnership() async {
    setState(() {
      _isCheckingPostOwner = true;
    });
    
    try {
      await _findPartnerPostDetailCubit.getFindPartnerPostDetail(
        widget.chatRoomInfo.findPartnerPostId!
      );
    } catch (e) {
      print('Error checking post ownership: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingPostOwner = false;
        });
      }
    }
  }

  // Check if there's any rent request attached to this chat room
  bool get _hasRentRequest => widget.chatRoomInfo.rentalRequest != null;

  // Kiểm tra nếu người dùng là người gửi yêu cầu
  bool get _isRequestSender => widget.chatRoomInfo.rentalRequest?.requesterId == widget.currentUserId;

  // Kiểm tra nếu yêu cầu thuê đang ở trạng thái chờ xác nhận
  bool get _hasPendingRentRequest => 
      _hasRentRequest && widget.chatRoomInfo.rentalRequest?.status == RentalRequestStatus.PENDING;

  // Check if rent request has expired
  bool get _hasExpiredRequest {
    if (!_hasRentRequest) return false;
    final request = widget.chatRoomInfo.rentalRequest!;
    return DateTime.now().isAfter(request.expiresAt);
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _rentRequestCubit),
        BlocProvider.value(value: _findPartnerPostDetailCubit),
      ],
      child: MultiBlocListener(
        listeners: [
          BlocListener<FindPartnerPostDetailCubit, FindPartnerPostDetailState>(
            listener: (context, state) {
              if (state is FindPartnerPostDetailLoaded) {
                setState(() {
                  _isPostOwner = state.postDetail.posterUserId == widget.currentUserId;
                });
              }
            },
          ),
          BlocListener<RentRequestCubit, RentRequestState>(
            listener: (context, rentRequestState) {
              if (rentRequestState is RentRequestSuccess) {
                Future.delayed(const Duration(milliseconds: 300), () {
                  widget.onInfoRefreshed();
                });
              }
            },
          ),
        ],
        child: BlocBuilder<RentRequestCubit, RentRequestState>(
          builder: (context, rentRequestState) {
            return Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: _buildActionContent(context, rentRequestState),
            );
          },
        ),
      ),
    );
  }

  Widget _buildActionContent(BuildContext context, RentRequestState rentRequestState) {
    // Nếu đang kiểm tra ownership, hiển thị loading
    if (_isCheckingPostOwner) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(8.0),
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final RentalRequestStatus? requestStatus = widget.chatRoomInfo.rentalRequest?.status;
    final bool isRoomRented = widget.chatRoomInfo.chatRoomStatus.contains('RENTED') || 
                             widget.chatRoomInfo.chatRoomStatus.contains('COMPLETED');
    final bool isChatRoomCanceled = widget.chatRoomInfo.chatRoomStatus.contains('CANCELED');
    final bool isFindPartnerChat = widget.chatRoomInfo.findPartnerPostId != null && 
                                  widget.chatRoomInfo.findPartnerPostId!.isNotEmpty;
    final bool isArchived = widget.chatRoomInfo.chatRoomStatus.contains('ARCHIVED');

    // Kiểm tra nếu yêu cầu đã bị hủy
    if (_hasRentRequest && widget.chatRoomInfo.rentalRequest?.status == RentalRequestStatus.CANCELED) {
      return _buildRequestStatusMessage(RentalRequestStatus.CANCELED);
    }

    // 1. Chủ trọ với yêu cầu chờ xử lý - hiển thị nút Accept/Reject
    if (widget.isLandlord && requestStatus == RentalRequestStatus.PENDING) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Nút chấp nhận
          Expanded(
            child: _buildActionButton(
              icon: Icons.check_circle_outline,
              label: 'CHẤP NHẬN',
              color: const Color(0xFF4CAF50),
              onTap: () => _handleRentRequestResponse(true),
            ),
          ),
          // Phân cách
          const SizedBox(width: 8),
          // Nút từ chối
          Expanded(
            child: _buildActionButton(
              icon: Icons.cancel_outlined,
              label: 'TỪ CHỐI',
              color: Colors.red,
              onTap: () => _handleRentRequestResponse(false),
            ),
          ),
        ],
      );
    }

    // 2. Người thuê chưa gửi yêu cầu & phòng chưa được thuê & không bị hủy
    if (!widget.isLandlord && 
        requestStatus == null && 
        !isRoomRented && 
        !isChatRoomCanceled &&
        !isArchived
    ) {
      // Nếu là find partner chat, chỉ cho phép post owner gửi yêu cầu thuê
      if (isFindPartnerChat && !_isPostOwner) {
        return const Padding(
          padding: EdgeInsets.all(8.0),
          child: Text(
            'Chỉ người tạo nhóm mới có quyền gửi yêu cầu thuê phòng',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        );
      }

      return Column(
        children: [
          // Nút yêu cầu thuê phòng
          _buildRentRequestButton(
            context,
            label: rentRequestState is RentRequestLoading ? 'Đang gửi yêu cầu...' : 'Yêu cầu thuê phòng',
            isLoading: rentRequestState is RentRequestLoading,
          ),
          
          // Thêm nút xem hợp đồng
          if (widget.chatRoomInfo.roomId != null && widget.chatRoomInfo.roomId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildViewContractButton(context),
            ),
        ],
      );
    }
    
    // 3. Người thuê có yêu cầu đang chờ - hiển thị trạng thái và nút hủy
    if (!widget.isLandlord && _hasPendingRentRequest) {
      return Column(
        children: [
          // Trạng thái yêu cầu
          _buildPendingRequestStatus(context, rentRequestState is RentRequestLoading),
          
          // Thêm nút xem hợp đồng
          if (widget.chatRoomInfo.roomId != null && widget.chatRoomInfo.roomId!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: _buildViewContractButton(context),
            ),
        ],
      );
    }

    // 4. Hiển thị trạng thái yêu cầu đã được xử lý
    if (_hasRentRequest) {
      return _buildRequestStatusMessage(requestStatus!);
    }

    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(color: color),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
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
      ),
    );
  }

  Widget _buildRentRequestButton(BuildContext context, {
    required String label,
    required bool isLoading,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLoading ? null : () => _sendRentRequest(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                  ),
                )
              else
                Icon(Icons.send_rounded, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPendingRequestStatus(BuildContext context, bool isLoading) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Thông tin trạng thái
        Expanded(
          child: Row(
            children: [
              Icon(
                Icons.access_time_rounded,
                size: 14,
                color: Colors.amber[700],
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Row(
                  children: [
                    Text(
                      'Đang chờ xác nhận · ',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.amber[700],
                      ),
                    ),
                    if (widget.chatRoomInfo.rentalRequest?.expiresAt != null)
                      Flexible(
                        child: ExpirationTimerWidget(
                          expiresAt: widget.chatRoomInfo.rentalRequest!.expiresAt,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        
        // Nút hủy
        if (!_hasExpiredRequest && _isRequestSender)
          TextButton.icon(
            onPressed: isLoading 
              ? null 
              : () => _showCancelRequestConfirmation(context),
            icon: Icon(Icons.cancel_outlined, size: 12, color: Colors.red[400]),
            label: Text(
              'Hủy',
              style: TextStyle(
                fontSize: 11,
                color: Colors.red[400],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildRequestStatusMessage(RentalRequestStatus status) {
    String message;
    Color color;
    IconData icon;

    switch (status) {
      case RentalRequestStatus.APPROVED:
        message = 'Yêu cầu đã được chấp nhận';
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case RentalRequestStatus.REJECTED:
        message = 'Yêu cầu đã bị từ chối';
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      case RentalRequestStatus.CANCELED:
        message = 'Yêu cầu đã bị hủy';
        color = Colors.orange;
        icon = Icons.cancel_outlined;
        break;
      case RentalRequestStatus.PENDING:
        message = 'Đang chờ xác nhận';
        color = Colors.amber[700]!;
        icon = Icons.access_time_rounded;
        break;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          message,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  void _sendRentRequest(BuildContext context) {
    final String? roomId = widget.chatRoomInfo.roomId;
    final String chatRoomId = widget.chatRoomInfo.chatRoomId;
    
    if (roomId != null && roomId.isNotEmpty && chatRoomId.isNotEmpty) {
      _rentRequestCubit.createRentRequest(
        roomId: roomId,
        chatRoomId: chatRoomId,
        startDate: DateTime.now(),
        findPartnerPostId: widget.chatRoomInfo.findPartnerPostId,
      );
    }
  }

  void _handleRentRequestResponse(bool accept) async {
    if (!widget.isLandlord) return;

    final String chatRoomId = widget.chatRoomInfo.chatRoomId;
    if (chatRoomId.isEmpty) return;
    
    try {
      if (accept) {
        print('🔄 [RoomActionArea] Đang gửi yêu cầu chấp nhận cho chat room: $chatRoomId');
        await _rentRequestCubit.acceptRentRequest(chatRoomId);
        print('✅ [RoomActionArea] Yêu cầu chấp nhận thành công');
      } else {
        print('🔄 [RoomActionArea] Đang gửi yêu cầu từ chối cho chat room: $chatRoomId');
        await _rentRequestCubit.rejectRentRequest(chatRoomId);
        print('✅ [RoomActionArea] Yêu cầu từ chối thành công');
      }
    } catch (e) {
      print('❌ [RoomActionArea] Lỗi khi xử lý yêu cầu: $e');
      // Show error snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCancelRequestConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy yêu cầu'),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu thuê phòng?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _rentRequestCubit.cancelRentRequest(widget.chatRoomInfo.chatRoomId);
            },
            child: const Text('Có'),
          ),
        ],
      ),
    );
  }

  // Thêm hàm mới để xây dựng nút xem hợp đồng
  Widget _buildViewContractButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _navigateToContractViewer(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.description_outlined, size: 16, color: Colors.purple[700]),
              const SizedBox(width: 4),
              Text(
                'Xem hợp đồng',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.purple[700],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Hàm để điều hướng đến màn hình xem hợp đồng
  void _navigateToContractViewer(BuildContext context) {
    final String? roomId = widget.chatRoomInfo.roomId;
    if (roomId != null && roomId.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ContractViewerScreen(roomId: roomId),
        ),
      );
    }
  }
} 