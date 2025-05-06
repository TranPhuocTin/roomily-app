import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/chat_room_info.dart';

abstract class DirectChatRoomState extends Equatable {
  const DirectChatRoomState();

  @override
  List<Object?> get props => [];
}

class DirectChatRoomInitial extends DirectChatRoomState {}

class DirectChatRoomLoading extends DirectChatRoomState {}

class DirectChatRoomLoadingForRoom extends DirectChatRoomState {}

class DirectChatRoomLoadingForUser extends DirectChatRoomState {}

class DirectChatRoomLoaded extends DirectChatRoomState {
  final ChatRoomInfo chatRoomInfo;

  const DirectChatRoomLoaded(this.chatRoomInfo);

  @override
  List<Object?> get props => [chatRoomInfo];
}

class DirectChatRoomError extends DirectChatRoomState {
  final String message;

  const DirectChatRoomError(this.message);

  @override
  List<Object?> get props => [message];
}