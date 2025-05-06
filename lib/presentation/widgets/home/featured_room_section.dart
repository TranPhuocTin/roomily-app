import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/core/utils/network_util.dart';
import 'package:roomily/data/blocs/home/recommendation_cubit.dart';
import 'package:roomily/data/models/ad_click_request_model.dart';
import 'package:roomily/data/models/ad_click_response_model.dart';
import 'package:roomily/data/models/ad_impression_request_model.dart';
import 'package:roomily/data/repositories/ad_repository.dart';
import 'package:roomily/presentation/screens/room_detail_screen.dart';
import 'package:roomily/presentation/widgets/home/room_card.dart';
import 'package:roomily/presentation/widgets/home/shimmer_room_card.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';


class FeaturedRoomsSection extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<RoomCardData> rooms;
  final EdgeInsetsGeometry padding;
  final bool isLoading;
  final int shimmerCount;

  const FeaturedRoomsSection({
    Key? key,
    this.title = 'Phòng nổi bật',
    this.subtitle,
    required this.rooms,
    this.padding = const EdgeInsets.symmetric(vertical: 16),
    this.isLoading = false,
    this.shimmerCount = 3,
  }) : super(key: key);

  @override
  State<FeaturedRoomsSection> createState() => _FeaturedRoomsSectionState();
}

class _FeaturedRoomsSectionState extends State<FeaturedRoomsSection> {
  final Set<String> _trackedRoomIds = {};
  final Map<String, Timer> _impressionTimers = {};
  static const Duration _impressionDelay = Duration(milliseconds: 1500); // 1.5 giây

  @override
  void dispose() {
    // Hủy tất cả timers khi widget bị dispose
    _impressionTimers.forEach((_, timer) => timer.cancel());
    _impressionTimers.clear();
    super.dispose();
  }

  Future<void> _handleRoomTap(BuildContext context, RoomCardData room) async {
    if (room.id == null) return;

    // Kiểm tra xem room có phải là promoted room hay không
    final isPromoted = room is PromotedRoomCardData && room.isPromoted;
    print('🏠 Tap on room: ${room.name} (ID: ${room.id}) - isPromoted: $isPromoted');
    
    if (isPromoted) {
      try {
        print('🔍 Đây là promoted room, bắt đầu xử lý tracking...');
        final PromotedRoomCardData promotedRoom = room as PromotedRoomCardData;
        print('📊 Room score: ${promotedRoom.score}');
        print('🆔 PromotedRoomId: ${promotedRoom.promotedRoomId ?? "không có"}');
        
        // Lấy userId từ AuthService
        final AuthService authService = GetIt.instance<AuthService>();
        final String? userId = authService.userId;
        print('👤 UserId: ${userId ?? "null"}');
        
        if (userId == null) {
          print('⚠️ Không có userId, chuyển đến chi tiết phòng mà không track');
          // Nếu không có userId, vẫn mở màn hình chi tiết phòng nhưng không track
          _navigateToRoomDetail(context, room.id!);
          return;
        }
        
        // Lấy IP address
        print('🌐 Đang lấy địa chỉ IP...');
        final String? ipAddress = await NetworkUtil.getIPv4Address();
        print('🌐 Địa chỉ IP: ${ipAddress ?? "không lấy được"}');
        
        if (ipAddress == null) {
          print('⚠️ Không lấy được IP, chuyển đến chi tiết phòng mà không track');
          // Nếu không lấy được IP, vẫn mở màn hình chi tiết phòng nhưng không track
          _navigateToRoomDetail(context, room.id!);
          return;
        }
        
        // Kiểm tra nếu không có promotedRoomId hoặc promotedRoomId là null
        if (promotedRoom.promotedRoomId == null) {
          print('⚠️ Không có promotedRoomId, sử dụng roomId thông thường');
          // Nếu không có promotedRoomId, mở màn hình chi tiết phòng bình thường
          _navigateToRoomDetail(context, room.id!);
          return;
        }
        
        // Tạo request model
        final clickRequest = AdClickRequestModel(
          promotedRoomId: promotedRoom.promotedRoomId!,
          ipAddress: ipAddress,
          userId: userId,
        );
        print('📝 Đã tạo AdClickRequestModel với promotedRoomId: ${promotedRoom.promotedRoomId}');
        
        // Dump model as JSON for debugging
        print('🛠️ AdClickRequestModel toJson: ${clickRequest.toJson()}');
        
        // Track click
        print('🚀 Gửi request tới AdRepository.trackPromotedRoomClick()...');
        final adRepository = GetIt.instance<AdRepository>();
        final AdClickResponseModel response = await adRepository.trackPromotedRoomClick(clickRequest);
        print('✅ Nhận được response: adClickId=${response.adClickId}, status=${response.status}');
        
        // Kiểm tra trạng thái response
        if (response.status == "error" || response.status == "duplicate") {
          print('⚠️ Response status là "error", không truyền adClickResponse vào RoomDetailScreen');
          // Nếu status là error, mở màn hình chi tiết phòng bình thường không kèm response
          _navigateToRoomDetail(context, room.id!);
          return;
        }
        
        // Mở màn hình chi tiết phòng với thông tin từ response
        print('📱 Chuyển đến chi tiết phòng với adClickResponse');
        _navigateToRoomDetail(context, room.id!, adClickResponse: response);
      } catch (e) {
        print('❌ Error tracking promoted room click: $e');
        // Stack trace để debug
        print('❌ Stack trace: ${StackTrace.current}');
        // Nếu có lỗi, vẫn mở màn hình chi tiết phòng nhưng không kèm response
        _navigateToRoomDetail(context, room.id!);
      }
    } else {
      print('📱 Phòng bình thường, chuyển đến chi tiết phòng');
      // Nếu không phải promoted room, mở màn hình chi tiết phòng bình thường
      _navigateToRoomDetail(context, room.id!);
    }
  }

  void _navigateToRoomDetail(BuildContext context, String roomId, {AdClickResponseModel? adClickResponse}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => RoomDetailScreen(
        roomId: roomId,
        adClickResponse: adClickResponse,
      ),
    ));
  }

  Future<void> _trackImpressions(List<PromotedRoomCardData> visiblePromotedRooms) async {
    if (visiblePromotedRooms.isEmpty) return;
    
    try {
      // Get auth service to get userId
      final AuthService authService = GetIt.instance<AuthService>();
      final String? userId = authService.userId;
      
      if (userId == null) {
        print('⚠️ Không có userId, không thể track impressions');
        return;
      }
      
      // Filter rooms that have promotedRoomId and not tracked yet
      final List<String> promotedRoomIdsToTrack = visiblePromotedRooms
          .where((room) => room.promotedRoomId != null && !_trackedRoomIds.contains(room.promotedRoomId))
          .map((room) => room.promotedRoomId!)
          .toList();
      
      if (promotedRoomIdsToTrack.isEmpty) return;
      
      print('👁️ Tracking impressions for rooms: $promotedRoomIdsToTrack');
      
      // Create impression request model
      final impressionRequest = AdImpressionRequestModel(
        promotedRoomIds: promotedRoomIdsToTrack,
        userId: userId,
      );
      
      // Track impressions
      final adRepository = GetIt.instance<AdRepository>();
      await adRepository.trackPromotedRoomImpression(impressionRequest);
      
      // Add tracked rooms to the set to avoid duplicate tracking
      _trackedRoomIds.addAll(promotedRoomIdsToTrack);
      
      print('✅ Successfully tracked impressions for rooms: $promotedRoomIdsToTrack');
    } catch (e) {
      print('❌ Error tracking impressions: $e');
      print('❌ Stack trace: ${StackTrace.current}');
    }
  }

  void _handleRoomVisibilityChanged(PromotedRoomCardData room, double visibleFraction) {
    if (room.promotedRoomId == null || _trackedRoomIds.contains(room.promotedRoomId)) {
      return; // Không có promotedRoomId hoặc đã track rồi
    }

    final roomId = room.promotedRoomId!;

    if (visibleFraction > 0.7) {
      // Room trở nên hiển thị, bắt đầu timer nếu chưa có
      if (!_impressionTimers.containsKey(roomId)) {
        print('⏱️ Bắt đầu đếm thời gian hiển thị cho room: $roomId');
        _impressionTimers[roomId] = Timer(_impressionDelay, () {
          print('⏱️ Đã hiển thị đủ 1.5 giây cho room: $roomId');
          _trackImpressions([room]);
          _impressionTimers.remove(roomId);
        });
      }
    } else {
      // Room không còn hiển thị đủ, hủy timer nếu có
      if (_impressionTimers.containsKey(roomId)) {
        print('⏱️ Hủy timer cho room vì không còn hiển thị đủ: $roomId');
        _impressionTimers[roomId]?.cancel();
        _impressionTimers.remove(roomId);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Extract promoted rooms from the list
    final List<PromotedRoomCardData> promotedRooms = widget.rooms
        .whereType<PromotedRoomCardData>()
        .where((room) => room.isPromoted && room.promotedRoomId != null)
        .toList();

    return Padding(
      padding: widget.padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.subtitle != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (widget.subtitle != null)
                    Text(
                      widget.subtitle!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
            ),
            
          // List of room cards
          if (widget.isLoading)
            // Hiển thị shimmer khi đang tải
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: widget.shimmerCount,
              itemBuilder: (context, index) {
                return const ShimmerRoomCard();
              },
            )
          else
            // Hiển thị danh sách phòng khi đã tải xong
            widget.rooms.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Column(
                        children: [
                          Icon(Icons.home_outlined, size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'Không có phòng nào',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: widget.rooms.length,
                    itemBuilder: (context, index) {
                      final room = widget.rooms[index];
                      // Wrap each promoted room card with individual visibility detector
                      if (room is PromotedRoomCardData && room.isPromoted && room.promotedRoomId != null) {
                        return VisibilityDetector(
                          key: Key('promoted_room_${room.promotedRoomId}'),
                          onVisibilityChanged: (visibilityInfo) {
                            _handleRoomVisibilityChanged(room, visibilityInfo.visibleFraction);
                          },
                          child: RoomCard(
                            imageUrl: room.imageUrl,
                            roomName: room.name,
                            price: room.price,
                            address: room.address,
                            squareMeters: room.squareMeters,
                            onTap: () => _handleRoomTap(context, room),
                          ),
                        );
                      } else {
                        return RoomCard(
                          imageUrl: room.imageUrl,
                          roomName: room.name,
                          price: room.price,
                          address: room.address,
                          squareMeters: room.squareMeters,
                          onTap: () => _handleRoomTap(context, room),
                        );
                      }
                    },
                  ),
        ],
      ),
    );
  }
}

/// Extension of RoomCardData for promoted rooms
class PromotedRoomCardData extends RoomCardData {
  final bool isPromoted;
  final double score;
  final String? promotedRoomId;

  const PromotedRoomCardData({
    required super.imageUrl,
    required super.name,
    required super.price,
    required super.address,
    required super.squareMeters,
    required super.id,
    required this.isPromoted,
    required this.score,
    this.promotedRoomId,
    super.onTap,
  });
}

class RoomCardData {
  final String imageUrl;
  final String name;
  final String price;
  final String address;
  final int squareMeters;
  final RoomType type;
  final String? id;
  final bool isSubscribed;
  final VoidCallback? onTap;

  const RoomCardData({
    required this.imageUrl,
    required this.name,
    required this.price,
    required this.address,
    required this.squareMeters,
    this.type = RoomType.normal,
    this.id,
    this.isSubscribed = false,
    this.onTap,
  });
}