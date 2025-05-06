import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/rented_room/rental_requests_state.dart';
import 'package:roomily/data/repositories/rented_room_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:roomily/core/services/secure_storage_service.dart';
import 'package:get_it/get_it.dart';

class RentalRequestsCubit extends Cubit<RentalRequestsState> {
  final RentedRoomRepository _rentedRoomRepository;

  RentalRequestsCubit({required RentedRoomRepository rentedRoomRepository})
      : _rentedRoomRepository = rentedRoomRepository,
        super(RentalRequestsInitial());

  // Lấy danh sách các yêu cầu thuê phòng bằng receiverId (thường là landlordId)
  Future<void> getRentalRequestsByReceiverId(String receiverId) async {
    emit(RentalRequestsLoading());

    final result = await _rentedRoomRepository.getRentalRequestsByReceiverId(receiverId);

    result.when(
      success: (rentalRequests) {
        if (kDebugMode) {
          print('Received RentalRequests: ${rentalRequests.length}');
        }
        
        emit(RentalRequestsLoaded(rentalRequests));
      },
      failure: (error) => emit(RentalRequestsError(error)),
    );
  }
  
  // Lấy danh sách các yêu cầu thuê phòng cho landlord (lấy id từ SecureStorage)
  Future<void> getLandlordRentalRequests() async {
    emit(RentalRequestsLoading());
    
    try {
      // Lấy userId từ SecureStorage
      final secureStorage = GetIt.I<SecureStorageService>();
      final userId = await secureStorage.getUserId();
      
      if (userId == null || userId.isEmpty) {
        emit(RentalRequestsError("Không thể xác định người dùng hiện tại"));
        return;
      }
      
      if (kDebugMode) {
        print('🔄 Fetching rental requests for landlord ID: $userId');
      }
      
      // Lấy danh sách yêu cầu thuê phòng
      final result = await _rentedRoomRepository.getRentalRequestsByReceiverId(userId);
      
      result.when(
        success: (rentalRequests) {
          if (kDebugMode) {
            print('✅ Received ${rentalRequests.length} rental requests for landlord');
          }
          
          emit(RentalRequestsLoaded(rentalRequests));
        },
        failure: (error) {
          if (kDebugMode) {
            print('❌ Failed to get rental requests: $error');
          }
          
          emit(RentalRequestsError(error));
        },
      );
    } catch (e) {
      emit(RentalRequestsError("Lỗi không xác định: $e"));
    }
  }
  
  // Chủ trọ chấp nhận yêu cầu thuê phòng, sử dụng chatRoomId
  Future<void> acceptRentRequest(String chatRoomId) async {
    if (kDebugMode) {
      print('🔄 Accepting rental request with chatRoomId: $chatRoomId');
    }
    
    final result = await _rentedRoomRepository.acceptRentRequest(chatRoomId);

    result.when(
      success: (response) {
        if (kDebugMode) {
          print('✅ Accept response from repository: $response');
        }
        
        // Refresh the list after accepting
        final currentState = state;
        if (currentState is RentalRequestsLoaded) {
          // Filter by chatRoomId instead of id
          final requests = currentState.rentalRequests.where(
            (request) => request.chatRoomId != chatRoomId
          ).toList();
          emit(RentalRequestsLoaded(requests));
        }
      },
      failure: (error) {
        if (kDebugMode) {
          print('❌ Error accepting request: $error');
        }
        emit(RentalRequestsError(error));
      },
    );
  }

  // Chủ trọ từ chối yêu cầu thuê phòng, sử dụng chatRoomId
  Future<void> rejectRentRequest(String chatRoomId) async {
    if (kDebugMode) {
      print('🔄 Rejecting rental request with chatRoomId: $chatRoomId');
    }
    
    final result = await _rentedRoomRepository.rejectRentRequest(chatRoomId);

    result.when(
      success: (response) {
        if (kDebugMode) {
          print('✅ Reject response from repository: $response');
        }
        
        // Refresh the list after rejecting
        final currentState = state;
        if (currentState is RentalRequestsLoaded) {
          // Filter by chatRoomId instead of id
          final requests = currentState.rentalRequests.where(
            (request) => request.chatRoomId != chatRoomId
          ).toList();
          emit(RentalRequestsLoaded(requests));
        }
      },
      failure: (error) {
        if (kDebugMode) {
          print('❌ Error rejecting request: $error');
        }
        emit(RentalRequestsError(error));
      },
    );
  }
}