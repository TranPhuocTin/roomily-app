import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/core/utils/format_utils.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/blocs/home/room_with_images_cubit.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/repositories/recommendation_repository.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/presentation/widgets/home/featured_room_section.dart';
import 'package:roomily/presentation/widgets/home/room_card.dart';

// States
abstract class RecommendationState extends Equatable {
  const RecommendationState();

  @override
  List<Object> get props => [];
}

class RecommendationInitial extends RecommendationState {}

class RecommendationLoading extends RecommendationState {}

class RecommendationLoaded extends RecommendationState {
  final List<RoomWithImages> roomsWithImages;
  final int total;
  final int page;
  final int pageSize;
  final int pages;
  final bool hasMoreData;

  const RecommendationLoaded({
    required this.roomsWithImages,
    required this.total,
    required this.page,
    required this.pageSize,
    required this.pages,
  }) : hasMoreData = page < pages;

  @override
  List<Object> get props => [roomsWithImages, total, page, pageSize, pages, hasMoreData];
}

class RecommendationError extends RecommendationState {
  final String message;

  const RecommendationError({required this.message});

  @override
  List<Object> get props => [message];
}

// Enhancement to RoomWithImages to include recommendation info
class EnhancedRoomWithImages extends RoomWithImages {
  final double score;
  final bool isPromoted;
  final String? promotedRoomId;

  EnhancedRoomWithImages({
    required Room room,
    required List<RoomImage> images,
    required this.score,
    required this.isPromoted,
    this.promotedRoomId,
  }) : super(room: room, images: images);
}

// Cubit để quản lý trạng thái gợi ý phòng
class RecommendationCubit extends Cubit<RecommendationState> {
  final RecommendationRepository _recommendationRepository;
  final RoomRepository _roomRepository;
  final RoomImageRepository _roomImageRepository;
  final AuthService? _authService;
  
  // Add map to store promotedRoomId by roomId
  final Map<String, String> _promotedRoomsMap = {};

  RecommendationCubit({
    required RecommendationRepository recommendationRepository,
    required RoomRepository roomRepository,
    required RoomImageRepository roomImageRepository,
    AuthService? authService,
  })  : _recommendationRepository = recommendationRepository,
        _roomRepository = roomRepository,
        _roomImageRepository = roomImageRepository,
        _authService = authService ?? GetIt.instance<AuthService>(),
        super(RecommendationInitial());

  Future<void> loadRecommendedRooms({
    int? topK,
    int page = 1,
    int? pageSize,
    bool isLoadMore = false,
  }) async {
    try {
      // Nếu không phải load thêm, hiển thị trạng thái loading
      if (!isLoadMore) {
        emit(RecommendationLoading());
      }

      // Lấy userId từ AuthService
      final userId = _authService?.userId;
      if (userId == null) {
        emit(const RecommendationError(message: 'Không thể lấy thông tin người dùng. Vui lòng đăng nhập lại.'));
        return;
      }

      debugPrint('🧩 Tải phòng được đề xuất cho người dùng: $userId (trang $page)');

      // Lấy danh sách ID phòng được gợi ý với phân trang
      final recommendationResult = await _recommendationRepository.getRecommendedRoomIds(
        userId,
        topK: topK,
        page: page,
        pageSize: pageSize,
      );

      switch (recommendationResult) {
        case Success(data: final pagination):
          final List<RoomWithImages> roomsWithImages = [];

          // Tải thông tin chi tiết và hình ảnh cho từng phòng từ danh sách recommendations
          for (final recommendation in pagination.recommendations) {
            try {
              final roomId = recommendation.roomId;
              final roomResult = await _roomRepository.getRoom(roomId);

              switch (roomResult) {
                case Success(data: final room):
                  final imagesResult = await _roomImageRepository.getRoomImages(roomId);

                  switch (imagesResult) {
                    case Success(data: final images):
                      // Sử dụng EnhancedRoomWithImages để lưu trữ thêm thông tin score và isPromoted
                      roomsWithImages.add(EnhancedRoomWithImages(
                        room: room,
                        images: images,
                        score: recommendation.score,
                        isPromoted: recommendation.isPromoted,
                        promotedRoomId: recommendation.promotedRoomId,
                      ));
                    case Failure():
                      // Nếu không tải được hình ảnh, vẫn thêm phòng với danh sách hình ảnh rỗng
                      roomsWithImages.add(EnhancedRoomWithImages(
                        room: room,
                        images: [],
                        score: recommendation.score,
                        isPromoted: recommendation.isPromoted,
                        promotedRoomId: recommendation.promotedRoomId,
                      ));
                  }
                case Failure(message: final message):
                  // Bỏ qua phòng này nếu không tải được thông tin
                  debugPrint('⚠️ Failed to load room $roomId: $message');
              }
            } catch (e) {
              debugPrint('⚠️ Error loading room ${recommendation.roomId}: $e');
            }
          }

          // Sắp xếp phòng theo score giảm dần
          roomsWithImages.sort((a, b) {
            if (a is EnhancedRoomWithImages && b is EnhancedRoomWithImages) {
              return b.score.compareTo(a.score);
            }
            return 0;
          });

          // Đưa các phòng được promoted lên đầu
          final promotedRooms = roomsWithImages.where((room) {
            return room is EnhancedRoomWithImages && room.isPromoted;
          }).toList();

          final regularRooms = roomsWithImages.where((room) {
            return room is EnhancedRoomWithImages && !room.isPromoted;
          }).toList();

          final sortedRooms = [...promotedRooms, ...regularRooms];

          // Nếu đang load thêm, kết hợp với dữ liệu cũ
          if (isLoadMore && state is RecommendationLoaded) {
            final currentState = state as RecommendationLoaded;
            final combinedRooms = [...currentState.roomsWithImages, ...sortedRooms];

            emit(RecommendationLoaded(
              roomsWithImages: combinedRooms,
              total: pagination.total,
              page: pagination.page,
              pageSize: pagination.pageSize,
              pages: pagination.pages,
            ));
          } else {
            emit(RecommendationLoaded(
              roomsWithImages: sortedRooms,
              total: pagination.total,
              page: pagination.page,
              pageSize: pagination.pageSize,
              pages: pagination.pages,
            ));
          }

        case Failure(message: final message):
          emit(RecommendationError(message: message));
      }
    } catch (e) {
      emit(RecommendationError(message: e.toString()));
    }
  }

  /// Loads promoted rooms for current user and stores a mapping of roomId to promotedRoomId
  Future<void> loadPromotedRooms() async {
    try {
      // Lấy userId từ AuthService
      final userId = _authService?.userId;
      if (userId == null) {
        debugPrint("⚠️ No userId available for loading promoted rooms");
        return;
      }

      debugPrint("🔍 Loading promoted rooms for user: $userId");
      final result = await _recommendationRepository.getPromotedRooms(userId);

      switch (result) {
        case Success(data: final pagination):
          // Reset existing maps
          _promotedRoomsMap.clear();
          _promotedRoomScores.clear();
          
          // Store mapping of roomId to promotedRoomId and scores
          for (final recommendation in pagination.recommendations) {
            if (recommendation.isPromoted && recommendation.promotedRoomId != null) {
              _promotedRoomsMap[recommendation.roomId] = recommendation.promotedRoomId!;
              _promotedRoomScores[recommendation.roomId] = recommendation.score;
              debugPrint("📝 Added promoted room: ${recommendation.roomId} -> ${recommendation.promotedRoomId} (score: ${recommendation.score})");
            }
          }
          
          debugPrint("✅ Loaded ${_promotedRoomsMap.length} promoted room mappings with scores");
        case Failure(message: final message):
          debugPrint("❌ Failed to load promoted rooms: $message");
      }
    } catch (e) {
      debugPrint("❌ Error loading promoted rooms: $e");
    }
  }

  /// Checks if a room is promoted
  bool isRoomPromoted(String roomId) {
    return _promotedRoomsMap.containsKey(roomId);
  }

  /// Get promotedRoomId for a roomId with null safety
  String? getPromotedRoomId(String roomId) {
    return _promotedRoomsMap[roomId];
  }
  
  /// Lưu trữ scores của mỗi promoted room theo roomId
  final Map<String, double> _promotedRoomScores = {};
  
  /// Get score for a promoted room with null safety
  double getPromotedRoomScore(String roomId) {
    return _promotedRoomScores[roomId] ?? 0.0;
  }

  // Chuyển đổi từ RoomWithImages sang RoomCardData
  List<RoomCardData> convertToRoomCardData(List<RoomWithImages> roomsWithImages) {
    return roomsWithImages.map((item) {
      final room = item.room;
      final images = item.images;

      // Nếu là EnhancedRoomWithImages, tạo PromotedRoomCardData
      if (item is EnhancedRoomWithImages) {
        return PromotedRoomCardData(
          imageUrl: images.isNotEmpty ? images.first.url : '',
          name: room.title,
          price: FormatUtils.formatCurrency(room.price),
          address: room.address,
          squareMeters: room.squareMeters.toInt(),
          id: room.id,
          isPromoted: item.isPromoted,
          score: item.score,
          promotedRoomId: item.promotedRoomId,
        );
      }

      // Kiểm tra nếu phòng có trong _promotedRoomsMap
      final promotedRoomId = _promotedRoomsMap[room.id];
      if (promotedRoomId != null) {
        return PromotedRoomCardData(
          imageUrl: images.isNotEmpty ? images.first.url : '',
          name: room.title,
          price: FormatUtils.formatCurrency(room.price),
          address: room.address,
          squareMeters: room.squareMeters.toInt(),
          id: room.id,
          isPromoted: true,
          score: 1.0, // Default score for promoted rooms
          promotedRoomId: promotedRoomId,
        );
      }

      // Trường hợp bình thường, tạo RoomCardData thông thường
      return RoomCardData(
        imageUrl: images.isNotEmpty ? images.first.url : '',
        name: room.title,
        price: FormatUtils.formatCurrency(room.price),
        address: room.address,
        squareMeters: room.squareMeters.toInt(),
        id: room.id,
      );
    }).toList();
  }

  // Tải thêm phòng (trang tiếp theo)
  Future<void> loadMoreRooms({int? topK, int? pageSize}) async {
    if (state is RecommendationLoaded) {
      final currentState = state as RecommendationLoaded;

      // Kiểm tra xem còn dữ liệu để tải không
      if (currentState.hasMoreData) {
        final nextPage = currentState.page + 1;
        await loadRecommendedRooms(
          topK: topK,
          page: nextPage,
          pageSize: pageSize ?? currentState.pageSize,
          isLoadMore: true,
        );
      }
    }
  }

  // Tải dữ liệu ban đầu bao gồm cả phòng được gợi ý và phòng được quảng cáo
  Future<void> loadInitialData({
    int? topK,
    int page = 1,
    int? pageSize,
  }) async {
    try {
      // Lấy userId từ AuthService
      final userId = _authService?.userId;
      if (userId == null) {
        emit(const RecommendationError(message: 'Không thể lấy thông tin người dùng. Vui lòng đăng nhập lại.'));
        return;
      }

      // Hiển thị trạng thái loading
      emit(RecommendationLoading());

      // Tải promoted rooms trước
      await loadPromotedRooms();

      // Sau đó tải recommended rooms
      await loadRecommendedRooms(
        topK: topK,
        page: page,
        pageSize: pageSize,
      );

      debugPrint('✅ Đã tải cả recommended và promoted rooms');
    } catch (e) {
      emit(RecommendationError(message: e.toString()));
    }
  }
  
  // Hàm để áp dụng filter và giữ thông tin về promoted room
  Future<List<RoomCardData>> applyFilterAndMarkPromoted(List<RoomWithImages> filteredRooms) async {
    // Đảm bảo promoted rooms đã được tải
    if (_promotedRoomsMap.isEmpty) {
      await loadPromotedRooms();
    }
    
    // Chuyển đổi các phòng đã lọc thành RoomCardData, đánh dấu các phòng được quảng cáo
    final roomCards = filteredRooms.map((item) {
      final room = item.room;
      final images = item.images;
      
      // Kiểm tra nếu phòng có trong _promotedRoomsMap
      final promotedRoomId = _promotedRoomsMap[room.id];
      if (promotedRoomId != null) {
        return PromotedRoomCardData(
          imageUrl: images.isNotEmpty ? images.first.url : '',
          name: room.title,
          price: FormatUtils.formatCurrency(room.price),
          address: room.address,
          squareMeters: room.squareMeters.toInt(),
          id: room.id,
          isPromoted: true,
          score: 1.0,
          promotedRoomId: promotedRoomId,
        );
      }
      
      // Trường hợp bình thường
      return RoomCardData(
        imageUrl: images.isNotEmpty ? images.first.url : '',
        name: room.title,
        price: FormatUtils.formatCurrency(room.price),
        address: room.address,
        squareMeters: room.squareMeters.toInt(),
        id: room.id,
      );
    }).toList();
    
    debugPrint('🔍 Đã áp dụng filter và đánh dấu ${_promotedRoomsMap.length} promoted rooms');
    return roomCards;
  }
}