import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/utils/tag_category.dart';
import 'package:roomily/data/blocs/home/room_create_state.dart';
import 'package:roomily/data/models/room_create.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:flutter/foundation.dart';

import '../../models/room.dart';

class RoomCreateCubit extends Cubit<RoomCreateState> {
  final RoomRepository repository;

  RoomCreateCubit(this.repository) : super(RoomCreateInitial());

  Future<String?> createRoom({
    required String title,
    required String description,
    required String address,
    required double price,
    required String city,
    required String district,
    required String ward,
    required double electricPrice,
    required double waterPrice,
    required String type,
    required int maxPeople,
    required List<String> tagIds,
    required double squareMeters,
    double? latitude,
    double? longitude,
    double? deposit,
    String? nearbyAmenities,
  }) async {
    emit(RoomCreateLoading());

    final roomCreate = RoomCreate(
      title: title,
      description: description,
      address: address,
      price: price,
      city: city,
      district: district,
      ward: ward,
      electricPrice: electricPrice,
      waterPrice: waterPrice,
      type: type,
      maxPeople: maxPeople,
      tags: tagIds,
      squareMeters: squareMeters,
      latitude: latitude,
      longitude: longitude,
      deposit: deposit,
      nearbyAmenities: nearbyAmenities,
    );

    if (kDebugMode) {
      print("Creating room with tags: $tagIds");
    }
    
    final result = await repository.postRoom(roomCreate);

    String? roomId;
    switch (result) {
      case Success():
        emit(RoomCreateLoaded(roomId: result.data.toString()));
      case Failure(message: final message):
        emit(RoomCreateError(message: message));
        if (kDebugMode) {
          print("Room creation failed: $message");
        }
    }
    
    return roomId;
  }

  Future<void> updateRoom({
    required String roomId,
    required String title,
    required String description,
    required String address,
    required double price,
    required String city,
    required String district,
    required String ward,
    required double electricPrice,
    required double waterPrice,
    required String type,
    required int maxPeople,
    required List<String> tagIds,
    required double squareMeters,
    double? latitude,
    double? longitude,
    double? deposit,
    String? nearbyAmenities,
  }) async {
    emit(RoomCreateLoading());

    try {
      // Tạo các đối tượng RoomTag từ tagIds
      final List<RoomTag> tags = tagIds.map((id) => RoomTag(id: id, name: '', category: TagCategory.BUILDING_FEATURE, displayName: '')).toList();
      
      // Tạo đối tượng Room với thông tin cập nhật
      final room = Room(
        id: roomId,
        title: title,
        description: description,
        address: address,
        price: price,
        city: city,
        district: district,
        ward: ward,
        electricPrice: electricPrice,
        waterPrice: waterPrice,
        type: type,
        maxPeople: maxPeople,
        tags: tags,
        squareMeters: squareMeters,
        latitude: latitude,
        longitude: longitude,
        deposit: deposit,
        nearbyAmenities: nearbyAmenities,
        createdAt: DateTime.now(), // Giá trị mặc định, sẽ bị ghi đè bởi server
        updatedAt: DateTime.now(), // Giá trị mặc định, sẽ bị ghi đè bởi server
      );

      if (kDebugMode) {
        print("Updating room with ID: $roomId and tags: $tagIds");
      }
      
      final updatedRoom = await repository.updateRoom(room);
      emit(RoomUpdateLoaded(room: updatedRoom));
    } catch (e) {
      emit(RoomCreateError(message: e.toString()));
      if (kDebugMode) {
        print("Room update failed: $e");
      }
    }
  }
}
