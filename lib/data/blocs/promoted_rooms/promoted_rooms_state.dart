import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/promoted_room_model.dart';
import 'package:roomily/data/models/ad_click_response_model.dart';

abstract class PromotedRoomsState extends Equatable {
  const PromotedRoomsState();

  @override
  List<Object?> get props => [];
}

class PromotedRoomsInitial extends PromotedRoomsState {}

class PromotedRoomsLoading extends PromotedRoomsState {}

class PromotedRoomsProcessing extends PromotedRoomsState {}

class PromotedRoomsLoaded extends PromotedRoomsState {
  final List<PromotedRoomModel> promotedRooms;

  const PromotedRoomsLoaded(this.promotedRooms);

  @override
  List<Object?> get props => [promotedRooms];
}

class PromotedRoomsClickTracked extends PromotedRoomsState {
  final AdClickResponseModel response;

  const PromotedRoomsClickTracked(this.response);

  @override
  List<Object?> get props => [response];
}

class PromotedRoomsError extends PromotedRoomsState {
  final String message;

  const PromotedRoomsError(this.message);

  @override
  List<Object?> get props => [message];
} 