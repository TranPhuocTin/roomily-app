// import 'package:flutter/material.dart';
// import 'package:flutter/foundation.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:roomily/core/config/dio_config.dart';
// import 'dart:async';
//
// // Models
// import 'package:roomily/data/models/chat_message.dart';
// import 'package:roomily/data/models/chat_room_info.dart';
// import 'package:roomily/data/models/rental_request.dart';
//
// // Blocs & Cubits
// import 'package:roomily/blocs/home/room_detail_cubit.dart';
// import 'package:roomily/blocs/home/room_detail_state.dart';
// import 'package:roomily/blocs/chat_room/chat_room_cubit.dart';
// import 'package:roomily/blocs/rented_room/rent_request_cubit.dart';
// import 'package:roomily/blocs/rented_room/rent_request_state.dart';
// import 'package:roomily/blocs/chat_message/chat_message.dart';
//
// // Services
// import 'package:roomily/core/services/message_handler_service.dart';
// import 'package:get_it/get_it.dart';
//
// // Repositories
// import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
// import 'package:roomily/data/repositories/chat_repository_impl.dart';
//
// // Widgets & UI
// import 'package:roomily/core/config/text_styles.dart';
// import 'package:roomily/presentation/widgets/chat/pinned_property_card.dart';
//
//
// // Tạo một widget riêng cho PinnedPropertyCard
// class ChatDetailScreenFix extends StatefulWidget {
//   final ChatRoomInfo chatRoomInfo;
//   // Thêm userID và userRole vào constructor
//   final String? currentUserId;
//   final String? userRole;
//
//   const ChatDetailScreenFix({
//     Key? key,
//     required this.chatRoomInfo,
//     this.currentUserId,
//     this.userRole,
//   }) : super(key: key);
//
//   @override
//   State<ChatDetailScreenFix> createState() => _ChatDetailScreenFixState();
// }
//
// class _ChatDetailScreenFixState extends State<ChatDetailScreenFix> {
//   // Messaging related
//   final TextEditingController _messageController = TextEditingController();
//   bool _isSendingMessage = false;
//
//   // Message subscription
//   StreamSubscription? _messageSubscription;
//
//   // Room & UI related
//   bool _showPropertyCard = true;
//
//   // Cubits
//   late final ChatMessageCubit _chatMessageCubit;
//
//   // Scroll controller for infinite scroll
//   final ScrollController _scrollController = ScrollController();
//   bool _isLoadingMore = false;
//
//   // Store a copy of ChatRoomInfo to manage state updates more efficiently
//   late ChatRoomInfo _chatRoomInfo;
//
//   // Computed properties
//   bool get _isLandlord {
//     // Kiểm tra nếu ID người dùng hiện tại là manager của phòng
//     return widget.currentUserId == _chatRoomInfo.managerId;
//   }
//
//   // Trạng thái yêu cầu thuê được đọc trực tiếp từ model
//   RentalRequestStatus? get _requestStatus => _chatRoomInfo.rentalRequest?.status;
//
//   // Check if there's any rent request attached to this chat room
//   bool get _hasRentRequest => _chatRoomInfo.rentalRequest != null;
//
//   // Kiểm tra nếu yêu cầu thuê đang ở trạng thái chờ xác nhận
//   bool get _hasPendingRentRequest =>
//       _hasRentRequest && _requestStatus == RentalRequestStatus.PENDING;
//
//   // Kiểm tra trạng thái để hiển thị nút xác nhận/từ chối
//   bool get _shouldShowActionButtons {
//     return _isLandlord && _hasRentRequest && _hasPendingRentRequest;
//   }
//
//   // Check if rent request has been approved
//   bool get _hasApprovedRentRequest =>
//       _hasRentRequest && _requestStatus == RentalRequestStatus.APPROVED;
//
//   // Check if rent request has been rejected
//   bool get _hasRejectedRentRequest =>
//       _hasRentRequest && _requestStatus == RentalRequestStatus.REJECTED;
//
//   // Check if rent request has been canceled
//   bool get _hasCanceledRentRequest =>
//       _hasRentRequest && _requestStatus == RentalRequestStatus.CANCELED;
//
//   // Check if chat room is canceled
//   bool get _isChatRoomCanceled =>
//       _chatRoomInfo.chatRoomStatus?.toString().contains('CANCELED') ?? false;
//
//   // Check if we have a rejected request (chat room canceled but no rental request)
//   bool get _hasImplicitRejection =>
//       _isChatRoomCanceled && !_hasRentRequest;
//
//   // Check if current user is the requester of rental request
//   bool get _isRequester {
//     return widget.currentUserId == _chatRoomInfo.rentalRequest?.requesterId;
//   }
//
//   // New property to check if landlord has a canceled room
//   bool get _isLandlordWithCanceledRoom {
//     return _isLandlord && (_isChatRoomCanceled || _hasCanceledRentRequest);
//   }
//
//   @override
//   void initState() {
//     super.initState();
//
//     // Initialize with widget's chatRoomInfo
//     _chatRoomInfo = widget.chatRoomInfo;
//
//     // Initialize cubits
//     _chatMessageCubit = ChatMessageCubit(
//       ChatRepositoryImpl(dio: DioConfig.createDio()),
//     );
//
//     // Set this chat room as active in MessageHandlerService
//     final messageHandler = GetIt.instance<MessageHandlerService>();
//     messageHandler.setActiveChatRoom(_chatRoomInfo.chatRoomId);
//
//     // Subscribe to new messages from queue
//     _messageSubscription = messageHandler.onNewMessage.listen((message) {
//       if (message.chatRoomId == _chatRoomInfo.chatRoomId) {
//         if (kDebugMode) {
//           print('🎯 ChatDetailScreen: Received message from subscription: ${message.displayMessage}');
//         }
//
//         // Update UI when receiving message from queue
//         if (mounted) {
//           final state = _chatMessageCubit.state;
//           if (state is ChatMessagesLoaded) {
//             // Make sure the message isn't already in the list
//             if (!state.messages.any((m) => m.id == message.id)) {
//               if (kDebugMode) {
//                 print('🎯 ChatDetailScreen: Adding message from queue to UI');
//               }
//               _chatMessageCubit.emit(ChatMessagesLoaded(
//                 messages: [message, ...state.messages],
//                 hasReachedMax: state.hasReachedMax,
//                 oldestMessageId: state.oldestMessageId,
//                 oldestTimestamp: state.oldestTimestamp,
//               ));
//             }
//           }
//         }
//       }
//     });
//
//     if (kDebugMode) {
//       print('📱 ChatDetailScreen - initState');
//       print('📱 Chat Room ID: ${_chatRoomInfo.chatRoomId}');
//       print('📱 Current User ID: ${widget.currentUserId}');
//     }
//
//     // Load room data for display
//     _loadRoomData();
//
//     // Initial message fetch
//     _chatMessageCubit.loadMessages(_chatRoomInfo.chatRoomId);
//
//     // Initialize scroll controller for infinite scroll
//     _scrollController.addListener(_onScroll);
//   }
//
//   @override
//   void dispose() {
//     // Clear active chat room reference
//     GetIt.instance<MessageHandlerService>().clearActiveChatRoom();
//
//     _messageController.dispose();
//     _scrollController.removeListener(_onScroll);
//     _scrollController.dispose();
//     _messageSubscription?.cancel();
//
//     super.dispose();
//   }
//
//   void _onScroll() {
//     if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
//         !_isLoadingMore) {
//       _loadMoreMessages();
//     }
//   }
//
//
//
//   void _loadRoomData() {
//     if (_chatRoomInfo.roomId != null && _chatRoomInfo.roomId!.isNotEmpty) {
//       context.read<RoomDetailCubit>().fetchRoomById(_chatRoomInfo.roomId!);
//     }
//   }
//
//
//   void _loadMoreMessages() {
//     if (_isLoadingMore) return;
//
//     setState(() {
//       _isLoadingMore = true;
//     });
//
//     _chatMessageCubit.loadMoreMessages(_chatRoomInfo.chatRoomId).then((_) {
//       setState(() {
//         _isLoadingMore = false;
//       });
//     });
//   }
//
//   // Gửi tin nhắn mới
//   Future<void> _sendMessage() async {
//     final messageText = _messageController.text.trim();
//     if (messageText.isEmpty || _isSendingMessage) return;
//
//     setState(() {
//       _isSendingMessage = true;
//     });
//
//     // Check if currentUserId is null
//     final String senderId = widget.currentUserId ?? 'unknown';
//
//     if (kDebugMode) {
//       print('========== SENDING MESSAGE ==========');
//       print('Current User ID: ${widget.currentUserId}');
//       print('Sender ID being used: $senderId');
//       print('Chat Room ID: ${_chatRoomInfo.chatRoomId}');
//       print('Message: $messageText');
//       print('=====================================');
//     }
//
//     try {
//       await _chatMessageCubit.sendMessage(
//         content: messageText,
//         senderId: senderId,
//         chatRoomId: _chatRoomInfo.chatRoomId,
//       );
//
//       // Clear the input field on successful sending
//       setState(() {
//         _messageController.clear();
//         _isSendingMessage = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isSendingMessage = false;
//       });
//
//       if (kDebugMode) {
//         print('❌ ERROR SENDING MESSAGE: $e');
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider.value(value: _chatMessageCubit),
//       ],
//       child: PopScope(
//         canPop: true,
//         onPopInvoked: (didPop) {
//           context.read<ChatRoomCubit>().getChatRooms();
//         },
//         child: Scaffold(
//           body: Stack(
//             children: [
//               // Background Image
//               _ChatBackground(),
//
//               // Main Content
//               SafeArea(
//                 child: Column(
//                   children: [
//                     // Header section
//                     _ChatHeader(
//                       roomName: _chatRoomInfo.roomName,
//                       roomType: _chatRoomInfo.chatRoomType,
//                       onBackPressed: () {
//                         context.read<ChatRoomCubit>().getChatRooms();
//                         Navigator.pop(context);
//                       },
//                     ),
//
//                     // Room visibility toggle
//                     if (_shouldShowRoomToggle)
//                       _RoomVisibilityToggle(
//                         isVisible: _showPropertyCard,
//                         onToggle: () => setState(() => _showPropertyCard = !_showPropertyCard),
//                       ),
//
//                     // Chat content area with optimized BlocListener
//                     Expanded(
//                       child: Column(
//                         children: [
//                           // Room info at the top with isolated rebuild
//                           if (_showPropertyCard && _shouldShowRoomInfo)
//                             RepaintBoundary(
//                               child: RoomInfoCard(
//                                 key: ValueKey('room_info_${_chatRoomInfo.chatRoomId}'),
//                                 chatRoomInfo: _chatRoomInfo,
//                                 isLandlord: _isLandlord,
//                                 currentUserId: widget.currentUserId,
//                                 onInfoRefreshed: _refreshChatRoomInfo,
//                               ),
//                             ),
//
//                           // Messages - Wrapped in a listener to handle state changes
//                           Expanded(
//                             child: RepaintBoundary(
//                               child: ChatMessageListener(
//                                 onStateChanged: (state) {
//                                   if (state is ChatMessageError) {
//                                     setState(() {
//                                       _isSendingMessage = false;
//                                     });
//                                   } else if (state is ChatMessagesLoaded && _isSendingMessage) {
//                                     setState(() {
//                                       _isSendingMessage = false;
//                                     });
//                                   }
//                                 },
//                                 child: MessageListWidget(
//                                   key: ValueKey('message_list_${_chatRoomInfo.chatRoomId}'),
//                                   currentUserId: widget.currentUserId,
//                                   isLandlord: _isLandlord,
//                                   rentRequestStatus: _requestStatus,
//                                   scrollController: _scrollController,
//                                   isLoadingMore: _isLoadingMore,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     // Input field
//                     Padding(
//                       padding: const EdgeInsets.symmetric(horizontal: 15),
//                       child: _ChatInputField(
//                         controller: _messageController,
//                         isSending: _isSendingMessage,
//                         onSend: _sendMessage,
//                       ),
//                     ),
//                     const SizedBox(height: 16),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//
//   // Helper properties for conditional UI
//   bool get _shouldShowRoomInfo =>
//       _chatRoomInfo.roomId != null && _chatRoomInfo.roomId!.isNotEmpty;
//
//   bool get _shouldShowRoomToggle => _shouldShowRoomInfo;
//
//   // Room Info Card
//   Future<void> _refreshChatRoomInfo() async {
//     try {
//       // Get the ChatRoomCubit instance
//       final chatRoomCubit = context.read<ChatRoomCubit>();
//
//       if (kDebugMode) {
//         print('📱 ChatDetailScreen: Refreshing chat room info for ${_chatRoomInfo.chatRoomId}');
//       }
//
//       // Request updated chat room info - this will emit a new state
//       // that only the RoomInfoCard will respond to with its isolated rebuild mechanism
//       chatRoomCubit.getChatRoomInfo(_chatRoomInfo.chatRoomId);
//
//       // The ChatRoomInfoLoaded state will be handled by the RoomInfoCard
//       // which has its own state management and will rebuild only itself
//       // This won't trigger a rebuild of MessageListWidget due to RepaintBoundary and buildWhen
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error refreshing chat room info: $e');
//       }
//     }
//   }
//
// }
//
// // Widget hiển thị background
// class _ChatBackground extends StatelessWidget {
//   @override
//   Widget build(BuildContext context) {
//     return Positioned(
//       top: 0,
//       left: 0,
//       right: 0,
//       child: Image.asset(
//         'assets/images/chat_background.jpg',
//         fit: BoxFit.cover,
//       ),
//     );
//   }
// }
//
// // Widget để xử lý các actions liên quan đến thuê phòng
// class RoomActionArea extends StatefulWidget {
//   final ChatRoomInfo chatRoomInfo;
//   final bool isLandlord;
//   final RoomDetailLoaded roomState;
//   final String? currentUserId;
//   final VoidCallback onInfoRefreshed;
//
//   const RoomActionArea({
//     Key? key,
//     required this.chatRoomInfo,
//     required this.isLandlord,
//     required this.roomState,
//     this.currentUserId,
//     required this.onInfoRefreshed,
//   }) : super(key: key);
//
//   @override
//   State<RoomActionArea> createState() => _RoomActionAreaState();
// }
//
// class _RoomActionAreaState extends State<RoomActionArea> {
//   late final RentRequestCubit _rentRequestCubit;
//
//   @override
//   void initState() {
//     super.initState();
//     _rentRequestCubit = RentRequestCubit(
//       rentedRoomRepository: RentedRoomRepositoryImpl(dio: DioConfig.createDio()),
//     );
//   }
//
//   // Kiểm tra nếu là người thuê
//   bool get _isRequester {
//     return widget.currentUserId == widget.chatRoomInfo.rentalRequest?.requesterId;
//   }
//
//   // Check if there's any rent request attached to this chat room
//   bool get _hasRentRequest => widget.chatRoomInfo.rentalRequest != null;
//
//   // Kiểm tra nếu yêu cầu thuê đang ở trạng thái chờ xác nhận
//   bool get _hasPendingRentRequest =>
//       _hasRentRequest && widget.chatRoomInfo.rentalRequest?.status == RentalRequestStatus.PENDING;
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider.value(
//       value: _rentRequestCubit,
//       child: BlocConsumer<RentRequestCubit, RentRequestState>(
//         listener: (context, rentRequestState) {
//           if (rentRequestState is RentRequestSuccess) {
//             // Refresh thông tin chat room để cập nhật UI
//             widget.onInfoRefreshed();
//           } else if (rentRequestState is RentRequestFailure) {
//             // Log error in debug mode
//             if (kDebugMode) {
//               print('Lỗi khi xử lý yêu cầu: ${rentRequestState.error}');
//             }
//           }
//         },
//         builder: (context, rentRequestState) {
//           // Container với background và border radius matching ProductChatBubble
//           return Container(
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.only(
//                 bottomLeft: Radius.circular(12),
//                 bottomRight: Radius.circular(12),
//               ),
//             ),
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             child: _buildActionContent(context, rentRequestState),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildActionContent(BuildContext context, RentRequestState rentRequestState) {
//     // Lấy trạng thái trực tiếp từ chatRoomInfo
//     final RentalRequestStatus? requestStatus = widget.chatRoomInfo.rentalRequest?.status;
//     final bool isRoomRented = widget.chatRoomInfo.chatRoomStatus.contains('RENTED');
//     final bool isChatRoomCanceled = widget.chatRoomInfo.chatRoomStatus.contains('CANCELED');
//
//     // 1. Chủ trọ với yêu cầu chờ xử lý - hiển thị nút Accept/Reject
//     if (widget.isLandlord && requestStatus == RentalRequestStatus.PENDING) {
//       return Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           // Nút chấp nhận
//           Expanded(
//             child: _buildActionButton(
//               icon: Icons.check_circle_outline,
//               label: 'CHẤP NHẬN',
//               color: const Color(0xFF4CAF50),
//               onTap: () => _handleRentRequestResponse(true),
//             ),
//           ),
//           // Phân cách
//           const SizedBox(width: 8),
//           // Nút từ chối
//           Expanded(
//             child: _buildActionButton(
//               icon: Icons.cancel_outlined,
//               label: 'TỪ CHỐI',
//               color: Colors.red,
//               onTap: () => _handleRentRequestResponse(false),
//             ),
//           ),
//         ],
//       );
//     }
//
//     // 2. Người thuê chưa gửi yêu cầu & phòng chưa được thuê
//     if (!widget.isLandlord && requestStatus == null && !isRoomRented) {
//       return _buildRentRequestButton(
//         context,
//         label: rentRequestState is RentRequestLoading ? 'Đang gửi yêu cầu...' : 'Yêu cầu thuê phòng',
//         isLoading: rentRequestState is RentRequestLoading,
//       );
//     }
//
//     // 3. Người thuê có yêu cầu đang chờ - hiển thị trạng thái và nút hủy
//     if (!widget.isLandlord && requestStatus == RentalRequestStatus.PENDING) {
//       return _buildPendingRequestStatus(context, rentRequestState is RentRequestLoading);
//     }
//
//     // 4. Người thuê với phòng đã bị hủy/chat bị hủy
//     if (!widget.isLandlord && isChatRoomCanceled) {
//       return _buildCanceledRoomActions(context, rentRequestState is RentRequestLoading);
//     }
//
//     // 5. Người thuê với yêu cầu đã được chấp nhận/từ chối
//     if (!widget.isLandlord && (requestStatus == RentalRequestStatus.APPROVED ||
//         requestStatus == RentalRequestStatus.REJECTED)) {
//       return _buildRequestResultStatus();
//     }
//
//     // Mặc định không hiển thị gì
//     return const SizedBox.shrink();
//   }
//
//   // Nút hành động chung
//   Widget _buildActionButton({
//     required IconData icon,
//     required String label,
//     required Color color,
//     required VoidCallback onTap,
//   }) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         splashColor: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(8),
//         child: Padding(
//           padding: const EdgeInsets.symmetric(vertical: 8),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.center,
//             children: [
//               Icon(icon, size: 16, color: color),
//               const SizedBox(width: 6),
//               Text(
//                 label,
//                 style: TextStyle(
//                   fontSize: 13,
//                   fontWeight: FontWeight.w500,
//                   color: color,
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   // Nút gửi yêu cầu thuê phòng
//   Widget _buildRentRequestButton(BuildContext context, {required String label, required bool isLoading}) {
//     return InkWell(
//       onTap: isLoading ? null : () => _sendRentRequest(context),
//       borderRadius: BorderRadius.circular(8),
//       splashColor: Theme.of(context).primaryColor.withOpacity(0.1),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (isLoading)
//               SizedBox(
//                 width: 16,
//                 height: 16,
//                 child: CircularProgressIndicator(
//                   strokeWidth: 2,
//                   valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
//                 ),
//               )
//             else
//               Icon(Icons.key_rounded, size: 16, color: Theme.of(context).primaryColor),
//
//             const SizedBox(width: 8),
//
//             Text(
//               label,
//               style: TextStyle(
//                 fontSize: 13,
//                 fontWeight: FontWeight.w500,
//                 color: Theme.of(context).primaryColor,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Hiển thị trạng thái đang chờ xác nhận
//   Widget _buildPendingRequestStatus(BuildContext context, bool isLoading) {
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         // Thông tin trạng thái
//         Expanded(
//           child: Row(
//             children: [
//               Icon(
//                 Icons.access_time_rounded,
//                 size: 14,
//                 color: Colors.amber[700],
//               ),
//               const SizedBox(width: 6),
//               Flexible(
//                 child: Row(
//                   children: [
//                     Text(
//                       'Đang chờ xác nhận · ',
//                       style: TextStyle(
//                         fontSize: 12,
//                         fontWeight: FontWeight.w500,
//                         color: Colors.amber[700],
//                       ),
//                     ),
//                     if (widget.chatRoomInfo.rentalRequest?.expiresAt != null)
//                       Flexible(
//                         child: ExpirationTimerWidget(
//                           expiresAt: widget.chatRoomInfo.rentalRequest!.expiresAt,
//                         ),
//                       ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//
//         // Nút hủy
//         TextButton.icon(
//           onPressed: isLoading
//               ? null
//               : () => _showCancelRequestConfirmation(context),
//           icon: Icon(Icons.cancel_outlined, size: 12, color: Colors.red[400]),
//           label: Text(
//             'Hủy',
//             style: TextStyle(
//               fontSize: 11,
//               color: Colors.red[400],
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Hiển thị trạng thái đã được chấp nhận/từ chối
//   Widget _buildRequestResultStatus() {
//     // Sử dụng trạng thái trực tiếp từ ChatRoomInfo
//     final bool isApproved = widget.chatRoomInfo.rentalRequest?.status == RentalRequestStatus.APPROVED;
//     final Color statusColor = isApproved ? Colors.green : Colors.redAccent;
//     final IconData statusIcon = isApproved ? Icons.check_circle_outline : Icons.cancel_outlined;
//     final String statusText = isApproved
//         ? 'Yêu cầu thuê phòng đã được chấp nhận'
//         : 'Yêu cầu thuê phòng đã bị từ chối';
//
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.center,
//       children: [
//         Icon(statusIcon, size: 14, color: statusColor),
//         const SizedBox(width: 6),
//         Text(
//           statusText,
//           style: TextStyle(
//             fontSize: 12,
//             fontWeight: FontWeight.w500,
//             color: statusColor,
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Hiển thị UI khi phòng đã bị hủy
//   Widget _buildCanceledRoomActions(BuildContext context, bool isLoading) {
//     // Đơn giản hóa: Trạng thái từ chatRoomStatus
//     final bool hasRentRequest = widget.chatRoomInfo.rentalRequest != null;
//     final String statusText = !hasRentRequest ?
//     'Yêu cầu đã bị từ chối/hủy' :
//     'Yêu cầu đã bị hủy';
//
//     return Row(
//       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//       children: [
//         // Thông báo hủy
//         Row(
//           children: [
//             Icon(Icons.info_outline, size: 14, color: Colors.orange[700]),
//             const SizedBox(width: 6),
//             Text(
//               statusText,
//               style: const TextStyle(
//                 fontSize: 12,
//                 fontWeight: FontWeight.w500,
//                 color: Colors.orange,
//               ),
//             ),
//           ],
//         ),
//
//         // Nút gửi yêu cầu mới
//         TextButton.icon(
//           onPressed: isLoading ? null : () => _sendRentRequest(context),
//           icon: const Icon(Icons.send, size: 14),
//           label: Text(
//             isLoading ? 'Đang gửi...' : 'Gửi yêu cầu mới',
//             style: const TextStyle(fontSize: 12),
//           ),
//           style: TextButton.styleFrom(
//             foregroundColor: Colors.white,
//             backgroundColor: Theme.of(context).primaryColor,
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//             textStyle: const TextStyle(fontSize: 12),
//             minimumSize: const Size(30, 26),
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Hàm xử lý gửi yêu cầu thuê phòng
//   void _sendRentRequest(BuildContext context) {
//     final String? roomId = widget.roomState.room.id;
//     final String chatRoomId = widget.chatRoomInfo.chatRoomId;
//
//     if (roomId != null && roomId.isNotEmpty && chatRoomId.isNotEmpty) {
//       // Đặt thời gian hết hạn là 24 giờ sau hiện tại
//       final DateTime startDate = DateTime.now();
//
//       if (kDebugMode) {
//         print('Sending rent request with start date: $startDate');
//       }
//
//       // Gọi API để tạo yêu cầu thuê phòng
//       _rentRequestCubit.createRentRequest(
//         roomId: roomId,
//         chatRoomId: chatRoomId,
//         startDate: startDate,
//       );
//
//       // Không cần setState() hoặc cập nhật thủ công - BlocListener sẽ xử lý
//     } else {
//       if (kDebugMode) {
//         print('Không thể gửi yêu cầu: Thiếu thông tin phòng');
//       }
//     }
//   }
//
//   void _handleRentRequestResponse(bool accept) async {
//     // Ensure user is a landlord
//     if (!widget.isLandlord) {
//       if (kDebugMode) {
//         print('Không có quyền xử lý yêu cầu thuê phòng');
//       }
//       return;
//     }
//
//     // Ensure there's a valid chat room ID
//     final String chatRoomId = widget.chatRoomInfo.chatRoomId;
//     if (chatRoomId.isEmpty) {
//       if (kDebugMode) {
//         print('Không thể xử lý: Thiếu thông tin phòng chat');
//       }
//       return;
//     }
//
//     try {
//       if (accept) {
//         await _rentRequestCubit.acceptRentRequest(chatRoomId);
//       } else {
//         await _rentRequestCubit.rejectRentRequest(chatRoomId);
//       }
//       setState(() {
//
//       });
//     } catch (e) {
//       if (kDebugMode) {
//         print('Lỗi khi ${accept ? "chấp nhận" : "từ chối"} yêu cầu: $e');
//       }
//     }
//   }
//
//   void _showCancelRequestConfirmation(BuildContext context) {
//     showDialog(
//       context: context,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: const Text('Hủy yêu cầu thuê phòng?'),
//           content: const Text('Bạn có chắc chắn muốn hủy yêu cầu thuê phòng này không? Bạn có thể gửi yêu cầu mới sau khi hủy.'),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(dialogContext).pop(),
//               child: const Text('Không'),
//             ),
//             TextButton(
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//                 _cancelRentRequest();
//               },
//               style: TextButton.styleFrom(
//                 foregroundColor: Colors.red,
//               ),
//               child: const Text('Hủy yêu cầu'),
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   void _cancelRentRequest() async {
//     if (!_hasRentRequest || !_hasPendingRentRequest || !_isRequester) {
//       if (kDebugMode) {
//         print('Không thể hủy: Yêu cầu không tồn tại hoặc không thuộc về bạn');
//       }
//       return;
//     }
//
//     final String chatRoomId = widget.chatRoomInfo.chatRoomId;
//
//     try {
//       // Gọi API hủy yêu cầu
//       await _rentRequestCubit.cancelRentRequest(chatRoomId);
//     } catch (e) {
//       if (kDebugMode) {
//         print('Lỗi khi hủy yêu cầu: $e');
//       }
//     }
//   }
// }
//
// // Widget header với nút back, tên phòng chat và các nút call
// class _ChatHeader extends StatelessWidget {
//   final String roomName;
//   final ChatRoomType roomType;
//   final VoidCallback onBackPressed;
//
//   const _ChatHeader({
//     required this.roomName,
//     required this.roomType,
//     required this.onBackPressed,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(
//         children: [
//           IconButton(
//             onPressed: onBackPressed,
//             icon: const Icon(
//               Icons.arrow_back_ios_rounded,
//               size: 24,
//             ),
//           ),
//           const SizedBox(width: 8),
//           const CircleAvatar(
//             radius: 20,
//             backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=User'), // Default avatar
//           ),
//           const SizedBox(width: 12),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Tooltip cho tên phòng dài
//                 Tooltip(
//                   message: roomName,
//                   child: Text(
//                     roomName,
//                     style: AppTextStyles.bodyLargeSemiBold,
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                 ),
//                 // Hiển thị loại phòng chat
//                 Text(
//                   _formatRoomType(roomType),
//                   style: TextStyle(
//                     fontSize: 12,
//                     color: Colors.grey[600],
//                   ),
//                   maxLines: 1,
//                 ),
//               ],
//             ),
//           ),
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white.withOpacity(0.5),
//             ),
//             child: IconButton(
//               onPressed: () {},
//               icon: Image.asset('assets/icons/call_icon.png'),
//             ),
//           ),
//           const SizedBox(width: 8),
//           Container(
//             decoration: BoxDecoration(
//               shape: BoxShape.circle,
//               color: Colors.white.withOpacity(0.5),
//             ),
//             child: IconButton(
//               onPressed: () {},
//               icon: Image.asset('assets/icons/video_call.png'),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // Helper để format room type thành dạng dễ đọc
//   String _formatRoomType(ChatRoomType type) {
//     switch (type) {
//       case ChatRoomType.DIRECT:
//         return 'Direct Message';
//       case ChatRoomType.GROUP:
//         return 'Group Chat';
//       default:
//         return type.toString().split('.').last;
//     }
//   }
// }
//
// // Widget nút bật/tắt hiển thị thông tin phòng
// class _RoomVisibilityToggle extends StatelessWidget {
//   final bool isVisible;
//   final VoidCallback onToggle;
//
//   const _RoomVisibilityToggle({
//     required this.isVisible,
//     required this.onToggle,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Align(
//       alignment: Alignment.centerRight,
//       child: GestureDetector(
//         onTap: onToggle,
//         child: Container(
//           margin: const EdgeInsets.only(top: 8, bottom: 4, right: 16),
//           padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//           decoration: BoxDecoration(
//             color: Colors.grey[200],
//             borderRadius: BorderRadius.circular(12),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 isVisible ? Icons.visibility_off : Icons.visibility,
//                 size: 16,
//                 color: Colors.grey[700],
//               ),
//               const SizedBox(width: 4),
//               Text(
//                 isVisible ? 'Ẩn thông tin phòng' : 'Hiển thị thông tin phòng',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[700],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// // Update the MessageListWidget to be more optimized
// class MessageListWidget extends StatelessWidget {
//   final String? currentUserId;
//   final bool isLandlord;
//   final RentalRequestStatus? rentRequestStatus;
//   final ScrollController scrollController;
//   final bool isLoadingMore;
//
//   const MessageListWidget({
//     Key? key,
//     this.currentUserId,
//     required this.isLandlord,
//     required this.rentRequestStatus,
//     required this.scrollController,
//     required this.isLoadingMore,
//   }) : super(key: key);
//
//   // Helper method to compare message lists for optimization
//   bool _areMessageListsEqual(List<ChatMessage> list1, List<ChatMessage> list2) {
//     if (list1.length != list2.length) return false;
//     for (int i = 0; i < list1.length; i++) {
//       if (list1[i].id != list2[i].id) return false;
//     }
//     return true;
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (kDebugMode) {
//       print('🛠️ MessageListWidget: Building message list UI');
//     }
//
//     return BlocBuilder<ChatMessageCubit, ChatMessageState>(
//       buildWhen: (previous, current) {
//         // Only rebuild when we have new messages or error state change
//         bool shouldRebuild = false;
//
//         if (current is ChatMessagesLoaded && previous is! ChatMessagesLoaded) {
//           shouldRebuild = true;
//         } else if (current is ChatMessagesLoaded && previous is ChatMessagesLoaded) {
//           shouldRebuild = !_areMessageListsEqual(
//               (current).messages,
//               (previous).messages
//           );
//         } else if (current is ChatMessagesError && previous is! ChatMessagesError) {
//           shouldRebuild = true;
//         } else if (current is ChatMessagesLoading && current.isFirstLoad &&
//             previous is! ChatMessagesLoading) {
//           shouldRebuild = true;
//         }
//
//         if (kDebugMode && shouldRebuild) {
//           print('🛠️ MessageListWidget: Rebuilding due to state change: ${previous.runtimeType} -> ${current.runtimeType}');
//         }
//
//         return shouldRebuild;
//       },
//       builder: (context, state) {
//         if (state is ChatMessagesLoading && state.isFirstLoad) {
//           // Hiển thị loading chỉ khi là lần tải đầu tiên
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         } else if (state is ChatMessagesLoaded) {
//           // Always use messages from state to ensure UI consistency
//           return Stack(
//             children: [
//               // Tin nhắn chính
//               _MessageList(
//                 messages: state.messages,
//                 currentUserId: currentUserId,
//                 isLandlord: isLandlord,
//                 rentRequestStatus: rentRequestStatus,
//               ),
//
//               // Indicator khi đang tải thêm tin nhắn (không phải lần đầu)
//               if (isLoadingMore)
//                 Positioned(
//                   bottom: 0,
//                   left: 0,
//                   right: 0,
//                   child: Container(
//                     color: Colors.black12,
//                     padding: const EdgeInsets.symmetric(vertical: 8),
//                     child: const Center(
//                       child: SizedBox(
//                         width: 24,
//                         height: 24,
//                         child: CircularProgressIndicator(strokeWidth: 2),
//                       ),
//                     ),
//                   ),
//                 ),
//             ],
//           );
//         } else if (state is ChatMessagesError) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                 const SizedBox(height: 16),
//                 Text(
//                   'Lỗi tải tin nhắn: ${state.error}',
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(color: Colors.red),
//                 ),
//                 const SizedBox(height: 16),
//                 ElevatedButton(
//                   onPressed: () => context.read<ChatMessageCubit>().loadMessages(
//                     context.findAncestorWidgetOfExactType<ChatDetailScreenFix>()!.chatRoomInfo.chatRoomId,
//                   ),
//                   child: const Text('Thử lại'),
//                 ),
//               ],
//             ),
//           );
//         } else {
//           // Empty state or unhandled state
//           return const Center(
//             child: Text('Không có tin nhắn nào'),
//           );
//         }
//       },
//     );
//   }
// }
//
// // Widget danh sách tin nhắn
// class _MessageList extends StatelessWidget {
//   final List<ChatMessage> messages;
//   final String? currentUserId;
//   final bool isLandlord;
//   final RentalRequestStatus? rentRequestStatus;
//
//   const _MessageList({
//     required this.messages,
//     required this.currentUserId,
//     required this.isLandlord,
//     required this.rentRequestStatus,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     if (kDebugMode) {
//       print('=========== MESSAGE LIST DEBUG ===========');
//       print('Current User ID: $currentUserId');
//       print('Total Messages: ${messages.length}');
//       print('========================================');
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       reverse: true,
//       itemCount: messages.length,
//       itemBuilder: (context, index) {
//         final message = messages[index];
//
//         // Log message details for debugging
//         if (kDebugMode) {
//           print('Message[$index] - senderId: ${message.senderId}, currentUserId: $currentUserId');
//         }
//
//         // Check if this message is from the current user
//         final bool isMe = message.senderId == currentUserId;
//         // Check if this is a system message
//         final bool isSystem = message.senderId == null;
//
//         if (isSystem) {
//           return _buildSystemMessage(message, context);
//         }
//
//         return _buildDetailUserMessage(message, isMe);
//       },
//     );
//   }
//
//   // Hiển thị tin nhắn hệ thống
//   Widget _buildSystemMessage(ChatMessage message, BuildContext context) {
//     final String messageContent = message.content ?? '';
//     final bool isRentRequestResponse =
//         messageContent.contains('Chủ trọ đã chấp nhận') ||
//             messageContent.contains('Chủ trọ đã từ chối');
//
//     // Xác định màu sắc dựa vào loại tin nhắn
//     Color bgColor = Colors.grey[100]!;
//     Color textColor = Colors.black87;
//     Color? borderColor = Colors.grey[300];
//     IconData? iconData;
//
//     if (messageContent.contains('chấp nhận')) {
//       bgColor = const Color(0xFFE8F5E9);
//       textColor = const Color(0xFF2E7D32);
//       borderColor = const Color(0xFF81C784);
//       iconData = Icons.check_circle_outline;
//     } else if (messageContent.contains('từ chối') || messageContent.contains('bị hủy')) {
//       bgColor = const Color(0xFFFFEBEE);
//       textColor = const Color(0xFFD32F2F);
//       borderColor = const Color(0xFFEF9A9A);
//       iconData = Icons.cancel_outlined;
//     } else if (messageContent.contains('chờ xử lý') || messageContent.contains('chờ xác nhận')) {
//       bgColor = const Color(0xFFFFF8E1);
//       textColor = const Color(0xFFFF8F00);
//       borderColor = const Color(0xFFFFCC80);
//       iconData = Icons.hourglass_empty;
//     } else if (messageContent.contains('gửi thành công') || messageContent.contains('đã gửi')) {
//       bgColor = const Color(0xFFE3F2FD);
//       textColor = const Color(0xFF1976D2);
//       borderColor = const Color(0xFF90CAF9);
//       iconData = Icons.send;
//     }
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Column(
//         children: [
//           Container(
//             width: double.infinity,
//             padding: const EdgeInsets.all(12),
//             margin: const EdgeInsets.symmetric(horizontal: 16),
//             decoration: BoxDecoration(
//               color: bgColor,
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: borderColor!, width: 1),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.black.withOpacity(0.03),
//                   blurRadius: 3,
//                   spreadRadius: 1,
//                   offset: const Offset(0, 1),
//                 ),
//               ],
//             ),
//             child: Column(
//               children: [
//                 if (iconData != null) ...[
//                   Icon(
//                     iconData,
//                     color: textColor,
//                     size: 28,
//                   ),
//                   const SizedBox(height: 10),
//                 ],
//                 Text(
//                   message.displayMessage,
//                   textAlign: TextAlign.center,
//                   style: TextStyle(
//                     fontSize: 15,
//                     color: textColor,
//                     fontWeight: isRentRequestResponse ? FontWeight.bold : FontWeight.normal,
//                     height: 1.4,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           // Show a helper text for the tenant with pending request
//           if (!this.isLandlord && this.rentRequestStatus == RentalRequestStatus.PENDING &&
//               messageContent.contains('Yêu cầu thuê phòng đã được gửi'))
//             Padding(
//               padding: const EdgeInsets.only(top: 8),
//               child: Text(
//                 'Chủ trọ sẽ xem xét yêu cầu của bạn sớm',
//                 style: TextStyle(
//                   fontSize: 12,
//                   color: Colors.grey[600],
//                   fontStyle: FontStyle.italic,
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
//
//   // Hiển thị tin nhắn người dùng - Đổi tên để tránh xung đột
//   Widget _buildDetailUserMessage(ChatMessage message, bool isMe) {
//     final Color messageBubbleColor = isMe
//         ? const Color(0xFFE8F0FE)
//         : const Color(0xFF1A73E8);
//
//     // Màu văn bản tương phản với màu nền
//     final Color textColor = isMe ? const Color(0xFF1A73E8) : Colors.white;
//
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 16),
//       child: Row(
//         // Position messages from current user to the right, others to the left
//         mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Only show the other person's avatar on the left
//           if (!isMe) ...[
//             CircleAvatar(
//               radius: 16,
//               backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(message.senderId ?? "U")}&background=random'),
//             ),
//             const SizedBox(width: 8),
//           ],
//
//           // Message content
//           Flexible(
//             child: Container(
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: messageBubbleColor,
//                 // Different border radius for current user vs others
//                 borderRadius: BorderRadius.circular(18).copyWith(
//                   bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
//                   bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(18),
//                 ),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 2,
//                     spreadRadius: 0,
//                     offset: const Offset(0, 1),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Message content
//                   Text(
//                     message.displayMessage,
//                     style: TextStyle(
//                       color: textColor,
//                       fontSize: 14,
//                     ),
//                   ),
//
//                   // Timestamp
//                   const SizedBox(height: 4),
//                   Row(
//                     mainAxisSize: MainAxisSize.min,
//                     mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
//                     children: [
//                       Text(
//                         _formatTimestamp(message.timestamp),
//                         style: TextStyle(
//                           color: isMe ? const Color(0xFF5F6368) : Colors.white70,
//                           fontSize: 10,
//                         ),
//                       ),
//                       if (isMe) ...[
//                         const SizedBox(width: 4),
//                         Icon(
//                           message.read == true ? Icons.done_all : Icons.done,
//                           size: 12,
//                           color: message.read == true ? const Color(0xFF4CAF50) : const Color(0xFF5F6368),
//                         ),
//                       ],
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           // Only show current user's avatar on the right
//           if (isMe) ...[
//             const SizedBox(width: 8),
//             CircleAvatar(
//               radius: 16,
//               backgroundImage: NetworkImage('https://ui-avatars.com/api/?name=${Uri.encodeComponent(currentUserId ?? "Me")}&background=E8F0FE&color=1A73E8'),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//
//
//   // Định dạng timestamp
//   String _formatTimestamp(String? timestamp) {
//     if (timestamp == null) return 'Đang gửi...';
//
//     try {
//       final DateTime dateTime = DateTime.parse(timestamp);
//       final now = DateTime.now();
//       final today = DateTime(now.year, now.month, now.day);
//       final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);
//
//       // Format giờ:phút
//       final timeString = '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
//
//       if (messageDate == today) {
//         // Hôm nay
//         return timeString;
//       } else if (messageDate == today.subtract(const Duration(days: 1))) {
//         // Hôm qua
//         return 'Hôm qua, $timeString';
//       } else {
//         // Các ngày khác
//         return '${dateTime.day}/${dateTime.month}, $timeString';
//       }
//     } catch (e) {
//       // Trả về nguyên bản nếu có lỗi parse
//       return timestamp;
//     }
//   }
// }
//
// // Widget trường nhập liệu
// class _ChatInputField extends StatelessWidget {
//   final TextEditingController controller;
//   final bool isSending;
//   final VoidCallback onSend;
//
//   const _ChatInputField({
//     required this.controller,
//     required this.isSending,
//     required this.onSend,
//   });
//
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 5),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(15),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 1,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 7),
//         child: Row(
//           children: [
//             IconButton(
//               onPressed: () {
//                 // Xử lý tải file lên sau này
//               },
//               icon: const Icon(Icons.attach_file, color: Colors.grey),
//             ),
//             Expanded(
//               child: TextField(
//                 controller: controller,
//                 decoration: InputDecoration(
//                   hintText: 'Soạn tin nhắn...',
//                   hintStyle: TextStyle(color: Colors.grey[400]),
//                   border: InputBorder.none,
//                 ),
//                 onSubmitted: (_) => onSend(),
//               ),
//             ),
//             Container(
//               width: 40,
//               height: 40,
//               decoration: const BoxDecoration(
//                 color: Color(0xFF234F68),
//                 shape: BoxShape.circle,
//               ),
//               child: IconButton(
//                 onPressed: onSend,
//                 icon: isSending
//                     ? const SizedBox(
//                   width: 16,
//                   height: 16,
//                   child: CircularProgressIndicator(
//                     strokeWidth: 2,
//                     valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                   ),
//                 )
//                     : const Icon(Icons.send, color: Colors.white, size: 20),
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
//
// // Widget hiển thị thời gian còn lại
// class ExpirationTimerWidget extends StatefulWidget {
//   final DateTime expiresAt;
//
//   const ExpirationTimerWidget({
//     Key? key,
//     required this.expiresAt,
//   }) : super(key: key);
//
//   @override
//   State<ExpirationTimerWidget> createState() => _ExpirationTimerWidgetState();
// }
//
// class _ExpirationTimerWidgetState extends State<ExpirationTimerWidget> {
//   late Timer _timer;
//   String _timeRemainingText = '';
//
//   @override
//   void initState() {
//     super.initState();
//     _updateRemainingTime();
//     _timer = Timer.periodic(const Duration(seconds: 1), (_) {
//       _updateRemainingTime();
//     });
//   }
//
//   @override
//   void dispose() {
//     _timer.cancel();
//     super.dispose();
//   }
//
//   void _updateRemainingTime() {
//     final now = DateTime.now();
//     final remaining = widget.expiresAt.difference(now);
//
//     if (remaining.isNegative) {
//       setState(() {
//         _timeRemainingText = 'Đã hết hạn';
//       });
//       _timer.cancel();
//       return;
//     }
//
//     final days = remaining.inDays;
//     final hours = remaining.inHours % 24;
//     final minutes = remaining.inMinutes % 60;
//     final seconds = remaining.inSeconds % 60;
//
//     setState(() {
//       if (days > 0) {
//         _timeRemainingText = '$days ngày ${hours}h còn lại';
//       } else if (hours > 0) {
//         _timeRemainingText = '$hours giờ ${minutes}p còn lại';
//       } else if (minutes > 0) {
//         _timeRemainingText = '$minutes phút ${seconds}s còn lại';
//       } else {
//         _timeRemainingText = '$seconds giây còn lại';
//       }
//     });
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Text(
//       _timeRemainingText,
//       style: TextStyle(
//         fontSize: 12,
//         fontWeight: FontWeight.w500,
//         color: Colors.amber[700],
//       ),
//       overflow: TextOverflow.ellipsis,
//     );
//   }
// }
//
// // Update RoomInfoCard to include build debugging and optimize rebuilds
// class RoomInfoCard extends StatefulWidget {
//   final ChatRoomInfo chatRoomInfo;
//   final bool isLandlord;
//   final String? currentUserId;
//   final VoidCallback onInfoRefreshed;
//
//   const RoomInfoCard({
//     Key? key,
//     required this.chatRoomInfo,
//     required this.isLandlord,
//     this.currentUserId,
//     required this.onInfoRefreshed,
//   }) : super(key: key);
//
//   @override
//   State<RoomInfoCard> createState() => _RoomInfoCardState();
// }
//
// class _RoomInfoCardState extends State<RoomInfoCard> {
//   // Create local state to isolate changes
//   late ChatRoomInfo _localChatRoomInfo;
//   StreamSubscription? _chatRoomSubscription;
//
//   @override
//   void initState() {
//     super.initState();
//     _localChatRoomInfo = widget.chatRoomInfo;
//
//     // Listen for chat room info updates from parent
//     _setupChatRoomInfoListener();
//   }
//
//   @override
//   void dispose() {
//     _chatRoomSubscription?.cancel();
//     super.dispose();
//   }
//
//   @override
//   void didUpdateWidget(RoomInfoCard oldWidget) {
//     super.didUpdateWidget(oldWidget);
//
//     // Update local state only if chat room ID or rental request status changes
//     if (widget.chatRoomInfo.chatRoomId != oldWidget.chatRoomInfo.chatRoomId ||
//         widget.chatRoomInfo.rentalRequest?.status != oldWidget.chatRoomInfo.rentalRequest?.status ||
//         widget.chatRoomInfo.chatRoomStatus != oldWidget.chatRoomInfo.chatRoomStatus) {
//       _localChatRoomInfo = widget.chatRoomInfo;
//     }
//   }
//
//   void _setupChatRoomInfoListener() {
//     // Listen for chat room status changes
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       if (context.mounted) {
//         // Cancel previous subscription if it exists
//         _chatRoomSubscription?.cancel();
//
//         // Create new subscription
//         _chatRoomSubscription = context.read<ChatRoomCubit>().stream.listen((state) {
//           if (state is ChatRoomInfoLoaded &&
//               state.chatRoomInfo.chatRoomId == _localChatRoomInfo.chatRoomId) {
//
//             // Only update if there's an actual change in status or rental request
//             bool hasStatusChange = state.chatRoomInfo.chatRoomStatus != _localChatRoomInfo.chatRoomStatus ||
//                 state.chatRoomInfo.rentalRequest?.status != _localChatRoomInfo.rentalRequest?.status;
//
//             if (hasStatusChange && mounted) {
//               if (kDebugMode) {
//                 print('🛠️ RoomInfoCard: Updating local state due to status change');
//                 print('🛠️ Previous status: ${_localChatRoomInfo.chatRoomStatus}, new status: ${state.chatRoomInfo.chatRoomStatus}');
//                 print('🛠️ Previous request status: ${_localChatRoomInfo.rentalRequest?.status}, new request status: ${state.chatRoomInfo.rentalRequest?.status}');
//               }
//
//               setState(() {
//                 _localChatRoomInfo = state.chatRoomInfo;
//               });
//             }
//           }
//         });
//       }
//     });
//   }
//
//   // Handle chat room info refresh locally
//   Future<void> _handleInfoRefresh() async {
//     try {
//       if (kDebugMode) {
//         print('🛠️ RoomInfoCard: Refreshing chat room info locally');
//       }
//
//       // Notify parent widget about requested refresh
//       widget.onInfoRefreshed();
//
//       // Parent's onInfoRefreshed will request info from the cubit
//       // We'll update our local state when listener gets the new data
//     } catch (e) {
//       if (kDebugMode) {
//         print('❌ Error refreshing chat room info: $e');
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     if (kDebugMode) {
//       print('🛠️ RoomInfoCard: Building room info UI for ${_localChatRoomInfo.chatRoomId}');
//     }
//
//     return BlocBuilder<RoomDetailCubit, RoomDetailState>(
//       buildWhen: (previous, current) {
//         bool shouldRebuild =
//             (current is RoomDetailLoaded && previous is! RoomDetailLoaded) ||
//                 (current is RoomDetailError && previous is! RoomDetailError) ||
//                 (current is RoomDetailLoading && previous is! RoomDetailLoading);
//
//         if (kDebugMode && shouldRebuild) {
//           print('🛠️ RoomInfoCard: Rebuilding due to state change: ${previous.runtimeType} -> ${current.runtimeType}');
//         }
//
//         return shouldRebuild;
//       },
//       builder: (context, state) {
//         if (state is RoomDetailLoaded) {
//           return Container(
//             margin: const EdgeInsets.symmetric(horizontal: 16),
//             child: Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(16),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.05),
//                     blurRadius: 8,
//                     spreadRadius: 1,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   // Product chat bubble
//                   ProductChatBubble(
//                     imageUrl: 'https://encrypted-tbn0.gstatic.com/images?q=tbn:ANd9GcThQrcN_jtpZLpMHVpgE_Z9jF4xrWeRXtBO0EkjgAvMF2gsmD-zvN7H3D9YHIo_I7D08vAjaw&s',
//                     roomName: state.room.title,
//                     price: '${state.room.price.toString().replaceAll(RegExp(r'\.0$'), '')} triệu',
//                     address: state.room.address,
//                     onTap: () {
//                       if (_localChatRoomInfo.roomId != null) {
//                         ScaffoldMessenger.of(context).showSnackBar(
//                           SnackBar(content: Text('Xem thông tin phòng ${state.room.title}')),
//                         );
//                       }
//                     },
//                   ),
//
//                   // Thêm thông báo nếu phòng đã được thuê (cho người thuê)
//                   if (state.room.status.toString().contains('RENTED') && !widget.isLandlord)
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       color: const Color(0xFFE8F5E9), // Màu xanh lá nhạt
//                       child: Row(
//                         children: [
//                           Icon(Icons.check_circle_outline, size: 16, color: Colors.green[800]),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               'Bạn đang thuê phòng này',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.green[900],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                   // Thêm thông báo nếu phòng đã được thuê (cho chủ trọ)
//                   if (state.room.status.toString().contains('RENTED') && widget.isLandlord)
//                     Container(
//                       width: double.infinity,
//                       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//                       color: const Color(0xFFE8F5E9), // Màu xanh lá nhạt
//                       child: Row(
//                         children: [
//                           Icon(Icons.check_circle_outline, size: 16, color: Colors.green[800]),
//                           const SizedBox(width: 8),
//                           Expanded(
//                             child: Text(
//                               'Phòng này đã được cho thuê',
//                               style: TextStyle(
//                                 fontSize: 12,
//                                 color: Colors.green[900],
//                                 fontWeight: FontWeight.w500,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),
//
//                   // Action buttons area - Use local version of chat room info
//                   RoomActionArea(
//                     chatRoomInfo: _localChatRoomInfo,
//                     isLandlord: widget.isLandlord,
//                     roomState: state,
//                     currentUserId: widget.currentUserId,
//                     onInfoRefreshed: _handleInfoRefresh,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//
//         if (state is RoomDetailLoading) {
//           return const Padding(
//             padding: EdgeInsets.all(12.0),
//             child: Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2),
//                   ),
//                   SizedBox(height: 8),
//                   Text(
//                     'Đang tải thông tin...',
//                     style: TextStyle(fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//
//         if (state is RoomDetailError) {
//           return Padding(
//             padding: const EdgeInsets.all(12.0),
//             child: Center(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   const Icon(Icons.error_outline, color: Colors.red, size: 24),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Lỗi: ${state.message}',
//                     style: const TextStyle(fontSize: 12),
//                     textAlign: TextAlign.center,
//                   ),
//                   TextButton(
//                     onPressed: () => context.read<RoomDetailCubit>().fetchRoomById(_localChatRoomInfo.roomId!),
//                     style: TextButton.styleFrom(
//                       tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     ),
//                     child: const Text('Thử lại', style: TextStyle(fontSize: 12)),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//
//         // Initial state or any other states
//         return const SizedBox.shrink();
//       },
//     );
//   }
// }
// // Replace the existing ChatRoomStatusListener with a more optimized version
// class ChatRoomStatusListener extends StatelessWidget {
//   final ChatRoomInfo chatRoomInfo;
//   final Function(ChatRoomInfo updatedInfo) onInfoChanged;
//   final Widget child;
//
//   const ChatRoomStatusListener({
//     Key? key,
//     required this.chatRoomInfo,
//     required this.onInfoChanged,
//     required this.child,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     // Use BlocConsumer to ensure we only rebuild when absolutely necessary
//     return BlocConsumer<ChatRoomCubit, ChatRoomState>(
//       listenWhen: (previous, current) {
//         // Only listen when we get ChatRoomInfoLoaded with the current chatRoomId
//         return current is ChatRoomInfoLoaded &&
//             current.chatRoomInfo.chatRoomId == chatRoomInfo.chatRoomId;
//       },
//       listener: (context, state) {
//         if (kDebugMode) {
//           print('📱 ChatRoomStatusListener received state: ${state.runtimeType}');
//         }
//
//         if (state is ChatRoomInfoLoaded) {
//           final updatedInfo = state.chatRoomInfo;
//
//           if (kDebugMode) {
//             print('📱 ChatRoomStatusListener: Processing ChatRoomInfoLoaded');
//             print('📱 Updated rental request status: ${updatedInfo.rentalRequest?.status}');
//             print('📱 Current status: ${chatRoomInfo.rentalRequest?.status}');
//           }
//
//           // Check if there's an actual status change before updating
//           bool hasStatusChange =
//               updatedInfo.chatRoomStatus != chatRoomInfo.chatRoomStatus ||
//                   updatedInfo.rentalRequest?.status != chatRoomInfo.rentalRequest?.status;
//
//           if (hasStatusChange) {
//             if (kDebugMode) {
//               print('📱 ChatRoomStatusListener: Status change detected, notifying parent');
//             }
//             onInfoChanged(updatedInfo);
//           } else {
//             if (kDebugMode) {
//               print('📱 ChatRoomStatusListener: No significant change, skipping update');
//             }
//           }
//         }
//       },
//       buildWhen: (previous, current) {
//         // Never rebuild based on state changes - we're just a listener container
//         return false;
//       },
//       builder: (context, state) {
//         // Always return the child directly without rebuilding
//         return child;
//       },
//     );
//   }
// }
//
// // Replace the existing ChatMessageListener with a more optimized version
// class ChatMessageListener extends StatelessWidget {
//   final Function(ChatMessageState state) onStateChanged;
//   final Widget child;
//
//   const ChatMessageListener({
//     Key? key,
//     required this.onStateChanged,
//     required this.child,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocConsumer<ChatMessageCubit, ChatMessageState>(
//       listenWhen: (previous, current) {
//         // Only listen to error states or specific loading states
//         return current is ChatMessageError ||
//             (current is ChatMessagesLoaded && previous is! ChatMessagesLoaded);
//       },
//       listener: (context, state) {
//         if (kDebugMode) {
//           print('📱 ChatMessageListener: Received state ${state.runtimeType}');
//         }
//         onStateChanged(state);
//       },
//       buildWhen: (previous, current) {
//         // Never rebuild based on state changes - the child MessageListWidget handles this itself
//         return false;
//       },
//       builder: (context, state) {
//         // Always return the child without causing rebuild
//         return child;
//       },
//     );
//   }
// }
//
