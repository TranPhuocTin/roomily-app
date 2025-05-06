import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'dart:async';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

// Models
import 'package:roomily/data/models/chat_message.dart';
import 'package:roomily/data/models/chat_room_info.dart';
import 'package:roomily/data/models/find_partner_post.dart';
import 'package:roomily/data/models/user.dart';

// Services
import 'package:roomily/core/services/message_handler_service.dart';
import 'package:get_it/get_it.dart';

// Repositories
import 'package:roomily/data/repositories/chat_repository_impl.dart';
import 'package:roomily/data/repositories/find_partner_repository_impl.dart';
import 'package:roomily/data/repositories/user_repository.dart';

// Widgets & UI
import 'package:roomily/core/config/text_styles.dart';
import 'package:roomily/core/config/app_colors.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/presentation/widgets/chat/pinned_property_card.dart';
import 'package:roomily/presentation/widgets/chat/room_info_card.dart';
import 'package:roomily/presentation/widgets/chat/room_action_area.dart';
import 'package:roomily/presentation/widgets/chat/find_partner_action_area.dart';
import 'package:roomily/core/services/auth_service.dart';

import '../../data/blocs/chat_message/chat_message_cubit.dart';
import '../../data/blocs/chat_message/chat_message_state.dart';
import '../../data/blocs/chat_room/chat_room_cubit.dart';
import '../../data/blocs/find_partner/find_partner_cubit.dart';
import '../../data/blocs/find_partner/find_partner_state.dart';
import '../../data/blocs/home/room_detail_cubit.dart';
import '../../data/blocs/home/room_detail_state.dart';
import '../../data/blocs/payment/payment_cubit.dart';
import '../../data/blocs/payment/payment_state.dart';
import '../../data/blocs/user/user_cubit.dart';
import '../../data/blocs/user/user_state.dart';
import '../../data/repositories/payment_repository_impl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../data/blocs/home/room_image_cubit.dart';
import '../../data/blocs/home/room_image_state.dart';
import '../../data/repositories/room_image_repository_impl.dart';

class ChatDetailScreenV2 extends StatefulWidget {
  final ChatRoomInfo chatRoomInfo;
  final bool isAdConversation;
  final String? adClickId;
  final String? currentUserId;
  final String? userRole;

  const ChatDetailScreenV2({
    Key? key,
    required this.chatRoomInfo,
    this.isAdConversation = false,
    this.adClickId,
    this.currentUserId,
    this.userRole,
  }) : super(key: key);

  @override
  State<ChatDetailScreenV2> createState() => _ChatDetailScreenV2State();
}

class _ChatDetailScreenV2State extends State<ChatDetailScreenV2> {
  // State map để lưu trữ và tái sử dụng các Cubit theo chatRoomId
  static final Map<String, ChatMessageCubit> _chatMessageCubitCache = {};

  // User cache to store user profiles by user ID
  final Map<String, User> _userCache = {};
  late UserCubit _userCubit;

  // Messaging state
  final TextEditingController _messageController = TextEditingController();

  // UI state
  bool _showPropertyCard = true;
  bool _isSendingMessage = false;

  // Scroll controller for infinite scroll
  final ScrollController _scrollController = ScrollController();

  // Message handler
  StreamSubscription? _messageSubscription;
  // Add subscription for refresh events
  StreamSubscription? _refreshSubscription;

  // Store a local copy of ChatRoomInfo to manage state updates efficiently
  late ChatRoomInfo _chatRoomInfo;

  // Cubit hiện tại cho màn hình này
  late ChatMessageCubit _chatMessageCubit;

  @override
  void initState() {
    super.initState();

    // Initialize with provided chat room info
    _chatRoomInfo = widget.chatRoomInfo;

    if (kDebugMode) {
      print('📱 ChatDetailScreenV2 - initState');
      print('📱 Chat Room ID: ${_chatRoomInfo.chatRoomId}');
      print('📱 Current User ID: ${widget.currentUserId}');
      print('📱 Initial Room Status: ${_chatRoomInfo.chatRoomStatus}');
    }

    // Initialize User Cubit
    _userCubit = UserCubit(userRepository: GetIt.instance<UserRepository>());

    // Sử dụng hoặc tạo mới ChatMessageCubit từ cache
    _initializeMessageCubit();

    // Setup message handling
    _setupMessageHandling();

    // Setup scrolling for pagination
    _setupScrolling();

    // Load initial room data if needed
    _loadRoomData();
  }

  void _initializeMessageCubit() {
    // Always create a new instance instead of using cache
    _chatMessageCubit = ChatMessageCubit(
      ChatRepositoryImpl(dio: DioConfig.createDio()),
    );
    
    // Load initial messages
    _chatMessageCubit.loadMessages(_chatRoomInfo.chatRoomId);

    if (kDebugMode) {
      print('🆕 Created new ChatMessageCubit for room ${_chatRoomInfo.chatRoomId}');
    }
  }

  void _setupMessageHandling() {
    // Set this chat room as active in MessageHandlerService
    final messageHandler = GetIt.instance<MessageHandlerService>();
    messageHandler.setActiveChatRoom(_chatRoomInfo.chatRoomId);

    // Subscribe to new messages from queue
    _messageSubscription =
        messageHandler.onNewMessage.listen(_handleNewMessage);
        
    // Subscribe to refresh events
    _refreshSubscription = messageHandler.onChatRoomRefresh.listen(_handleRefreshEvent);
  }
  
  // Add new handler for refresh events
  void _handleRefreshEvent(String chatRoomId) {
    if (chatRoomId == _chatRoomInfo.chatRoomId && mounted) {
      if (kDebugMode) {
        print('🔄 ChatDetailScreenV2: Received refresh event for current chat room');
      }
      
      // Reload messages
      _chatMessageCubit.loadMessages(_chatRoomInfo.chatRoomId);
    }
  }

  void _handleNewMessage(ChatMessage message) {
    if (message.chatRoomId == _chatRoomInfo.chatRoomId && mounted) {
      if (kDebugMode) {
        print('📨 New message received');
        print('📨 Sender ID: ${message.senderId}');
        if (message.senderId == null) {
          print('🔔 System message detected: ${message.content}');
        }
      }

      // Xử lý tất cả tin nhắn, bao gồm cả system message
      final state = _chatMessageCubit.state;
      if (state is ChatMessagesLoaded) {
        if (!state.messages.any((m) => m.id == message.id)) {
          _chatMessageCubit.emit(ChatMessagesLoaded(
            messages: [message, ...state.messages],
            hasReachedMax: state.hasReachedMax,
            oldestMessageId: state.oldestMessageId,
            oldestTimestamp: state.oldestTimestamp,
          ));

          // If it's a system message, refresh chat room info
          if (message.senderId == null) {
            if (kDebugMode) {
              print('🔄 Refreshing chat room info after system message');
            }
            Future.microtask(() {
              if (mounted) {
                context
                    .read<ChatRoomCubit>()
                    .getChatRoomInfo(_chatRoomInfo.chatRoomId);
              }
            });
          }
        }
      }
    }
  }

  void _setupScrolling() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        _loadMoreMessages();
      }
    });
  }

  void _loadMoreMessages() {
    if (_chatMessageCubit.state is ChatMessagesLoaded &&
        !(_chatMessageCubit.state as ChatMessagesLoaded).hasReachedMax) {
      _chatMessageCubit.loadMoreMessages(_chatRoomInfo.chatRoomId);
    }
  }

  void _loadRoomData() {
    if (_chatRoomInfo.roomId != null && _chatRoomInfo.roomId!.isNotEmpty) {
      context.read<RoomDetailCubit>().fetchRoomById(_chatRoomInfo.roomId!);
    }
  }

  Future<void> _sendMessage() async {
    final messageText = _messageController.text.trim();
    if (messageText.isEmpty || _isSendingMessage) return;

    setState(() {
      _isSendingMessage = true;
    });

    final String senderId = widget.currentUserId ?? 'unknown';

    try {
      await _chatMessageCubit.sendMessage(
        content: messageText,
        senderId: senderId,
        chatRoomId: _chatRoomInfo.chatRoomId,
        isAdConversion: widget.isAdConversation,
        adClickId: widget.adClickId,
      );

      // Clear the input field on successful sending
      _messageController.clear();
    } catch (e) {
      if (kDebugMode) {
        print('❌ ERROR SENDING MESSAGE: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSendingMessage = false;
        });
      }
    }
  }

  bool get _isLandlord => widget.currentUserId == _chatRoomInfo.managerId;

  bool get _shouldShowRoomInfo =>
      _chatRoomInfo.roomId != null && _chatRoomInfo.roomId!.isNotEmpty;

  bool get _shouldShowRoomToggle => _shouldShowRoomInfo;

  @override
  void dispose() {
    // Clear active chat room reference and unsubscribe
    final messageHandler = GetIt.instance<MessageHandlerService>();
    if (kDebugMode) {
      print('♻️ ChatDetailScreenV2: Disposing - clearing active chat room ${_chatRoomInfo.chatRoomId}');
    }
    messageHandler.clearActiveChatRoom();

    // Clear user cache when leaving chat
    _userCache.clear();

    _messageController.dispose();
    _scrollController.removeListener(_loadMoreMessages);
    _scrollController.dispose();
    _messageSubscription?.cancel();
    // Cancel refresh subscription
    _refreshSubscription?.cancel();

    // Dispose the ChatMessageCubit since we're not caching it anymore
    _chatMessageCubit.close();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _chatMessageCubit),
      ],
      child: BlocListener<ChatRoomCubit, ChatRoomState>(
        listenWhen: (previous, current) {
          final shouldUpdate = current is ChatRoomInfoLoaded &&
              current.chatRoomInfo.chatRoomId == _chatRoomInfo.chatRoomId;
          if (kDebugMode && shouldUpdate) {
            print('🔄 ChatDetailScreenV2: State update detected');
            print('Previous state: ${previous.runtimeType}');
            print('Current state: ${current.runtimeType}');
          }
          return shouldUpdate;
        },
        listener: (context, state) {
          if (state is ChatRoomInfoLoaded) {
            if (kDebugMode) {
              print('👂 ChatDetailScreenV2: Processing new ChatRoomInfo');
              print('Room Status: ${state.chatRoomInfo.chatRoomStatus}');
            }

            setState(() {
              _chatRoomInfo = state.chatRoomInfo;
            });
          }
        },
        child: PopScope(
          canPop: true,
          onPopInvoked: (didPop) async {
            await context.read<ChatRoomCubit>().getChatRooms();
          },
          child: Scaffold(
            body: _buildChatBody(),
          ),
        ),
      ),
    );
  }

  Widget _buildChatBody() {
    // Use theme colors exactly like ChatRoomScreen
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = const Color(0xFF00C6FF); // Bright blue accent
    
    return Stack(
      children: [
        // Background
        _ChatBackground(),
        // Background gradient


        // Hidden component to handle chat room updates
        _ChatRoomInfoHandler(
          chatRoomId: _chatRoomInfo.chatRoomId,
          onChatRoomInfoUpdated: (newInfo) {
            if (kDebugMode) {
              print('ℹ️ ChatRoomInfoHandler: Received updated chat room info');
            }
            _chatRoomInfo = newInfo;
          },
        ),

        // Content with matching header color and style to ChatRoomScreen
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Modern gradient background exactly like ChatRoomScreen
            Container(
              height: MediaQuery.of(context).padding.top + 80, // Height for status bar + header
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
            
            // Decorative circle element exactly like ChatRoomScreen
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
            
            // Main content
            Column(
              children: [
                // Colored top area that extends under the status bar
                Container(
                  height: MediaQuery.of(context).padding.top,
                  color: Colors.transparent, // Transparent to show gradient background
                ),
                Expanded(
                  child: SafeArea(
                    bottom: true,
                    top: false, // We're manually handling the top padding
                    child: Column(
                      children: [
                        // Header
                        _ChatHeader(
                          roomName: _chatRoomInfo.roomName,
                          roomType: _chatRoomInfo.chatRoomType,
                          onBackPressed: () {
                            context.read<ChatRoomCubit>().getChatRooms();
                            Navigator.pop(context);
                          },
                          primaryColor: primaryColor,
                          accentColor: accentColor,
                        ),

                        const SizedBox(height: 5,),

                        // Room visibility toggle
                        if (_shouldShowRoomToggle)
                          _RoomVisibilityToggle(
                            isVisible: _showPropertyCard,
                            onToggle: () =>
                                setState(() => _showPropertyCard = !_showPropertyCard),
                          ),

                        // Main content area
                        Expanded(
                          child: Column(
                            children: [
                              // Room info card (if visible)
                              if (_showPropertyCard && _shouldShowRoomInfo)
                                _buildRoomInfoCard(),

                              // Messages
                              Expanded(
                                child: _buildMessageList(),
                              ),
                            ],
                          ),
                        ),

                        // Input field
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          child: _ChatInputField(
                            controller: _messageController,
                            isSending: _isSendingMessage,
                            onSend: _sendMessage,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildRoomInfoCard() {
    if (kDebugMode) {
      print('🏗️ ChatDetailScreenV2: Building RoomInfoCard');
    }
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: _RoomInfoCard(
        chatRoomInfo: _chatRoomInfo,
        isLandlord: _isLandlord,
        currentUserId: widget.currentUserId,
        onInfoRefreshed: () => context
            .read<ChatRoomCubit>()
            .getChatRoomInfo(_chatRoomInfo.chatRoomId),
      ),
    );
  }

  Widget _buildMessageList() {
    if (kDebugMode) {
      print('📝 ChatDetailScreenV2: Building MessageList');
    }

    // Sử dụng MessageListManager để tách biệt completely
    return MessageListManager(
      key: ValueKey('msg_manager_${_chatRoomInfo.chatRoomId}'),
      chatRoomId: _chatRoomInfo.chatRoomId,
      currentUserId: widget.currentUserId,
      scrollController: _scrollController,
      chatMessageCubit: _chatMessageCubit,
      getUserProfile: getUserProfile,
      userCache: _userCache,
    );
  }

  // Method to get user from cache or load from API
  Future<User?> getUserProfile(String userId) async {
    // Return from cache if already loaded
    if (_userCache.containsKey(userId)) {
      if (kDebugMode) {
        print('👤 Using cached user profile for ID: $userId');
      }
      return _userCache[userId];
    }

    // Load from API if not in cache
    if (kDebugMode) {
      print('🔍 Loading user profile for ID: $userId');
    }

    await _userCubit.getUserInfoById(userId);

    // Check if user info was loaded successfully
    if (_userCubit.state is UserInfoByIdLoaded) {
      final user = (_userCubit.state as UserInfoByIdLoaded).user;
      // Cache the user profile
      _userCache[userId] = user;
      return user;
    }

    return null;
  }
}

// Add a new widget to handle chat room info updates
class _ChatRoomInfoHandler extends StatelessWidget {
  final String chatRoomId;
  final Function(ChatRoomInfo) onChatRoomInfoUpdated;

  const _ChatRoomInfoHandler({
    required this.chatRoomId,
    required this.onChatRoomInfoUpdated,
  });

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChatRoomCubit, ChatRoomState>(
      listenWhen: (previous, current) {
        final shouldUpdate = current is ChatRoomInfoLoaded &&
            current.chatRoomInfo.chatRoomId == chatRoomId;
        if (kDebugMode && shouldUpdate) {
          print('🔄 ChatRoomInfoHandler: State update detected');
          print('Previous state: ${previous.runtimeType}');
          print('Current state: ${current.runtimeType}');
        }
        return shouldUpdate;
      },
      listener: (context, state) {
        if (state is ChatRoomInfoLoaded) {
          if (kDebugMode) {
            print('👂 ChatRoomInfoHandler: Processing new ChatRoomInfo');
            print('Room Status: ${state.chatRoomInfo.chatRoomStatus}');
          }

          // Notify parent about the update
          onChatRoomInfoUpdated(state.chatRoomInfo);

          // Force a rebuild of action areas if status has changed
          if (state.chatRoomInfo.chatRoomStatus != null) {
            Future.microtask(() {
              if (context.mounted) {
                context.read<ChatRoomCubit>().emit(state);
              }
            });
          }
        }
      },
      child: const SizedBox.shrink(), // Invisible widget
    );
  }
}

// Background widget
class _ChatBackground extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Background image
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Image.asset(
            'assets/images/chat_background.jpg',
            fit: BoxFit.cover,
          ),
        ),
        // Gradient overlay for better readability
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.9),
                  Colors.white.withValues(alpha: 0.7 ),
                  Colors.white.withValues(alpha: 0.85),
                  Colors.white.withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// Header widget
class _ChatHeader extends StatelessWidget {
  final String roomName;
  final ChatRoomType roomType;
  final VoidCallback onBackPressed;
  final Color primaryColor;
  final Color accentColor;

  const _ChatHeader({
    required this.roomName,
    required this.roomType,
    required this.onBackPressed,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.transparent, // Transparent to show gradient from parent
      ),
      child: Row(
        children: [
          // Back button with animation - styled exactly like ChatRoomScreen
          Hero(
            tag: 'back_button',
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onBackPressed,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        spreadRadius: 1,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.arrow_back_ios_rounded,
                    size: 16,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Tooltip(
                  message: roomName,
                  child: Text(
                    roomName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 0.5,
                      shadows: [
                        Shadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatRoomType(roomType),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w400,
                  ),
                  maxLines: 1,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRoomType(ChatRoomType type) {
    switch (type) {
      case ChatRoomType.DIRECT:
        return 'Tin nhắn trực tiếp';
      case ChatRoomType.GROUP:
        return 'Nhóm chat';
      default:
        return type.toString().split('.').last;
    }
  }
}

// Room visibility toggle
class _RoomVisibilityToggle extends StatelessWidget {
  final bool isVisible;
  final VoidCallback onToggle;

  const _RoomVisibilityToggle({
    required this.isVisible,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: GestureDetector(
        onTap: onToggle,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.only(bottom: 8, right: 16),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isVisible 
                ? const Color(0xFF234F68).withOpacity(0.12) 
                : const Color(0xFF234F68).withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF234F68).withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isVisible ? Icons.visibility_off : Icons.visibility,
                size: 16,
                color: const Color(0xFF234F68),
              ),
              const SizedBox(width: 4),
              Text(
                isVisible ? 'Hide room info' : 'Show room info',
                style: AppTextStyles.bodySmallMedium.copyWith(
                  color: const Color(0xFF234F68),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Room info card
class _RoomInfoCard extends StatelessWidget {
  final ChatRoomInfo chatRoomInfo;
  final bool isLandlord;
  final String? currentUserId;
  final VoidCallback onInfoRefreshed;

  const _RoomInfoCard({
    required this.chatRoomInfo,
    required this.isLandlord,
    this.currentUserId,
    required this.onInfoRefreshed,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RoomDetailCubit, RoomDetailState>(
      builder: (context, state) {
        if (state is RoomDetailLoaded) {
          return BlocProvider(
            create: (context) {
              final roomId = state.room.id;
              final roomImageCubit = RoomImageCubit(RoomImageRepositoryImpl());
              if (roomId != null && roomId.isNotEmpty) {
                roomImageCubit.fetchRoomImages(roomId);
              }
              return roomImageCubit;
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    spreadRadius: 1,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Product chat bubble with RoomImageCubit integration
                  BlocBuilder<RoomImageCubit, RoomImageState>(
                    builder: (context, imageState) {
                      String? imageUrl;

                      // Use the first image from RoomImageCubit if available
                      if (imageState is RoomImageLoaded &&
                          imageState.images.isNotEmpty) {
                        imageUrl = imageState.images.first.url;
                      }

                      return ProductChatBubble(
                        imageUrl: imageUrl,
                        roomName: state.room.title,
                        price:
                            '${state.room.price.toString().replaceAll(RegExp(r'\.0$'), '')} triệu',
                        address: state.room.address,
                        onTap: () {
                          if (chatRoomInfo.roomId != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'View details of ${state.room.title}')),
                            );
                          }
                        },
                      );
                    },
                  ),

                  // Room status indicator (if any)
                  if (state.room.status.toString().contains('RENTED'))
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      color: const Color(0xFFE8F5E9),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 16, color: Colors.green[800]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              isLandlord
                                  ? 'This room is currently rented'
                                  : 'You are renting this room',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green[900],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Replace placeholder with actual RoomActionArea
                  Container(
                    width: double.infinity,
                    padding:
                        const EdgeInsets.symmetric(vertical: 0, horizontal: 0),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(16),
                        bottomRight: Radius.circular(16),
                      ),
                    ),
                    child: _buildActionWidget(context),
                  ),
                ],
              ),
            ),
          );
        }

        if (state is RoomDetailLoading) {
          return const Padding(
            padding: EdgeInsets.all(16.0),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildActionWidget(BuildContext context) {
    // Kiểm tra xem chat room có liên quan đến find partner post không
    bool isFindPartnerChat = chatRoomInfo.findPartnerPostId != null &&
        chatRoomInfo.findPartnerPostId!.isNotEmpty &&
        chatRoomInfo.chatRoomType == ChatRoomType.DIRECT;

    if (isFindPartnerChat) {
      // Sử dụng FindPartnerCubit để xác định isPostOwner
      final findPartnerCubit = FindPartnerCubit(
        FindPartnerRepositoryImpl(dio: DioConfig.createDio()),
      );

      // Tạo phiên bản FindPartnerActionArea với isPostOwner ban đầu là false
      // và cập nhật lại sau khi có kết quả từ API
      return BlocProvider(
        create: (context) =>
            findPartnerCubit..getFindPartnersForRoom(chatRoomInfo.roomId ?? ''),
        child: BlocBuilder<FindPartnerCubit, FindPartnerState>(
          builder: (context, state) {
            bool isPostOwner = false;
            FindPartnerPost? findPartnerPost;

            // Kiểm tra nếu đang trong trạng thái loading, hiển thị indicator
            if (state is FindPartnerLoading) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 8.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  ),
                ),
              );
            }

            if (state is FindPartnerLoaded && state.posts.isNotEmpty) {
              // Tìm bài đăng tương ứng với findPartnerPostId trong chatRoomInfo
              try {
                findPartnerPost = state.posts.firstWhere(
                  (post) =>
                      post.findPartnerPostId == chatRoomInfo.findPartnerPostId,
                );
              } catch (e) {
                // Không tìm thấy bài đăng phù hợp
                findPartnerPost = null;
              }

              // Kiểm tra nếu người dùng hiện tại là người đăng bài
              if (findPartnerPost != null && currentUserId != null) {
                isPostOwner = currentUserId == findPartnerPost.posterId;
              }
            }

            return FindPartnerActionArea(
              chatRoomInfo: chatRoomInfo,
              findPartnerPost: findPartnerPost,
              isPostOwner: isPostOwner,
              currentUserId: currentUserId,
              onInfoRefreshed: onInfoRefreshed,
            );
          },
        ),
      );
    } else {
      // Sử dụng RoomActionArea thông thường cho các trường hợp khác
      return RoomActionArea(
        chatRoomInfo: chatRoomInfo,
        isLandlord: isLandlord,
        currentUserId: currentUserId,
        onInfoRefreshed: onInfoRefreshed,
      );
    }
  }
}

// Message list
class _OptimizedMessageList extends StatefulWidget {
  final List<ChatMessage> messages;
  final String? currentUserId;
  final bool isLoadingMore;
  final ScrollController scrollController;
  final Future<User?> Function(String) getUserProfile;
  final Map<String, User> userCache;

  const _OptimizedMessageList({
    Key? key,
    required this.messages,
    this.currentUserId,
    required this.isLoadingMore,
    required this.scrollController,
    required this.getUserProfile,
    required this.userCache,
  }) : super(key: key);

  @override
  State<_OptimizedMessageList> createState() => _OptimizedMessageListState();
}

class _OptimizedMessageListState extends State<_OptimizedMessageList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Stack(
      children: [
        ListView.builder(
          controller: widget.scrollController,
          padding: const EdgeInsets.all(16),
          reverse: true,
          itemCount: widget.messages.length,
          itemBuilder: (context, index) {
            final message = widget.messages[index];
            final bool isMe = message.senderId == widget.currentUserId;
            final bool isSystem = message.senderId == null;

            // For a reversed list, we need to check the next message (which is the previous in time)
            final bool showSenderName = !isMe &&
                (
                    // First message or different sender from the next message
                    index == widget.messages.length - 1 ||
                        message.senderId !=
                            widget.messages[index + 1].senderId);

            if (isSystem) {
              return _buildSystemMessage(message);
            }

            return _buildUserMessage(message, isMe,
                showSenderName: showSenderName);
          },
        ),
        if (widget.isLoadingMore)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              color: Colors.black12,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF234F68),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSystemMessage(ChatMessage message) {
    final String messageContent = message.content ?? '';
    Color bgColor = Colors.grey[100]!;
    Color textColor = Colors.black87;
    Color? borderColor = Colors.grey[300];
    IconData? iconData;

    if (messageContent.contains('accepted')) {
      bgColor = const Color(0xFFEDF7ED);
      textColor = const Color(0xFF1E8E3E);
      borderColor = const Color(0xFF81C784);
      iconData = Icons.check_circle_outline;
    } else if (messageContent.contains('rejected') ||
        messageContent.contains('canceled')) {
      bgColor = const Color(0xFFFDEFEF);
      textColor = const Color(0xFFD32F2F);
      borderColor = const Color(0xFFEF9A9A);
      iconData = Icons.cancel_outlined;
    } else if (messageContent.contains('pending')) {
      bgColor = const Color(0xFFFFF8E1);
      textColor = const Color(0xFFFF8F00);
      borderColor = const Color(0xFFFFCC80);
      iconData = Icons.hourglass_empty;
    } else if (messageContent.contains('sent')) {
      bgColor = const Color(0xFFE3F2FD);
      textColor = const Color(0xFF1976D2);
      borderColor = const Color(0xFF90CAF9);
      iconData = Icons.send;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor!, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
              spreadRadius: 1,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            if (iconData != null) ...[
              Icon(
                iconData,
                color: textColor,
                size: 32,
              ),
              const SizedBox(height: 12),
            ],
            Text(
              message.displayMessage,
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMediumMedium.copyWith(
                color: textColor,
                height: 1.4,
              ),
            ),
            if (message.metadata != null) ...[
              const SizedBox(height: 16),
              _QRCodeMessage(checkoutId: message.metadata!),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildUserMessage(ChatMessage message, bool isMe,
      {bool showSenderName = true}) {
    // Reverse the bubble colors - Make sender (isMe) messages blue and receiver messages light
    final Color bubbleColor = isMe 
        ? const Color(0xFF1A73E8)  // Changed: Now blue for sender (was light)
        : const Color(0xFFE3F2FD); // Changed: Now light for receiver (was blue)
    final Color textColor = isMe 
        ? Colors.white           // Changed: Now white for sender (was dark)
        : const Color(0xFF234F68); // Changed: Now dark for receiver (was white)

    // Load user profile for this message if sender ID is available
    final String senderId = message.senderId ?? 'unknown';

    // Check if message contains an image
    final bool hasImage = message.image != null && message.image!.isNotEmpty;
    final bool hasTextContent = message.content != null && message.content != 'Image' && message.content!.isNotEmpty;

    return FutureBuilder<User?>(
        future: widget.getUserProfile(senderId),
        builder: (context, snapshot) {
          final User? userProfile = snapshot.data ?? widget.userCache[senderId];
          final String displayName = userProfile?.fullName ?? senderId;

          // Check if profile picture is valid
          String? profilePicture = userProfile?.profilePicture;
          final bool hasValidProfilePicture =
              profilePicture != null && profilePicture.trim().isNotEmpty;

          return Padding(
            padding: EdgeInsets.only(bottom: showSenderName ? 16 : 6),
            child: Column(
              crossAxisAlignment:
                  isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                // Name displayed above the message for non-user messages
                if (!isMe && showSenderName)
                  Padding(
                    padding: const EdgeInsets.only(left: 40, bottom: 4),
                    child: Text(
                      displayName,
                      style: AppTextStyles.bodySmallSemiBold.copyWith(
                        color: AppColors.grey700,
                      ),
                    ),
                  ),

                // Message content with avatar
                Row(
                  mainAxisAlignment:
                      isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start, // Changed from end to start
                  children: [
                    // Avatar for receiver
                    if (!isMe)
                      _buildAvatar(
                        hasValidProfilePicture: hasValidProfilePicture,
                        profilePicture: profilePicture,
                      ),
                    
                    if (!isMe) const SizedBox(width: 8),
                    
                    // Message content
                    Flexible(
                      child: Column(
                        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                        children: [
                          // Text bubble
                          if (hasTextContent)
                            _buildTextBubble(
                              message: message,
                              isMe: isMe,
                              bubbleColor: bubbleColor,
                              textColor: textColor,
                              showSenderName: showSenderName,
                            ),
                          
                          // Timestamp - Now shown outside the bubble
                          if (hasTextContent)
                            Padding(
                              padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                              child: _buildTimestamp(
                                message: message,
                                isMe: isMe,
                              ),
                            ),
                          
                          // Image content
                          if (hasImage)
                            Column(
                              crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (hasTextContent) const SizedBox(height: 8),
                                _buildImageContent(
                                  context: context,
                                  imageUrl: message.image!,
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(top: 4, left: 4, right: 4),
                                  child: _buildTimestamp(
                                    message: message,
                                    isMe: isMe,
                                    isImageOnly: !hasTextContent,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    
                    if (isMe) const SizedBox(width: 8),
                    
                    // Avatar for sender
                    if (isMe)
                      _buildCurrentUserAvatar(),
                  ],
                ),
              ],
            ),
          );
        });
  }
  
  Widget _buildAvatar({
    required bool hasValidProfilePicture,
    required String? profilePicture,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.grey300,
        backgroundImage: hasValidProfilePicture
            ? NetworkImage(profilePicture!)
            : AssetImage('assets/images/default_avatar.png') as ImageProvider,
        onBackgroundImageError: (_, __) {
          // Handle error
        },
        child: !hasValidProfilePicture
            ? Icon(Icons.person, size: 16, color: Colors.white)
            : null,
      ),
    );
  }
  
  Widget _buildCurrentUserAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CircleAvatar(
        radius: 16,
        backgroundColor: AppColors.grey300,
        backgroundImage: widget.userCache.containsKey(widget.currentUserId ?? '')
            ? _getProfileImage(widget.userCache[widget.currentUserId!]?.profilePicture)
            : _getDefaultAvatar(widget.currentUserId ?? 'Me', isCurrentUser: true),
        onBackgroundImageError: (_, __) {
          // Fallback handling
        },
        child: _isValidProfilePicture(widget.userCache[widget.currentUserId ?? '']?.profilePicture)
            ? null
            : Icon(Icons.person, size: 16, color: Colors.white),
      ),
    );
  }
  
  Widget _buildTextBubble({
    required ChatMessage message,
    required bool isMe,
    required Color bubbleColor,
    required Color textColor,
    required bool showSenderName,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bubbleColor,
        borderRadius: BorderRadius.circular(18).copyWith(
          bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
          bottomLeft: !isMe ? const Radius.circular(4) : const Radius.circular(18),
          topLeft: !isMe && !showSenderName ? const Radius.circular(6) : null,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        message.displayMessage,
        style: AppTextStyles.bodyMediumRegular.copyWith(
          color: textColor,
        ),
      ),
    );
  }
  
  Widget _buildImageContent({
    required BuildContext context,
    required String imageUrl,
  }) {
    return GestureDetector(
      onTap: () {
        // Image viewing functionality could be added here
      },
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.65,
          maxHeight: 250,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              spreadRadius: 1,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            imageUrl,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Container(
                width: 200,
                height: 200,
                color: Colors.grey[200],
                child: Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded / 
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 2,
                  ),
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) {
              return Container(
                width: 150,
                height: 150,
                color: Colors.grey[200],
                child: const Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        ),
      ),
    );
  }
  
  Widget _buildTimestamp({
    required ChatMessage message,
    required bool isMe,
    bool isImageOnly = false,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        Text(
          _formatTimestamp(message.timestamp),
          style: AppTextStyles.bodyXSmallRegular.copyWith(
            color: AppColors.grey600,
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 4),
          Icon(
            message.read == true ? Icons.done_all : Icons.done,
            size: 12,
            color: message.read == true
                ? const Color(0xFF4CAF50)
                : AppColors.grey500,
          ),
        ],
      ],
    );
  }
  
  // Helper method to check if a profile picture is valid
  bool _isValidProfilePicture(String? profilePicture) {
    return profilePicture != null && profilePicture.trim().isNotEmpty;
  }

  // Helper method to get a profile image
  ImageProvider _getProfileImage(String? profilePicture) {
    if (_isValidProfilePicture(profilePicture)) {
      try {
        return NetworkImage(profilePicture!);
      } catch (e) {
        if (kDebugMode) {
          print('Error loading profile image: $e');
        }
        return AssetImage('assets/images/default_avatar.png');
      }
    }
    return AssetImage('assets/images/default_avatar.png');
  }

  // Helper method to get a default avatar
  ImageProvider _getDefaultAvatar(String userId, {bool isCurrentUser = false}) {
    final String background = isCurrentUser ? 'E8F0FE' : 'random';
    final String color = isCurrentUser ? '1A73E8' : 'FFFFFF';
    return NetworkImage(
        'https://ui-avatars.com/api/?name=${Uri.encodeComponent(userId)}&background=$background&color=$color');
  }

  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Sending...';

    try {
      final DateTime dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

      final timeString =
          '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

      if (messageDate == today) {
        return timeString;
      } else if (messageDate == today.subtract(const Duration(days: 1))) {
        return 'Yesterday, $timeString';
      } else {
        return '${dateTime.day}/${dateTime.month}, $timeString';
      }
    } catch (e) {
      return timestamp;
    }
  }
}

class _QRCodeMessage extends StatelessWidget {
  final String checkoutId;

  const _QRCodeMessage({
    Key? key,
    required this.checkoutId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentCubit(
        paymentRepository: PaymentRepositoryImpl(),
      )..getCheckout(checkoutId: checkoutId),
      child: BlocBuilder<PaymentCubit, PaymentResponseState>(
        builder: (context, state) {
          if (state is PaymentResponseLoading) {
            return const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          if (state is PaymentResponseSuccess) {
            final payment = state.paymentResponse;
            return Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        spreadRadius: 0,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: payment.qrCode,
                        version: QrVersions.auto,
                        size: 250.0,
                        backgroundColor: Colors.white,
                        padding: const EdgeInsets.all(8),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Số tiền: ${_formatAmount(payment.amount)} VNĐ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Mã đơn: ${payment.orderCode}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF1A73E8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'STK: ${payment.accountNumber}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Tên TK: ${payment.accountName}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      if (payment.expireAt != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Hết hạn: ${_formatExpireTime(payment.expireAt!)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            );
          }

          if (state is PaymentResponseFailure) {
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Không thể tải mã QR: ${state.error}',
                      style: TextStyle(color: Colors.red[700]),
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      context
                          .read<PaymentCubit>()
                          .getCheckout(checkoutId: checkoutId);
                    },
                    child: const Text('Thử lại'),
                  ),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  String _formatExpireTime(String expireAt) {
    try {
      final expireDate = DateTime.parse(expireAt);
      final now = DateTime.now();
      final difference = expireDate.difference(now);

      if (difference.inHours > 24) {
        return '${difference.inDays} ngày ${difference.inHours % 24} giờ';
      } else if (difference.inHours > 0) {
        return '${difference.inHours} giờ ${difference.inMinutes % 60} phút';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes} phút';
      } else {
        return 'Đã hết hạn';
      }
    } catch (e) {
      return expireAt;
    }
  }

  String _formatAmount(int amount) {
    final formatted = amount.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (match) => '${match[1]},');
    return formatted;
  }
}

// Input field
class _ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _ChatInputField({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  State<_ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<_ChatInputField> {
  File? _selectedImage;
  
  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    final accentColor = const Color(0xFF00C6FF);
    
    return Card(
      elevation: 8,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Selected image preview
          if (_selectedImage != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 8, right: 8, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100, // Fixed square width
                        height: 100, // Fixed square height
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: Colors.grey[100],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(
                            _selectedImage!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 4,
                        right: 4,
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Expanded(child: Container()), // Spacer
                ],
              ),
            ),
          
          Container(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white,
                  Colors.grey.shade50,
                ],
              ),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withOpacity(0.08),
                  blurRadius: 10,
                  spreadRadius: -2,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Media attachment button
                _buildIconButton(
                  context,
                  icon: Icons.add_circle_outline_rounded,
                  onPressed: () {
                    // Show attachment options
                    _showAttachmentOptions(context);
                  },
                  color: accentColor,
                ),
                
                // Text input field
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: TextField(
                      controller: widget.controller,
                      decoration: InputDecoration(
                        hintText: _selectedImage != null 
                            ? 'Thêm mô tả (không bắt buộc)' 
                            : 'Nhập tin nhắn...',
                        hintStyle: AppTextStyles.bodyMediumRegular.copyWith(
                          color: AppColors.grey400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                        isDense: true,
                      ),
                      onSubmitted: (_) => _handleSend(),
                      style: AppTextStyles.bodyMediumRegular.copyWith(
                        color: AppColors.grey800,
                      ),
                      maxLines: 5,
                      minLines: 1,
                      cursorColor: primaryColor,
                      textCapitalization: TextCapitalization.sentences,
                    ),
                  ),
                ),
                
                // Send button with animation
                AnimatedSendButton(
                  isSending: widget.isSending,
                  onSend: _handleSend,
                  primaryColor: primaryColor,
                  accentColor: accentColor,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend() {
    if (_selectedImage != null) {
      _sendImageWithMessage();
    } else if (widget.controller.text.trim().isNotEmpty) {
      widget.onSend();
    }
  }

  Future<void> _sendImageWithMessage() async {
    if (_selectedImage == null) return;
    
    // Get the ChatMessageCubit and necessary parameters
    final chatMessageCubit = context.read<ChatMessageCubit>();
    final chatDetailState = context.findAncestorStateOfType<_ChatDetailScreenV2State>();
    
    if (chatDetailState != null) {
      final String senderId = chatDetailState.widget.currentUserId ?? 'unknown';
      final String chatRoomId = chatDetailState._chatRoomInfo.chatRoomId;
      
      try {
        // Set sending state through the parent widget
        chatDetailState.setState(() {
          chatDetailState._isSendingMessage = true;
        });
        
        // Convert File to base64 for sending
        final bytes = await _selectedImage!.readAsBytes();
        final base64Image = base64Encode(bytes);
        
        // Get message text (if any)
        final String messageText = widget.controller.text.trim();
        
        // Send message with image
        await chatMessageCubit.sendMessage(
          content: messageText.isNotEmpty ? messageText : 'Image', // Use text input if available
          senderId: senderId,
          chatRoomId: chatRoomId,
          isAdConversion: false,
          adClickId: null,
          image: base64Image, // Pass the base64 encoded image
        );
        
        // Clear the input field and selected image on successful sending
        widget.controller.clear();
        setState(() {
          _selectedImage = null;
        });
      } catch (e) {
        if (kDebugMode) {
          print('❌ ERROR SENDING IMAGE MESSAGE: $e');
        }
        // Show error snackbar
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Không thể gửi hình ảnh: $e')),
          );
        }
      } finally {
        // Reset sending state
        if (chatDetailState.mounted) {
          chatDetailState.setState(() {
            chatDetailState._isSendingMessage = false;
          });
        }
      }
    }
  }

  Widget _buildIconButton(
    BuildContext context, {
    required IconData icon,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(
            icon,
            color: color,
            size: 24,
          ),
        ),
      ),
    );
  }

  void _showAttachmentOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => AttachmentOptionsSheet(
        onImageSelected: (File image) {
          Navigator.pop(context); // Close the bottom sheet immediately
          
          // Update state to show the selected image in the input field
          setState(() {
            _selectedImage = image;
          });
        },
      ),
    );
  }
}

// Updated Attachment options sheet
class AttachmentOptionsSheet extends StatelessWidget {
  final Function(File) onImageSelected;

  AttachmentOptionsSheet({
    Key? key,
    required this.onImageSelected,
  }) : super(key: key);

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(BuildContext context, ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        imageQuality: 70, // Reduce quality to save bandwidth
      );
      
      if (pickedFile != null) {
        onImageSelected(File(pickedFile.path));
        // No need to call Navigator.pop here as it's now handled in the parent
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error picking image: $e');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Không thể chọn hình ảnh: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = [
      {
        'icon': Icons.image_rounded,
        'label': 'Hình ảnh',
        'color': Colors.blue,
        'onTap': () => _pickImage(context, ImageSource.gallery),
      },
      {
        'icon': Icons.camera_alt_rounded,
        'label': 'Camera',
        'color': Colors.purple,
        'onTap': () => _pickImage(context, ImageSource.camera),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      // Wrap content in a SingleChildScrollView to prevent overflow
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
            margin: const EdgeInsets.only(bottom: 20),
          ),
          Text(
            'Đính kèm',
            style: AppTextStyles.bodyLargeSemiBold.copyWith(color: AppColors.grey800),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: options.map((option) => _buildAttachmentOption(
              context,
              icon: option['icon'] as IconData,
              label: option['label'] as String,
              color: option['color'] as Color,
              onTap: option['onTap'] as Function(),
            )).toList(),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildAttachmentOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color color,
    required Function() onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTextStyles.bodySmallRegular.copyWith(color: AppColors.grey700),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
      ),
    );
  }
}

// MessageListManager class
class MessageListManager extends StatefulWidget {
  final String chatRoomId;
  final String? currentUserId;
  final ScrollController scrollController;
  final ChatMessageCubit chatMessageCubit;
  final Future<User?> Function(String) getUserProfile;
  final Map<String, User> userCache;

  const MessageListManager({
    Key? key,
    required this.chatRoomId,
    this.currentUserId,
    required this.scrollController,
    required this.chatMessageCubit,
    required this.getUserProfile,
    required this.userCache,
  }) : super(key: key);

  @override
  State<MessageListManager> createState() => _MessageListManagerState();
}

class _MessageListManagerState extends State<MessageListManager>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return BlocProvider.value(
      value: widget.chatMessageCubit,
      child: BlocConsumer<ChatMessageCubit, ChatMessageState>(
        listenWhen: (previous, current) {
          // Chỉ phản ứng khi trạng thái thực sự thay đổi
          if (previous is ChatMessagesLoaded && current is ChatMessagesLoaded) {
            return previous.messages.length != current.messages.length;
          }
          return previous.runtimeType != current.runtimeType;
        },
        listener: (context, state) {
          if (state is ChatMessageError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${state.error}')),
            );
          }
        },
        buildWhen: (previous, current) {
          // Tối ưu hóa việc rebuild bằng cách chỉ rebuild khi state thay đổi đáng kể
          if (previous is ChatMessagesLoaded && current is ChatMessagesLoaded) {
            return previous.messages.length != current.messages.length;
          }
          return previous.runtimeType != current.runtimeType;
        },
        builder: (context, state) {
          if (state is ChatMessagesLoading && state.isFirstLoad) {
            if (kDebugMode) {
              print(
                  '⏳ MessageListManager: MessageList is loading (first load)');
            }
            return const Center(child: CircularProgressIndicator());
          } else if (state is ChatMessagesLoaded) {
            if (kDebugMode) {
              print(
                  '✅ MessageListManager: MessageList is loaded with ${state.messages.length} messages');
            }
            return RepaintBoundary(
              child: _OptimizedMessageList(
                key: ValueKey(
                    'message_list_${widget.chatRoomId}_${state.messages.length}'),
                messages: state.messages,
                currentUserId: widget.currentUserId,
                isLoadingMore: state is ChatMessagesLoading
                    ? !(state as ChatMessagesLoading).isFirstLoad
                    : false,
                scrollController: widget.scrollController,
                getUserProfile: widget.getUserProfile,
                userCache: widget.userCache,
              ),
            );
          } else if (state is ChatMessageError) {
            if (kDebugMode) {
              print('❌ MessageListManager: MessageList error: ${state.error}');
            }
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading messages: ${state.error}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () =>
                        widget.chatMessageCubit.loadMessages(widget.chatRoomId),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else {
            if (kDebugMode) {
              print('ℹ️ MessageListManager: MessageList has no messages');
            }
            return const Center(child: Text('No messages'));
          }
        },
      ),
    );
  }

  @override
  void didUpdateWidget(MessageListManager oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Không load lại messages khi chatRoomId không thay đổi
    if (oldWidget.chatRoomId != widget.chatRoomId) {
      widget.chatMessageCubit.loadMessages(widget.chatRoomId);
    }
  }
}

// Animated Send Button Component
class AnimatedSendButton extends StatelessWidget {
  final bool isSending;
  final VoidCallback onSend;
  final Color primaryColor;
  final Color accentColor;

  const AnimatedSendButton({
    Key? key,
    required this.isSending,
    required this.onSend,
    required this.primaryColor,
    required this.accentColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isSending ? null : onSend,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: 45,
        height: 45,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              primaryColor,
              accentColor,
            ],
          ),
          borderRadius: BorderRadius.circular(25),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.4),
              blurRadius: 8,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: isSending
              ? const Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                )
              : Center(
                  child: Transform.rotate(
                    angle: -0.5, // Slight rotation for style
                    child: const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
