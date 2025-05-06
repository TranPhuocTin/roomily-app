import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:roomily/data/repositories/chat_room_repository.dart';
import 'package:roomily/data/models/chat_room.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:roomily/data/models/chat_room_info.dart';

import '../auth/auth_aware_cubit.dart';

// Chat Room State
abstract class ChatRoomState extends Equatable {
  const ChatRoomState();

  @override
  List<Object?> get props => [];
}

class ChatRoomInitial extends ChatRoomState {}

class ChatRoomLoading extends ChatRoomState {}

class ChatRoomLoaded extends ChatRoomState {
  final List<ChatRoom> chatRooms;

  const ChatRoomLoaded(this.chatRooms);

  @override
  List<Object?> get props => [chatRooms];
}

class ChatRoomError extends ChatRoomState {
  final String message;

  const ChatRoomError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatRoomInfoLoading extends ChatRoomState {}

class ChatRoomInfoLoaded extends ChatRoomState {
  final ChatRoomInfo chatRoomInfo;

  const ChatRoomInfoLoaded(this.chatRoomInfo);

  @override
  List<Object?> get props => [chatRoomInfo];
}

class ChatRoomInfoError extends ChatRoomState {
  final String message;

  const ChatRoomInfoError(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatRoomInfoCached extends ChatRoomState {
  final ChatRoomInfo chatRoomInfo;

  const ChatRoomInfoCached(this.chatRoomInfo);

  @override
  List<Object?> get props => [chatRoomInfo];
}

class ChatRoomCubit extends AuthAwareCubit<ChatRoomState> {
  final ChatRoomRepository repository;
  // Keep a cache of chat rooms to maintain state across navigation
  List<ChatRoom> _cachedChatRooms = [];
  // Cache for chat room info
  ChatRoomInfo? _cachedChatRoomInfo;
  
  ChatRoomCubit({
    required this.repository,
  }) : super(ChatRoomInitial()) {
    // Nếu đã xác thực, tự động làm mới chat rooms
    if (isAuthenticated && userId != null) {
      if (kDebugMode) {
        print('🔄 [ChatRoomCubit] Auto-refreshing chat rooms with userId: $userId');
      }
      refreshChatRooms();
    }
  }

  @override
  void onAuthenticated() {
    if (kDebugMode) {
      print('✅ [ChatRoomCubit] User đã xác thực - userId: $userId');
    }
    refreshChatRooms();
  }
  
  @override
  void onUnauthenticated() {
    if (kDebugMode) {
      print('🔄 [ChatRoomCubit] User đã đăng xuất - xóa cache');
    }
    _cachedChatRooms = [];
    emit(ChatRoomInitial());
  }
  
  @override
  void onUserDataChanged(Map<String, dynamic> userData) {
    if (kDebugMode) {
      print('🔄 [ChatRoomCubit] Dữ liệu người dùng đã thay đổi - userId: ${userData['userId']}');
    }
    refreshChatRooms();
  }

  Future<void> getChatRooms() async {
    if (kDebugMode) {
      print('🔄 [ChatRoomCubit] Đang lấy danh sách chat rooms - userId: $userId, isAuthenticated: $isAuthenticated');
    }
    
    // Kiểm tra xác thực trước
    if (!isAuthenticated || userId == null) {
      if (kDebugMode) {
        print('⚠️ [ChatRoomCubit] Bỏ qua việc làm mới chat rooms - user chưa xác thực');
      }
      emit(ChatRoomLoaded([]));
      return;
    }
    
    // Nếu đã có cache, trả về ngay và refresh ngầm
    if (_cachedChatRooms.isNotEmpty && state is! ChatRoomLoaded) {
      emit(ChatRoomLoaded(_cachedChatRooms));
      _refreshChatRoomsInBackground();
      return;
    }

    // Nếu đã load rồi, chỉ refresh ngầm
    if (state is ChatRoomLoaded) {
      _refreshChatRoomsInBackground();
      return;
    }

    // Load lần đầu hoặc refresh có hiển thị loading
    emit(ChatRoomLoading());
    
    final result = await repository.getChatRooms();
    
    result.when(
      success: (chatRooms) {
        _cachedChatRooms = chatRooms;
        emit(ChatRoomLoaded(chatRooms));
      },
      failure: (error) => emit(ChatRoomError(error)),
    );
  }

  // Helper method to refresh data without showing loading state
  Future<void> _refreshChatRoomsInBackground() async {
    // Check authentication before making API call
    if (!isAuthenticated || userId == null) {
      if (kDebugMode) {
        print('⚠️ [ChatRoomCubit] Bỏ qua việc làm mới ngầm chat rooms - user chưa xác thực');
      }
      return;
    }
    
    // Lưu lại trạng thái unreadCount của các phòng chat hiện tại
    Map<String, int> unreadCountMap = {};
    if (state is ChatRoomLoaded) {
      final currentRooms = (state as ChatRoomLoaded).chatRooms;
      for (var room in currentRooms) {
        if (room.unreadCount > 0) {
          unreadCountMap[room.chatRoomId] = room.unreadCount;
        }
      }
    }
    
    final result = await repository.getChatRooms();
    
    result.when(
      success: (chatRooms) {
        // Nếu có dữ liệu unreadCount đã lưu, ưu tiên sử dụng chúng
        if (unreadCountMap.isNotEmpty) {
          final updatedRooms = chatRooms.map((room) {
            if (unreadCountMap.containsKey(room.chatRoomId)) {
              // Nếu phòng này có trong map unreadCount, sử dụng giá trị đã lưu
              return ChatRoom(
                chatRoomId: room.chatRoomId,
                roomName: room.roomName,
                lastMessage: room.lastMessage,
                lastMessageTime: room.lastMessageTime,
                lastMessageSender: room.lastMessageSender,
                unreadCount: unreadCountMap[room.chatRoomId]!, // Giữ nguyên unreadCount
                group: room.group,
              );
            }
            return room; // Trả về nguyên bản nếu không có trong map
          }).toList();
          
          _cachedChatRooms = updatedRooms; // Update cache
          // Only update if we're still in a loaded state
          if (state is ChatRoomLoaded) {
            emit(ChatRoomLoaded(updatedRooms));
          }
        } else {
          _cachedChatRooms = chatRooms; // Update cache
          // Only update if we're still in a loaded state
          if (state is ChatRoomLoaded) {
            emit(ChatRoomLoaded(chatRooms));
          }
        }
      },
      failure: (_) {
        // Ignore failures during background refresh
      },
    );
  }

  // Public method for background refresh without showing loading state
  Future<void> refreshChatRoomsInBackground() async {
    return _refreshChatRoomsInBackground();
  }

  // Force a refresh, showing loading state
  Future<void> refreshChatRooms() async {
    try {
      if (kDebugMode) {
        print('🔄 [ChatRoomCubit] Đang làm mới chat rooms...');
      }
      
      // Kiểm tra xác thực trước
      if (!isAuthenticated || userId == null) {
        if (kDebugMode) {
          print('⚠️ [ChatRoomCubit] Bỏ qua việc làm mới chat rooms - user chưa xác thực');
        }
        emit(ChatRoomLoaded([]));
        return;
      }
      
      // Lưu lại trạng thái unreadCount của các phòng chat hiện tại
      Map<String, int> unreadCountMap = {};
      if (state is ChatRoomLoaded) {
        final currentRooms = (state as ChatRoomLoaded).chatRooms;
        for (var room in currentRooms) {
          if (room.unreadCount > 0) {
            unreadCountMap[room.chatRoomId] = room.unreadCount;
          }
        }
      }
      
      emit(ChatRoomLoading());

      final result = await repository.getChatRooms();

      result.when(
        success: (chatRooms) {
          // Nếu có dữ liệu unreadCount đã lưu, ưu tiên sử dụng chúng
          if (unreadCountMap.isNotEmpty) {
            final updatedRooms = chatRooms.map((room) {
              if (unreadCountMap.containsKey(room.chatRoomId)) {
                // Nếu phòng này có trong map unreadCount, sử dụng giá trị đã lưu
                return ChatRoom(
                  chatRoomId: room.chatRoomId,
                  roomName: room.roomName,
                  lastMessage: room.lastMessage,
                  lastMessageTime: room.lastMessageTime,
                  lastMessageSender: room.lastMessageSender,
                  unreadCount: unreadCountMap[room.chatRoomId]!, // Giữ nguyên unreadCount
                  group: room.group,
                );
              }
              return room; // Trả về nguyên bản nếu không có trong map
            }).toList();
            
            _cachedChatRooms = updatedRooms;
            emit(ChatRoomLoaded(updatedRooms));
          } else {
            _cachedChatRooms = chatRooms;
            emit(ChatRoomLoaded(chatRooms));
          }
        },
        failure: (error) {
          // If we have cached data, use it instead of showing error
          if (_cachedChatRooms.isNotEmpty) {
            emit(ChatRoomLoaded(_cachedChatRooms));
          } else {
            emit(ChatRoomError(error));
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ChatRoomCubit] Lỗi làm mới chat rooms: $e');
      }
      
      // If we have cached data, use it instead of showing error
      if (_cachedChatRooms.isNotEmpty) {
        emit(ChatRoomLoaded(_cachedChatRooms));
      } else {
        emit(ChatRoomError(e.toString()));
      }
    }
  }

  // Update a single chat room in the list
  void updateChatRoom(ChatRoom updatedChatRoom) {
    if (state is ChatRoomLoaded) {
      final chatRooms = List<ChatRoom>.from((state as ChatRoomLoaded).chatRooms);
      
      final index = chatRooms.indexWhere((room) => room.chatRoomId == updatedChatRoom.chatRoomId);
      if (index == -1) {
        chatRooms.add(updatedChatRoom);
        if (kDebugMode) {
          print('🔄 [ChatRoomCubit] Đã thêm chat room mới: ${updatedChatRoom.chatRoomId}');
        }
      } else {
        chatRooms[index] = updatedChatRoom;
        if (kDebugMode) {
          print('🔄 [ChatRoomCubit] Đã cập nhật chat room: ${updatedChatRoom.chatRoomId}');
        }
      }

      _cachedChatRooms = chatRooms;
      emit(ChatRoomLoaded(chatRooms));
    } else {
      if (kDebugMode) {
        print('⚠️ [ChatRoomCubit] Không thể cập nhật chat room vì state không phải là ChatRoomLoaded');
      }
    }
  }

  // Add a new chat room to the list
  void addChatRoom(ChatRoom newChatRoom) {
    if (state is ChatRoomLoaded) {
      final chatRooms = List<ChatRoom>.from((state as ChatRoomLoaded).chatRooms);
      
      final index = chatRooms.indexWhere((room) => room.chatRoomId == newChatRoom.chatRoomId);
      if (index == -1) {
        chatRooms.add(newChatRoom);
        if (kDebugMode) {
          print('🔄 [ChatRoomCubit] Đã thêm chat room mới: ${newChatRoom.chatRoomId}');
        }
      } else {
        chatRooms[index] = newChatRoom;
        if (kDebugMode) {
          print('🔄 [ChatRoomCubit] Đã cập nhật chat room: ${newChatRoom.chatRoomId}');
        }
      }

      _cachedChatRooms = chatRooms;
      emit(ChatRoomLoaded(chatRooms));
    } else {
      if (kDebugMode) {
        print('⚠️ [ChatRoomCubit] Không thể thêm chat room vì state không phải là ChatRoomLoaded');
      }
    }
  }

  Future<void> getChatRoomInfo(String chatRoomId) async {
    try {
      if (kDebugMode) {
        print('🔄 [ChatRoomCubit] Đang lấy thông tin chat room: $chatRoomId');
      }
      emit(ChatRoomInfoLoading());
      
      final result = await repository.getChatRoomInfo(chatRoomId);
      
      result.when(
        success: (chatRoomInfo) => emit(ChatRoomInfoLoaded(chatRoomInfo)),
        failure: (errorMessage) {
          if (kDebugMode) {
            print('❌ [ChatRoomCubit] Lỗi lấy thông tin chat room: $errorMessage');
          }
          emit(ChatRoomInfoError(errorMessage));
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ChatRoomCubit] Lỗi không mong đợi khi lấy thông tin chat room: $e');
      }
      emit(ChatRoomInfoError('Lỗi không mong đợi: $e'));
    }
  }

  // Cache chat room info without emitting a new state
  void setCachedChatRoomInfo(ChatRoomInfo chatRoomInfo) {
    _cachedChatRoomInfo = chatRoomInfo;
    if (kDebugMode) {
      print('📝 [ChatRoomCubit] Chat room info cached: ${chatRoomInfo.chatRoomId}');
    }
  }

  // Get cached chat room info
  ChatRoomInfo? getCachedChatRoomInfo() {
    return _cachedChatRoomInfo;
  }

  // Get chat room info without triggering navigation
  Future<void> getChatRoomInfoWithoutNavigation(String chatRoomId) async {
    try {
      if (kDebugMode) {
        print('🔄 [ChatRoomCubit] Đang lấy thông tin chat room (không tự động chuyển màn hình): $chatRoomId');
      }
      
      final result = await repository.getChatRoomInfo(chatRoomId);
      
      result.when(
        success: (chatRoomInfo) {
          _cachedChatRoomInfo = chatRoomInfo;
          // Emit a different state that won't trigger navigation
          emit(ChatRoomInfoCached(chatRoomInfo));
        },
        failure: (errorMessage) {
          if (kDebugMode) {
            print('❌ [ChatRoomCubit] Lỗi lấy thông tin chat room: $errorMessage');
          }
          emit(ChatRoomInfoError(errorMessage));
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ [ChatRoomCubit] Lỗi không mong đợi khi lấy thông tin chat room: $e');
      }
      emit(ChatRoomInfoError('Lỗi không mong đợi: $e'));
    }
  }

  // Xử lý tin nhắn mới cho chat room - đẩy lên đầu và tăng unreadCount
  void handleNewMessageForChatRoom(String chatRoomId, String messageContent, String? senderId) {
    if (state is ChatRoomLoaded) {
      final chatRooms = List<ChatRoom>.from((state as ChatRoomLoaded).chatRooms);
      
      final index = chatRooms.indexWhere((room) => room.chatRoomId == chatRoomId);
      if (index != -1) {
        // Lấy chat room cần cập nhật
        final chatRoom = chatRooms[index];
        
        // Tạo phiên bản cập nhật với tin nhắn mới + unreadCount tăng lên
        // Chỉ tăng unreadCount khi không phải tin nhắn từ người dùng hiện tại
        final isCurrentUserMessage = senderId == userId;
        
        final updatedChatRoom = ChatRoom(
          chatRoomId: chatRoom.chatRoomId,
          roomName: chatRoom.roomName,
          lastMessage: messageContent,
          lastMessageTime: DateTime.now().toIso8601String(),
          lastMessageSender: senderId,
          unreadCount: isCurrentUserMessage ? chatRoom.unreadCount : chatRoom.unreadCount + 1,
          group: chatRoom.group,
        );
        
        // Xóa chat room ở vị trí cũ
        chatRooms.removeAt(index);
        
        // Thêm vào đầu danh sách
        chatRooms.insert(0, updatedChatRoom);
        
        if (kDebugMode) {
          print('📲 [ChatRoomCubit] Đã cập nhật thứ tự chat room có tin nhắn mới: ${chatRoom.chatRoomId}');
          print('📲 [ChatRoomCubit] Số tin nhắn chưa đọc: ${updatedChatRoom.unreadCount}');
        }
        
        // Cập nhật cache và emit state mới
        _cachedChatRooms = chatRooms;
        emit(ChatRoomLoaded(chatRooms));
      }
    }
  }
  
  // Reset số tin nhắn chưa đọc của chat room
  void resetUnreadCount(String chatRoomId) {
    if (state is ChatRoomLoaded) {
      final chatRooms = List<ChatRoom>.from((state as ChatRoomLoaded).chatRooms);
      
      final index = chatRooms.indexWhere((room) => room.chatRoomId == chatRoomId);
      if (index != -1 && chatRooms[index].unreadCount > 0) {
        final chatRoom = chatRooms[index];
        
        // Tạo phiên bản mới với unreadCount = 0
        final updatedChatRoom = ChatRoom(
          chatRoomId: chatRoom.chatRoomId,
          roomName: chatRoom.roomName,
          lastMessage: chatRoom.lastMessage,
          lastMessageTime: chatRoom.lastMessageTime,
          lastMessageSender: chatRoom.lastMessageSender,
          unreadCount: 0, // Reset về 0
          group: chatRoom.group,
        );
        
        chatRooms[index] = updatedChatRoom;
        
        if (kDebugMode) {
          print('🔄 [ChatRoomCubit] Đã đặt lại số tin nhắn chưa đọc cho ${chatRoom.chatRoomId}');
        }
        
        _cachedChatRooms = chatRooms;
        emit(ChatRoomLoaded(chatRooms));
      }
    }
  }
}