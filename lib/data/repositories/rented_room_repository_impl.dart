import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/rented_room.dart';
import 'package:roomily/data/repositories/rented_room_repository.dart';
import 'package:dio/dio.dart';
import 'package:roomily/data/models/rent_request.dart';
import 'package:roomily/data/models/rental_request.dart';
import 'package:flutter/foundation.dart';
import 'package:roomily/data/models/bill_log.dart';
import 'package:roomily/data/models/utility_reading_request.dart';
import 'package:roomily/data/models/landlord_confirmation_request.dart';
import 'dart:convert';

class RentedRoomRepositoryImpl extends RentedRoomRepository {
  final Dio _dio;

  RentedRoomRepositoryImpl({Dio? dio}) : _dio = DioConfig.createDio();

  @override
  Future<Result<RentalRequest>> createRentRequest(RentRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.requestToRent(),
        data: jsonEncode(request.toJson()),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      // Xử lý response thành công - trả về RentalRequest
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (kDebugMode) {
          print('API response data: ${response.data}');
        }

        // Parse response data to RentalRequest
        final rentalRequest = RentalRequest.fromJson(response.data);
        return Success(rentalRequest);
      }

      return Failure("Yêu cầu không thành công: ${response.statusCode}");
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in createRentRequest: ${e.message}');
        print('Response data: ${e.response?.data}');
      }

      // Xử lý các lỗi format nhưng có thể thành công
      if (e.error is FormatException ||
          (e.message?.contains("format") ?? false) ||
          (e.message?.contains("unexpected") ?? false)) {
        return Failure("Không thể xử lý phản hồi từ máy chủ");
      }

      return Failure(e.message ?? "Có lỗi xảy ra khi gửi yêu cầu thuê phòng");
    } catch (e) {
      if (kDebugMode) {
        print('Exception in createRentRequest: $e');
      }
      return Failure("Có lỗi không xác định khi xử lý yêu cầu: $e");
    }
  }

  @override
  Future<Result<String>> acceptRentRequest(String chatRoomId) async {
    try {
      if (kDebugMode) {
        print('Calling accept API with chatRoomId: $chatRoomId');
      }

      // Cập nhật endpoint để sử dụng chatRoomId thay vì privateCode
      final response = await _dio.post(
        ApiConstants.acceptRentRequest(chatRoomId),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Lấy data dưới dạng string (có thể là "1" hoặc "")
        final String rawData = response.data?.toString().trim() ?? "";

        if (kDebugMode) {
          print('Accept API response data: "$rawData"');
        }

        // Return trực tiếp giá trị response, không chuyển đổi
        return Success(rawData);
      }

      return Failure(
          "Không thể chấp nhận yêu cầu thuê phòng: ${response.statusCode}");
    } catch (e) {
      if (kDebugMode) {
        print('Exception in acceptRentRequest: $e');
      }
      return Failure("Có lỗi không xác định khi chấp nhận yêu cầu thuê phòng");
    }
  }

  @override
  Future<Result<String>> rejectRentRequest(String chatRoomId) async {
    try {
      if (kDebugMode) {
        print('Calling deny API with chatRoomId: $chatRoomId');
      }

      final response = await _dio.post(
        ApiConstants.denyRentRequest(chatRoomId),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String rawData = response.data?.toString().trim() ?? "";

        if (kDebugMode) {
          print('Deny API response data: "$rawData"');
        }

        // Return trực tiếp giá trị response, không chuyển đổi
        return Success(rawData);
      }

      return Failure(
          "Không thể từ chối yêu cầu thuê phòng: ${response.statusCode}");
    } catch (e) {
      if (kDebugMode) {
        print('Exception in rejectRentRequest: $e');
      }
      return Failure("Có lỗi không xác định khi từ chối yêu cầu thuê phòng");
    }
  }

  @override
  Future<Result<String>> cancelRentRequest(String chatRoomId) async {
    try {
      final response = await _dio.delete(
        ApiConstants.cancelRentRequest(chatRoomId),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          responseType: ResponseType.plain,
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final String rawData = response.data?.toString().trim() ?? "";

        if (kDebugMode) {
          print('Cancel API response data: "$rawData"');
        }

        return Success(rawData);
      }

      return Failure(
          "Không thể hủy yêu cầu thuê phòng: ${response.statusCode}");
    } catch (e) {
      if (kDebugMode) {
        print('Exception in cancelRentRequest: $e');
      }
      return Failure("Có lỗi không xác định khi hủy yêu cầu thuê phòng");
    }
  }

  @override
  Future<Result<List<RentedRoom>>> getRentedRooms() async {
    try {
      final response = await _dio.get(ApiConstants.getRentedRooms());
      final rentedRooms =
          (response.data as List).map((e) => RentedRoom.fromJson(e)).toList();
      return Success(rentedRooms);
    } catch (e) {
      debugPrint('Failed to get rented rooms: $e');
      return Failure('Failed to load rented rooms');
    }
  }

  @override
  Future<Result<BillLog>> getActiveBillLogByRentedRoomId(String rentedRoomId) async {
    try {
      debugPrint('REQUEST[GET] => PATH: api/v1/bill-logs/active/rented-room/$rentedRoomId');
      
      final response = await _dio.get(
        ApiConstants.getActiveBillLogByRentedRoomId(rentedRoomId),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      
      debugPrint('RESPONSE[${response.statusCode}] => PATH: api/v1/bill-logs/active/rented-room/$rentedRoomId');
      debugPrint('Response Data:');
      debugPrint('${response.data}');
      
      if (response.statusCode == 200) {
        // Check if the response is empty or a string
        if (response.data == null || 
            response.data == '' || 
            (response.data is String && (response.data as String).isEmpty)) {
          debugPrint('API returned empty response, returning BillLog.empty()');
          // Return an empty bill log with NO_ACTIVE_BILL status
          return Failure("NO_ACTIVE_BILL_FOUND");
        }
        
        // Check if the response is a string but not empty
        if (response.data is String) {
          debugPrint('API returned string response: ${response.data}');
          try {
            // Try to decode the string as JSON
            final Map<String, dynamic> jsonData = jsonDecode(response.data);
            return Success(BillLog.fromJson(jsonData));
          } catch (e) {
            debugPrint('Failed to parse string response as JSON: $e');
            return Failure("NO_ACTIVE_BILL_FOUND");
          }
        }
        
        debugPrint('Active bill log response: ${response.data}');
        final billLog = BillLog.fromJson(response.data);
        return Success(billLog);
      }
      
      return Failure("Failed to get active bill log: ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint('DioException in getActiveBillLog: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      
      return Failure(e.message ?? "Failed to get active bill log");
    } catch (e) {
      debugPrint('Exception in getActiveBillLog: $e');
      return Failure("Unexpected error: $e");
    }
  }

  @override
  Future<Result<BillLog>> getActiveBillLogByRoomId(String roomId) async {
    try {
      debugPrint('REQUEST[GET] => PATH: api/v1/bill-logs/active/room/$roomId');
      
      final response = await _dio.get(
        ApiConstants.getActiveBillLogByRoomId(roomId),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      
      debugPrint('RESPONSE[${response.statusCode}] => PATH: api/v1/bill-logs/active/room/$roomId');
      debugPrint('Response Data:');
      debugPrint('${response.data}');
      
      if (response.statusCode == 200) {
        // Check if the response is empty or a string
        if (response.data == null || 
            response.data == '' || 
            (response.data is String && (response.data as String).isEmpty)) {
          debugPrint('API returned empty response, returning NO_ACTIVE_BILL_FOUND');
          return Failure("NO_ACTIVE_BILL_FOUND");
        }
        
        // Check if the response is a string but not empty
        if (response.data is String) {
          debugPrint('API returned string response: ${response.data}');
          try {
            // Try to decode the string as JSON
            final Map<String, dynamic> jsonData = jsonDecode(response.data);
            return Success(BillLog.fromJson(jsonData));
          } catch (e) {
            debugPrint('Failed to parse string response as JSON: $e');
            return Failure("NO_ACTIVE_BILL_FOUND");
          }
        }
        
        debugPrint('Active bill log by room id response: ${response.data}');
        final billLog = BillLog.fromJson(response.data);
        return Success(billLog);
      }
      
      return Failure("Failed to get active bill log by room id: ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint('DioException in getActiveBillLogByRoomId: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      
      return Failure(e.message ?? "Failed to get active bill log by room id");
    } catch (e) {
      debugPrint('Exception in getActiveBillLogByRoomId: $e');
      return Failure("Unexpected error: $e");
    }
  }
  
  @override
  Future<Result<BillLog>> updateUtilityReadings(String billLogId, UtilityReadingRequest request) async {
    try {
      debugPrint('REQUEST[PATCH] => PATH: api/v1/bill-logs/utility-readings/$billLogId');
      
      // Create FormData instead of JSON
      final formData = FormData.fromMap({
        'electricity': request.electricity.toString(),
        'water': request.water.toString(),
        if (request.electricityImage != null) 'electricityImage': await MultipartFile.fromFile(
          request.electricityImage!.path,
          filename: 'electricity.jpg',
        ),
        if (request.waterImage != null) 'waterImage': await MultipartFile.fromFile(
          request.waterImage!.path,
          filename: 'water.jpg',
        ),
      });
      
      final response = await _dio.patch(
        ApiConstants.updateUtilityReadings(billLogId),
        data: formData,
      );
      
      debugPrint('RESPONSE[${response.statusCode}] => PATH: api/v1/bill-logs/utility-readings/$billLogId');
      debugPrint('Response Data Type: ${response.data.runtimeType}');
      debugPrint('Response Data: ${response.data}');
      
      if (response.statusCode == 200) {
        // Check if response data is null, empty string, or just a string
        if (response.data == null || 
            response.data == '' || 
            (response.data is String && (response.data as String).isEmpty)) {
          debugPrint('API returned empty response. This is expected for successful updates.');
          // Return a special result to indicate success but no data
          return Failure("SUCCESS_BUT_NO_DATA");
        }
        
        // If the response is a string but not empty, try to parse it as JSON
        if (response.data is String && (response.data as String).isNotEmpty) {
          try {
            // Try to decode the string as JSON
            final Map<String, dynamic> jsonData = jsonDecode(response.data);
            debugPrint('Successfully parsed string response as JSON');
            return Success(BillLog.fromJson(jsonData));
          } catch (e) {
            debugPrint('Failed to parse string response as JSON: $e');
            // The update likely succeeded but we can't parse the response
            return Failure("SUCCESS_BUT_NO_DATA");
          }
        }
        
        debugPrint('Got JSON response for utility readings update');
        final updatedBillLog = BillLog.fromJson(response.data);
        return Success(updatedBillLog);
      }
      
      return Failure("Failed to update utility readings: ${response.statusCode}");
    } on DioException catch (e) {
      debugPrint('DioException in updateUtilityReadings: ${e.message}');
      debugPrint('Response data: ${e.response?.data}');
      
      return Failure(e.message ?? "Failed to update utility readings");
    } catch (e) {
      debugPrint('Exception in updateUtilityReadings: $e');
      return Failure("Unexpected error: $e");
    }
  }
  
  @override
  Future<Result<List<BillLog>>> getBillLogHistory(String roomId) async {
    try {
      final response = await _dio.get(
        ApiConstants.getBillLogHistory(roomId),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Get bill log history response: ${response.data}');
        }
        
        final List<dynamic> data = response.data;
        final billLogs = data.map((json) => BillLog.fromJson(json)).toList();
        return Success(billLogs);
      }
      
      return Failure("Failed to get bill log history: ${response.statusCode}");
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in getBillLogHistory: ${e.message}');
        print('Response data: ${e.response?.data}');
      }
      
      return Failure(e.message ?? "Failed to get bill log history");
    } catch (e) {
      if (kDebugMode) {
        print('Exception in getBillLogHistory: $e');
      }
      return Failure("Unexpected error: $e");
    }
  }
  
  @override
  Future<Result<BillLog?>> confirmUtilityReadings(String billLogId, LandlordConfirmationRequest request) async {
    try {
      final response = await _dio.post(
        ApiConstants.confirmUtilityReadings(billLogId),
        data: jsonEncode(request.toJson()),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      
      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Confirm utility readings response: ${response.data}');
        }
        
        // Kiểm tra nếu response.data là null, rỗng hoặc là String
        if (response.data == null || 
            (response.data is String && (response.data as String).isEmpty) ||
            response.data is String) {
          if (kDebugMode) {
            print('API returned empty or string response. Considering request successful.');
          }
          // Trả về thành công nhưng với dữ liệu null
          return Success(null);
        }
        
        // Nếu có data JSON hợp lệ, parse như bình thường
        final updatedBillLog = BillLog.fromJson(response.data);
        return Success(updatedBillLog);
      }
      
      return Failure("Failed to confirm utility readings: ${response.statusCode}");
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in confirmUtilityReadings: ${e.message}');
        print('Response data: ${e.response?.data}');
      }
      
      return Failure(e.message ?? "Failed to confirm utility readings");
    } catch (e) {
      if (kDebugMode) {
        print('Exception in confirmUtilityReadings: $e');
      }
      return Failure("Unexpected error: $e");
    }
  }

  @override
  Future<Result<List<BillLog>>> getBillLogHistoryByRentedRoomId(String rentedRoomId) async {
    try {
      final response = await _dio.get(
        ApiConstants.getBillLogHistoryByRentedRoomId(rentedRoomId),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Get bill log history by rented room id response: ${response.data}');
        }

        final List<dynamic> data = response.data;
        final billLogs = data.map((json) => BillLog.fromJson(json)).toList();
        return Success(billLogs);
      }

      return Failure("Failed to get bill log history by rented room id: ${response.statusCode}");
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in getBillLogHistoryByRentedRoomId: ${e.message}');
        print('Response data: ${e.response?.data}');
      }

      return Failure(e.message ?? "Failed to get bill log history by rented room id");
    } catch (e) {
      if (kDebugMode) {
        print('Exception in getBillLogHistoryByRentedRoomId: $e');
      }
      return Failure("Unexpected error: $e");
    }
  }

  @override
  Future<Result<List<RentedRoom>>> getRentedRoomsByLandlordId(String landlordId) async {
    try {
      final response = await _dio.get(
        ApiConstants.rentedRoomsByLandlord(landlordId),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Get rented rooms by landlord id response: ${response.data}');
        }

        final List<dynamic> data = response.data;
        final rentedRooms = data.map((json) => RentedRoom.fromJson(json)).toList();
        return Success(rentedRooms);
      }

      return Failure("Failed to get rented rooms by landlord id: ${response.statusCode}");
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in getRentedRoomsByLandlordId: ${e.message}');
        print('Response data: ${e.response?.data}');
      }

      return Failure(e.message ?? "Failed to get rented rooms by landlord id");
    } catch (e) {
      if (kDebugMode) {
        print('Exception in getRentedRoomsByLandlordId: $e');
      }
      return Failure("Unexpected error: $e");
    }
  }

  @override
  Future<Result<List<RentalRequest>>> getRentalRequestsByReceiverId(String receiverId) async {
    try {
      final response = await _dio.get(
        ApiConstants.getRentalRequestsByReceiver(receiverId),
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );

      if (response.statusCode == 200) {
        if (kDebugMode) {
          print('Get rental requests response: ${response.data}');
        }

        final List<dynamic> data = response.data;
        final rentalRequests = data.map((json) => RentalRequest.fromJson(json)).toList();
        return Success(rentalRequests);
      }

      return Failure("Failed to get rental requests: ${response.statusCode}");
    } on DioException catch (e) {
      if (kDebugMode) {
        print('DioException in getRentalRequestsByReceiverId: ${e.message}');
        print('Response data: ${e.response?.data}');
      }

      return Failure(e.message ?? "Failed to get rental requests");
    } catch (e) {
      if (kDebugMode) {
        print('Exception in getRentalRequestsByReceiverId: $e');
      }
      return Failure("Unexpected error: $e");
    }
  }

  @override
  Future<Result<bool>> exitRentedRoom(String rentedRoomId) async {
    try {
      final response = await _dio.delete(
        '/api/v1/rented-rooms/exit/$rentedRoomId',
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
        ),
      );
      if (response.statusCode == 200) {
        return Success(true);
      }
      return Failure('Không thể thoát phòng: ${response.statusCode}');
    } on DioException catch (e) {
      return Failure(e.message ?? 'Có lỗi xảy ra khi thoát phòng');
    } catch (e) {
      return Failure('Có lỗi không xác định khi thoát phòng: $e');
    }
  }
}
