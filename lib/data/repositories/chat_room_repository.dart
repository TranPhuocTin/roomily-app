import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/chat_room_info.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/models/direct_chat_room.dart';

abstract class ChatRoomRepository {
  Future<Result<List<ChatRoom>>> getChatRooms();
  Future<Result<ChatRoomInfo>> createDirectChatRoom(String roomId);
  Future<Result<ChatRoomInfo>> createDirectChatRoomToUser(String userId, {String? findPartnerPostId});
  Future<Result<ChatRoomInfo>> getChatRoomInfo(String chatRoomId);
}