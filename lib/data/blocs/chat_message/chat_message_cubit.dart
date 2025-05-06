import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:roomily/data/repositories/chat_repository.dart';
import 'package:roomily/data/models/chat_message.dart';

import 'chat_message_state.dart';

class ChatMessageCubit extends Cubit<ChatMessageState> {
  final ChatRepository _chatRepository;
  static const int _messagesPerPage = 20;

  ChatMessageCubit(this._chatRepository) : super(ChatMessageInitial());

  // Tải tin nhắn lần đầu
  Future<void> loadMessages(String chatRoomId) async {
    if (kDebugMode) {
      print('📩 CHAT LOAD INITIAL MESSAGES [${DateTime.now()}]');
      print('📩 Chat Room ID: $chatRoomId');
    }
    
    emit(ChatMessagesLoading());
    
    try {
      
      final result = await _chatRepository.getChatMessages(
        chatRoomId: chatRoomId,
        pivot: "",
        timestamp: "",
        prev: _messagesPerPage,
      );
      
      result.when(
        success: (messages) {
          if (kDebugMode) {
            print('✅ LOADED ${messages.length} MESSAGES');
            
            // Log sender IDs for debugging
            print('✅ DEBUG TRACKING - Messages sender IDs:');
            for (var i = 0; i < messages.length; i++) {
              print('✅ Message[$i] - sender.id: ${messages[i].senderId}');
            }
          }
          
          // Sắp xếp tin nhắn từ mới đến cũ (đảo ngược vì ListView hiển thị ngược)
          final sortedMessages = messages..sort((a, b) => 
              (b.timestamp ?? '').compareTo(a.timestamp ?? ''));
          
          String? oldestMessageId;
          String? oldestTimestamp;
          
          if (sortedMessages.isNotEmpty) {
            final oldestMessage = sortedMessages.last;
            oldestMessageId = oldestMessage.id;
            oldestTimestamp = oldestMessage.timestamp;
          }
          
          emit(ChatMessagesLoaded(
            messages: sortedMessages,
            hasReachedMax: messages.length < _messagesPerPage,
            oldestMessageId: oldestMessageId,
            oldestTimestamp: oldestTimestamp,
          ));
        },
        failure: (error) {
          if (kDebugMode) {
            print('❌ FAILED TO LOAD MESSAGES: $error');
          }
          emit(ChatMessagesError(error.toString()));
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ EXCEPTION LOADING MESSAGES: $e');
      }
      emit(ChatMessagesError(e.toString()));
    }
  }
  
  // Tải thêm tin nhắn cũ hơn
  Future<void> loadMoreMessages(String chatRoomId) async {
    // Kiểm tra trạng thái hiện tại
    if (state is! ChatMessagesLoaded) return;
    final currentState = state as ChatMessagesLoaded;
    
    // Nếu đã tới giới hạn tin nhắn cũ nhất
    if (currentState.hasReachedMax) return;
    
    // Nếu không có tin nhắn cũ để lấy pivot và timestamp
    if (currentState.oldestMessageId == null || currentState.oldestTimestamp == null) return;
    
    if (kDebugMode) {
      print('📩 CHAT LOAD MORE MESSAGES [${DateTime.now()}]');
      print('📩 Chat Room ID: $chatRoomId');
      print('📩 Pivot Message ID: ${currentState.oldestMessageId}');
      print('📩 Timestamp: ${currentState.oldestTimestamp}');
    }
    
    // Emit loading state mà vẫn giữ tin nhắn hiện tại
    emit(ChatMessagesLoading(isFirstLoad: false));
    
    try {
      final result = await _chatRepository.getChatMessages(
        chatRoomId: chatRoomId,
        pivot: currentState.oldestMessageId!, // dùng ID tin nhắn cũ nhất làm điểm mốc
        timestamp: currentState.oldestTimestamp!, // thời gian của tin nhắn cũ nhất
        prev: _messagesPerPage,
      );
      
      result.when(
        success: (newMessages) {
          if (kDebugMode) {
            print('✅ LOADED ${newMessages.length} MORE MESSAGES');
          }
          
          // Tin nhắn mới tiếp tục được sắp xếp
          final sortedNewMessages = newMessages..sort((a, b) => 
              (b.timestamp ?? '').compareTo(a.timestamp ?? ''));
          
          // Kết hợp tin nhắn cũ và mới
          final allMessages = [...currentState.messages, ...sortedNewMessages];
          
          String? oldestMessageId;
          String? oldestTimestamp;
          
          if (sortedNewMessages.isNotEmpty) {
            final oldestMessage = sortedNewMessages.last;
            oldestMessageId = oldestMessage.id;
            oldestTimestamp = oldestMessage.timestamp;
          } else {
            // Giữ nguyên nếu không có tin nhắn mới
            oldestMessageId = currentState.oldestMessageId;
            oldestTimestamp = currentState.oldestTimestamp;
          }
          
          emit(ChatMessagesLoaded(
            messages: allMessages,
            hasReachedMax: newMessages.length < _messagesPerPage,
            oldestMessageId: oldestMessageId,
            oldestTimestamp: oldestTimestamp,
          ));
        },
        failure: (error) {
          if (kDebugMode) {
            print('❌ FAILED TO LOAD MORE MESSAGES: $error');
          }
          // Phục hồi state trước đó nếu có lỗi
          emit(currentState);
        },
      );
    } catch (e) {
      if (kDebugMode) {
        print('❌ EXCEPTION LOADING MORE MESSAGES: $e');
      }
      // Phục hồi state trước đó nếu có lỗi
      emit(currentState);
    }
  }

  Future<void> sendMessage({
    required String content,
    required String senderId,
    required String chatRoomId,
    required bool isAdConversion,
    String? adClickId,
    String? image,
  }) async {
    // Check if image is valid (not null and not empty)
    final bool hasImage = image != null && image.isNotEmpty;
    final bool hasAdClickId = adClickId != null && adClickId.isNotEmpty;
    
    if (kDebugMode) {
      print('📩 CHAT REQUEST [${DateTime.now()}]');
      print('📩 API: /api/v1/chat/send');
      print('📩 Method: POST');
      print('📩 Request type: multipart/form-data');
      print('📩 Form fields:');
      print('📩 - content: $content');
      print('📩 - senderId: $senderId');
      print('📩 - chatRoomId: $chatRoomId');
      print('📩 - Has image: ${hasImage ? 'YES' : 'NO'}');
      print('📩 - Has adClickId: ${hasAdClickId ? 'YES' : 'NO'}');
      print('📩 - adClickId: $adClickId');
      print('📩 - isAdConversation: $isAdConversion');
      print('📩 DEBUG TRACKING - senderId type: ${senderId.runtimeType}');
      print('📩 DEBUG TRACKING - senderId length: ${senderId.length}');
    }
    
    // Get current messages if available
    List<ChatMessage> currentMessages = [];
    String? oldestMessageId;
    String? oldestTimestamp;
    bool hasReachedMax = true;
    
    if (state is ChatMessagesLoaded) {
      final loadedState = state as ChatMessagesLoaded;
      currentMessages = List.from(loadedState.messages);
      oldestMessageId = loadedState.oldestMessageId;
      oldestTimestamp = loadedState.oldestTimestamp;
      hasReachedMax = loadedState.hasReachedMax;
    }
    
    // Only emit loading state if we don't have messages yet
    if (currentMessages.isEmpty) {
      emit(ChatMessagesLoading());
    }

    try {
      // Send directly as form-data fields (not as JSON body)
      final result = await _chatRepository.sendMessage(
        content: content,
        senderId: senderId,
        chatRoomId: chatRoomId,
        image: hasImage ? image : null,
        isAdConversion: isAdConversion,
        adClickId: hasAdClickId ? adClickId :  null,
      );

      result.when(
        success: (message) {
          if (kDebugMode) {
            print('✅ CHAT RESPONSE SUCCESS [${DateTime.now()}]');
            print('✅ Status: SUCCESS');
            print('✅ Message ID: ${message.id}');
            print('✅ Timestamp: ${message.timestamp}');
            print('✅ Has image: ${message.image != null && message.image!.isNotEmpty}');
            print('✅ Full response: ${message.toJson()}');
          }
          
          // Always add the new message to the top of the list
          final updatedMessages = [message, ...currentMessages];
          
          // Always emit ChatMessagesLoaded for consistency
          emit(ChatMessagesLoaded(
            messages: updatedMessages,
            hasReachedMax: hasReachedMax,
            oldestMessageId: oldestMessageId,
            oldestTimestamp: oldestTimestamp,

          ));
        },
        failure: (error) {
          if (kDebugMode) {
            print('❌ CHAT RESPONSE ERROR [${DateTime.now()}]');
            print('❌ Status: FAILED');
            print('❌ Error details: $error');
            print('❌ Request that caused error:');
            print('❌ - content: $content');
            print('❌ - senderId: $senderId');
            print('❌ - chatRoomId: $chatRoomId');
            print('❌ - Has image: ${hasImage ? 'YES' : 'NO'}');
          }
          emit(ChatMessageError(error.toString()));
        },
      );
    } catch (e, stackTrace) {
      if (kDebugMode) {
        print('⚠️ CHAT EXCEPTION [${DateTime.now()}]');
        print('⚠️ Exception: $e');
        print('⚠️ Stack trace:');
        print(stackTrace.toString().split('\n').take(10).join('\n'));
        print('⚠️ Request that caused exception:');
        print('⚠️ - content: $content');
        print('⚠️ - senderId: $senderId');
        print('⚠️ - chatRoomId: $chatRoomId');
        print('⚠️ - Has image: ${hasImage ? 'YES' : 'NO'}');
      }
      emit(ChatMessageError(e.toString()));
    }
  }

  // Reset state to initial (useful when changing UI views)
  void reset() {
    if (kDebugMode) {
      print('🔄 Reset chat message state [${DateTime.now()}]');
    }
    emit(ChatMessageInitial());
  }
} 