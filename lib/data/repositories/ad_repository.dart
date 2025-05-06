import 'package:roomily/data/models/campaign_create_model.dart';
import 'package:roomily/data/models/campaign_model.dart';
import 'package:roomily/data/models/promoted_room_model.dart';
import 'package:roomily/data/models/ad_click_request_model.dart';
import 'package:roomily/data/models/ad_click_response_model.dart';
import 'package:roomily/data/models/ad_impression_request_model.dart';
abstract class AdRepository {
  Future<void> createCampaign(CampaignCreateModel campaignData);
  Future<List<CampaignModel>> getCampaigns();
  Future<void> pauseCampaign(String campaignId);
  Future<void> resumeCampaign(String campaignId);
  Future<void> deleteCampaign(String campaignId);
  Future<void> updateCampaign(String campaignId, CampaignCreateModel campaignData);
  Future<List<PromotedRoomModel>> getPromotedRoomsByCampaign(String campaignId);
  Future<void> addPromotedRoom(String campaignId, String roomId, {double? cpcBid});
  Future<void> deletePromotedRoom(String promotedRoomId);
  Future<void> updatePromotedRoom(String promotedRoomId, {double? cpcBid});
  Future<AdClickResponseModel> trackPromotedRoomClick(AdClickRequestModel clickData);
  Future<void> trackPromotedRoomImpression(AdImpressionRequestModel impressionData);
} 