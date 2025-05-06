import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/campaign_create_model.dart';
import 'package:roomily/data/repositories/ad_repository.dart';
import 'package:roomily/data/blocs/campaigns/campaigns_state.dart';

class CampaignsCubit extends Cubit<CampaignsState> {
  final AdRepository _adRepository;

  CampaignsCubit({required AdRepository adRepository})
      : _adRepository = adRepository,
        super(CampaignsInitial());

  Future<void> fetchCampaigns() async {
    emit(CampaignsLoading());
    try {
      final campaigns = await _adRepository.getCampaigns();
      if (!isClosed) {
        emit(CampaignsLoaded(campaigns));
      }
    } catch (e) {
      if (!isClosed) {
        // TODO: Improve error handling (e.g., parse specific exceptions)
        emit(CampaignsError(e.toString()));
      }
    }
  }
  
  Future<void> pauseCampaign(String campaignId) async {
    // Lưu state hiện tại để khôi phục nếu cần
    final currentState = state;
    
    // Emit trạng thái đang pause
    if (!isClosed) {
      emit(PausingCampaign(campaignId));
    }
    
    try {
      await _adRepository.pauseCampaign(campaignId);
      
      if (!isClosed) {
        // Báo thành công
        emit(PauseCampaignSuccess(campaignId));
        
        // Fetch lại campaigns để cập nhật UI
        await fetchCampaigns();
      }
    } catch (e) {
      if (!isClosed) {
        // Báo lỗi
        emit(PauseCampaignError(campaignId, e.toString()));
        
        // Khôi phục state trước đó
        if (currentState is CampaignsLoaded) {
          emit(currentState);
        }
      }
    }
  }
  
  Future<void> resumeCampaign(String campaignId) async {
    // Lưu state hiện tại để khôi phục nếu cần
    final currentState = state;
    
    // Emit trạng thái đang resume
    if (!isClosed) {
      emit(ResumingCampaign(campaignId));
    }
    
    try {
      await _adRepository.resumeCampaign(campaignId);
      
      if (!isClosed) {
        // Báo thành công
        emit(ResumeCampaignSuccess(campaignId));
        
        // Fetch lại campaigns để cập nhật UI
        await fetchCampaigns();
      }
    } catch (e) {
      if (!isClosed) {
        // Báo lỗi
        emit(ResumeCampaignError(campaignId, e.toString()));
        
        // Khôi phục state trước đó
        if (currentState is CampaignsLoaded) {
          emit(currentState);
        }
      }
    }
  }
  
  Future<void> deleteCampaign(String campaignId) async {
    // Lưu state hiện tại để khôi phục nếu cần
    final currentState = state;
    
    // Emit trạng thái đang xóa
    if (!isClosed) {
      emit(DeletingCampaign(campaignId));
    }
    
    try {
      await _adRepository.deleteCampaign(campaignId);
      
      if (!isClosed) {
        // Báo thành công
        emit(DeleteCampaignSuccess(campaignId));
        
        // Fetch lại campaigns để cập nhật UI
        await fetchCampaigns();
      }
    } catch (e) {
      if (!isClosed) {
        // Báo lỗi
        emit(DeleteCampaignError(campaignId, e.toString()));
        
        // Khôi phục state trước đó
        if (currentState is CampaignsLoaded) {
          emit(currentState);
        }
      }
    }
  }
  
  Future<void> updateCampaign(String campaignId, CampaignCreateModel campaignData) async {
    // Lưu state hiện tại để khôi phục nếu cần
    final currentState = state;
    
    // Emit trạng thái đang cập nhật
    if (!isClosed) {
      emit(UpdatingCampaign(campaignId));
    }
    
    try {
      await _adRepository.updateCampaign(campaignId, campaignData);
      
      if (!isClosed) {
        // Báo thành công - không tự động fetch lại campaigns ở đây
        emit(UpdateCampaignSuccess(campaignId));
      }
    } catch (e) {
      if (!isClosed) {
        // Báo lỗi
        emit(UpdateCampaignError(campaignId, e.toString()));
        
        // Khôi phục state trước đó
        if (currentState is CampaignsLoaded) {
          emit(currentState);
        }
      }
    }
  }
} 