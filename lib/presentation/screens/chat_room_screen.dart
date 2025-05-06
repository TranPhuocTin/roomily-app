import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/presentation/screens/chat_detail_screen_v2.dart';
import 'package:roomily/presentation/widgets/home/header_widget.dart';
import 'package:roomily/presentation/widgets/chat/chat_item_widget.dart';
import 'package:roomily/presentation/widgets/chat/delete_chat_bottom_sheet.dart';
import 'package:roomily/data/repositories/chat_room_repository.dart';
import 'package:roomily/data/repositories/chat_room_repository_impl.dart';
import 'package:roomily/data/models/chat_room.dart';
import 'package:roomily/data/models/chat_room_info.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/message_handler_service.dart';

import '../../data/blocs/auth/auth_cubit.dart';
import '../../data/blocs/auth/auth_state.dart';
import '../../data/blocs/chat_room/chat_room_cubit.dart';
import '../../data/blocs/user/user_cubit.dart';
import '../../data/blocs/user/user_state.dart';

class ChatRoomScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // LUÔN làm mới danh sách chat room khi màn hình được xây dựng
    // Điều này đảm bảo khi chuyển đổi role, dữ liệu luôn được cập nhật
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatRoomCubit>().refreshChatRooms();
    });
    
    return ChatRoomView();
  }
}

class ChatRoomView extends StatefulWidget {
  @override
  _ChatRoomViewState createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends State<ChatRoomView> with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  bool _isNavigating = false; // Add flag to prevent multiple navigations
  bool _pendingNavigation = false; // Flag to track when navigation should occur
  
  // Animation controllers
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  bool get wantKeepAlive => true; // Giữ trạng thái khi chuyển tab

  @override
  void initState() {
    super.initState();
    // Gọi lần đầu khi khởi tạo widget
    _refreshChatRooms();
    
    // Initialize animations
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );
    
    _fadeController.forward();
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  // Thêm phương thức để làm mới dữ liệu
  void _refreshChatRooms() {
    // Lấy thông tin người dùng hiện tại
    final authState = context.read<AuthCubit>().state;
    final userId = authState.userId;
    final roles = authState.roles;
    
    // Log để debug
    debugPrint('🔄 Làm mới chat rooms - UserId: $userId, Roles: $roles');
    
    // Luôn gọi refreshChatRooms thay vì getChatRooms để đảm bảo dữ liệu mới nhất
    context.read<ChatRoomCubit>().refreshChatRooms();
  }

  // Thêm phương thức didChangeDependencies để đảm bảo dữ liệu được load khi quay lại
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Kiểm tra trạng thái xác thực
    final authState = context.read<AuthCubit>().state;
    if (authState.status == AuthStatus.authenticated) {
      // Làm mới dữ liệu mỗi khi dependencies thay đổi hoặc khi quay lại tab này
      _refreshChatRooms();
    }
  }

  // Hiển thị dialog loading mới với thiết kế đẹp hơn
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
                strokeWidth: 3,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Đang tải dữ liệu...',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Vui lòng đợi trong giây lát',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Xử lý khi click vào chat item
  void _handleChatItemTap(BuildContext context, ChatRoom chat) {
    debugPrint('🔔 ChatRoomScreen: Tapped on chat room ${chat.chatRoomId}');
    
    // Reset số tin nhắn chưa đọc
    if (chat.unreadCount > 0) {
      context.read<ChatRoomCubit>().resetUnreadCount(chat.chatRoomId);
    }
    
    // Subscribe to the specific chat room via MessageHandlerService
    try {
      final messageHandlerService = GetIt.instance<MessageHandlerService>();
      debugPrint('🔔 ChatRoomScreen: Setting up subscription for chat room ${chat.chatRoomId}');
      messageHandlerService.setActiveChatRoom(chat.chatRoomId);
    } catch (e) {
      debugPrint('❌ ChatRoomScreen: Error setting up chat room subscription: $e');
    }
    
    // Set pending navigation flag to true
    _pendingNavigation = true;
    // Gọi API để lấy thông tin chat room
    context.read<ChatRoomCubit>().getChatRoomInfo(chat.chatRoomId);
  }

  // Navigation method extracted for better organization
  void _navigateToChatDetail(BuildContext context, ChatRoomInfo chatRoomInfo) {
    if (!_isNavigating && mounted) {
      _isNavigating = true;
      
      // Get current state from AuthCubit
      final authState = context.read<AuthCubit>().state;
      
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ChatDetailScreenV2(
            chatRoomInfo: chatRoomInfo,
            currentUserId: authState.userId,
            userRole: authState.isLandlord ? AuthCubit.ROLE_LANDLORD : AuthCubit.ROLE_TENANT,
          ),
        ),
      ).then((_) {
        // Reset the navigation flag when returning from the pushed screen
        if (mounted) {
          _isNavigating = false;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Cần thiết cho AutomaticKeepAliveClientMixin
    
    // Define theme colors for consistent UI
    final primaryColor = Theme.of(context).primaryColor;
    final primaryLight = Color.lerp(primaryColor, Colors.white, 0.7);
    final accentColor = Color(0xFF00C6FF); // Bright blue accent
    
    return MultiBlocListener(
      listeners: [
        // Listener for chat room info - decoupled from navigation
        BlocListener<ChatRoomCubit, ChatRoomState>(
          listenWhen: (previous, current) {
            // Only listen for ChatRoomInfoLoaded, ChatRoomInfoCached or ChatRoomInfoError states
            return current is ChatRoomInfoLoaded || current is ChatRoomInfoCached || current is ChatRoomInfoError;
          },
          listener: (context, state) {
            if (state is ChatRoomInfoLoaded) {
              // Store chat room info but don't navigate automatically
              // This allows other parts of the app to trigger the navigation when needed
              context.read<ChatRoomCubit>().setCachedChatRoomInfo(state.chatRoomInfo);
              
              if (_pendingNavigation) {
                _pendingNavigation = false;
                _navigateToChatDetail(context, state.chatRoomInfo);
              }
            } else if (state is ChatRoomInfoError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.white),
                      SizedBox(width: 12),
                      Expanded(child: Text('Lỗi: ${state.message}')),
                    ],
                  ),
                  backgroundColor: Colors.redAccent,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  margin: EdgeInsets.all(12),
                ),
              );
            }
          },
        ),
      ],
      child: Scaffold(
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            // Modern gradient background
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    primaryColor,
                    Color.lerp(primaryColor, accentColor, 0.7) ?? accentColor,
                  ],
                  stops: const [0.3, 1.0],
                ),
              ),
            ),
            
            // Decorative elements
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 50,
                      spreadRadius: 20,
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
            ),
            
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    // Enhanced header with animations
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'chat_icon',
                            child: Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Image.asset(
                                'assets/icons/message_active_icon.png',
                                width: 26,
                                height: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tin nhắn',
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                    letterSpacing: 0.5,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.1),
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Trò chuyện với chủ nhà và người thuê trọ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.white.withOpacity(0.9),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ],
                            ),
                          ),

                        ],
                      ),
                    ),
                    
                    // Chat content container with enhanced design
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.only(top: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.08),
                              blurRadius: 15,
                              offset: Offset(0, -3),
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(32),
                            topRight: Radius.circular(32),
                          ),
                          child: BlocBuilder<ChatRoomCubit, ChatRoomState>(
                            buildWhen: (previous, current) {
                              // Chỉ rebuild khi các state liên quan đến danh sách chat room
                              if (current is ChatRoomLoaded || current is ChatRoomLoading || 
                                  current is ChatRoomError || current is ChatRoomInitial) {
                                return true;
                              }
                              // Không rebuild khi là các state liên quan đến thông tin chat room
                              return false;
                            },
                            builder: (context, state) {
                              if (state is ChatRoomLoading || state is ChatRoomInfoLoading) {
                                return _buildLoadingState();
                              } else if (state is ChatRoomError) {
                                return _buildErrorState(state, context);
                              } else if (state is ChatRoomLoaded) {
                                final chatRooms = state.chatRooms;
                                
                                if (chatRooms.isEmpty) {
                                  return _buildEmptyState();
                                }
                                
                                return _buildChatList(chatRooms);
                              } else {
                                return _buildInitialState();
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Refined UI components
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Đang tải tin nhắn...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Color(0xFF424242),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(ChatRoomError state, BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Color(0xFFFFEBEE),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: Colors.redAccent,
              size: 48,
            ),
          ),
          const SizedBox(height: 28),
          Text(
            'Không thể tải tin nhắn',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Lỗi: ${state.message}',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              context.read<ChatRoomCubit>().refreshChatRooms();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Thử lại'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 2,
              shadowColor: Theme.of(context).primaryColor.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor.withOpacity(0.08),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).primaryColor.withOpacity(0.05),
                  blurRadius: 30,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 64,
              color: Theme.of(context).primaryColor.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 36),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50),
            child: Text(
              'Bắt đầu cuộc trò chuyện với chủ nhà hoặc người thuê ngay hôm nay!',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 15,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInitialState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Đang khởi tạo...',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildChatList(List<ChatRoom> chatRooms) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatRoomCubit>().refreshChatRooms();
      },
      color: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      displacement: 40,
      strokeWidth: 3,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
        itemCount: chatRooms.length,
        physics: const AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final chat = chatRooms[index];
          // Create staggered animation for list items
          return AnimatedBuilder(
            animation: _fadeController,
            builder: (context, child) {
              // Stagger animation based on index
              final delay = index * 0.1;
              final startValue = delay;
              final endValue = 1.0;
              final animValue = _fadeController.value;
              
              // Calculate the current value based on controller and delay
              final progress = (animValue - startValue) / (endValue - startValue);
              final opacity = progress.clamp(0.0, 1.0);
              final offset = (1 - opacity) * 30;
              
              if (opacity <= 0) return const SizedBox.shrink();
              
              return Transform.translate(
                offset: Offset(0, offset),
                child: Opacity(
                  opacity: opacity,
                  child: child,
                ),
              );
            },
            child: _buildChatItem(chat, context),
          );
        },
      ),
    );
  }
  
  Widget _buildChatItem(ChatRoom chat, BuildContext context) {
    // Kiểm tra xem có senderId không
    final String? senderId = chat.lastMessageSender;
    
    // Nếu có senderId, sử dụng UserCubit để lấy thông tin người dùng
    if (senderId != null && senderId.isNotEmpty) {
      // Gọi API lấy thông tin người dùng
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.read<UserCubit>().getUserInfoById(senderId);
      });
      
      // Sử dụng BlocBuilder để lắng nghe kết quả từ UserCubit
      return BlocBuilder<UserCubit, UserInfoState>(
        buildWhen: (previous, current) {
          // Chỉ rebuild khi có thông tin người dùng được tải và ID khớp với senderId
          return (current is UserInfoByIdLoaded && 
                 (current as UserInfoByIdLoaded).user.id == senderId);
        },
        builder: (context, state) {
          String displayName = chat.roomName;
          
          // Nếu đã lấy được thông tin người dùng
          if (state is UserInfoByIdLoaded && state.user.id == senderId) {
            // Sử dụng tên người dùng thay vì tên phòng
            displayName = state.user.fullName;
            // Debug log
            debugPrint('📝 Hiển thị tên người gửi: ${displayName} cho chatRoom: ${chat.chatRoomId}');
          } else {
            debugPrint('📝 Chưa có thông tin người gửi, sử dụng tên phòng: ${chat.roomName}');
          }
          
          return _buildChatItemContent(chat, context, displayName);
        },
      );
    }
    
    // Nếu không có senderId, sử dụng roomName làm displayName
    debugPrint('📝 Không có senderId, sử dụng tên phòng: ${chat.roomName}');
    return _buildChatItemContent(chat, context, chat.roomName);
  }
  
  // Tách phần nội dung thành phương thức riêng để tái sử dụng
  Widget _buildChatItemContent(ChatRoom chat, BuildContext context, String displayName) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Dismissible(
        key: Key(chat.chatRoomId),
        direction: DismissDirection.endToStart,
        background: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFFF5D6B), Color(0xFFFF3A53)],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.delete_outline_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Xóa',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        confirmDismiss: (direction) async {
          return await showModalBottomSheet<bool>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (BuildContext context) {
              return DeleteChatBottomSheet(
                name: displayName, // Sử dụng displayName thay vì chat.roomName
              );
            },
          );
        },
        onDismissed: (direction) {
          // _deleteChat(context, chat.chatRoomId);
        },
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(24),
            onTap: () => _handleChatItemTap(context, chat),
            child: Ink(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ChatItemWidget(
                name: displayName, // Sử dụng displayName thay vì chat.roomName
                message: chat.lastMessage ?? '',
                isOnline: false,
                avatar: '',
                lastMessageTime: chat.lastMessageTime,
                unreadCount: chat.unreadCount,
                lastMessageSender: chat.lastMessageSender,
                isGroup: chat.group,
                chatRoomId: chat.chatRoomId,
              ),
            ),
          ),
        ),
      ),
    );
  }
}