import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/room.dart';

abstract class LandlordRoomsState extends Equatable {
  const LandlordRoomsState();

  @override
  List<Object> get props => [];
}

class LandlordRoomsInitial extends LandlordRoomsState {}

class LandlordRoomsLoading extends LandlordRoomsState {}

class LandlordRoomsLoaded extends LandlordRoomsState {
  final List<Room> rooms;

  const LandlordRoomsLoaded({required this.rooms});

  @override
  List<Object> get props => [rooms];
}

class LandlordRoomsError extends LandlordRoomsState {
  final String message;

  const LandlordRoomsError({required this.message});

  @override
  List<Object> get props => [message];
}

// Trạng thái đang xử lý (cho các hoạt động như xóa, cập nhật)
class LandlordRoomsProcessing extends LandlordRoomsState {}

// Trạng thái thành công (sau khi hoàn thành các hoạt động như xóa, cập nhật)
class LandlordRoomsSuccess extends LandlordRoomsState {
  final String message;

  const LandlordRoomsSuccess({required this.message});

  @override
  List<Object> get props => [message];
} 