import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/chat_room_info.dart';
import 'package:roomily/data/models/find_partner_post.dart';
import 'package:roomily/data/models/rental_request.dart';
import 'package:roomily/data/repositories/find_partner_repository_impl.dart';
import 'package:roomily/core/config/dio_config.dart';

import '../../../data/blocs/find_partner/find_partner_cubit.dart';
import '../../../data/blocs/find_partner/find_partner_state.dart';

class FindPartnerActionArea extends StatefulWidget {
  final ChatRoomInfo chatRoomInfo;
  final FindPartnerPost? findPartnerPost;
  final bool isPostOwner;
  final String? currentUserId;
  final VoidCallback onInfoRefreshed;

  const FindPartnerActionArea({
    Key? key,
    required this.chatRoomInfo,
    this.findPartnerPost,
    required this.isPostOwner,
    this.currentUserId,
    required this.onInfoRefreshed,
  }) : super(key: key);

  @override
  State<FindPartnerActionArea> createState() => _FindPartnerActionAreaState();
}

class _FindPartnerActionAreaState extends State<FindPartnerActionArea> {
  late final FindPartnerCubit _findPartnerCubit;
  bool _isUserInFindPartnerPost = false;
  bool _isCheckingUserStatus = true;
  
  @override
  void initState() {
    super.initState();
    _findPartnerCubit = FindPartnerCubit(
      FindPartnerRepositoryImpl(dio: DioConfig.createDio()),
    );
    
    // Kiểm tra nếu người dùng đã là thành viên của find partner post
    if (widget.chatRoomInfo.roomId != null && 
        widget.chatRoomInfo.roomId!.isNotEmpty) {
      _isCheckingUserStatus = true;
      print('📌 DEBUG: Calling checkUserInFindPartnerPost with roomId: ${widget.chatRoomInfo.roomId}');
      print('📌 DEBUG: Current userId: ${widget.currentUserId}');
      print('📌 DEBUG: ChatRoomInfo: ${widget.chatRoomInfo.toString()}');
      _findPartnerCubit.checkUserInFindPartnerPost(widget.chatRoomInfo.roomId!);
    } else {
      _isCheckingUserStatus = false;
      print('⚠️ DEBUG: Cannot check user in find partner post because roomId is null or empty');
      print('⚠️ DEBUG: ChatRoomInfo: ${widget.chatRoomInfo.toString()}');
    }
  }

  @override
  void dispose() {
    _findPartnerCubit.close();
    super.dispose();
  }

  // Kiểm tra nếu có request được gắn với chat room hiện tại
  bool get _hasRequest => widget.chatRoomInfo.rentalRequest != null;

  // Kiểm tra nếu request đang ở trạng thái chờ
  bool get _hasPendingRequest => 
      _hasRequest && widget.chatRoomInfo.rentalRequest?.status == RentalRequestStatus.PENDING;
      
  // Kiểm tra nếu tồn tại find partner post và id
  bool get _hasFindPartnerPostId => 
      widget.chatRoomInfo.findPartnerPostId != null && 
      widget.chatRoomInfo.findPartnerPostId!.isNotEmpty;

  bool get _hasCompleted => widget.chatRoomInfo.chatRoomStatus.contains('COMPLETED');

  @override
  Widget build(BuildContext context) {
    // Thêm debug log
    print('isPostOwner: ${widget.isPostOwner}');
    print('hasPendingRequest: $_hasPendingRequest');
    print('hasRequest: $_hasRequest');
    print('rentalRequest: ${widget.chatRoomInfo.rentalRequest}');
    print('rentalRequest status: ${widget.chatRoomInfo.rentalRequest?.status}');
    print('isUserInFindPartnerPost: $_isUserInFindPartnerPost');

    return BlocProvider(
      create: (context) => _findPartnerCubit,
      child: BlocConsumer<FindPartnerCubit, FindPartnerState>(
        listener: (context, state) {
          // Thêm log cho tất cả các state
          print('🔹 DEBUG: Current FindPartnerState: ${state.runtimeType}');
          
          if (state is FindPartnerRequestSent || 
              state is FindPartnerRequestAccepted || 
              state is FindPartnerRequestRejected ||
              state is FindPartnerRequestCanceled) {
            // Hiển thị thông báo thành công
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_getSuccessMessage(state)),
                backgroundColor: Colors.green,
              ),
            );
          } else if (state is FindPartnerError) {
            // Hiển thị lỗi nếu có
            print('❌ DEBUG: FindPartnerError: ${state.message}');
            setState(() {
              _isCheckingUserStatus = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Lỗi: ${state.message}'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is FindPartnerUserCheckResult) {
            // Cập nhật trạng thái người dùng trong find partner post
            print('🟢 DEBUG: FindPartnerUserCheckResult: ${state.isUserInPost}');
            setState(() {
              _isUserInFindPartnerPost = state.isUserInPost;
              _isCheckingUserStatus = false;
            });
            print('🚀 Updated isUserInFindPartnerPost: $_isUserInFindPartnerPost');
          } else if (state is FindPartnerChecking) {
            print('🔄 DEBUG: Checking if user is in find partner post...');
            setState(() {
              _isCheckingUserStatus = true;
            });
          } else if (state is FindPartnerLoaded) {
            print('📋 DEBUG: Find partner posts loaded: ${state.posts.length}');
            for (var post in state.posts) {
              print('📋 DEBUG: Post ID: ${post.findPartnerPostId}, Room ID: ${post.roomId}');
              print('📋 DEBUG: Post participants: ${post.participants.length}');
              if (widget.currentUserId != null) {
                final isInPost = post.participants.any((p) => p.userId == widget.currentUserId);
                print('📋 DEBUG: Current user in this post: $isInPost');
              }
            }
          }
        },
        builder: (context, state) {
          final bool isLoading = state is FindPartnerRequestSending || 
                                state is FindPartnerRequestAccepting ||
                                state is FindPartnerRequestRejecting ||
                                state is FindPartnerRequestCanceling ||
                                state is FindPartnerChecking;
          
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: _buildActionContent(context, state, isLoading),
          );
        },
      ),
    );
  }

  Widget _buildActionContent(BuildContext context, FindPartnerState state, bool isLoading) {
    // Lấy trạng thái từ chatRoomInfo
    final RentalRequestStatus? requestStatus = widget.chatRoomInfo.rentalRequest?.status;
    
    // Log tất cả các biến điều kiện
    print('🔍 DEBUG: _buildActionContent conditions:');
    print('🔍 DEBUG: isPostOwner: ${widget.isPostOwner}');
    print('🔍 DEBUG: hasRequest: $_hasRequest');
    print('🔍 DEBUG: hasPendingRequest: $_hasPendingRequest');
    print('🔍 DEBUG: hasFindPartnerPostId: $_hasFindPartnerPostId');
    print('🔍 DEBUG: isUserInFindPartnerPost: $_isUserInFindPartnerPost');
    print('🔍 DEBUG: isCheckingUserStatus: $_isCheckingUserStatus');
    print('🔍 DEBUG: requestStatus: $requestStatus');
    print('🔍 DEBUG: currentUserId: ${widget.currentUserId}');
    
    // Kiểm tra nếu người dùng hiện tại có quyền chấp nhận/từ chối
    bool canAcceptReject = widget.currentUserId != null && 
                           widget.chatRoomInfo.rentalRequest?.recipientId == widget.currentUserId;
    
    // Kiểm tra nếu người dùng hiện tại là người gửi yêu cầu
    bool isRequester = widget.currentUserId != null && 
                       widget.chatRoomInfo.rentalRequest?.requesterId == widget.currentUserId;
    
    // Hiển thị loading khi đang kiểm tra trạng thái của user trong find partner post
    if (_isCheckingUserStatus && state is FindPartnerChecking) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[400]!),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Đang kiểm tra...',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.blue[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    // 1. Hiển thị nút Accept/Reject cho người có quyền chấp nhận và yêu cầu đang ở trạng thái PENDING
    if (canAcceptReject && requestStatus == RentalRequestStatus.PENDING) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          // Nút chấp nhận
          Expanded(
            child: _buildActionButton(
              icon: Icons.check_circle_outline,
              label: 'CHẤP NHẬN',
              color: const Color(0xFF4CAF50),
              onTap: () => _acceptRequest(widget.chatRoomInfo.chatRoomId),
              isLoading: isLoading && state is FindPartnerRequestAccepting,
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
              onTap: () => _rejectRequest(widget.chatRoomInfo.chatRoomId),
              isLoading: isLoading && state is FindPartnerRequestRejecting,
            ),
          ),
        ],
      );
    }
    
    // 2. Hiển thị trạng thái "đang chờ phản hồi" cho người gửi yêu cầu
    if (isRequester && requestStatus == RentalRequestStatus.PENDING) {
      return _buildPendingRequestStatus();
    }
    
    // 3. Người xem chưa gửi yêu cầu và có find partner post ID và KHÔNG phải là chủ post
    // VÀ chưa là thành viên của find partner post VÀ không đang check status
    if (!widget.isPostOwner && 
        !_hasRequest && 
        _hasFindPartnerPostId &&
        !_isUserInFindPartnerPost &&
        !_isCheckingUserStatus &&
        !_hasCompleted) {
      print('🔄 DEBUG isPostOwner:  ${widget.isPostOwner}');
      print('🔄 DEBUG hasRequest:  $_hasRequest');
      print('🔄 DEBUG hasFindPartnerPostId:  $_hasFindPartnerPostId');
      print('🔄 DEBUG isUserInFindPartnerPost:  $_isUserInFindPartnerPost');
      print('🔄 DEBUG isCheckingUserStatus:  $_isCheckingUserStatus');
      print('🔄 DEBUG hasCompleted:  $_hasCompleted');
      return _buildSendRequestButton(context, isLoading);
    }
    
    // 4. Hiển thị trạng thái yêu cầu đã được xử lý (đã chấp nhận/từ chối)
    if (_hasRequest && requestStatus != RentalRequestStatus.PENDING) {
      return _buildRequestStatusMessage(requestStatus!);
    }

    // 5. Người xem là chủ post - hiển thị thông báo
    if (widget.isPostOwner && _hasFindPartnerPostId) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 14,
              color: Colors.blue[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bạn là người tạo bài đăng tìm bạn ở ghép này',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue[700],
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // 6. Người dùng đã là thành viên của find partner post
    if (_isUserInFindPartnerPost && _hasFindPartnerPostId) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
        child: Row(
          children: [
            Icon(
              Icons.group,
              size: 14,
              color: Colors.green[700],
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Bạn đã là thành viên của nhóm tìm bạn ở ghép này',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.green[700],
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Mặc định
    return const SizedBox.shrink();
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isLoading,
  }) {
    return ElevatedButton.icon(
      onPressed: isLoading ? null : onTap,
      icon: isLoading 
          ? SizedBox(
              width: 16, 
              height: 16, 
              child: CircularProgressIndicator(
                strokeWidth: 2, 
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : Icon(icon, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      ),
    );
  }

  Widget _buildSendRequestButton(BuildContext context, bool isLoading) {
    return _buildActionButton(
      icon: Icons.group_add,
      label: isLoading ? 'Đang gửi yêu cầu...' : 'Tham gia nhóm',
      color: Colors.blue,
      onTap: () => _sendRequest(
        findPartnerPostId: widget.chatRoomInfo.findPartnerPostId!,
        chatRoomId: widget.chatRoomInfo.chatRoomId,
      ),
      isLoading: isLoading && context.read<FindPartnerCubit>().state is FindPartnerRequestSending,
    );
  }

  Widget _buildPendingRequestStatus() {
    return Column(
      children: [
        Row(
          children: [
            Icon(
              Icons.access_time_rounded,
              size: 14,
              color: Colors.amber[700],
            ),
            const SizedBox(width: 8),
            Text(
              'Đang chờ chấp nhận',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.amber[700],
              ),
            ),
            const Spacer(),
            // Thêm nút hủy yêu cầu
            TextButton.icon(
              onPressed: () => _showCancelRequestConfirmation(context),
              icon: Icon(Icons.cancel_outlined, size: 14, color: Colors.red[400]),
              label: Text(
                'Hủy yêu cầu',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.red[400],
                  fontWeight: FontWeight.w500,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCancelRequestConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận hủy yêu cầu'),
        content: const Text('Bạn có chắc chắn muốn hủy yêu cầu tham gia nhóm tìm bạn ở ghép?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Không'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelRequest(widget.chatRoomInfo.chatRoomId);
            },
            child: const Text('Có'),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestStatusMessage(RentalRequestStatus status) {
    String message;
    Color color;
    IconData icon;

    switch (status) {
      case RentalRequestStatus.APPROVED:
        message = 'Bạn đã tham gia thành công';
        color = Colors.green;
        icon = Icons.check_circle_outline;
        break;
      case RentalRequestStatus.REJECTED:
        message = 'Yêu cầu tham gia đã bị từ chối';
        color = Colors.red;
        icon = Icons.cancel_outlined;
        break;
      case RentalRequestStatus.CANCELED:
        message = 'Yêu cầu tham gia đã bị hủy';
        color = Colors.orange;
        icon = Icons.cancel_outlined;
        break;
      default:
        message = 'Đang chờ xác nhận';
        color = Colors.amber[700]!;
        icon = Icons.access_time_rounded;
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

  void _sendRequest({
    required String findPartnerPostId,
    required String chatRoomId,
  }) {
    _findPartnerCubit.sendFindPartnerRequest(
      findPartnerPostId: findPartnerPostId,
      chatRoomId: chatRoomId,
    );
  }

  void _acceptRequest(String chatRoomId) {
    _findPartnerCubit.acceptFindPartnerRequest(chatRoomId);
  }

  void _rejectRequest(String chatRoomId) {
    _findPartnerCubit.rejectFindPartnerRequest(chatRoomId);
  }

  void _cancelRequest(String chatRoomId) {

    _findPartnerCubit.cancelFindPartnerRequest(chatRoomId);
  }

  String _getSuccessMessage(FindPartnerState state) {
    if (state is FindPartnerRequestSent) {
      return 'Đã gửi yêu cầu tham gia nhóm tìm bạn ở ghép';
    } else if (state is FindPartnerRequestAccepted) {
      return 'Đã chấp nhận thành viên vào nhóm tìm bạn ở ghép';
    } else if (state is FindPartnerRequestRejected) {
      return 'Đã từ chối yêu cầu tham gia nhóm';
    } else if (state is FindPartnerRequestCanceled) {
      return 'Đã hủy yêu cầu tham gia nhóm';
    }
    return '';
  }
} 