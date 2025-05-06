import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/chat_message.dart';

abstract class ChatMessageState extends Equatable {
  const ChatMessageState();

  @override
  List<Object?> get props => [];
}

class ChatMessageInitial extends ChatMessageState {}

class ChatMessageLoading extends ChatMessageState {}

class ChatMessageSuccess extends ChatMessageState {
  final ChatMessage message;

  const ChatMessageSuccess(this.message);

  @override
  List<Object?> get props => [message];
}

class ChatMessageError extends ChatMessageState {
  final String error;

  const ChatMessageError(this.error);

  @override
  List<Object?> get props => [error];
}

// Thêm các state mới cho việc tải danh sách tin nhắn
class ChatMessagesLoading extends ChatMessageState {
  final bool isFirstLoad;
  
  const ChatMessagesLoading({this.isFirstLoad = true});
  
  @override
  List<Object?> get props => [isFirstLoad];
}

class ChatMessagesLoaded extends ChatMessageState {
  final List<ChatMessage> messages;
  final bool hasReachedMax;
  final String? oldestMessageId;
  final String? oldestTimestamp;
  
  const ChatMessagesLoaded({
    required this.messages,
    this.hasReachedMax = false,
    this.oldestMessageId,
    this.oldestTimestamp,
  });
  
  @override
  List<Object?> get props => [messages, hasReachedMax, oldestMessageId, oldestTimestamp];
  
  ChatMessagesLoaded copyWith({
    List<ChatMessage>? messages,
    bool? hasReachedMax,
    String? oldestMessageId,
    String? oldestTimestamp,
  }) {
    return ChatMessagesLoaded(
      messages: messages ?? this.messages,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      oldestMessageId: oldestMessageId ?? this.oldestMessageId,
      oldestTimestamp: oldestTimestamp ?? this.oldestTimestamp,
    );
  }
}

class ChatMessagesError extends ChatMessageState {
  final String error;
  
  const ChatMessagesError(this.error);
  
  @override
  List<Object?> get props => [error];
} 