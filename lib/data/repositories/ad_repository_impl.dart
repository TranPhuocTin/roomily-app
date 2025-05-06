import 'package:dio/dio.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/data/models/campaign_create_model.dart';
import 'package:roomily/data/models/campaign_model.dart';
import 'package:roomily/data/models/promoted_room_model.dart';
import 'package:roomily/data/models/ad_click_request_model.dart';
import 'package:roomily/data/models/ad_click_response_model.dart';
import 'package:roomily/data/repositories/ad_repository.dart';
import 'package:roomily/data/models/ad_impression_request_model.dart';

class AdRepositoryImpl implements AdRepository {
  final Dio _dio;

  AdRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<void> createCampaign(CampaignCreateModel campaignData) async {
    try {
      await _dio.post(
        ApiConstants.createCampaign(),
        data: campaignData.toJson(),
      );
    } on DioException catch (e) {
      // TODO: Handle specific DioExceptions (e.g., 4xx, 5xx) and rethrow custom errors
      print('DioException creating campaign: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error creating campaign: $e');
      rethrow;
    }
  }

  @override
  Future<List<CampaignModel>> getCampaigns() async {
    try {
      final response = await _dio.get(ApiConstants.getCampaigns());
      // Assuming the response data is a List<dynamic>
      if (response.data is List) {
        final List<dynamic> dataList = response.data;
        return dataList.map((json) => CampaignModel.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        // Handle unexpected response format
        throw Exception('Unexpected response format for campaigns');
      }
    } on DioException catch (e) {
      // TODO: Handle specific DioExceptions (e.g., 4xx, 5xx) and rethrow custom errors
      print('DioException fetching campaigns: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error fetching campaigns: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> pauseCampaign(String campaignId) async {
    try {
      await _dio.patch(
        ApiConstants.pauseCampaign(campaignId),
      );
    } on DioException catch (e) {
      print('DioException pausing campaign: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error pausing campaign: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> resumeCampaign(String campaignId) async {
    try {
      await _dio.patch(
        ApiConstants.resumeCampaign(campaignId),
      );
    } on DioException catch (e) {
      print('DioException resuming campaign: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error resuming campaign: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> deleteCampaign(String campaignId) async {
    try {
      await _dio.delete(
        ApiConstants.deleteCampaign(campaignId),
      );
    } on DioException catch (e) {
      print('DioException deleting campaign: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error deleting campaign: $e');
      rethrow;
    }
  }
  
  @override
  Future<void> updateCampaign(String campaignId, CampaignCreateModel campaignData) async {
    try {
      await _dio.put(
        ApiConstants.updateCampaign(campaignId),
        data: campaignData.toJson(),
      );
    } on DioException catch (e) {
      print('DioException updating campaign: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error updating campaign: $e');
      rethrow;
    }
  }
  
  @override
  Future<List<PromotedRoomModel>> getPromotedRoomsByCampaign(String campaignId) async {
    try {
      final response = await _dio.get(
        ApiConstants.getPromotedRoomsByCampaign(campaignId),
      );
      
      // Assuming the response data is a List<dynamic>
      if (response.data is List) {
        final List<dynamic> dataList = response.data;
        return dataList.map((json) => 
          PromotedRoomModel.fromJson(json as Map<String, dynamic>)
        ).toList();
      } else {
        // Handle unexpected response format
        throw Exception('Unexpected response format for promoted rooms');
      }
    } on DioException catch (e) {
      print('DioException fetching promoted rooms: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error fetching promoted rooms: $e');
      rethrow;
    }
  }

  @override
  Future<void> addPromotedRoom(String campaignId, String roomId, {double? cpcBid}) async {
    try {
      final Map<String, dynamic> data = {
        'roomId': roomId,
      };
      
      // Chỉ thêm cpcBid nếu nó được cung cấp (cho mô hình CPC)
      if (cpcBid != null) {
        data['cpcBid'] = cpcBid;
      }
      
      await _dio.post(
        ApiConstants.getPromotedRoomsByCampaign(campaignId),
        data: data,
      );
    } on DioException catch (e) {
      print('DioException adding promoted room: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error adding promoted room: $e');
      rethrow;
    }
  }

  @override
  Future<void> deletePromotedRoom(String promotedRoomId) async {
    try {
      await _dio.delete(
        ApiConstants.deletePromotedRoom(promotedRoomId),
      );
    } on DioException catch (e) {
      print('DioException deleting promoted room: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error deleting promoted room: $e');
      rethrow;
    }
  }

  @override
  Future<void> updatePromotedRoom(String promotedRoomId, {double? cpcBid}) async {
    try {
      final data = <String, dynamic>{};
      
      // Chỉ cập nhật cpcBid nếu nó được cung cấp (cho mô hình CPC)
      if (cpcBid != null) {
        data['cpcBid'] = cpcBid;
      }
      
      await _dio.patch(
        ApiConstants.updatePromotedRoom(promotedRoomId),
        data: data,
      );
    } on DioException catch (e) {
      print('DioException updating promoted room: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error updating promoted room: $e');
      rethrow;
    }
  }

  @override
  Future<AdClickResponseModel> trackPromotedRoomClick(AdClickRequestModel clickData) async {
    try {
      final response = await _dio.patch(
        ApiConstants.trackPromotedRoomClick(),
        data: clickData.toJson(),
      );
      
      return AdClickResponseModel.fromJson(response.data);
    } on DioException catch (e) {
      print('DioException tracking promoted room click: ${e.message}');
      rethrow;
    } catch (e) {
      print('Error tracking promoted room click: $e');
      rethrow;
    }
  }

  @override
Future<void> trackPromotedRoomImpression(AdImpressionRequestModel impressionData) async {
  try {
    await _dio.patch(
      ApiConstants.trackPromotedRoomImpression(),
      data: impressionData.toJson(),
    );
  } on DioException catch (e) {
    print('DioException tracking impression: ${e.message}');
    rethrow;
  } catch (e) {
    print('Error tracking impression: $e');
    rethrow;
  }
}
} 