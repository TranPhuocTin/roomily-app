import 'package:equatable/equatable.dart';

abstract class RoomReportState extends Equatable {
  const RoomReportState();

  @override
  List<Object?> get props => [];
}

class RoomReportInitial extends RoomReportState {}

class RoomReportLoading extends RoomReportState {}

class RoomReportSuccess extends RoomReportState {}

class RoomReportError extends RoomReportState {
  final String message;

  const RoomReportError({required this.message});

  @override
  List<Object?> get props => [message];
} 