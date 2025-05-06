import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/result/result.dart';
import 'package:roomily/data/models/chat_message.dart';
import 'package:roomily/data/repositories/chat_repository.dart';
import 'package:roomily/core/config/dio_config.dart';

class ChatRepositoryImpl implements ChatRepository {
  final Dio _dio;

  ChatRepositoryImpl({Dio? dio})
      : _dio = dio ?? DioConfig.createDio();

  @override
  Future<Result<ChatMessage>> sendMessage({
    required String content,
    required String senderId,
    required String chatRoomId,
    required bool isAdConversion,
    String? adClickId,
    String? image,
  }) async {
    if (kDebugMode) {
      print('🔍 [REPOSITORY] Starting sendMessage operation');
    }

    try {
      // Prepare the API endpoint
      final url = ApiConstants.baseUrl + ApiConstants.sendChatMessage();
      if (kDebugMode) {
        print('🔍 [REPOSITORY] API URL: $url');
      }

      // Create a FormData object
      final formData = FormData();

      // Add required fields
      formData.fields.add(MapEntry('content', content));
      formData.fields.add(MapEntry('senderId', senderId));
      formData.fields.add(MapEntry('chatRoomId', chatRoomId));
      formData.fields.add(MapEntry('isAdConversion', isAdConversion.toString()));

      // Add optional adClickId
      if (adClickId != null && adClickId.isNotEmpty) {
        formData.fields.add(MapEntry('adClickId', adClickId));
      }

      // Handle image upload
      if (image != null && image.isNotEmpty) {
        if (image.startsWith('/9j/') || image.startsWith('iVBOR')) {
          // Handle base64 image
          try {
            final bytes = base64Decode(image);
            final tempDir = await getTemporaryDirectory();
            final tempFile = File('${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.jpg');
            await tempFile.writeAsBytes(bytes);

            formData.files.add(MapEntry(
              'image',
              await MultipartFile.fromFile(
                tempFile.path,
                filename: path.basename(tempFile.path),
              ),
            ));

            if (kDebugMode) {
              print('🔍 [REPOSITORY] Base64 image converted to file: ${tempFile.path}');
            }
          } catch (e) {
            if (kDebugMode) {
              print('🔍 [REPOSITORY] Error processing base64 image: $e');
            }
            throw Exception('Invalid image data format');
          }
        } else {
          // Handle file path
          formData.files.add(MapEntry(
            'image',
            await MultipartFile.fromFile(
              image,
              filename: path.basename(image),
            ),
          ));

          if (kDebugMode) {
            print('🔍 [REPOSITORY] Image file added: $image');
          }
        }
      }

      if (kDebugMode) {
        print('🔍 [REPOSITORY] FormData fields: ${formData.fields}');
        print('🔍 [REPOSITORY] FormData files: ${formData.files}');
      }

      // FormData automatically sets the Content-Type to multipart/form-data
      final headers = {
        'Accept': 'application/json',
      };

      if (kDebugMode) {
        print('🔍 [REPOSITORY] Request headers: $headers');
      }

      // Measuring request time
      final stopwatch = Stopwatch()..start();

      // Send POST request with FormData
      final response = await _dio.post(
        url,
        data: formData,
        options: Options(headers: headers),
      );

      stopwatch.stop();
      if (kDebugMode) {
        print('🔍 [REPOSITORY] Request completed in ${stopwatch.elapsedMilliseconds}ms');
      }

      // Handle success response
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('🔍 [REPOSITORY] Response status: ${response.statusCode}');
          print('🔍 [REPOSITORY] Response headers: ${response.headers}');
          print('🔍 [REPOSITORY] Response data: ${response.data}');
        }

        final chatMessage = ChatMessage.fromJson(response.data);
        if (kDebugMode) {
          print('🔍 [REPOSITORY] Parsed chat message: ${chatMessage.toJson()}');
        }

        return Result.success(chatMessage);
      } else {
        if (kDebugMode) {
          print('🔍 [REPOSITORY] Unexpected status code: ${response.statusCode}');
          print('🔍 [REPOSITORY] Response body: ${response.data}');
        }

        return Result.failure(Exception('Failed to send message. Status code: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('🔍 [REPOSITORY] DioException: ${e.type}');
        print('🔍 [REPOSITORY] Error message: ${e.message}');
        print('🔍 [REPOSITORY] Request: ${e.requestOptions.uri}');
        print('🔍 [REPOSITORY] Request data: ${e.requestOptions.data}');
        print('🔍 [REPOSITORY] Response: ${e.response?.data}');
        print('🔍 [REPOSITORY] Status code: ${e.response?.statusCode}');
      }

      return Result.failure(Exception('Network error: ${e.message}'));
    } catch (e) {
      if (kDebugMode) {
        print('🔍 [REPOSITORY] General exception: $e');
      }

      return Result.failure(Exception('Failed to send message: $e'));
    }
  }

  @override
  Future<Result<List<ChatMessage>>> getChatMessages({
    required String chatRoomId,
    required String pivot,
    required String timestamp,
    required int prev,
  }) async {
    if (kDebugMode) {
      print('🔍 [REPOSITORY] Starting getChatMessages operation');
      print('🔍 [REPOSITORY] Parameters: chatRoomId=$chatRoomId, pivot=$pivot, timestamp=$timestamp, prev=$prev');
    }

    try {
      // Prepare the API endpoint with query parameters
      final url = '${ApiConstants.baseUrl}${ApiConstants.chatMessages()}';

      // Chỉ thêm tham số pivot và timestamp khi chúng có giá trị
      final queryParameters = {
        'chatRoomId': chatRoomId,
        'prev': prev.toString(),
        if (pivot.isNotEmpty) 'pivot': pivot,
        if (timestamp.isNotEmpty) 'timestamp': timestamp,
      };

      if (kDebugMode) {
        print('🔍 [REPOSITORY] API URL: $url');
        print('🔍 [REPOSITORY] Query parameters: $queryParameters');
      }

      // Measuring request time
      final stopwatch = Stopwatch()..start();

      // Send GET request
      final response = await _dio.get(
        url,
        queryParameters: queryParameters,
      );

      stopwatch.stop();
      if (kDebugMode) {
        print('🔍 [REPOSITORY] Request completed in ${stopwatch.elapsedMilliseconds}ms');
        print('🔍 [REPOSITORY] Response status: ${response.statusCode}');
      }

      // Handle success response
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('🔍 [REPOSITORY] Response data type: ${response.data.runtimeType}');

          // Add detailed logging for message structure
          if (response.data is List && response.data.isNotEmpty) {
            print('🔍 [REPOSITORY] ====== DEBUGGING MESSAGE JSON STRUCTURE ======');
            print('🔍 [REPOSITORY] First message sample: ${response.data[0]}');
            print('🔍 [REPOSITORY] Sender field: ${response.data[0]['sender']}');
            print('🔍 [REPOSITORY] SenderId direct field: ${response.data[0]['senderId']}');

            // List all top-level keys in the first message
            final firstMessage = response.data[0];
            print('🔍 [REPOSITORY] All keys in message: ${firstMessage.keys.toList()}');
            print('🔍 [REPOSITORY] ===========================================');
          }
        }

        final List<dynamic> messagesJson = response.data;
        final messages = messagesJson.map((json) => ChatMessage.fromJson(json)).toList();

        if (kDebugMode) {
          print('🔍 [REPOSITORY] Parsed ${messages.length} messages');
        }

        return Result.success(messages);
      } else {
        if (kDebugMode) {
          print('🔍 [REPOSITORY] Unexpected status code: ${response.statusCode}');
        }
        return Result.failure(Exception('Failed with status: ${response.statusCode}'));
      }
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [REPOSITORY] DioException: ${e.message}');
        print('❌ [REPOSITORY] Status code: ${e.response?.statusCode}');
        print('❌ [REPOSITORY] Response data: ${e.response?.data}');
      }
      return Result.failure(Exception(e.message ?? 'Failed to get chat messages'));
    } catch (e) {
      if (kDebugMode) {
        print('❌ [REPOSITORY] Unexpected error: $e');
      }
      return Result.failure(Exception('An unexpected error occurred: $e'));
    }
  }
}