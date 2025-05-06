import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/home/room_review_state.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/repositories/room_repository.dart';

import '../../../core/utils/result.dart';
import '../../repositories/review_repository.dart';

class RoomReviewCubit extends Cubit<RoomReviewState> {
  ReviewRepository repository;

  RoomReviewCubit(this.repository) : super(RoomReviewInitial());

  Future<void> fetchRoomReviews(String roomId) async {
    emit(RoomReviewLoading());

    final result = await repository.getReviewsByRoom(roomId);

    switch (result) {
      case Success(data: final reviews):
        emit(RoomReviewLoaded(reviews: reviews));
        break;
      case Failure(message: final message):
        emit(RoomReviewError(message: message));
        break;
    }
  }
}