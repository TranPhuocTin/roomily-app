import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/home/room_detail_state.dart';
import 'package:roomily/data/models/room_create.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/core/utils/result.dart';

import '../../models/room.dart';

class RoomDetailCubit extends Cubit<RoomDetailState> {
  final RoomRepository repository;

  RoomDetailCubit(this.repository) : super(RoomDetailInitial());

  Future<void> fetchRoomById(String id) async {
    emit(RoomDetailLoading());

    final result = await repository.getRoom(id);
    
    switch (result) {
      case Success(data: final room):
        emit(RoomDetailLoaded(room: room));
      case Failure(message: final message):
        emit(RoomDetailError(message: message));
    }
  }
}
