import 'package:roomily/data/models/room.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/room_create.dart';
import 'package:roomily/data/models/room_filter.dart';

abstract class RoomRepository {
  Future<Result<Room>> getRoom(String id);
  Future<List<Room>> getRooms();
  Future<Room> updateRoom(Room room);
  Future<void> deleteRoom(String id);
  Future<Result<String>> postRoom(RoomCreate room);
  Future<Result<List<Room>>> getRoomsWithFilter(RoomFilter filter);
  Future<Result<List<Room>>> getLandlordRooms(String landlordId);
}