import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/repositories/room_repository.dart';

import 'landlord_rooms_state.dart';

class LandlordRoomsCubit extends Cubit<LandlordRoomsState> {
  final RoomRepository _roomRepository;

  LandlordRoomsCubit({
    required RoomRepository roomRepository,
  })  : _roomRepository = roomRepository,
        super(LandlordRoomsInitial());

  /// Loads all rooms for a specific landlord
  Future<void> getLandlordRooms(String landlordId) async {
    if (kDebugMode) {
      print('Loading rooms for landlord: $landlordId');
    }
    
    emit(LandlordRoomsLoading());

    final result = await _roomRepository.getLandlordRooms(landlordId);

    switch (result) {
      case Success(data: final rooms):
        if (kDebugMode) {
          print('Successfully loaded ${rooms.length} rooms for landlord');
        }
        emit(LandlordRoomsLoaded(rooms: rooms));
      case Failure(message: final message):
        if (kDebugMode) {
          print('Failed to load landlord rooms: $message');
        }
        emit(LandlordRoomsError(message: message));
    }
  }

  /// Filters rooms by status
  void filterRoomsByStatus(String status) {
    if (state is LandlordRoomsLoaded) {
      final currentState = state as LandlordRoomsLoaded;
      final allRooms = currentState.rooms;
      
      if (status == 'Tất cả') {
        emit(LandlordRoomsLoaded(rooms: allRooms));
        return;
      }
      
      final filteredRooms = allRooms.where((room) => room.status == status).toList();
      emit(LandlordRoomsLoaded(rooms: filteredRooms));
    }
  }

  /// Searches rooms by query
  void searchRooms(String query) {
    if (state is LandlordRoomsLoaded) {
      final currentState = state as LandlordRoomsLoaded;
      final allRooms = currentState.rooms;
      
      if (query.isEmpty) {
        emit(LandlordRoomsLoaded(rooms: allRooms));
        return;
      }
      
      final searchLower = query.toLowerCase();
      final filteredRooms = allRooms.where((room) {
        return room.title.toLowerCase().contains(searchLower) ||
               room.address.toLowerCase().contains(searchLower) ||
               room.description.toLowerCase().contains(searchLower);
      }).toList();
      
      emit(LandlordRoomsLoaded(rooms: filteredRooms));
    }
  }

  /// Làm mới dữ liệu phòng
  Future<void> refreshLandlordRooms(String landlordId) async {
    if (kDebugMode) {
      print('Refreshing rooms for landlord: $landlordId');
    }
    
    // Không thay đổi trạng thái hiện tại nhưng vẫn fetch lại dữ liệu
    final result = await _roomRepository.getLandlordRooms(landlordId);

    switch (result) {
      case Success(data: final rooms):
        if (kDebugMode) {
          print('Successfully refreshed ${rooms.length} rooms for landlord');
        }
        emit(LandlordRoomsLoaded(rooms: rooms));
      case Failure(message: final message):
        if (kDebugMode) {
          print('Failed to refresh landlord rooms: $message');
        }
        // Chỉ emit lỗi nếu không có dữ liệu trước đó
        if (state is! LandlordRoomsLoaded) {
          emit(LandlordRoomsError(message: message));
        }
    }
  }
  
  /// Thử lại tải dữ liệu với số lần thử
  Future<void> retryGetLandlordRooms(String landlordId, {int retries = 3}) async {
    if (kDebugMode) {
      print('Retrying to load rooms for landlord: $landlordId, remaining retries: $retries');
    }
    
    if (retries <= 0) {
      if (kDebugMode) {
        print('No more retries left for loading landlord rooms');
      }
      return;
    }
    
    try {
      emit(LandlordRoomsLoading());
      final result = await _roomRepository.getLandlordRooms(landlordId);
      
      switch (result) {
        case Success(data: final rooms):
          if (kDebugMode) {
            print('Successfully loaded ${rooms.length} rooms for landlord after retry');
          }
          emit(LandlordRoomsLoaded(rooms: rooms));
        case Failure(message: final message):
          if (kDebugMode) {
            print('Failed to load landlord rooms after retry: $message');
          }
          // Thử lại sau 1 giây
          await Future.delayed(Duration(seconds: 1));
          retryGetLandlordRooms(landlordId, retries: retries - 1);
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error during retry loading landlord rooms: $e');
      }
      // Thử lại sau 1 giây
      await Future.delayed(Duration(seconds: 1));
      retryGetLandlordRooms(landlordId, retries: retries - 1);
    }
  }

  /// Xóa phòng theo ID
  Future<void> deleteRoom(String roomId, String landlordId) async {
    if (kDebugMode) {
      print('Deleting room: $roomId');
    }
    
    try {
      emit(LandlordRoomsProcessing());
      
      // Gọi API để xóa phòng
      await _roomRepository.deleteRoom(roomId);
      
      // Nếu xóa thành công, cập nhật danh sách phòng trong trạng thái hiện tại
      if (state is LandlordRoomsLoaded) {
        final currentState = state as LandlordRoomsLoaded;
        final updatedRooms = currentState.rooms.where((room) => room.id != roomId).toList();
        emit(LandlordRoomsLoaded(rooms: updatedRooms));
      } else {
        // Nếu không có dữ liệu phòng, lấy dữ liệu mới mà không emit Loading
        final result = await _roomRepository.getLandlordRooms(landlordId);
        
        switch (result) {
          case Success(data: final rooms):
            emit(LandlordRoomsLoaded(rooms: rooms));
          case Failure():
            // Không xử lý lỗi ở đây vì đã có catch bên ngoài
            break;
        }
      }
      
      // Thông báo xóa thành công
      emit(LandlordRoomsSuccess(message: 'Xóa phòng thành công'));
      
      // Quay lại trạng thái Loaded
      if (state is LandlordRoomsSuccess) {
        // Lấy lại dữ liệu mới từ repository mà không emit Loading
        final result = await _roomRepository.getLandlordRooms(landlordId);
        
        switch (result) {
          case Success(data: final rooms):
            emit(LandlordRoomsLoaded(rooms: rooms));
          case Failure():
            // Không xử lý lỗi ở đây vì đã có catch bên ngoài
            break;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting room: $e');
      }
      emit(LandlordRoomsError(message: 'Không thể xóa phòng: ${e.toString()}'));
      
      // Quay lại trạng thái Loaded nếu có
      if (state is LandlordRoomsLoaded) {
        final currentState = state as LandlordRoomsLoaded;
        emit(LandlordRoomsLoaded(rooms: currentState.rooms));
      }
    }
  }
} 