import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/rented_room/rent_request_state.dart';
import 'package:roomily/data/models/rent_request.dart';
import 'package:roomily/data/repositories/rented_room_repository.dart';
import 'package:flutter/foundation.dart';

class RentRequestCubit extends Cubit<RentRequestState> {
  final RentedRoomRepository _rentedRoomRepository;

  RentRequestCubit({required RentedRoomRepository rentedRoomRepository})
      : _rentedRoomRepository = rentedRoomRepository,
        super(RentRequestInitial());

// Tenant gửi yêu cầu tạo phòng
  Future<void> createRentRequest({
    required String roomId,
    required String chatRoomId,
    required DateTime startDate,
    String? findPartnerPostId,
  }) async {
    emit(RentRequestLoading());

    final request = RentRequest(
      roomId: roomId,
      chatRoomId: chatRoomId,
      startDate: startDate,
      findPartnerPostId: findPartnerPostId,
    );

    final result = await _rentedRoomRepository.createRentRequest(request);

    result.when(
      success: (rentalRequest) {
        if (kDebugMode) {
          print('Received RentalRequest: ${rentalRequest.toJson()}');
        }
        
        emit(RentRequestSuccess(
          "Yêu cầu thuê phòng đã được gửi thành công", 
          rentalRequest: rentalRequest
        ));
      },
      failure: (error) => emit(RentRequestFailure(error)),
    );
  }

  // Lấy danh sách các yêu cầu thuê phòng cho landlord
  Future<void> getLandlordRentalRequests(String landlordId) async {
    emit(RentRequestLoading());
    
    if (kDebugMode) {
      print('🔄 Fetching rental requests for landlord: $landlordId');
    }

    final result = await _rentedRoomRepository.getRentalRequestsByReceiverId(landlordId);

    result.when(
      success: (rentalRequests) {
        if (kDebugMode) {
          print('✅ Received ${rentalRequests.length} rental requests for landlord');
        }
        
        emit(RentRequestListSuccess(rentalRequests));
      },
      failure: (error) {
        if (kDebugMode) {
          print('❌ Failed to get rental requests: $error');
        }
        
        emit(RentRequestFailure(error));
      },
    );
  }

  // Chủ trọ chấp nhận yêu cầu thuê phòng
  Future<void> acceptRentRequest(String chatRoomId) async {
    emit(RentRequestLoading());

    final result = await _rentedRoomRepository.acceptRentRequest(chatRoomId);

    result.when(
      success: (response) {
        // Log response từ API
        if (kDebugMode) {
          print('Accept response from repository: $response');
        }

        final bool isSuccess = (response == "1" || response == "1.0" || response.isEmpty);
        
        if (isSuccess) {
          emit(RentRequestSuccess("Đã chấp nhận yêu cầu thuê phòng thành công"));
        } else {
          emit(RentRequestSuccess("Đã gửi yêu cầu chấp nhận, nhưng có thể chưa hoàn tất"));
        }
      },
      failure: (error) => emit(RentRequestFailure(error)),
    );
  }
  

  // Chủ trọ từ chối yêu cầu thuê phòng
  Future<void> rejectRentRequest(String chatRoomId) async {
    emit(RentRequestLoading());

    final result = await _rentedRoomRepository.rejectRentRequest(chatRoomId);

    result.when(
      success: (response) {
        // Log response từ API
        if (kDebugMode) {
          print('Deny response from repository: $response');
        }
        
        // Kiểm tra response là 1 hoặc rỗng (cả hai đều coi là thành công)
        final bool isSuccess = (response == "1" || response == "1.0" || response.isEmpty);
        
        if (isSuccess) {
          emit(RentRequestSuccess("Đã từ chối yêu cầu thuê phòng thành công"));
        } else {
          emit(RentRequestSuccess("Đã gửi yêu cầu từ chối, nhưng có thể chưa hoàn tất"));
        }
      },
      failure: (error) => emit(RentRequestFailure(error)),
    );
  }

  // Hủy yêu cầu thuê phòng
  Future<void> cancelRentRequest(String chatRoomId) async {
    emit(RentRequestLoading()); 

    final result = await _rentedRoomRepository.cancelRentRequest(chatRoomId);

    result.when(
      success: (response) {
        emit(RentRequestSuccess("Đã hủy yêu cầu thuê phòng thành công"));
      },
      failure: (error) => emit(RentRequestFailure(error)),
    );
  }
}