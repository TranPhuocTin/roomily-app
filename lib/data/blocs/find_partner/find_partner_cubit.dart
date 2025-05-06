import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/find_partner_post.dart';
import 'package:roomily/data/models/find_partner_post_create.dart';
import 'package:roomily/data/repositories/find_partner_repository.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:get_it/get_it.dart';

import 'find_partner_state.dart';

class FindPartnerCubit extends Cubit<FindPartnerState> {
  final FindPartnerRepository _findPartnerRepository;
  
  FindPartnerCubit(this._findPartnerRepository) : super(const FindPartnerInitial());
  
  Future<void> getFindPartnersForRoom(String roomId) async {
    emit(const FindPartnerLoading());
    final result = await _findPartnerRepository.getFindPartners(roomId: roomId);
    
    result.when(
      success: (posts) {
        emit(FindPartnerLoaded(posts));
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
  
  Future<void> createFindPartner(FindPartnerPostCreate findPartnerPostCreate) async {
    emit(const FindPartnerSubmitting());
    try {
      await _findPartnerRepository.createFindPartner(findPartnerPostCreate: findPartnerPostCreate);
      emit(const FindPartnerSubmitted());
      
      // Reload the data after successful creation
      await getFindPartnersForRoom(findPartnerPostCreate.roomId);
    } catch (e) {
      emit(FindPartnerError(e.toString()));
    }
  }
  
  Future<void> checkUserInFindPartnerPost(String roomId) async {
    emit(const FindPartnerChecking());
    
    // Lấy userId từ AuthService
    final authService = GetIt.I<AuthService>();
    final userId = authService.userId;
    print('Current userid: $userId');
    
    if (userId == null) {
      emit(const FindPartnerError("Không tìm thấy thông tin người dùng. Vui lòng đăng nhập lại."));
      return;
    }

    // Thay vì gọi API checkUserInFindPartnerPost, chúng ta sẽ gọi getActiveFindPartnerPosts
    // và kiểm tra xem danh sách có rỗng không
    final result = await _findPartnerRepository.getActiveFindPartnerPosts();
    
    result.when(
      success: (posts) {
        // Kiểm tra xem danh sách posts có rỗng không
        final isUserInPost = posts.isNotEmpty;
        // Trả về kết quả (true nếu có posts, false nếu không có)
        emit(FindPartnerUserCheckResult(isUserInPost));
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
  
  Future<void> getActiveFindPartnerPosts() async {
    emit(const FindPartnerLoading());
    final result = await _findPartnerRepository.getActiveFindPartnerPosts();

    result.when(
      success: (posts) {
        emit(FindPartnerActivePosts(posts));
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
  
  Future<void> sendFindPartnerRequest({
    required String findPartnerPostId,
    required String chatRoomId,
  }) async {
    emit(const FindPartnerRequestSending());
    
    final result = await _findPartnerRepository.sendFindPartnerRequest(
      findPartnerPostId: findPartnerPostId,
      chatRoomId: chatRoomId,
    );
    
    result.when(
      success: (rentalRequest) {
        emit(FindPartnerRequestSent(rentalRequest));
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
  
  Future<void> acceptFindPartnerRequest(String chatRoomId) async {
    emit(const FindPartnerRequestAccepting());
    
    final result = await _findPartnerRepository.acceptFindPartnerRequest(chatRoomId);
    
    result.when(
      success: (_) {
        emit(const FindPartnerRequestAccepted());
        
        // Optionally refresh active find partner posts after accepting
        getActiveFindPartnerPosts();
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
  
  Future<void> rejectFindPartnerRequest(String chatRoomId) async {
    emit(const FindPartnerRequestRejecting());
    
    final result = await _findPartnerRepository.rejectFindPartnerRequest(chatRoomId);
    print('🔴 RejectFindPartnerRequest: ${result.toString()}');
    
    result.when(
      success: (_) {
        emit(const FindPartnerRequestRejected());
        
        // Optionally refresh active find partner posts after rejecting
        getActiveFindPartnerPosts();
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
  
  Future<void> cancelFindPartnerRequest(String chatRoomId) async {
    emit(const FindPartnerRequestCanceling());
    
    final result = await _findPartnerRepository.cancelFindPartnerRequest(chatRoomId);
    
    result.when(
      success: (_) {
        emit(const FindPartnerRequestCanceled());
        
        // Optionally refresh active find partner posts after canceling
        getActiveFindPartnerPosts();
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
  
  Future<void> updateFindPartnerPost({
    required String findPartnerPostId,
    String? description,
    int? maxPeople,
  }) async {
    emit(const FindPartnerSubmitting());
    
    final result = await _findPartnerRepository.updateFindPartnerPost(
      findPartnerPostId: findPartnerPostId,
      description: description,
      maxPeople: maxPeople,
    );
    
    result.when(
      success: (success) {
        emit(const FindPartnerUpdated());
        
        // Refresh active find partner posts after updating
        getActiveFindPartnerPosts();
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
  
  Future<void> removeParticipant({
    required String findPartnerPostId,
    required String userId,
  }) async {
    emit(const FindPartnerRemovingParticipant());
    
    final result = await _findPartnerRepository.removeParticipant(
      findPartnerPostId: findPartnerPostId,
      userId: userId,
    );
    
    result.when(
      success: (_) {
        emit(FindPartnerParticipantRemoved(userId));
        
        // Refresh active find partner posts after removing participant
        getActiveFindPartnerPosts();
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
  
  Future<void> exitFindPartnerPost(String findPartnerPostId) async {
    emit(const FindPartnerExiting());
    
    final result = await _findPartnerRepository.exitFindPartnerPost(findPartnerPostId);
    
    result.when(
      success: (_) {
        emit(const FindPartnerExited());
        
        // Refresh active find partner posts after exiting
        getActiveFindPartnerPosts();
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
  
  Future<void> addParticipant({
    required String findPartnerPostId,
    required String privateId,
  }) async {
    emit(const FindPartnerAddingParticipant());
    
    final result = await _findPartnerRepository.addParticipant(
      findPartnerPostId: findPartnerPostId,
      privateId: privateId,
    );
    
    result.when(
      success: (_) {
        emit(FindPartnerParticipantAdded(privateId));
        
        // Refresh post details after adding participant
        getActiveFindPartnerPosts();
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }

  Future<void> deleteFindPartnerPost(String findPartnerPostId) async {
    emit(const FindPartnerDeleting());
    
    final result = await _findPartnerRepository.deleteFindPartnerPost(findPartnerPostId);
    
    result.when(
      success: (_) {
        emit(const FindPartnerDeleted());
        
        // Refresh active find partner posts after deleting
        getActiveFindPartnerPosts();
      },
      failure: (message) {
        emit(FindPartnerError(message));
      },
    );
  }
} 