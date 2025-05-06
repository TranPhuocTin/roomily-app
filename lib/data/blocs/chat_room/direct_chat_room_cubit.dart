import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/repositories/chat_room_repository.dart';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:roomily/presentation/screens/chat_detail_screen_v2.dart';
import 'package:roomily/data/models/chat_room_info.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:get_it/get_it.dart';

import '../home/room_detail_cubit.dart';
import 'chat_room_cubit.dart';
import 'direct_chat_room_state.dart';

class DirectChatRoomCubit extends Cubit<DirectChatRoomState> {
  final ChatRoomRepository repository;
  final ChatRoomCubit chatRoomCubit;
  final RoomDetailCubit roomDetailCubit;
  final AuthService _authService = GetIt.I<AuthService>();

  DirectChatRoomCubit({
    required this.repository, 
    required this.chatRoomCubit,
    required this.roomDetailCubit,
  }) : super(DirectChatRoomInitial());

  Future<void> createDirectChatRoom(String roomId, {
    BuildContext? context,
    bool isAdConversation = false,
    String? adClickId
  }) async {
    emit(DirectChatRoomLoadingForRoom());
    debugPrint('Creating direct chat room for roomId: $roomId');
    if (isAdConversation) {
      debugPrint('This is an ad conversation with adClickId: $adClickId');
    }

    final result = await repository.createDirectChatRoom(roomId);

    result.when(
      success: (chatRoomInfo) async {
        debugPrint('Success: Direct chat room created with ID: ${chatRoomInfo.chatRoomId}');
        
        bool chatRoomExists = false;
        
        // Kiểm tra nếu phòng chat đã tồn tại
        if (chatRoomCubit.state is ChatRoomLoaded) {
          final currentState = chatRoomCubit.state as ChatRoomLoaded;
          final chatRooms = currentState.chatRooms;

          chatRoomExists = chatRooms.any((room) => room.chatRoomId == chatRoomInfo.chatRoomId);
        }
        
        // Nếu phòng chat không tồn tại, refresh danh sách chat room
        if (!chatRoomExists) {
          await chatRoomCubit.refreshChatRooms();
        }
        
        // Tải thông tin chi tiết phòng chat trước khi điều hướng
        await chatRoomCubit.getChatRoomInfo(chatRoomInfo.chatRoomId);
        
        emit(DirectChatRoomLoaded(chatRoomInfo));
        
        // Get current user ID and roles
        final String? currentUserId = _authService.userId;
        final List<String> userRoles = _authService.roles;
        
        // Navigate to chat detail if context is provided
        if (context != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatDetailScreenV2(
                chatRoomInfo: chatRoomInfo,
                isAdConversation: isAdConversation,
                adClickId: adClickId,
                currentUserId: currentUserId,
                userRole: userRoles.isNotEmpty ? userRoles.first : null,
              ),
            ),
          );
        }
      },
      failure: (message) {
        debugPrint('Error: $message');
        emit(DirectChatRoomError(message));
      },
    );
  }

  Future<void> createDirectChatRoomToUser(
    String userId, {
    String? findPartnerPostId,
    BuildContext? context,
    bool isAdConversation = false,
    String? adClickId
  }) async {
    emit(DirectChatRoomLoadingForUser());
    debugPrint('Creating direct chat room to user: $userId with findPartnerPostId: $findPartnerPostId');
    if (isAdConversation) {
      debugPrint('This is an ad conversation with adClickId: $adClickId');
    }

    final result = await repository.createDirectChatRoomToUser(userId, findPartnerPostId: findPartnerPostId);

    result.when(
      success: (chatRoomInfo) async {
        debugPrint('Success: Direct chat room created with ID: ${chatRoomInfo.chatRoomId}');
        
        bool chatRoomExists = false;
        
        // Kiểm tra nếu phòng chat đã tồn tại
        if (chatRoomCubit.state is ChatRoomLoaded) {
          final currentState = chatRoomCubit.state as ChatRoomLoaded;
          final chatRooms = currentState.chatRooms;

          chatRoomExists = chatRooms.any((room) => room.chatRoomId == chatRoomInfo.chatRoomId);
        }
        
        // Nếu phòng chat không tồn tại, refresh danh sách chat room
        if (!chatRoomExists) {
          await chatRoomCubit.refreshChatRooms();
        }
        
        // Tải thông tin chi tiết phòng chat trước khi điều hướng
        await chatRoomCubit.getChatRoomInfo(chatRoomInfo.chatRoomId);
        
        emit(DirectChatRoomLoaded(chatRoomInfo));
        
        // Get current user ID and roles
        final String? currentUserId = _authService.userId;
        final List<String> userRoles = _authService.roles;
        
        // Navigate to chat detail if context is provided
        if (context != null) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ChatDetailScreenV2(
                chatRoomInfo: chatRoomInfo,
                isAdConversation: isAdConversation,
                adClickId: adClickId,
                currentUserId: currentUserId,
                userRole: userRoles.isNotEmpty ? userRoles.first : null,
              ),
            ),
          );
        }
      },
      failure: (message) {
        debugPrint('Error: $message');
        emit(DirectChatRoomError(message));
      },
    );
  }
}
