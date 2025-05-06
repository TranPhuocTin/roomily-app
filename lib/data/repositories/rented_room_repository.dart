import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/models/rent_request.dart';
import 'package:roomily/data/models/rental_request.dart';
import 'package:roomily/data/models/utility_reading_request.dart';
import 'package:roomily/data/models/landlord_confirmation_request.dart';

abstract class RentedRoomRepository {
  Future<Result<RentalRequest>> createRentRequest(RentRequest request);
  Future<Result<String>> acceptRentRequest(String chatRoomId);
  Future<Result<String>> rejectRentRequest(String chatRoomId);
  Future<Result<String>> cancelRentRequest(String chatRoomId);
  Future<Result<List<RentalRequest>>> getRentalRequestsByReceiverId(String receiverId);
  //Rented room for tenant
  Future<Result<List<RentedRoom>>> getRentedRooms();
  
  //Bill log
  Future<Result<BillLog>> getActiveBillLogByRentedRoomId(String rentedRoomId);
  Future<Result<BillLog>> updateUtilityReadings(String billLogId, UtilityReadingRequest request);
  Future<Result<BillLog>> getActiveBillLogByRoomId(String roomId);
  Future<Result<List<RentedRoom>>> getRentedRoomsByLandlordId(String landlordId);

  Future<Result<List<BillLog>>> getBillLogHistory(String roomId);
  Future<Result<List<BillLog>>> getBillLogHistoryByRentedRoomId(String rentedRoomId);
  
  // Landlord confirmation of utility readings
  Future<Result<BillLog?>> confirmUtilityReadings(String billLogId, LandlordConfirmationRequest request);
  Future<Result<bool>> exitRentedRoom(String rentedRoomId);
}