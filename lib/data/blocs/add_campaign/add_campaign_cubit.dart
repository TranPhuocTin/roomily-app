import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/campaign_create_model.dart';
import 'package:roomily/data/repositories/ad_repository.dart';

import 'add_campaign_state.dart';

class AddCampaignCubit extends Cubit<AddCampaignState> {
  final AdRepository _adRepository;

  AddCampaignCubit({required AdRepository adRepository})
      : _adRepository = adRepository,
        super(AddCampaignInitial());

  Future<void> createCampaign(CampaignCreateModel campaignData) async {
    emit(AddCampaignLoading());
    try {
      await _adRepository.createCampaign(campaignData);
      if (!isClosed) {
        emit(const AddCampaignSuccess());
      }
    } catch (e) {
      if (!isClosed) {
        emit(AddCampaignFailure(e.toString()));
      }
    }
  }
} 