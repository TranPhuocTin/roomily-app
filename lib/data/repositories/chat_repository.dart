import 'dart:io';
import 'package:roomily/core/result/result.dart';
import 'package:roomily/data/models/chat_message.dart';

abstract class ChatRepository {
  Future<Result<ChatMessage>> sendMessage({
    required String content,
    required String senderId,
    required String chatRoomId,
    String? image,
    required bool isAdConversion,
    String? adClickId,
  });

  Future<Result<List<ChatMessage>>> getChatMessages({
    required String chatRoomId,
    required String pivot,
    required String timestamp,
    required int prev,
  });
} 