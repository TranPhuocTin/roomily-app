import 'package:roomily/data/models/room_filter.dart';

class ApiConstants {
  // Base URL
  // static const String baseUrl = 'https://sadly-stirred-marmoset.ngrok-free.app/';
  static const String baseUrl = 'https://api.roomily.tech/';
  static const String recommendBaseUrl = 'https://external.roomily.tech/';
  //Authentication endpoints
  static String login () => 'api/v1/auth/login';
  static String logout () => 'api/v1/auth/logout';
  static String register () => 'api/v1/auth/register';
  static String getUser(String userId) => '/api/v1/users/$userId';
  static String updateUser() => 'api/v1/users';
  
  
  // Room enpoinds
  //Get room by id
  static String room (String roomId) => 'api/v1/rooms/$roomId';
  //Post room
  static String postRoom () => 'api/v1/rooms';
  //Get landlord rooms
  static String landlordRooms (String landlordId) => 'api/v1/rooms/landlords/$landlordId';
    //Room filter
  static String roomFilter() => 'api/v1/rooms/filter';
  //Get recommended rooms
  static String recommendRooms(String userId) => 'api/v1/recommend/$userId';
  //Get recommend room by userId
  static String recommendRoomByUserId(String userId) => 'recommend/$userId';
  static String promotedRoomByUserId(String userId) => 'ads/promoted//$userId';


  //Favorite endpoints
  static String tooggleRoomFavorite (String roomId) => 'api/v1/favorites/$roomId';
  //Get favorite rooms by user
  static String favoriteRoom () => 'api/v1/favorites';
  //Get favorite count of user
  static String userFavoriteCount () => 'api/v1/favorites/count';
  //Get favorite count of room
  static String roomFavoriteCount (String roomId) => 'api/v1/favorites/count/$roomId';
  //Check if room is favorited by user
  static String checkRoomFavorite (String roomId) => 'api/v1/favorites/$roomId';

  //Room image endpoints
  //Get room images by room
  static String roomImage (String roomId) => 'api/v1/room-images/rooms/$roomId';
  //Get room images url by room
  static String roomImageUrl (String roomId) => 'api/v1/room-images/urls/rooms/$roomId';

  //Subscription endpoints
  //Get subscriptions
  static String subscriptions () => 'api/v1/subscriptions';
  //Sign subscription
  static String signSubscription (String subscriptionId) => 'api/v1/subscriptions/subscribe/$subscriptionId';
  //Cancel subscription
  static String cancelSubscription () => 'api/v1/subscriptions/unsubscribe';
  //Renew subscription
  static String renewSubscription () => 'api/v1/subscriptions/renew';
  //Get popular subscription
  static String popularSubscription () => 'api/v1/subscriptions/popular';
  //Get active subscription information
  static String activeSubscription () => 'api/v1/subscriptions/active';

  //Notification endpoints
  //Get notifications
  static String notifications () => 'api/v1/notifications';
  //Get notification by id
  static String notification(String notificationId) => 'api/v1/notifications/$notificationId';
  //Get unread notifications
  static String unReadNotifications () => 'api/v1/notifications/unread';
  //Get read notifications
  static String readNotifications () => 'api/v1/notifications/read';
  //Mark notification which is already read
  static String markNotificationAsRead (String notificationId) => 'api/v1/notifications/mark/$notificationId';
  //Mark all notifications as read
  static String markAllNotificationsAsRead () => 'api/v1/notifications/mark/all';

  //Review endpoints
  //Get reviews by room
  static String reviews (String roomId) => 'api/v1/reviews/rooms/$roomId';
  //Post review by room
  static String postReview (String roomId) => 'api/v1/reviews/rooms/$roomId';
  //Delete review by reviewId
  static String deleteReview (String reviewId) => 'api/v1/reviews/$reviewId';
  //Update review by reviewId
  static String updateReview (String reviewId) => 'api/v1/reviews/$reviewId';


  //Room image endpoints
  //Get room images by room
  static String roomImages (String roomId) => 'api/v1/room-images/rooms/$roomId';
  //Get room images url by room
  static String roomImageUrls (String roomId) => 'api/v1/room-images/urls/rooms/$roomId';
  //Post room image by room
  static String postRoomImage (String roomId) => 'api/v1/room-images/rooms/$roomId';
  //Delete room image by imageId request body: [imageId]
  static String deleteRoomImage (String roomId) => 'api/v1/room-images/rooms/$roomId';

  //Tag endpoints
  //Get all tags
  static String allTag() => 'api/v1/tags';
  //Get recommended tags
  static String recommendedTags() => 'api/v1/rooms/recommended-tags';

  //Chat room endpoints
  //Create direct chat room to landlord
  static String createDirectChatRoom (String roomId) => 'api/v1/chat-rooms/direct/landlord/$roomId';
  //Create direct chat room to user with findPartnerPostId
  static String createDirectChatRoomToUser (String userId) => 'api/v1/chat-rooms/direct/$userId';
  //Get chat room info by chatRoomId
  static String getChatRoomInfo(String chatRoomID) => 'api/v1/chat-rooms/$chatRoomID';
  
  //Rented process endpoints
  //Get rented rooms
  static String requestToRent () => 'api/v1/rented-rooms/request/create';
  //Cancel rent request
  static String cancelRentRequest (String chatRoomId) => 'api/v1/rented-rooms/request/cancel/$chatRoomId';
  //Deny rent request
  static String denyRentRequest (String chatRoomId) => 'api/v1/rented-rooms/deny/$chatRoomId';
  //Accept rent request
  static String acceptRentRequest (String chatRoomId) => 'api/v1/rented-rooms/accept/$chatRoomId';
  //Get rental requests by receiver
  static String getRentalRequestsByReceiver(String receiverId) => 'api/v1/rented-rooms/request/receiver/$receiverId';
  //Get rented rooms by user
  static String rentedRooms () => 'api/v1/rented-rooms';
  //Get rented rooms information
  static String rentedRoom (String roomId) => 'api/v1/rented-rooms/room/$roomId';
  //Get rented rooms by landlord
  static String rentedRoomsByLandlord (String landlordId) => 'api/v1/rented-rooms/landlord/$landlordId';
  //Rented room tenant endpoints
  static String getRentedRooms() => 'api/v1/rented-rooms';
  

  //Chat message endpoints
  //Get chat messages by chat room(Query param)
  static String chatMessages () => 'api/v1/chat/messages';
  //Send chat message to chat room
  static String sendChatMessage () => 'api/v1/chat/send';
  //Get chat rooms
  static String chatRooms () => 'api/v1/chat-rooms/my-chats';

  //Payment endpoints
  static String createPayment () => 'api/v1/payments/create';
  static String getCheckout(String checkoutId) => 'api/v1/payments/checkout/$checkoutId';

  //Transaction endpoints
  static String getTransactionHistoriesOfRentedRoom(String rentedRoomId) => 'api/v1/transactions/topup/$rentedRoomId';
  
  //Contract endpoints
  //Get contract by id
  static String getDefaultContract (String roomId) => 'api/v1/contracts/default/$roomId';
  //Get contract by room
  static String getContractByRoom (String roomId) => 'api/v1/contracts/rooms/$roomId';
  //Get contract by rented room
  static String getContractByRentedRoom (String rentedRoomId) => 'api/v1/contracts/$rentedRoomId';
  //Get contract by user
  static String getContractByUser () => 'api/v1/contracts/user';
  //Download contract as PDF
  static String downloadContractPdf (String roomId) => 'api/v1/contracts/download/default-contract/$roomId';
  //Download rented room contract as PDF
  static String downloadRentedRoomContractPdf (String rentedRoomId) => 'api/v1/contracts/download/rented-contract/$rentedRoomId';
  //Get contract responsibilities
  static String getContractResponsibilities (String roomId) => 'api/v1/contracts/responsibilities/$roomId';
  //Modify contract
  static String modifyContract () => 'api/v1/contracts/modify';
  //Get landlord information
  static String getLandlordInfo () => 'api/v1/contracts/landlord-info';
  //Update landlord information
  static String updateLandlordInfo () => 'api/v1/contracts/landlord-fill';
  //Get tenant information
  static String getTenantInfo (String roomId) => 'api/v1/contracts/tenant-info/$roomId';
  //Update tenant information
  static String updateTenantInfo () => 'api/v1/contracts/tenant-fill';

  //Bill-logs endpoints
  static String getActiveBillLogByRentedRoomId(String rentedRoomId) => 'api/v1/bill-logs/active/rented-room/$rentedRoomId';
  static String getActiveBillLogByRoomId(String roomId) => 'api/v1/bill-logs/active/room/$roomId';
  static String updateUtilityReadings(String billLogId) => 'api/v1/bill-logs/$billLogId';
  static String getBillLogHistoryByRentedRoomId(String rentedRoomId) => 'api/v1/bill-logs/rented-room/$rentedRoomId';

  // Landlord statistics endpoint
  static String landlordStatistics(String userId) => 'api/statistics/landlord/$userId';

  // Additional bill-logs endpoints for landlord management
  static String getBillLogHistory(String roomId) => 'api/v1/bill-logs/room/$roomId';
  static String confirmUtilityReadings(String billLogId) => 'api/v1/bill-logs/$billLogId/check';

  // User enpoints
  static String getCurrentUserInfo() => 'api/v1/auth/me';

  //Map endpoints
  static String autoCompletePlace () => 'https://maps.googleapis.com/maps/api/place/autocomplete/json';
  static String placeDetail() => 'https://maps.googleapis.com/maps/api/place/details/json';

  //Find partner endpoints
  //Create findPartner post with 2 types: 'NEW_RENTAL' or 'ADDITIONAL_TENANT', NEW_RENTAL mean the room is new and ADDITIONAL_TENANT mean the room is already rented
  static String createFindPartnerPost() => 'api/v1/find-partner';
  //Get findPartner posts by roomId
  static String getFindPartnerPosts(String roomId) => 'api/v1/find-partner/active/room/$roomId';
  //Check if user is already in the findPartner post if the user is already in the findPartner post,
  //The return value is plain true or false, if true call getActiveFindPartnerPosts() and show info
  //If false, the user can create or join new findPartner post
  static String checkUserInFindPartnerPost(String userId, String roomId) => 'api/v1/find-partner/active/$userId/$roomId';
  //Get active findPartner posts of user
  static String getActiveFindPartnerPosts() => 'api/v1/find-partner/active/user';
  //The user request to join the findPartner post
  static String requestToJoinFindPartnerPost() => 'api/v1/find-partner/request';
  //The user request to accept the another user to join the findPartner post
  //Query param: privateId
  static String requestToAcceptFindPartnerPost(String chatRoomId) => 'api/v1/find-partner/accept-request/$chatRoomId';
  //The user request to reject the another user to join the findPartner post
  static String requestToRejectFindPartnerPost(String chatRoomId) => 'api/v1/find-partner/reject-request/$chatRoomId';
  //The user request to cancel their own request to join the findPartner post
  static String requestToCancelFindPartnerPost(String chatRoomId) => 'api/v1/find-partner/request/cancel/$chatRoomId';
  //Update find partner post
  static String updateFindPartnerPost(String findPartnerPostId) => 'api/v1/find-partner/$findPartnerPostId';
  //Get find partner post detail
  static String getFindPartnerPostDetail(String findPartnerPostId) => 'api/v1/find-partner/$findPartnerPostId';
  //Remove participant from find partner post
  static String removeParticipant(String findPartnerPostId, String userId) => 'api/v1/find-partner/$findPartnerPostId/remove-participant';
  //Exit find partner post (current user)
  static String exitFindPartnerPost(String findPartnerPostId) => 'api/v1/find-partner/$findPartnerPostId/exit';
  //Add participant to find partner post
  static String addParticipant(String findPartnerPostId) => 'api/v1/find-partner/$findPartnerPostId/add-participant';

  static String deleteFindPartnerPost(String findPartnerPostId) => 'api/v1/find-partner/$findPartnerPostId';

  // Budget plan endpoints
  static String saveBudgetPlanPreference() => 'api/v1/budget-plan/save-user-preference';
  static String getSearchedRooms() => 'api/v1/budget-plan/get-searched-room';
  static String getRoomBudgetPlanDetail(String roomId) => 'api/v1/budget-plan/get-room-budget-plan-detail/$roomId';
  static String isUserPreferenceExists() => 'api/v1/budget-plan/is-user-preference-exists';
  static String extractUserPrompt() => 'extract';

  // Ads endpoints
  static String createCampaign() => 'api/v1/ads/campaigns';
  static String getCampaigns() => 'api/v1/ads/campaigns';
  static String pauseCampaign(String campaignId) => 'api/v1/ads/campaigns/$campaignId/pause';
  static String resumeCampaign(String campaignId) => 'api/v1/ads/campaigns/$campaignId/resume';
  static String deleteCampaign(String campaignId) => 'api/v1/ads/campaigns/$campaignId';
  static String updateCampaign(String campaignId) => 'api/v1/ads/campaigns/$campaignId';
  static String getPromotedRoomsByCampaign(String campaignId) => 'api/v1/ads/promoted-rooms/campaigns/$campaignId';
  static String deletePromotedRoom(String promotedRoomId) => 'api/v1/ads/promoted-rooms/$promotedRoomId';
  static String updatePromotedRoom(String promotedRoomId) => 'api/v1/ads/promoted-rooms/$promotedRoomId';
  static String trackPromotedRoomClick() => 'api/v1/ads/promoted-rooms/click';
  static String trackPromotedRoomImpression() => 'api/v1/ads/impression';

  //Recommendation endpoints
  static String getRecommendedRoomIds(String userId) => 'api/v1/recommend/$userId';

  //Wallet endpoints
  static String getWithdrawInfo() => 'api/wallet/withdraw-info';
  static String createWithdrawRequest() => 'api/wallet/withdraw-info';
  static String withDrawMoney(double amount) => 'api/wallet/withdraw/$amount';

  // Room report endpoint
  static String roomReport() => 'api/v1/room-reports';
}
