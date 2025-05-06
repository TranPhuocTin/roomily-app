import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/repositories/ad_repository.dart';
import 'package:roomily/data/blocs/promoted_rooms/promoted_rooms_state.dart';
import 'package:roomily/data/models/ad_click_request_model.dart';
import 'package:roomily/data/models/ad_click_response_model.dart';

class PromotedRoomsCubit extends Cubit<PromotedRoomsState> {
  final AdRepository _adRepository;

  PromotedRoomsCubit({required AdRepository adRepository})
      : _adRepository = adRepository,
        super(PromotedRoomsInitial());

  Future<void> fetchPromotedRooms(String campaignId) async {
    try {
      emit(PromotedRoomsLoading());
      final promotedRooms = await _adRepository.getPromotedRoomsByCampaign(campaignId);
      emit(PromotedRoomsLoaded(promotedRooms));
    } catch (e) {
      emit(PromotedRoomsError(e.toString()));
    }
  }
  
  Future<void> addPromotedRoom(String campaignId, String roomId, double? bid) async {
    try {
      emit(PromotedRoomsProcessing());
      await _adRepository.addPromotedRoom(campaignId, roomId, cpcBid: bid);
      // Refetch the promoted rooms to update the list
      final promotedRooms = await _adRepository.getPromotedRoomsByCampaign(campaignId);
      emit(PromotedRoomsLoaded(promotedRooms));
    } catch (e) {
      emit(PromotedRoomsError(e.toString()));
    }
  }
  
  Future<void> deletePromotedRoom(String promotedRoomId, String campaignId) async {
    try {
      emit(PromotedRoomsProcessing());
      await _adRepository.deletePromotedRoom(promotedRoomId);
      // Refetch the promoted rooms to update the list after deletion
      final promotedRooms = await _adRepository.getPromotedRoomsByCampaign(campaignId);
      emit(PromotedRoomsLoaded(promotedRooms));
    } catch (e) {
      emit(PromotedRoomsError(e.toString()));
    }
  }
  
  Future<void> updatePromotedRoom(String promotedRoomId, double? bid, String campaignId) async {
    try {
      emit(PromotedRoomsProcessing());
      await _adRepository.updatePromotedRoom(promotedRoomId, cpcBid: bid);
      // Refetch the promoted rooms to update the list after updating
      final promotedRooms = await _adRepository.getPromotedRoomsByCampaign(campaignId);
      emit(PromotedRoomsLoaded(promotedRooms));
    } catch (e) {
      emit(PromotedRoomsError(e.toString()));
    }
  }
  
  Future<AdClickResponseModel?> trackPromotedRoomClick(
    String promotedRoomId, 
    String ipAddress, 
    String userId
  ) async {
    try {
      emit(PromotedRoomsProcessing());
      
      final clickData = AdClickRequestModel(
        promotedRoomId: promotedRoomId,
        ipAddress: ipAddress,
        userId: userId,
      );
      
      final response = await _adRepository.trackPromotedRoomClick(clickData);
      
      // We don't need to refetch the promoted rooms list here since clicks don't change the list
      emit(PromotedRoomsClickTracked(response));
      
      return response;
    } catch (e) {
      emit(PromotedRoomsError(e.toString()));
      return null;
    }
  }
} 