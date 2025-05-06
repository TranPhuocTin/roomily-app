import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/repositories/favorite_repository.dart';

import 'favorite_state.dart';

class FavoriteCubit extends Cubit<FavoriteState> {
  final FavoriteRepository repository;

  FavoriteCubit(this.repository) : super(FavoriteInitial());

  Future<void> getFavoriteRooms() async {
    emit(FavoriteLoading());

    final result = await repository.getRoomFavorites();
    
    switch (result) {
      case Success(data: final rooms):
        if (state is FavoriteLoaded) {
          final currentState = state as FavoriteLoaded;
          emit(currentState.copyWith(favoriteRooms: rooms));
        } else {
          emit(FavoriteLoaded(favoriteRooms: rooms));
        }
      case Failure(message: final message):
        emit(FavoriteError(message: message));
    }
  }

  Future<void> toggleFavorite(String roomId) async {
    // Lưu trạng thái hiện tại
    final currentState = state;
    
    // Kiểm tra trạng thái yêu thích hiện tại
    final checkResult = await repository.checkRoomIsFavorite(roomId);
    
    bool currentFavoriteStatus = false;
    switch (checkResult) {
      case Success(data: final isFavorite):
        currentFavoriteStatus = isFavorite;
        print('[FavoriteCubit] Current favorite status: $currentFavoriteStatus');
      case Failure(message: final message):
        print('[FavoriteCubit] Error checking favorite status: $message');
        emit(FavoriteError(message: message));
        return;
    }
    
    // Optimistically update UI
    if (currentState is FavoriteLoaded) {
      print('[FavoriteCubit] Current favorite rooms count: ${currentState.favoriteRooms.length}');
      // If we're removing a favorite, remove it from the favoriteRooms list
      List<Room> updatedRooms = List.from(currentState.favoriteRooms);
      
      if (currentFavoriteStatus) {
        updatedRooms.removeWhere((room) => room.id == roomId);
        print('[FavoriteCubit] Removed room from list. New count: ${updatedRooms.length}');
      }
      
      emit(currentState.copyWith(
        favoriteRooms: updatedRooms,
        isFavorite: !currentFavoriteStatus,
        roomFavoriteCount: currentFavoriteStatus 
          ? currentState.roomFavoriteCount - 1 
          : currentState.roomFavoriteCount + 1,
        userFavoriteCount: currentFavoriteStatus 
          ? currentState.userFavoriteCount - 1 
          : currentState.userFavoriteCount + 1,
      ));
      print('[FavoriteCubit] Emitted new state with ${updatedRooms.length} rooms');
    }

    // Thực hiện toggle
    final result = await repository.toggleFavoriteRoom(roomId);
    
    switch (result) {
      case Success(data: final toggleResult):
        print('[FavoriteCubit] Toggle result: $toggleResult');
        // toggleResult = true nghĩa là phòng vừa được thêm vào danh sách yêu thích
        // toggleResult = false nghĩa là phòng vừa bị xóa khỏi danh sách yêu thích
        
        // Kiểm tra xem kết quả có khớp với dự đoán không
        bool expectedResult = !currentFavoriteStatus;
        if (toggleResult != expectedResult) {
          print('[FavoriteCubit] Toggle result doesn\'t match expected result. Refreshing list...');
          // Nếu kết quả không khớp với dự đoán, cập nhật lại danh sách
          await getFavoriteRooms();
        } else {
          print('[FavoriteCubit] Toggle successful as expected');
        }
      case Failure(message: final message):
        print('[FavoriteCubit] Toggle error: $message');
        // Khôi phục lại trạng thái cũ nếu có lỗi
        if (currentState is FavoriteLoaded) {
          emit(currentState);
        }
        emit(FavoriteError(message: message));
    }
  }

  Future<void> getUserFavoriteCount() async {
    final result = await repository.getTotalFavoriteCountOfUser();
    
    switch (result) {
      case Success(data: final count):
        if (state is FavoriteLoaded) {
          final currentState = state as FavoriteLoaded;
          emit(currentState.copyWith(userFavoriteCount: count));
        } else {
          emit(FavoriteLoaded(userFavoriteCount: count));
        }
      case Failure(message: final message):
        emit(FavoriteError(message: message));
    }
  }

  Future<void> getRoomFavoriteCount(String roomId) async {
    final result = await repository.getTotalFavoriteCountOfRoom(roomId);
    
    switch (result) {
      case Success(data: final count):
        if (state is FavoriteLoaded) {
          final currentState = state as FavoriteLoaded;
          emit(currentState.copyWith(roomFavoriteCount: count));
        } else {
          emit(FavoriteLoaded(roomFavoriteCount: count));
        }
      case Failure(message: final message):
        emit(FavoriteError(message: message));
    }
  }

  Future<void> checkRoomIsFavorite(String roomId) async {
    final result = await repository.checkRoomIsFavorite(roomId);
    
    switch (result) {
      case Success(data: final isFavorite):
        if (state is FavoriteLoaded) {
          final currentState = state as FavoriteLoaded;
          emit(currentState.copyWith(isFavorite: isFavorite));
        } else {
          emit(FavoriteLoaded(isFavorite: isFavorite));
        }
      case Failure(message: final message):
        emit(FavoriteError(message: message));
    }
  }

  Future<void> loadRoomFavoriteData(String roomId) async {
    emit(FavoriteLoading());
    
    // Kiểm tra trạng thái yêu thích trước
    final checkResult = await repository.checkRoomIsFavorite(roomId);
    
    bool isFavorite = false;
    switch (checkResult) {
      case Success(data: final favoriteStatus):
        isFavorite = favoriteStatus;
        // Emit trạng thái ban đầu với isFavorite
        emit(FavoriteLoaded(isFavorite: isFavorite));
      case Failure(message: final message):
        emit(FavoriteError(message: message));
        return; // Dừng nếu có lỗi khi kiểm tra trạng thái
    }
    
    // Sau đó lấy số lượt yêu thích của phòng
    final countResult = await repository.getTotalFavoriteCountOfRoom(roomId);
    
    switch (countResult) {
      case Success(data: final count):
        if (state is FavoriteLoaded) {
          final currentState = state as FavoriteLoaded;
          // Giữ nguyên trạng thái yêu thích và cập nhật số lượng
          emit(currentState.copyWith(
            isFavorite: isFavorite,
            roomFavoriteCount: count
          ));
        }
      case Failure(message: final message):
        emit(FavoriteError(message: message));
    }
  }
} 