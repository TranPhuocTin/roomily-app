import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/data/blocs/chat_message/chat_message.dart';
import 'package:roomily/data/models/chat_message.dart';
import 'package:roomily/data/models/chat_room.dart';
import 'package:roomily/core/services/stomp_service.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/core/services/local_notification_service.dart';
import 'package:roomily/data/models/user.dart';
import 'package:roomily/data/repositories/chat_repository.dart';
import 'package:stomp_dart_client/stomp_dart_client.dart';
import 'package:flutter/material.dart';

import '../../data/blocs/chat_room/chat_room_cubit.dart';
import '../../data/blocs/user/user_cubit.dart';
import '../../data/blocs/user/user_state.dart';
import '../../presentation/screens/chat_detail_screen_v2.dart';

class MessageHandlerService {
  final GetIt _getIt = GetIt.instance;
  final List<StompUnsubscribe> _subscriptions = [];
  
  // Singleton pattern
  static final MessageHandlerService _instance = MessageHandlerService._internal();
  factory MessageHandlerService() => _instance;
  
  // Stream controllers for messaging events
  final _newMessageController = StreamController<ChatMessage>.broadcast();
  final _chatRoomUpdateController = StreamController<ChatRoom>.broadcast();
  final _chatRoomRefreshController = StreamController<String>.broadcast();
  
  // Streams for components to listen to
  Stream<ChatMessage> get onNewMessage => _newMessageController.stream;
  Stream<ChatRoom> get onChatRoomUpdate => _chatRoomUpdateController.stream;
  Stream<String> get onChatRoomRefresh => _chatRoomRefreshController.stream;
  
  // Reference to current active chat room (if any)
  String? _activeChatRoomId;
  
  // Subscriptions
  StreamSubscription? _connectionSubscription;
  StreamSubscription? _authStateSubscription;
  
  // Flag to track initialization status
  bool _isInitialized = false;
  
  // Local notification service
  late LocalNotificationService _localNotificationService;
  
  MessageHandlerService._internal() {
    if (kDebugMode) {
      print('🏗️ MessageHandler: Creating MessageHandlerService instance');
    }
    
    // Initialize local notification service
    _localNotificationService = LocalNotificationService();
  }
  
  // Set active chat room ID when entering chat detail
  void setActiveChatRoom(String? chatRoomId) {
    _activeChatRoomId = chatRoomId;
    if (kDebugMode) {
      print('🔵 MessageHandler: Set active chat room to $chatRoomId');
    }
    
    // Cancel any notifications for this chat room
    if (chatRoomId != null) {
      _localNotificationService.cancelChatRoomNotifications(chatRoomId);
      
      // Subscribe to chat room specific refresh topic
      _setupChatRoomRefreshSubscription(chatRoomId);
    }
  }
  
  // Set up subscription to chat room specific refresh topic
  void _setupChatRoomRefreshSubscription(String chatRoomId) {
    try {
      final stompService = _getIt<StompService>();
      final authService = _getIt<AuthService>();
      
      // Get current user ID
      final userId = authService.userId;
      if (userId == null) {
        if (kDebugMode) {
          print('⚠️ MessageHandler: Cannot subscribe to chat room refresh - userId is null');
        }
        return;
      }
      
      if (!stompService.isConnected) {
        if (kDebugMode) {
          print('⚠️ MessageHandler: Cannot subscribe to chat room refresh - STOMP not connected');
        }
        return;
      }
      
      if (kDebugMode) {
        print('🔌 MessageHandler: Setting up chat room refresh subscription');
        print('🔌 MessageHandler: User ID: $userId');
        print('🔌 MessageHandler: Chat Room ID: $chatRoomId');
      }
      
      // Subscribe to chat room specific refresh topic
      final refreshSubscription = stompService.subscribe(
        '/user/$userId/queue/refresh/$chatRoomId',
        (frame) {
          if (frame.body != null) {
            if (kDebugMode) {
              print('📩 MessageHandler: Received chat room refresh notification');
              print('📩 MessageHandler: Payload: ${frame.body}');
            }
            
            // Handle refresh notification
            _handleChatMessageRefresh(chatRoomId);
          }
        },
      );
      
      _subscriptions.add(refreshSubscription);
      
      if (kDebugMode) {
        print('✅ MessageHandler: Chat room refresh subscription set up successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error setting up chat room refresh subscription: $e');
      }
    }
  }

  void _handleChatMessageRefresh(String chatRoomId) async {
    try {
      if (kDebugMode) {
        print('🔄 MessageHandler: Refreshing chat message for chat room $chatRoomId');
      }
      
      // If this is the active chat room, we need to notify the UI to refresh
      bool isActiveChatRoom = _activeChatRoomId == chatRoomId;
      
      // Add broadcast event to notify listeners about refresh
      _chatRoomRefreshController.add(chatRoomId);
      
      // Only attempt to refresh the chat room list if GetIt has ChatRoomCubit
      if (_getIt.isRegistered<ChatRoomCubit>()) {
        await _getIt<ChatRoomCubit>().refreshChatRoomsInBackground();
        
        // Also refresh the chat room info for the active chat room
        if (isActiveChatRoom) {
          await _getIt<ChatRoomCubit>().getChatRoomInfo(chatRoomId);
        }
      } else if (kDebugMode) {
        print('⚠️ MessageHandler: ChatRoomCubit not registered, skipping refresh');
      }
      
      if (kDebugMode) {
        print('✅ MessageHandler: Successfully triggered refresh for chat room $chatRoomId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error handling chat message refresh: $e');
      }
    }
  }
  
  // Clear active chat room ID when leaving chat detail
  void clearActiveChatRoom() {
    _activeChatRoomId = null;
    if (kDebugMode) {
      print('🔵 MessageHandler: Cleared active chat room');
    }
  }
  
  // Initialize the service and set up subscriptions
  Future<void> initialize() async {
    if (_isInitialized) {
      if (kDebugMode) {
        print('🔄 MessageHandler: Already initialized, skipping initialization');
      }
      return;
    }
    
    if (kDebugMode) {
      print('🚀 MessageHandler: Initializing message handler service');
    }
    
    try {
      // Initialize local notification service
      await _localNotificationService.initialize();
      
      // Listen for auth state changes to handle login/logout
      _setupAuthListener();
      
      // Setup STOMP connection listener
      _setupStompConnectionListener();
      
      // Setup notification tap listener
      _setupNotificationTapListener();
      
      _isInitialized = true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error initializing: $e');
      }
    }
  }
  
  // Setup listener for notification taps
  void _setupNotificationTapListener() {
    _localNotificationService.onNotificationTap.listen((payloadString) {
      if (payloadString != null) {
        try {
          final payloadData = jsonDecode(payloadString);
          if (payloadData['type'] == 'chat_message' && payloadData['chatRoomId'] != null) {
            final chatRoomId = payloadData['chatRoomId'];
            
            // Get current user information from AuthService
            final authService = _getIt<AuthService>();
            final currentUserId = authService.userId;
            final List<String> userRoles = authService.roles;
            final userRole = userRoles.isNotEmpty ? userRoles.first : null;
            
            if (chatRoomId != null && _getIt.isRegistered<ChatRoomCubit>()) {
              // Navigate to chat room detail
              _navigateToChatDetail(chatRoomId, currentUserId, userRole);
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('❌ MessageHandler: Error handling notification tap: $e');
          }
        }
      }
    });
  }
  
  // Navigate to chat detail screen
  void _navigateToChatDetail(String chatRoomId, String? currentUserId, String? userRole) {
    // Get ChatRoomCubit and load chat room info
    final chatRoomCubit = _getIt<ChatRoomCubit>();
    
    // Load the chat room info first (without auto-navigation)
    chatRoomCubit.getChatRoomInfoWithoutNavigation(chatRoomId).then((_) {
      if (kDebugMode) {
        print('🔔 MessageHandler: Successfully loaded chat room info for navigation from notification');
      }
      
      // Verify we have a valid state with chat room info
      if (chatRoomCubit.state is ChatRoomInfoCached) {
        final chatRoomInfo = (chatRoomCubit.state as ChatRoomInfoCached).chatRoomInfo;
        
        // Use navigatorKey from GetIt to navigate
        final navigatorKey = _getIt<GlobalKey<NavigatorState>>();
        final context = navigatorKey.currentContext;
        
        if (context != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatDetailScreenV2(
                chatRoomInfo: chatRoomInfo,
                currentUserId: currentUserId,
                userRole: userRole,
              ),
            ),
          );
          
          if (kDebugMode) {
            print('✅ MessageHandler: Successfully navigated to chat detail from notification');
          }
        } else {
          if (kDebugMode) {
            print('⚠️ MessageHandler: No BuildContext available for navigation');
          }
        }
      } else {
        if (kDebugMode) {
          print('⚠️ MessageHandler: ChatRoomInfo not available in cached state');
          print('Current state: ${chatRoomCubit.state.runtimeType}');
        }
      }
    }).catchError((error) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error loading chat room info: $error');
      }
    });
  }
  
  // Listen to authentication state changes
  void _setupAuthListener() {
    try {
      final authService = _getIt<AuthService>();
      
      _authStateSubscription = authService.authStateChanges.listen((isAuthenticated) {
        if (kDebugMode) {
          print('🔐 MessageHandler: Auth state changed: $isAuthenticated');
        }
        
        if (isAuthenticated) {
          // User just logged in, make sure STOMP is connected
          _connectToStompIfNeeded();
        } else {
          // User logged out, clear subscriptions
          _unsubscribeAll();
        }
      });
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error setting up auth listener: $e');
      }
    }
  }
  
  // Setup STOMP connection listener
  void _setupStompConnectionListener() {
    try {
      final stompService = _getIt<StompService>();
      
      // Connect if not already connected
      _connectToStompIfNeeded();
      
      // Cancel existing subscription if any
      _connectionSubscription?.cancel();
      
      // Listen for connection status
      _connectionSubscription = stompService.connectionStatus.listen((connected) {
        if (connected) {
          _setupSubscriptions();
        } else {
          if (kDebugMode) {
            print('⚠️ MessageHandler: STOMP disconnected');
          }
        }
      });
    } catch (e) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error setting up STOMP connection listener: $e');
      }
    }
  }
  
  // Connect to STOMP if needed
  void _connectToStompIfNeeded() {
    try {
      final stompService = _getIt<StompService>();
      final authService = _getIt<AuthService>();
      
      // Only try to connect if user is authenticated
      if (authService.isAuthenticated) {
        if (!stompService.isConnected) {
          if (kDebugMode) {
            print('🔌 MessageHandler: Connecting to STOMP server');
          }
          stompService.connect();
        } else if (stompService.isConnected) {
          // Already connected, set up subscriptions directly
          _setupSubscriptions();
        }
      } else {
        if (kDebugMode) {
          print('⚠️ MessageHandler: Not connecting to STOMP - user not authenticated');
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error connecting to STOMP: $e');
      }
    }
  }
  
  // Set up subscriptions to user-specific queues
  void _setupSubscriptions() {
    try {
      final stompService = _getIt<StompService>();
      final authService = _getIt<AuthService>();
      
      // Get current user ID
      final userId = authService.userId;
      if (userId == null) {
        if (kDebugMode) {
          print('⚠️ MessageHandler: Cannot subscribe - userId is null');
        }
        return;
      }
      
      if (kDebugMode) {
        print('✅ MessageHandler: STOMP connected, subscribing for userId: $userId');
      }
      
      // Clear any existing subscriptions
      _unsubscribeAll();
      
      // Subscribe to private message queue
      final messageSubscription = stompService.subscribe(
        '/user/$userId/queue/messages',
        (frame) {
          if (frame.body != null) {
            _handleIncomingChatMessage(frame.body!);
          }
        },
      );
      _subscriptions.add(messageSubscription);
      
      // Subscribe to chat room updates
      final chatRoomSubscription = stompService.subscribe(
        '/user/$userId/queue/chat-room',
        (frame) {
          if (frame.body != null) {
            if (kDebugMode) {
              print('📩 MessageHandler: Received chat room update');
            }
            _handleIncomingChatRoomUpdate(frame.body!);
          }
        },
      );
      _subscriptions.add(chatRoomSubscription);
      
      if (kDebugMode) {
        print('✅ MessageHandler: Subscriptions set up successfully');
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error setting up subscriptions: $e');
      }
    }
  }
  
  // Handle incoming chat message from STOMP
  void _handleIncomingChatMessage(String messageBody) {
    try {
      final dynamic jsonData = jsonDecode(messageBody);
      final message = ChatMessage.fromJson(jsonData);
      
      // Phát sự kiện message mới
      _newMessageController.add(message);
      
      // Cập nhật ChatRoomCubit
      if (_getIt.isRegistered<ChatRoomCubit>()) {
        // Thay vì chỉ refresh danh sách, cập nhật thứ tự và badge
        if (message.chatRoomId != null && message.content != null) {
          _getIt<ChatRoomCubit>().handleNewMessageForChatRoom(
            message.chatRoomId!,
            message.content!,
            message.senderId,
          );
        }
        
        // Xử lý riêng cho tất cả system message (senderId = null)
        if (message.senderId == null) {
          if (kDebugMode) {
            print('🏷️ MessageHandler: System message detected: ${message.content}');
          }
          
          // Cập nhật thông tin chi tiết của phòng chat mà không tự động chuyển màn hình
          _getIt<ChatRoomCubit>().getChatRoomInfoWithoutNavigation(message.chatRoomId!);
          
          // Hiển thị thông báo cho system message
          _showNotificationForMessage(message);
        } else {
          // Xử lý thông báo cho tin nhắn thông thường
          _showNotificationForMessage(message);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error processing message: $e');
      }
    }
  }
  
  // Show notification for incoming message
  void _showNotificationForMessage(ChatMessage message) async {
    try {
      // Chỉ hiển thị thông báo khi không ở trong chat room
      if (message.chatRoomId != _activeChatRoomId) {
        String senderName = "";
        String? roomName;
        
        // Lấy thông tin chat room
        if (_getIt.isRegistered<ChatRoomCubit>()) {
          final chatRoomCubit = _getIt<ChatRoomCubit>();
          final state = chatRoomCubit.state;
          
          if (state is ChatRoomLoaded) {
            final chatRoom = state.chatRooms.firstWhere(
              (room) => room.chatRoomId == message.chatRoomId,
              orElse: () => ChatRoom(
                chatRoomId: message.chatRoomId!,
                roomName: "Chat Room",
                unreadCount: 0,
                group: false
              ),
            );
            roomName = chatRoom.roomName;
          }
        }
        
        // Nếu là system message
        if (message.senderId == null) {
          await _localNotificationService.showMessageNotification(
            message,
            "System",
            roomName,
          );
          return;
        }
        
        // Lấy thông tin người gửi
        if (_getIt.isRegistered<UserCubit>()) {
          final userCubit = _getIt<UserCubit>();
          await userCubit.getUserInfoById(message.senderId!);
          
          // Check if we got user info
          if (userCubit.state is UserInfoByIdLoaded) {
            final user = (userCubit.state as UserInfoByIdLoaded).user;
            senderName = user.fullName;
          }
        }
        
        // Hiển thị thông báo
        await _localNotificationService.showMessageNotification(
          message,
          senderName,
          roomName,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error showing notification: $e');
      }
    }
  }
  
  // Handle incoming chat room update from STOMP
  void _handleIncomingChatRoomUpdate(String chatRoomBody) {
    try {
      // Kiểm tra xem nội dung có phải là UUID không
      if (RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false)
          .hasMatch(chatRoomBody)) {
        final String chatRoomId = chatRoomBody;
        
        if (kDebugMode) {
          print('📩 MessageHandler: Received chat room update notification');
          print('📩 MessageHandler: Chat Room ID: $chatRoomId');
          print('📩 MessageHandler: Active Chat Room ID: $_activeChatRoomId');
          print('📩 MessageHandler: Is this the active chat room? ${chatRoomId == _activeChatRoomId}');
        }
        
        // Luồng xử lý realtime cho landlord
        if (_getIt.isRegistered<ChatRoomCubit>()) {
          // 1. Refresh danh sách chat rooms để cập nhật badge và thứ tự
          _getIt<ChatRoomCubit>().refreshChatRoomsInBackground();
          
          // 2. Cập nhật thông tin chi tiết của chat room này để lấy thông tin rental request mới nhất
          final chatRoomCubit = _getIt<ChatRoomCubit>();
          chatRoomCubit.getChatRoomInfoWithoutNavigation(chatRoomId).then((_) {
            if (kDebugMode) {
              print('✅ MessageHandler: Refreshed detailed info for chat room $chatRoomId without navigation');
              
              // Kiểm tra xem có rental request không
              final state = chatRoomCubit.state;
              if (state is ChatRoomInfoCached) {
                final hasRentalRequest = state.chatRoomInfo.rentalRequest != null;
                final requestStatus = state.chatRoomInfo.rentalRequest?.status;
                print('📋 MessageHandler: Has rental request: $hasRentalRequest');
                if (hasRentalRequest) {
                  print('📋 MessageHandler: Request status: $requestStatus');
                }
              }
            }
          });
          
          // 3. Nếu chat room này đang được mở, cần thông báo cho người dùng
          if (chatRoomId == _activeChatRoomId) {
            if (kDebugMode) {
              print('🔔 MessageHandler: Active chat room updated, notifying UI');
            }
            
            // Có thể hiển thị toast/snackbar ở đây nếu cần
            // Không cần làm gì vì _ChatRoomInfoHandler trong ChatDetailScreenV2 
            // đã lắng nghe state của ChatRoomCubit và sẽ tự cập nhật UI
          }
        }
        return;
      }

      // Nếu không phải UUID, xử lý như JSON
      final dynamic jsonData = jsonDecode(chatRoomBody);
      final chatRoom = ChatRoom.fromJson(jsonData);
      
      if (kDebugMode) {
        print('📩 MessageHandler: Received chat room update: ${chatRoom.roomName}');
      }
      
      // Send to stream for components that are listening
      _chatRoomUpdateController.add(chatRoom);
      
      // Update chat room list
      if (_getIt.isRegistered<ChatRoomCubit>()) {
        if (kDebugMode) {
          print('✅ MessageHandler: Refreshing ChatRoomCubit after room update');
        }
        _getIt<ChatRoomCubit>().refreshChatRoomsInBackground();
      }
      
    } catch (e) {
      if (kDebugMode) {
        print('❌ MessageHandler: Error processing chat room update: $e');
      }
    }
  }
  
  // Clean up all subscriptions
  void _unsubscribeAll() {
    if (_subscriptions.isNotEmpty) {
      if (kDebugMode) {
        print('🧹 MessageHandler: Clearing ${_subscriptions.length} subscriptions');
      }
      
      for (final unsubscribe in _subscriptions) {
        unsubscribe();
      }
      _subscriptions.clear();
    }
  }
  
  // Dispose resources
  void dispose() {
    if (kDebugMode) {
      print('♻️ MessageHandler: Disposing MessageHandlerService');
    }
    
    _unsubscribeAll();
    _connectionSubscription?.cancel();
    _authStateSubscription?.cancel();
    
    if (!_newMessageController.isClosed) {
      _newMessageController.close();
    }
    
    if (!_chatRoomUpdateController.isClosed) {
      _chatRoomUpdateController.close();
    }
    
    // Close refresh controller when disposing
    if (!_chatRoomRefreshController.isClosed) {
      _chatRoomRefreshController.close();
    }
    
    _localNotificationService.dispose();
  }
} 