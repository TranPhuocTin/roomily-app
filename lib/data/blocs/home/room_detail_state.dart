import 'package:equatable/equatable.dart';

import '../../models/models.dart';

abstract class RoomDetailState extends Equatable {
  const RoomDetailState();

  @override
  List<Object> get props => [];
}

class RoomDetailInitial extends RoomDetailState {}

class RoomDetailLoading extends RoomDetailState {}

class RoomDetailLoaded extends RoomDetailState {
  final Room room;

  const RoomDetailLoaded({required this.room});

  @override
  List<Object> get props => [room];
}

class RoomDetailError extends RoomDetailState {
  final String message;

  const RoomDetailError({required this.message});

  @override
  List<Object> get props => [message];
}

class RoomDetailDeleted extends RoomDetailState {}
