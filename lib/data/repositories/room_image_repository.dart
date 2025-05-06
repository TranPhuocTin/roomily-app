import 'package:dio/dio.dart';
import 'package:roomily/data/models/room_image.dart';

import '../../core/utils/result.dart';

abstract class RoomImageRepository {
  //Get list room images by room Response: (List<RoomImage>)
  Future<Result<List<RoomImage>>> getRoomImages(String roomId);
  //Post List<MultipartFile> by room
  Future<Result<void>> postRoomImage(String roomId, List<MultipartFile> imageFiles);
  //Delete room image by List<imageIds>
  Future<Result<void>> deleteRoomImage(String roomId, List<String> imageIds);
  //Get list room image urls by room Response: (List<String>)
  Future<Result<List<String>>> getRoomImageUrls(String roomId);

}