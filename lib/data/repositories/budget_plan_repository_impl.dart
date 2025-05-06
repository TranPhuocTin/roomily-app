import 'package:dio/dio.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/data/models/budget_plan_preference.dart';
import 'package:roomily/data/models/budget_plan_room.dart';
import 'package:roomily/data/models/budget_plan_room_detail.dart';
import 'package:roomily/data/repositories/budget_plan_repository.dart';

class BudgetPlanRepositoryImpl implements BudgetPlanRepository {
  final Dio _dio;

  BudgetPlanRepositoryImpl({Dio? dio}) : _dio = dio ?? DioConfig.createDio();

  @override
  Future<bool> saveBudgetPlanPreference(BudgetPlanPreference preference) async {
    try {
      final response = await _dio.post(ApiConstants.saveBudgetPlanPreference(),
        data: preference.toJson(),
      );
      
      return response.statusCode == 200 || response.statusCode == 201;
    } on DioException catch (e) {
      print('Error saving budget plan preference: $e');
      return false;
    } catch (e) {
      print('Unexpected error saving budget plan preference: $e');
      return false;
    }
  }
  
  @override
  Future<List<BudgetPlanRoom>> getSearchedRooms() async {
    try {
      final response = await _dio.get(ApiConstants.getSearchedRooms(),
      );
      
      if (response.statusCode == 200) {
        final List<dynamic> roomsJson = response.data;
        return roomsJson
            .map((roomJson) => BudgetPlanRoom.fromJson(roomJson))
            .toList();
      } else {
        return [];
      }
    } on DioException catch (e) {
      print('Error getting searched rooms: $e');
      return [];
    } catch (e) {
      print('Unexpected error getting searched rooms: $e');
      return [];
    }
  }
  
  @override
  Future<BudgetPlanRoomDetail> getRoomBudgetPlanDetail(String roomId, int scope) async {
    try {
      // Validate the scope parameter
      if (scope < 1 || scope > 3) {
        throw ArgumentError('Scope must be between 1 and 3 (1=ward, 2=district, 3=city)');
      }
      
      final response = await _dio.get(
        ApiConstants.getRoomBudgetPlanDetail(roomId),
        queryParameters: {
          'scope': scope,
        },
      );
      
      if (response.statusCode == 200) {
        return BudgetPlanRoomDetail.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch room budget plan details. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Error getting room budget plan detail: $e');
      throw Exception('Failed to fetch room budget plan details: ${e.message}');
    } catch (e) {
      print('Unexpected error getting room budget plan detail: $e');
      throw Exception('Unexpected error: $e');
    }
  }
  
  @override
  Future<bool> isUserPreferenceExists() async {
    try {
      final response = await _dio.get(ApiConstants.isUserPreferenceExists());
      
      if (response.statusCode == 200) {
        // API should return a boolean directly
        return response.data == true;
      } else {
        return false;
      }
    } on DioException catch (e) {
      print('Error checking if user preference exists: $e');
      return false;
    } catch (e) {
      print('Unexpected error checking if user preference exists: $e');
      return false;
    }
  }
  
  @override
  Future<BudgetPlanPreference> extractUserPrompt(String userPrompt) async {
    try {
      final response = await _dio.post(
        '${ApiConstants.recommendBaseUrl}${ApiConstants.extractUserPrompt()}',
        data: {
          'sentence': userPrompt,
        },
      );
      
      if (response.statusCode == 200) {
        return BudgetPlanPreference.fromJson(response.data);
      } else {
        throw Exception('Failed to extract user prompt. Status code: ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('Error extracting user prompt: $e');
      throw Exception('Failed to extract user prompt: ${e.message}');
    } catch (e) {
      print('Unexpected error extracting user prompt: $e');
      throw Exception('Unexpected error: $e');
    }
  }
} 