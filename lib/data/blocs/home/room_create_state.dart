import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/room.dart';

import '../../models/models.dart';
import '../../models/room_create.dart';

sealed class RoomCreateState extends Equatable {
  @override
  List<Object?> get props => [];
}

class RoomCreateInitial extends RoomCreateState {}

class RoomCreateLoading extends RoomCreateState {}

class RoomCreateLoaded extends RoomCreateState {
  final String roomId;

  RoomCreateLoaded({required this.roomId});

  @override
  List<Object?> get props => [roomId];
}

class RoomUpdateLoaded extends RoomCreateState {
  final Room room;

  RoomUpdateLoaded({required this.room});

  @override
  List<Object?> get props => [room];
}

class RoomCreateError extends RoomCreateState {
  final String message;

  RoomCreateError({required this.message});

  @override
  List<Object?> get props => [message];
}
