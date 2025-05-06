import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/campaign_model.dart';

abstract class CampaignsState extends Equatable {
  const CampaignsState();

  @override
  List<Object?> get props => [];
}

class CampaignsInitial extends CampaignsState {}

class CampaignsLoading extends CampaignsState {}

class CampaignsLoaded extends CampaignsState {
  final List<CampaignModel> campaigns;

  const CampaignsLoaded(this.campaigns);

  @override
  List<Object?> get props => [campaigns];
}

class CampaignsError extends CampaignsState {
  final String message;

  const CampaignsError(this.message);

  @override
  List<Object?> get props => [message];
}

// States for pausing a campaign
class PausingCampaign extends CampaignsState {
  final String campaignId;
  
  const PausingCampaign(this.campaignId);
  
  @override
  List<Object?> get props => [campaignId];
}

class PauseCampaignSuccess extends CampaignsState {
  final String campaignId;
  
  const PauseCampaignSuccess(this.campaignId);
  
  @override
  List<Object?> get props => [campaignId];
}

class PauseCampaignError extends CampaignsState {
  final String campaignId;
  final String message;
  
  const PauseCampaignError(this.campaignId, this.message);
  
  @override
  List<Object?> get props => [campaignId, message];
}

// States for resuming a campaign
class ResumingCampaign extends CampaignsState {
  final String campaignId;
  
  const ResumingCampaign(this.campaignId);
  
  @override
  List<Object?> get props => [campaignId];
}

class ResumeCampaignSuccess extends CampaignsState {
  final String campaignId;
  
  const ResumeCampaignSuccess(this.campaignId);
  
  @override
  List<Object?> get props => [campaignId];
}

class ResumeCampaignError extends CampaignsState {
  final String campaignId;
  final String message;
  
  const ResumeCampaignError(this.campaignId, this.message);
  
  @override
  List<Object?> get props => [campaignId, message];
}

// States for deleting a campaign
class DeletingCampaign extends CampaignsState {
  final String campaignId;
  
  const DeletingCampaign(this.campaignId);
  
  @override
  List<Object?> get props => [campaignId];
}

class DeleteCampaignSuccess extends CampaignsState {
  final String campaignId;
  
  const DeleteCampaignSuccess(this.campaignId);
  
  @override
  List<Object?> get props => [campaignId];
}

class DeleteCampaignError extends CampaignsState {
  final String campaignId;
  final String message;
  
  const DeleteCampaignError(this.campaignId, this.message);
  
  @override
  List<Object?> get props => [campaignId, message];
}

// States for updating a campaign
class UpdatingCampaign extends CampaignsState {
  final String campaignId;
  
  const UpdatingCampaign(this.campaignId);
  
  @override
  List<Object?> get props => [campaignId];
}

class UpdateCampaignSuccess extends CampaignsState {
  final String campaignId;
  
  const UpdateCampaignSuccess(this.campaignId);
  
  @override
  List<Object?> get props => [campaignId];
}

class UpdateCampaignError extends CampaignsState {
  final String campaignId;
  final String message;
  
  const UpdateCampaignError(this.campaignId, this.message);
  
  @override
  List<Object?> get props => [campaignId, message];
} 