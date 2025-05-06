import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/core/utils/result.dart';

// States
abstract class RoomWithImagesState extends Equatable {
  const RoomWithImagesState();

  @override
  List<Object> get props => [];
}

class RoomWithImagesInitial extends RoomWithImagesState {}

class RoomWithImagesLoading extends RoomWithImagesState {}

class RoomWithImagesLoaded extends RoomWithImagesState {
  final List<RoomWithImages> roomsWithImages;

  const RoomWithImagesLoaded({required this.roomsWithImages});

  @override
  List<Object> get props => [roomsWithImages];
}

class RoomWithImagesError extends RoomWithImagesState {
  final String message;

  const RoomWithImagesError({required this.message});

  @override
  List<Object> get props => [message];
}

// Data class to hold a room and its images
class RoomWithImages {
  final Room room;
  final List<RoomImage> images;

  RoomWithImages({required this.room, required this.images});
}

// Cubit
class RoomWithImagesCubit extends Cubit<RoomWithImagesState> {
  final RoomRepository _roomRepository;
  final RoomImageRepository _roomImageRepository;

  RoomWithImagesCubit({
    required RoomRepository roomRepository,
    required RoomImageRepository roomImageRepository,
  })  : _roomRepository = roomRepository,
        _roomImageRepository = roomImageRepository,
        super(RoomWithImagesInitial());

  Future<void> loadRoomsWithImages(RoomFilter filter) async {
    try {
      emit(RoomWithImagesLoading());

      // Tải danh sách phòng
      final roomsResult = await _roomRepository.getRoomsWithFilter(filter);

      switch (roomsResult) {
        case Success(data: final rooms):
          // Tải hình ảnh cho từng phòng
          final List<RoomWithImages> roomsWithImages = [];
          
          for (final room in rooms) {
            if (room.id != null) {
              final imagesResult = await _roomImageRepository.getRoomImages(room.id!);
              
              switch (imagesResult) {
                case Success(data: final images):
                  roomsWithImages.add(RoomWithImages(room: room, images: images));
                case Failure():
                  // Nếu không tải được hình ảnh, vẫn thêm phòng với danh sách hình ảnh rỗng
                  roomsWithImages.add(RoomWithImages(room: room, images: []));
              }
            } else {
              // Nếu phòng không có ID, thêm với danh sách hình ảnh rỗng
              roomsWithImages.add(RoomWithImages(room: room, images: []));
            }
          }
          
          emit(RoomWithImagesLoaded(roomsWithImages: roomsWithImages));
          
        case Failure(message: final message):
          emit(RoomWithImagesError(message: message));
      }
    } catch (e) {
      emit(RoomWithImagesError(message: e.toString()));
    }
  }
} 