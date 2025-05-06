import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/find_partner_post.dart';
import 'package:roomily/data/models/find_partner_post_create.dart';
import 'package:roomily/data/models/rental_request.dart';
import 'package:roomily/data/models/find_partner_post_detail.dart';

abstract class FindPartnerRepository {
  Future<Result<List<FindPartnerPost>>> getFindPartners({
    required String roomId,
  });

  Future<void> createFindPartner({
    required FindPartnerPostCreate findPartnerPostCreate,
  });
  
  Future<Result<bool>> checkUserInFindPartnerPost({
    required String userId, 
    required String roomId,
  });
  
  Future<Result<List<FindPartnerPost>>> getActiveFindPartnerPosts();
  
  Future<Result<RentalRequest>> sendFindPartnerRequest({
    required String findPartnerPostId,
    required String chatRoomId,
  });
  
  Future<Result<bool>> acceptFindPartnerRequest(String chatRoomId);
  
  Future<Result<bool>> rejectFindPartnerRequest(String chatRoomId);
  
  Future<Result<bool>> cancelFindPartnerRequest(String chatRoomId);
  
  Future<Result<bool>> updateFindPartnerPost({
    required String findPartnerPostId,
    String? description,
    int? maxPeople,
  });
  
  Future<FindPartnerPostDetail> getFindPartnerPostDetail(String postId);
  
  Future<Result<bool>> removeParticipant({
    required String findPartnerPostId,
    required String userId,
  });
  
  Future<Result<bool>> exitFindPartnerPost(String findPartnerPostId);
  
  Future<Result<bool>> addParticipant({
    required String findPartnerPostId,
    required String privateId,
  });

  Future<Result<bool>> deleteFindPartnerPost(String findPartnerPostId);
}

