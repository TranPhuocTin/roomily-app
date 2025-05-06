import 'package:equatable/equatable.dart';

abstract class AddCampaignState extends Equatable {
  const AddCampaignState();

  @override
  List<Object?> get props => [];
}

class AddCampaignInitial extends AddCampaignState {}

class AddCampaignLoading extends AddCampaignState {}

class AddCampaignSuccess extends AddCampaignState {
  const AddCampaignSuccess();
}

class AddCampaignFailure extends AddCampaignState {
  final String error;

  const AddCampaignFailure(this.error);

  @override
  List<Object?> get props => [error];
} 