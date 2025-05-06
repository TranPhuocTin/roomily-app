import 'package:equatable/equatable.dart';

import '../../models/models.dart';

abstract class RoomReviewState extends Equatable {
  const RoomReviewState();

  @override
  List<Object> get props => [];
}

class RoomReviewInitial extends RoomReviewState {}

class RoomReviewLoading extends RoomReviewState {}

class RoomReviewLoaded extends RoomReviewState {
  final List<RoomReview> reviews;

  const RoomReviewLoaded({required this.reviews});

  @override
  List<Object> get props => [reviews];
}

class RoomReviewError extends RoomReviewState {
  final String message;

  const RoomReviewError({required this.message});

  @override
  List<Object> get props => [message];
}

