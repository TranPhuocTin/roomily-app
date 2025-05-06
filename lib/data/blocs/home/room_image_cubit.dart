import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/home/room_image_state.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/core/utils/result.dart';
import '../../repositories/room_image_repository.dart';

class RoomImageCubit extends Cubit<RoomImageState> {
  final RoomImageRepository repository;

  // Cache để lưu ảnh đã tải theo roomId
  final Map<String, List<RoomImage>> _imageCache = {};
  // ID của phòng đang được tải
  String? _currentRoomId;

  RoomImageCubit(this.repository) : super(RoomImageInitial());

  Future<void> fetchRoomImages(String roomId) async {
    // Kiểm tra xem đã có trong cache chưa
    if (_imageCache.containsKey(roomId) && _imageCache[roomId]!.isNotEmpty) {
      _currentRoomId = roomId;
      emit(RoomImageLoaded(images: _imageCache[roomId]!, roomId: roomId));
      return;
    }
    
    _currentRoomId = roomId;
    emit(RoomImageLoading(roomId: roomId));

    final result = await repository.getRoomImages(roomId);

    // Kiểm tra xem roomId có còn là roomId hiện tại không
    // để tránh việc emit state cho roomId đã không còn được quan tâm
    if (_currentRoomId != roomId) {
      return;
    }

    switch (result) {
      case Success(data: final images):
        // Lưu vào cache
        _imageCache[roomId] = images;
        emit(RoomImageLoaded(images: images, roomId: roomId));
      case Failure(message: final message):
        emit(RoomImageError(message: message, roomId: roomId));
    }
  }

  Future<void> fetchAllRoomImages(List<String> roomIds) async {
    // Start with empty map and loading state
    emit(AllRoomImagesState(roomImagesMap: {}, isLoading: true));
    
    final Map<String, List<RoomImage>> roomImagesMap = {};
    
    try {
      // Sử dụng cache nếu có
      final List<String> roomIdsToFetch = [];
      
      // Kiểm tra những roomId nào đã có trong cache
      for (final roomId in roomIds) {
        if (_imageCache.containsKey(roomId) && _imageCache[roomId]!.isNotEmpty) {
          roomImagesMap[roomId] = _imageCache[roomId]!;
        } else {
          roomIdsToFetch.add(roomId);
        }
      }
      
      // Chỉ tải những roomId chưa có trong cache
      if (roomIdsToFetch.isNotEmpty) {
      // Process all room IDs in parallel for better performance
        final futures = roomIdsToFetch.map((roomId) => repository.getRoomImages(roomId));
      final results = await Future.wait(futures);
      
      // Process all results
        for (int i = 0; i < roomIdsToFetch.length; i++) {
          final roomId = roomIdsToFetch[i];
        final result = results[i];
        
        switch (result) {
          case Success(data: final images):
            roomImagesMap[roomId] = images;
              // Cập nhật cache
              _imageCache[roomId] = images;
          case Failure():
            // Just skip this room if there was an error
            roomImagesMap[roomId] = [];
          }
        }
      }
      
      // Emit success state with all room images
      emit(AllRoomImagesState(roomImagesMap: roomImagesMap, isLoading: false));
    } catch (e) {
      emit(AllRoomImagesState(
        roomImagesMap: roomImagesMap,
        isLoading: false,
        error: e.toString()
      ));
    }
  }

  Future<void> uploadRoomImages(String roomId, List<MultipartFile> imageFiles) async {
    emit(RoomImageUploading(roomId: roomId));
    print("DEBUG: RoomImageCubit - Starting upload of ${imageFiles.length} images for room $roomId");
    
    try {
      print("DEBUG: RoomImageCubit - About to call repository.postRoomImage");
      final result = await repository.postRoomImage(roomId, imageFiles);
      print("DEBUG: RoomImageCubit - API call completed, result type: ${result.runtimeType}");
      
      switch (result) {
        case Success():
          print("DEBUG: RoomImageCubit - Upload successful, fetching updated images");
          // After successful upload, fetch the updated images
          await fetchRoomImages(roomId);
          print("DEBUG: RoomImageCubit - Images fetched successfully");
        case Failure(message: final message):
          print("DEBUG: RoomImageCubit - Upload error from API: $message");
          emit(RoomImageUploadError(message: message, roomId: roomId));
      }
    } catch (e) {
      print("DEBUG: RoomImageCubit - Exception during upload: $e");
      emit(RoomImageUploadError(message: e.toString(), roomId: roomId));
    }
  }

  Future<void> deleteRoomImages(String roomId, List<String> imageIds) async {
    if (imageIds.isEmpty) {
      return; // Nothing to delete
    }
    
    emit(RoomImageDeleting(roomId: roomId));
    print("DEBUG: RoomImageCubit - Starting deletion of ${imageIds.length} images for room $roomId");
    
    try {
      final result = await repository.deleteRoomImage(roomId, imageIds);
      
      switch (result) {
        case Success():
          print("DEBUG: RoomImageCubit - Deletion successful, fetching updated images");
          // After successful deletion, fetch the updated images
          await fetchRoomImages(roomId);
          print("DEBUG: RoomImageCubit - Images fetched successfully after deletion");
          emit(RoomImageDeleteSuccess(roomId: roomId));
        case Failure(message: final message):
          print("DEBUG: RoomImageCubit - Deletion error from API: $message");
          emit(RoomImageDeleteError(message: message, roomId: roomId));
      }
    } catch (e) {
      print("DEBUG: RoomImageCubit - Exception during deletion: $e");
      emit(RoomImageDeleteError(message: e.toString(), roomId: roomId));
    }
  }
  
  // Xóa dữ liệu trong cache khi không cần thiết nữa
  void clearCache() {
    _imageCache.clear();
  }
  
  // Xóa một roomId cụ thể khỏi cache
  void clearRoomFromCache(String roomId) {
    _imageCache.remove(roomId);
  }
}

