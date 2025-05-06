import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/core/utils/room_type.dart' as api_room_type;
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/presentation/screens/room_detail_screen.dart';
import 'package:roomily/presentation/widgets/home/room_card.dart';
import 'package:roomily/presentation/widgets/home/featured_room_section.dart';
import 'package:roomily/presentation/widgets/home/shimmer_room_card.dart';
import 'package:roomily/presentation/widgets/search/filter_bottom_sheet.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/rendering.dart';
import 'package:roomily/core/services/tag_service.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/data/repositories/ad_repository.dart';
import 'package:roomily/data/models/ad_click_request_model.dart';
import 'package:roomily/data/models/ad_click_response_model.dart';
import 'package:roomily/data/models/ad_impression_request_model.dart';
import 'package:roomily/core/utils/network_util.dart';
import 'package:roomily/data/repositories/recommendation_repository.dart';
import 'package:roomily/data/blocs/home/recommendation_cubit.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'dart:async';
import 'dart:math' as math;

import '../../data/blocs/room_filter/room_filter_cubit.dart';
import '../../data/blocs/room_filter/room_filter_state.dart';

class SeeAllRoomsScreen extends StatefulWidget {
  final String title;
  final String? roomType; // Loại phòng (VIP, thường, v.v.)
  final RoomFilter? initialFilter;
  final bool shouldLoadInitialData;

  const SeeAllRoomsScreen({
    super.key,
    this.title = 'Danh sách phòng',
    this.roomType,
    this.initialFilter,
    this.shouldLoadInitialData = true, // Mặc định là true để không ảnh hưởng các nơi khác
  });

  @override
  State<SeeAllRoomsScreen> createState() => _SeeAllRoomsScreenState();
}

class _SeeAllRoomsScreenState extends State<SeeAllRoomsScreen> {
  late RoomFilterCubit _roomFilterCubit;
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  // Repository để lấy hình ảnh phòng
  late RoomImageRepository _roomImageRepository;
  
  // Trạng thái filter hiện tại
  late RoomFilter _currentFilter;
  
  // Trạng thái hiển thị filter
  bool _isFilterVisible = false;
  
  // Cache hình ảnh phòng
  final Map<String, List<RoomImage>> _roomImagesCache = {};
  
  // Cache RoomCardData để tracking promoted rooms
  final Map<String, RoomCardData> _roomCardDataCache = {};
  
  // Default limit for room queries
  static const int defaultLimit = 12;
  
  // Variables for tracking impressions
  final Set<String> _trackedRoomIds = {};
  final Map<String, Timer> _impressionTimers = {};
  static const Duration _impressionDelay = Duration(milliseconds: 1500); // 1.5 giây
  
  // Recommendation cubit để lấy promoted rooms
  late RecommendationCubit _recommendationCubit;
  
  // Services & Repositories for CPM tracking
  late AuthService _authService;
  late AdRepository _adRepository;

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo services và repositories
    _roomImageRepository = GetIt.instance<RoomImageRepository>();
    _authService = GetIt.instance<AuthService>();
    _adRepository = GetIt.instance<AdRepository>();
    
    // Khởi tạo RecommendationCubit
    _recommendationCubit = RecommendationCubit(
      recommendationRepository: GetIt.instance<RecommendationRepository>(),
      roomRepository: GetIt.instance<RoomRepository>(),
      roomImageRepository: _roomImageRepository,
    );
    
    // Tải danh sách promoted rooms
    _loadPromotedRooms();
    
    // Khởi tạo RoomFilterCubit
    _roomFilterCubit = RoomFilterCubit();
    
    // Khởi tạo filter theo yêu cầu shouldLoadInitialData
    if (widget.shouldLoadInitialData) {
      // Khởi tạo filter bình thường nếu cần load dữ liệu ban đầu
      _currentFilter = widget.initialFilter ?? RoomFilter.defaultFilter();
      
      // Kiểm tra và xử lý roomType từ tham số nếu có
      if (widget.roomType != null && widget.roomType!.isNotEmpty) {
        // Chuyển đổi từ String sang RoomType enum
        api_room_type.RoomType? typeEnum;
        if (widget.roomType!.toUpperCase() == 'ROOM' || widget.roomType!.toUpperCase() == 'PHÒNG TRỌ') {
          typeEnum = api_room_type.RoomType.ROOM;
        } else if (widget.roomType!.toUpperCase() == 'APARTMENT' || widget.roomType!.toUpperCase() == 'CHUNG CƯ') {
          typeEnum = api_room_type.RoomType.APARTMENT;
        }
        
        if (typeEnum != null) {
          _currentFilter = _currentFilter.copyWith(type: typeEnum);
        }
      }
      
      // Ensure limit is set to defaultLimit
      if (_currentFilter.limit != defaultLimit) {
        _currentFilter = RoomFilter(
          city: _currentFilter.city,
          district: _currentFilter.district,
          ward: _currentFilter.ward,
          type: _currentFilter.type,
          minPrice: _currentFilter.minPrice,
          maxPrice: _currentFilter.maxPrice,
          minPeople: _currentFilter.minPeople,
          maxPeople: _currentFilter.maxPeople,
          limit: defaultLimit,
          tagIds: _currentFilter.tagIds,
        );
      }
    } else {
      // Khởi tạo filter hoàn toàn trống nếu không cần load dữ liệu ban đầu
      _currentFilter = RoomFilterExtension.empty();
    }
    
    // Đảm bảo các trường filter có giá trị null thay vì chuỗi rỗng để xử lý nhất quán
    _currentFilter = _currentFilter.normalize();
    
    // Tải dữ liệu tiện ích
    _loadAmenities();
    
    // Chỉ tải danh sách phòng với filter ban đầu nếu shouldLoadInitialData là true
    if (widget.shouldLoadInitialData) {
      _roomFilterCubit.loadRooms(customFilter: _currentFilter);
    }
    
    // Thêm listener cho scroll controller để tải thêm dữ liệu khi cuộn đến cuối
    _scrollController.addListener(_onScroll);
  }

  // Tải danh sách promoted rooms
  Future<void> _loadPromotedRooms() async {
    try {
      await _recommendationCubit.loadPromotedRooms();
      debugPrint('✅ Đã tải promoted rooms');
    } catch (e) {
      debugPrint('❌ Lỗi khi tải promoted rooms: $e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _roomFilterCubit.close();
    _recommendationCubit.close();
    
    // Hủy tất cả timers khi widget bị dispose
    _impressionTimers.forEach((_, timer) => timer.cancel());
    _impressionTimers.clear();
    
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    final state = _roomFilterCubit.state;
    
    // Kiểm tra nếu đã cuộn đến gần cuối hơn và chưa đạt giới hạn
    if (currentScroll >= maxScroll - 300 && 
        !state.hasReachedMax && 
        state.status != RoomFilterStatus.loadingMore) {
      // Debug để theo dõi
      debugPrint('Loading more rooms at scroll position: $currentScroll / $maxScroll');
      _roomFilterCubit.loadMoreRooms();
    }
  }

  // Lấy hình ảnh cho phòng
  Future<List<RoomImage>> _getRoomImages(String roomId) async {
    // Kiểm tra cache trước
    if (_roomImagesCache.containsKey(roomId)) {
      final images = _roomImagesCache[roomId]!;
      debugPrint('🖼️ Lấy ảnh từ cache cho room $roomId: ${images.length} ảnh');
      if (images.isNotEmpty) {
        debugPrint('🖼️ URL ảnh đầu tiên từ cache: ${images.first.url}');
      }
      return images;
    }
    
    try {
      // Gọi API để lấy hình ảnh
      final result = await _roomImageRepository.getRoomImages(roomId);
      
      // Xử lý kết quả
      if (result is Success<List<RoomImage>>) {
        final images = result.data;
        debugPrint('🖼️ Lấy ảnh cho room $roomId từ API: ${images.length} ảnh');
        if (images.isNotEmpty) {
          debugPrint('🖼️ URL ảnh đầu tiên từ API: ${images.first.url}');
        } else {
          debugPrint('⚠️ Không có ảnh cho room $roomId từ API');
        }
        // Lưu vào cache
        _roomImagesCache[roomId] = images;
        return images;
      } else {
        debugPrint('❌ Lấy ảnh thất bại cho room $roomId');
        return [];
      }
    } catch (e) {
      debugPrint('❌ Error loading images for room $roomId: $e');
      return [];
    }
  }

  // Tạo RoomCardData từ Room và danh sách hình ảnh, kiểm tra nếu là promoted room
  RoomCardData _createRoomCardData(Room room, List<RoomImage> images) {
    // Nếu room đã được cache, trả về từ cache
    if (_roomCardDataCache.containsKey(room.id ?? '')) {
      return _roomCardDataCache[room.id ?? '']!;
    }
    
    // Debug thông tin ảnh
    if (images.isNotEmpty) {
      debugPrint('🖼️ Tạo RoomCardData với ảnh URL: ${images.first.url}');
    } else {
      debugPrint('⚠️ Tạo RoomCardData không có ảnh cho room ${room.id}');
    }
    
    // Kiểm tra nếu room là promoted room
    final String? promotedRoomId = _recommendationCubit.getPromotedRoomId(room.id ?? '');
    
    RoomCardData roomCardData;
    if (promotedRoomId != null) {
      // Nếu là promoted room, tạo PromotedRoomCardData
      roomCardData = PromotedRoomCardData(
        imageUrl: images.isNotEmpty ? images.first.url : '',
        name: room.title,
        price: '${room.price.toStringAsFixed(0)} đ',
        address: room.address,
        squareMeters: room.squareMeters?.toInt() ?? 0,
        id: room.id,
        isPromoted: true,
        score: 1.0, // Default score
        promotedRoomId: promotedRoomId,
      );
      debugPrint('🔍 Đã đánh dấu promoted room: ${room.id}, promotedRoomId: $promotedRoomId');
    } else {
      // Trường hợp thường, tạo RoomCardData thông thường
      roomCardData = RoomCardData(
        imageUrl: images.isNotEmpty ? images.first.url : '',
        name: room.title,
        price: '${room.price.toStringAsFixed(0)} đ',
        address: room.address,
        squareMeters: room.squareMeters?.toInt() ?? 0,
        id: room.id,
      );
    }
    
    // Lưu vào cache
    _roomCardDataCache[room.id ?? ''] = roomCardData;
    
    return roomCardData;
  }

  // Xử lý khi người dùng nhấn nút tìm kiếm
  void _handleSearch(String query) {
    if (query.isEmpty) return;
    
    // Cập nhật filter với từ khóa tìm kiếm
    final newFilter = _currentFilter.copyWith(
      // Giả sử API hỗ trợ tìm kiếm theo từ khóa
      // Nếu không, cần thêm trường searchKeyword vào RoomFilter
    );
    
    setState(() {
      _currentFilter = newFilter;
    });
    
    // Tải lại danh sách phòng với filter mới
    _roomFilterCubit.loadRooms(customFilter: newFilter);
  }

  // Hiển thị bottom sheet filter
  void _showFilterBottomSheet() {
    setState(() {
      _isFilterVisible = true;
    });
    
    // Chuẩn hóa filter trước khi truyền cho FilterBottomSheet
    final normalizedFilter = _currentFilter.normalize();
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterBottomSheet(
        initialFilter: normalizedFilter,
        onApplyFilter: (filter) {
          // Chuẩn hóa filter nhận được từ FilterBottomSheet
          final normalizedReturnedFilter = filter.normalize();
          setState(() {
            _currentFilter = normalizedReturnedFilter;
            _isFilterVisible = false;
          });
          
          // Tải lại danh sách phòng với filter mới
          _roomFilterCubit.loadRooms(customFilter: normalizedReturnedFilter);
          
          // Không cần đóng bottom sheet ở đây vì đã được xử lý trong FilterBottomSheet
        },
        onClose: () {
          setState(() {
            _isFilterVisible = false;
          });
          
          // Không cần đóng bottom sheet ở đây vì đã được xử lý trong FilterBottomSheet
        },
      ),
    ).then((_) {
      // Đảm bảo _isFilterVisible được cập nhật khi bottom sheet đóng
      // bằng cách khác (như vuốt xuống)
      if (_isFilterVisible) {
        setState(() {
          _isFilterVisible = false;
        });
      }
    });
  }
  
  // Xử lý tracking impression khi room được hiển thị
  void _handleRoomVisibilityChanged(RoomCardData room, double visibleFraction) {
    // Chỉ xử lý nếu là promoted room
    if (room is! PromotedRoomCardData || room.promotedRoomId == null) {
      return;
    }
    
    // Đảm bảo promotedRoomId không null và chưa được track
    final promotedRoomId = room.promotedRoomId!;
    if (_trackedRoomIds.contains(promotedRoomId)) {
      return; // Đã track rồi
    }

    if (visibleFraction > 0.7) {
      // Room trở nên hiển thị, bắt đầu timer nếu chưa có
      if (!_impressionTimers.containsKey(promotedRoomId)) {
        debugPrint('⏱️ Bắt đầu đếm thời gian hiển thị cho room: $promotedRoomId');
        _impressionTimers[promotedRoomId] = Timer(_impressionDelay, () {
          debugPrint('⏱️ Đã hiển thị đủ 1.5 giây cho room: $promotedRoomId');
          _trackImpressions([room]);
          _impressionTimers.remove(promotedRoomId);
        });
      }
    } else {
      // Room không còn hiển thị đủ, hủy timer nếu có
      if (_impressionTimers.containsKey(promotedRoomId)) {
        debugPrint('⏱️ Hủy timer cho room vì không còn hiển thị đủ: $promotedRoomId');
        _impressionTimers[promotedRoomId]?.cancel();
        _impressionTimers.remove(promotedRoomId);
      }
    }
  }

  // Helper để tạo AdImpressionRequestModel an toàn
  AdImpressionRequestModel _createImpressionRequest(List<String> promotedRoomIds, String userId) {
    return AdImpressionRequestModel(
      promotedRoomIds: promotedRoomIds,
      userId: userId,
    );
  }
  
  // Helper để tạo AdClickRequestModel an toàn
  AdClickRequestModel _createClickRequest(String promotedRoomId, String ipAddress, String userId) {
    return AdClickRequestModel(
      promotedRoomId: promotedRoomId,
      ipAddress: ipAddress,
      userId: userId,
    );
  }
  
  // Định nghĩa lại cách triển khai _trackImpressions
  Future<void> _trackImpressions(List<PromotedRoomCardData> visiblePromotedRooms) async {
    // Lọc các phòng có promotedRoomId và chưa được track
    final promotedRooms = visiblePromotedRooms
        .where((room) => room.promotedRoomId != null && !_trackedRoomIds.contains(room.promotedRoomId))
        .toList();
    
    if (promotedRooms.isEmpty) return;
    
    // Lấy userId từ AuthService
    final userId = _authService.userId;
    if (userId == null) {
      debugPrint('⚠️ Không có userId, không thể track impressions');
      return;
    }
    
    try {
      // Tạo danh sách promotedRoomIds (chắc chắn không null)
      final List<String> promotedRoomIds = [];
      for (final room in promotedRooms) {
        if (room.promotedRoomId != null) {
          promotedRoomIds.add(room.promotedRoomId!);
        }
      }
      
      if (promotedRoomIds.isEmpty) return;
      
      debugPrint('👁️ Tracking impressions for rooms: $promotedRoomIds');
      
      // Tạo và gửi request
      final request = _createImpressionRequest(promotedRoomIds, userId);
      await _adRepository.trackPromotedRoomImpression(request);
      
      // Đánh dấu các phòng đã được track
      for (final id in promotedRoomIds) {
        _trackedRoomIds.add(id);
      }
      
      debugPrint('✅ Successfully tracked impressions');
    } catch (e) {
      debugPrint('❌ Error tracking impressions: $e');
    }
  }

  // Xử lý khi room được nhấn vào
  Future<void> _handleRoomTap(BuildContext context, RoomCardData room) async {
    if (room.id == null) return;
    
    // Kiểm tra xem có phải là promoted room không
    if (room is PromotedRoomCardData && room.isPromoted && room.promotedRoomId != null) {
      final promotedRoomId = room.promotedRoomId!;
      
      try {
        debugPrint('🔍 Đây là promoted room, bắt đầu xử lý tracking...');
        
        // Lấy userId
        final userId = _authService.userId;
        if (userId == null) {
          debugPrint('⚠️ Không có userId, chuyển đến chi tiết phòng mà không track');
          _navigateToRoomDetail(context, room.id!);
          return;
        }
        
        // Lấy IP address
        final ipAddress = await NetworkUtil.getIPv4Address();
        if (ipAddress == null) {
          debugPrint('⚠️ Không lấy được IP, chuyển đến chi tiết phòng mà không track');
          _navigateToRoomDetail(context, room.id!);
          return;
        }
        
        // Tạo request
        final request = _createClickRequest(promotedRoomId, ipAddress, userId);
        
        // Gửi request
        final response = await _adRepository.trackPromotedRoomClick(request);
        
        // Kiểm tra response
        if (response.status == "error" || response.status == "duplicate") {
          debugPrint('⚠️ Response status là "${response.status}", không truyền adClickResponse');
          _navigateToRoomDetail(context, room.id!);
          return;
        }
        
        // Chuyển đến màn hình chi tiết
        _navigateToRoomDetail(context, room.id!, adClickResponse: response);
      } catch (e) {
        debugPrint('❌ Error tracking click: $e');
        _navigateToRoomDetail(context, room.id!);
      }
    } else {
      // Trường hợp thường
      _navigateToRoomDetail(context, room.id!);
    }
  }

  // Chuyển đến màn hình chi tiết phòng
  void _navigateToRoomDetail(BuildContext context, String roomId, {AdClickResponseModel? adClickResponse}) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => RoomDetailScreen(
        roomId: roomId,
        adClickResponse: adClickResponse,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    // Debug log khi build được gọi
    debugPrint('Building UI with filter: $_currentFilter');
    
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.filter_list,
              color: _isFilterVisible ? Colors.blue : Colors.grey[700],
            ),
            onPressed: _showFilterBottomSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          // Padding(
          //   padding: const EdgeInsets.all(16.0),
          //   child: TextField(
          //     controller: _searchController,
          //     decoration: InputDecoration(
          //       hintText: 'Tìm kiếm phòng...',
          //       prefixIcon: const Icon(Icons.search),
          //       suffixIcon: IconButton(
          //         icon: const Icon(Icons.clear),
          //         onPressed: () {
          //           _searchController.clear();
          //         },
          //       ),
          //       border: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(30),
          //         borderSide: BorderSide(color: Colors.grey[300]!),
          //       ),
          //       enabledBorder: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(30),
          //         borderSide: BorderSide(color: Colors.grey[300]!),
          //       ),
          //       focusedBorder: OutlineInputBorder(
          //         borderRadius: BorderRadius.circular(30),
          //         borderSide: const BorderSide(color: Colors.blue),
          //       ),
          //       filled: true,
          //       fillColor: Colors.grey[100],
          //       contentPadding: const EdgeInsets.symmetric(vertical: 0),
          //     ),
          //     onSubmitted: _handleSearch,
          //   ),
          // ),
          
          // Filter chips - Chỉ hiển thị khi có filter đang active
          if (_hasActiveFilters())
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                key: ValueKey('filter_chips_row_${_currentFilter.hashCode}'),
                children: _buildFilterChips(),
              ),
            ),
          
          // Danh sách phòng
          Expanded(
            child: BlocBuilder<RoomFilterCubit, RoomFilterState>(
              bloc: _roomFilterCubit,
              builder: (context, state) {
                // Chỉ hiển thị shimmer khi đang tải dữ liệu, không hiển thị khi ở trạng thái initial và chưa load data
                if (state.status == RoomFilterStatus.loading && state.rooms.isEmpty) {
                  // Hiển thị shimmer chỉ khi đang tải
                  return GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.6,
                    ),
                    itemCount: 6,
                    itemBuilder: (context, index) => const ShimmerRoomCard(),
                  );
                } else if (state.status == RoomFilterStatus.error) {
                  // Hiển thị lỗi
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        Text(
                          'Đã xảy ra lỗi: ${state.errorMessage}',
                          style: const TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            _roomFilterCubit.loadRooms(customFilter: _currentFilter);
                          },
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                  );
                } else if (state.status == RoomFilterStatus.initial && !widget.shouldLoadInitialData) {
                  // Trạng thái khởi tạo và không cần load dữ liệu ban đầu - hiển thị hướng dẫn chọn bộ lọc
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.filter_alt_outlined, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Chọn bộ lọc để tìm phòng',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[600],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Nhấn vào biểu tượng bộ lọc ở góc trên bên phải để bắt đầu',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showFilterBottomSheet,
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Mở bộ lọc'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state.status == RoomFilterStatus.empty) {
                  // Hiển thị rõ ràng khi status là empty
                  debugPrint('Rendering empty state UI with filter: ${state.filter}');
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          'Không tìm thấy phòng ở ${state.filter.city ?? "địa điểm này"}',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Vui lòng thử với bộ lọc khác',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _showFilterBottomSheet,
                          icon: const Icon(Icons.filter_list),
                          label: const Text('Thay đổi bộ lọc'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  );
                } else if (state.rooms.isEmpty) {
                  // Trường hợp rooms rỗng nhưng không phải status empty
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off, size: 48, color: Colors.grey),
                        const SizedBox(height: 16),
                        const Text(
                          'Không tìm thấy phòng nào phù hợp với bộ lọc',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showFilterBottomSheet,
                          child: const Text('Thay đổi bộ lọc'),
                        ),
                      ],
                    ),
                  );
                } else {
                  // Hiển thị danh sách phòng
                  
                  // Áp dụng thuật toán phân phối promoted rooms
                  final List<Room> distributedRooms = distributePromotedRooms(state.rooms);
                  
                  return Stack(
                    children: [
                      Column(
                        children: [
                          Expanded(
                            child: GridView.builder(
                              controller: _scrollController,
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16, 
                                vertical: 16,
                              ),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 8,
                                crossAxisSpacing: 8,
                                childAspectRatio: 0.6,
                              ),
                              itemCount: distributedRooms.length,
                              itemBuilder: (context, index) {                            
                                final room = distributedRooms[index];
                                
                                return _buildRoomCard(room, context);
                              },
                            ),
                          ),
                          
                          // Hiển thị footer loading khi đang tải thêm
                          if (state.status == RoomFilterStatus.loadingMore)
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              // Avoid overflow by constraining height
                              height: 60,
                              alignment: Alignment.center,
                              child: _buildLoadingMoreFooter(),
                            ),
                        ],
                      ),
                      
                      // Hiển thị loading indicator overlay khi đang tải (nhưng không phải tải thêm)
                      if (state.status == RoomFilterStatus.loading && state.rooms.isNotEmpty)
                        const Positioned.fill(
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                    ],
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tạo filter chip
  Widget _buildFilterChip(String label, VoidCallback onRemove, {bool isRemoveAll = false}) {
    // Sử dụng màu chủ đạo Indigo 500 (0xFF3F51B5) giống trong FilterBottomSheet
    final primaryColor = const Color(0xFF3F51B5);
    // Sử dụng màu accent Deep Orange 500 (0xFFFF5722) cho nút xóa tất cả
    final accentColor = const Color(0xFFFF5722);
    
    // Tạo key duy nhất cho mỗi chip dựa trên label
    final chipKey = ValueKey('filter_chip_${label.hashCode}');
    
    return Padding(
      key: chipKey,
      padding: const EdgeInsets.only(right: 8.0, bottom: 8.0),
      child: Chip(
        label: Text(
          label,
          style: TextStyle(
            color: isRemoveAll ? accentColor : primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        deleteIcon: Icon(
          isRemoveAll ? Icons.clear_all : Icons.clear,
          size: 18,
        ),
        onDeleted: () {
          debugPrint('Filter chip deleted: $label');
          onRemove();
        },
        backgroundColor: isRemoveAll ? accentColor.withOpacity(0.1) : primaryColor.withOpacity(0.1),
        deleteIconColor: isRemoveAll ? accentColor : primaryColor,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isRemoveAll ? accentColor.withOpacity(0.3) : primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
      ),
    );
  }

  // Kiểm tra xem có filter nào đang được áp dụng không
  bool _hasActiveFilters() {
    return _currentFilter.isActive;
  }


  // Helper method để chuyển đổi RoomType sang text hiển thị
  String _roomTypeToDisplayText(api_room_type.RoomType? type) {
    if (type == null || type == api_room_type.RoomType.ALL) return 'Tất cả';
    
    switch (type) {
      case api_room_type.RoomType.ROOM:
        return 'Phòng trọ';
      case api_room_type.RoomType.APARTMENT:
        return 'Chung cư';
      default:
        return type.toString().split('.').last;
    }
  }

  // Định dạng giá tiền để hiển thị (vd: 1,000,000)
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
  }

  // Lấy tên tiện ích từ tagId
  String _getAmenityName(String tagId) {
    // Sử dụng TagService để lấy tên tiện ích từ ID
    final tagService = GetIt.instance<TagService>();
    final tag = tagService.getTagById(tagId);
    
    // Nếu tìm thấy tag, trả về tên của nó, ngược lại trả về ID
    return tag?.displayName ?? tagId;
  }

  // Phương thức mới: Áp dụng bộ lọc và tải lại dữ liệu
  void _applyFilterAndReload(RoomFilter newFilter) {
    // Debug print để theo dõi filter trước khi thay đổi
    debugPrint('Before filter change: $_currentFilter');
    
    // Xử lý mối quan hệ phụ thuộc
    // Nếu city được đặt về null, hãy đảm bảo district và ward cũng null
    if (newFilter.city == null && _currentFilter.city != null) {
      debugPrint('City is null, setting district and ward to null');
      newFilter = RoomFilter(
        city: null,
        district: null,
        ward: null,
        type: newFilter.type,
        minPrice: newFilter.minPrice,
        maxPrice: newFilter.maxPrice,
        minPeople: newFilter.minPeople,
        maxPeople: newFilter.maxPeople,
        limit: defaultLimit, // Use the constant
        tagIds: newFilter.tagIds,
        hasFindPartnerPost: newFilter.hasFindPartnerPost,
      );
    }
    
    // Nếu district được đặt về null, hãy đảm bảo ward cũng null
    if (newFilter.district == null && _currentFilter.district != null) {
      debugPrint('District is null, setting ward to null');
      newFilter = RoomFilter(
        city: newFilter.city,
        district: null,
        ward: null,
        type: newFilter.type,
        minPrice: newFilter.minPrice,
        maxPrice: newFilter.maxPrice,
        minPeople: newFilter.minPeople,
        maxPeople: newFilter.maxPeople,
        limit: defaultLimit, // Use the constant
        tagIds: newFilter.tagIds,
        hasFindPartnerPost: newFilter.hasFindPartnerPost,
      );
    }
    
    // Ensure limit is always set to defaultLimit
    if (newFilter.limit != defaultLimit) {
      debugPrint('Setting limit to defaultLimit: $defaultLimit');
      newFilter = RoomFilter(
        city: newFilter.city,
        district: newFilter.district,
        ward: newFilter.ward,
        type: newFilter.type,
        minPrice: newFilter.minPrice,
        maxPrice: newFilter.maxPrice,
        minPeople: newFilter.minPeople,
        maxPeople: newFilter.maxPeople,
        limit: defaultLimit,
        tagIds: newFilter.tagIds,
        hasFindPartnerPost: newFilter.hasFindPartnerPost,
      );
    }
    
    // Chuẩn hóa filter trước khi áp dụng
    final normalizedFilter = newFilter.normalize();
    
    // Debug print để theo dõi filter sau khi chuẩn hóa
    debugPrint('After normalization: $normalizedFilter');
    
    // Luôn cập nhật UI và tải lại dữ liệu khi filter thay đổi
    setState(() {
      _currentFilter = normalizedFilter;
      debugPrint('Updated _currentFilter in setState: $_currentFilter');
    });
    
    // Tải lại danh sách phòng với filter mới
    _roomFilterCubit.loadRooms(customFilter: normalizedFilter);
    debugPrint('Called loadRooms with filter: $normalizedFilter');
  }

  List<Widget> _buildFilterChips() {
    List<Widget> chips = [];

    if (_currentFilter.city != null && _currentFilter.city!.isNotEmpty) {
      chips.add(_buildFilterChip('Thành phố: ${_currentFilter.city}', () {
        // Debug print khi chip city được click
        debugPrint('City chip clicked! Current city: ${_currentFilter.city}');
        
        // Create a completely new filter instead of using copyWith
        final newFilter = RoomFilter(
          city: null,
          district: null,
          ward: null,
          type: _currentFilter.type,
          minPrice: _currentFilter.minPrice,
          maxPrice: _currentFilter.maxPrice,
          minPeople: _currentFilter.minPeople,
          maxPeople: _currentFilter.maxPeople,
          limit: defaultLimit, // Use the constant
          tagIds: _currentFilter.tagIds,
          hasFindPartnerPost: _currentFilter.hasFindPartnerPost,
        );
        
        debugPrint('Created new filter with null city: $newFilter');
        _applyFilterAndReload(newFilter);
        
        // Debug print sau khi áp dụng filter mới
        debugPrint('After applying filter - city: ${_currentFilter.city}, district: ${_currentFilter.district}, ward: ${_currentFilter.ward}');
      }));
    }

    if (_currentFilter.district != null && _currentFilter.district!.isNotEmpty) {
      chips.add(_buildFilterChip('Quận: ${_currentFilter.district}', () {
        // Debug print khi chip district được click
        debugPrint('District chip clicked! Current district: ${_currentFilter.district}');
        
        // Create a completely new filter instead of using copyWith
        final newFilter = RoomFilter(
          city: _currentFilter.city,
          district: null,
          ward: null,
          type: _currentFilter.type,
          minPrice: _currentFilter.minPrice,
          maxPrice: _currentFilter.maxPrice,
          minPeople: _currentFilter.minPeople,
          maxPeople: _currentFilter.maxPeople,
          limit: defaultLimit, // Use the constant
          tagIds: _currentFilter.tagIds,
          hasFindPartnerPost: _currentFilter.hasFindPartnerPost,
        );
        
        debugPrint('Created new filter with null district: $newFilter');
        _applyFilterAndReload(newFilter);
        
        // Debug print sau khi áp dụng filter mới
        debugPrint('After applying filter - city: ${_currentFilter.city}, district: ${_currentFilter.district}, ward: ${_currentFilter.ward}');
      }));
    }

    if (_currentFilter.ward != null && _currentFilter.ward!.isNotEmpty) {
      chips.add(_buildFilterChip('Phường: ${_currentFilter.ward}', () {
        // Debug print khi chip ward được click
        debugPrint('Ward chip clicked! Current ward: ${_currentFilter.ward}');
        
        // Create a completely new filter instead of using copyWith
        final newFilter = RoomFilter(
          city: _currentFilter.city,
          district: _currentFilter.district,
          ward: null,
          type: _currentFilter.type,
          minPrice: _currentFilter.minPrice,
          maxPrice: _currentFilter.maxPrice,
          minPeople: _currentFilter.minPeople,
          maxPeople: _currentFilter.maxPeople,
          limit: defaultLimit, // Use the constant
          tagIds: _currentFilter.tagIds,
          hasFindPartnerPost: _currentFilter.hasFindPartnerPost,
        );
        
        debugPrint('Created new filter with null ward: $newFilter');
        _applyFilterAndReload(newFilter);
        
        // Debug print sau khi áp dụng filter mới
        debugPrint('After applying filter - city: ${_currentFilter.city}, district: ${_currentFilter.district}, ward: ${_currentFilter.ward}');
      }));
    }

    // Chỉ hiển thị chip loại phòng nếu không phải ALL
    if (_currentFilter.type != null && _currentFilter.type != api_room_type.RoomType.ALL) {
      chips.add(_buildFilterChip('Loại: ${_roomTypeToDisplayText(_currentFilter.type)}', () {
        // Debug print khi chip type được click
        debugPrint('Type chip clicked! Current type: ${_currentFilter.type}');
        
        // Create a completely new filter instead of using copyWith
        final newFilter = RoomFilter(
          city: _currentFilter.city,
          district: _currentFilter.district,
          ward: _currentFilter.ward,
          type: api_room_type.RoomType.ALL,
          minPrice: _currentFilter.minPrice,
          maxPrice: _currentFilter.maxPrice,
          minPeople: _currentFilter.minPeople,
          maxPeople: _currentFilter.maxPeople,
          limit: defaultLimit, // Use the constant
          tagIds: _currentFilter.tagIds,
          hasFindPartnerPost: _currentFilter.hasFindPartnerPost,
        );
        
        debugPrint('Created new filter with ALL type: $newFilter');
        _applyFilterAndReload(newFilter);
        
        // Debug print sau khi áp dụng filter mới
        debugPrint('After applying filter - type: ${_currentFilter.type}');
      }));
    }

    if (_currentFilter.minPrice != null) {
      chips.add(_buildFilterChip('Giá từ: ${_formatPrice(_currentFilter.minPrice!)}đ', () {
        // Debug print khi chip minPrice được click
        debugPrint('MinPrice chip clicked! Current minPrice: ${_currentFilter.minPrice}');
        
        // Create a completely new filter instead of using copyWith
        final newFilter = RoomFilter(
          city: _currentFilter.city,
          district: _currentFilter.district,
          ward: _currentFilter.ward,
          type: _currentFilter.type,
          minPrice: null,
          maxPrice: _currentFilter.maxPrice,
          minPeople: _currentFilter.minPeople,
          maxPeople: _currentFilter.maxPeople,
          limit: defaultLimit, // Use the constant
          tagIds: _currentFilter.tagIds,
          hasFindPartnerPost: _currentFilter.hasFindPartnerPost,
        );
        
        debugPrint('Created new filter with null minPrice: $newFilter');
        _applyFilterAndReload(newFilter);
        
        // Debug print sau khi áp dụng filter mới
        debugPrint('After applying filter - minPrice: ${_currentFilter.minPrice}');
      }));
    }

    if (_currentFilter.maxPrice != null) {
      chips.add(_buildFilterChip('Giá đến: ${_formatPrice(_currentFilter.maxPrice!)}đ', () {
        // Debug print khi chip maxPrice được click
        debugPrint('MaxPrice chip clicked! Current maxPrice: ${_currentFilter.maxPrice}');
        
        // Create a completely new filter instead of using copyWith
        final newFilter = RoomFilter(
          city: _currentFilter.city,
          district: _currentFilter.district,
          ward: _currentFilter.ward,
          type: _currentFilter.type,
          minPrice: _currentFilter.minPrice,
          maxPrice: null,
          minPeople: _currentFilter.minPeople,
          maxPeople: _currentFilter.maxPeople,
          limit: defaultLimit, // Use the constant
          tagIds: _currentFilter.tagIds,
          hasFindPartnerPost: _currentFilter.hasFindPartnerPost,
        );
        
        debugPrint('Created new filter with null maxPrice: $newFilter');
        _applyFilterAndReload(newFilter);
        
        // Debug print sau khi áp dụng filter mới
        debugPrint('After applying filter - maxPrice: ${_currentFilter.maxPrice}');
      }));
    }

    if (_currentFilter.minPeople != null) {
      chips.add(_buildFilterChip('Số người tối thiểu: ${_currentFilter.minPeople}', () {
        // Debug print khi chip minPeople được click
        debugPrint('MinPeople chip clicked! Current minPeople: ${_currentFilter.minPeople}');
        
        // Create a completely new filter instead of using copyWith
        final newFilter = RoomFilter(
          city: _currentFilter.city,
          district: _currentFilter.district,
          ward: _currentFilter.ward,
          type: _currentFilter.type,
          minPrice: _currentFilter.minPrice,
          maxPrice: _currentFilter.maxPrice,
          minPeople: null,
          maxPeople: _currentFilter.maxPeople,
          limit: defaultLimit, // Use the constant
          tagIds: _currentFilter.tagIds,
          hasFindPartnerPost: _currentFilter.hasFindPartnerPost,
        );
        
        debugPrint('Created new filter with null minPeople: $newFilter');
        _applyFilterAndReload(newFilter);
        
        // Debug print sau khi áp dụng filter mới
        debugPrint('After applying filter - minPeople: ${_currentFilter.minPeople}');
      }));
    }

    if (_currentFilter.maxPeople != null) {
      chips.add(_buildFilterChip('Số người tối đa: ${_currentFilter.maxPeople}', () {
        // Debug print khi chip maxPeople được click
        debugPrint('MaxPeople chip clicked! Current maxPeople: ${_currentFilter.maxPeople}');
        
        // Create a completely new filter instead of using copyWith
        final newFilter = RoomFilter(
          city: _currentFilter.city,
          district: _currentFilter.district,
          ward: _currentFilter.ward,
          type: _currentFilter.type,
          minPrice: _currentFilter.minPrice,
          maxPrice: _currentFilter.maxPrice,
          minPeople: _currentFilter.minPeople,
          maxPeople: null,
          limit: defaultLimit, // Use the constant
          tagIds: _currentFilter.tagIds,
          hasFindPartnerPost: _currentFilter.hasFindPartnerPost,
        );
        
        debugPrint('Created new filter with null maxPeople: $newFilter');
        _applyFilterAndReload(newFilter);
        
        // Debug print sau khi áp dụng filter mới
        debugPrint('After applying filter - maxPeople: ${_currentFilter.maxPeople}');
      }));
    }

    // Add filter chip for hasFindPartnerPost
    if (_currentFilter.hasFindPartnerPost == true) {
      chips.add(_buildFilterChip('Tìm người ở ghép', () {
        // Debug print when hasFindPartnerPost chip is clicked
        debugPrint('hasFindPartnerPost chip clicked! Current value: ${_currentFilter.hasFindPartnerPost}');
        
        // Create a completely new filter instead of using copyWith
        final newFilter = RoomFilter(
          city: _currentFilter.city,
          district: _currentFilter.district,
          ward: _currentFilter.ward,
          type: _currentFilter.type,
          minPrice: _currentFilter.minPrice,
          maxPrice: _currentFilter.maxPrice,
          minPeople: _currentFilter.minPeople,
          maxPeople: _currentFilter.maxPeople,
          limit: defaultLimit, // Use the constant
          tagIds: _currentFilter.tagIds,
          hasFindPartnerPost: null, // Reset to null to disable this filter
        );
        
        debugPrint('Created new filter with null hasFindPartnerPost: $newFilter');
        _applyFilterAndReload(newFilter);
        
        // Debug print after applying new filter
        debugPrint('After applying filter - hasFindPartnerPost: ${_currentFilter.hasFindPartnerPost}');
      }));
    }

    if (_currentFilter.tagIds != null && _currentFilter.tagIds!.isNotEmpty) {
      for (var tagId in _currentFilter.tagIds!) {
        chips.add(_buildFilterChip('Tiện ích: ${_getAmenityName(tagId)}', () {
          // Debug print khi chip tagId được click
          debugPrint('TagId chip clicked! Current tagId: $tagId');
          
          // Create a new list without the removed tag
          final List<String> newTagIds = List.from(_currentFilter.tagIds!);
          newTagIds.remove(tagId);
          
          // Create a completely new filter instead of using copyWith
          final newFilter = RoomFilter(
            city: _currentFilter.city,
            district: _currentFilter.district,
            ward: _currentFilter.ward,
            type: _currentFilter.type,
            minPrice: _currentFilter.minPrice,
            maxPrice: _currentFilter.maxPrice,
            minPeople: _currentFilter.minPeople,
            maxPeople: _currentFilter.maxPeople,
            limit: defaultLimit, // Use the constant
            tagIds: newTagIds.isEmpty ? null : newTagIds,
            hasFindPartnerPost: _currentFilter.hasFindPartnerPost,
          );
          
          debugPrint('Created new filter with updated tagIds: $newFilter');
          _applyFilterAndReload(newFilter);
          
          // Debug print sau khi áp dụng filter mới
          debugPrint('After applying filter - tagIds: ${_currentFilter.tagIds}');
        }));
      }
    }

    if (_hasActiveFilters()) {
      chips.add(_buildFilterChip('Xóa tất cả', () {
        // Debug print khi chip xóa tất cả được click
        debugPrint('Clear all chip clicked!');
        
        // Sử dụng phương thức static từ extension
        final emptyFilter = RoomFilterExtension.empty();
        debugPrint('Created empty filter: $emptyFilter');
        
        _applyFilterAndReload(emptyFilter);
        
        // Debug print sau khi áp dụng filter mới
        debugPrint('After applying empty filter - city: ${_currentFilter.city}, district: ${_currentFilter.district}, ward: ${_currentFilter.ward}');
      }, isRemoveAll: true));
    }

    return chips;
  }

  // Tải dữ liệu tiện ích
  Future<void> _loadAmenities() async {
    try {
      final tagService = GetIt.instance<TagService>();
      await tagService.getAllTags();
    } catch (e) {
      debugPrint('Error loading amenities: $e');
    }
  }

  // Hiển thị footer loading khi tải thêm dữ liệu
  Widget _buildLoadingMoreFooter() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Đang tải thêm phòng...',
          style: TextStyle(
            fontSize: 13,
            color: Theme.of(context).primaryColor,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
          ),
        ),
      ],
    );
  }

  // Thêm phương thức getter trực tiếp trong FutureBuilder
  Widget _buildRoomCard(Room room, BuildContext context) {
    if (room.id == null) {
      return const ShimmerRoomCard();
    }
    
    return FutureBuilder<List<RoomImage>>(
      future: _getRoomImages(room.id!),
      builder: (context, snapshot) {
        // Thêm xử lý khi đang loading
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const ShimmerRoomCard();
        }
        
        // Thêm xử lý khi có lỗi
        if (snapshot.hasError) {
          debugPrint('❌ Error loading images in FutureBuilder: ${snapshot.error}');
          
          // Vẫn hiển thị RoomCard nhưng không có ảnh
          final roomCardData = _createRoomCardData(room, []);
          return RoomCard(
            imageUrl: '',
            roomName: roomCardData.name,
            price: roomCardData.price,
            address: roomCardData.address,
            squareMeters: roomCardData.squareMeters,
            onTap: () => _handleRoomTap(context, roomCardData),
          );
        }
        
        // Lấy dữ liệu ảnh
        final images = snapshot.data ?? [];
        debugPrint('🖼️ FutureBuilder có ${images.length} ảnh cho room ${room.id}');
        
        // Tạo room card data
        final roomCardData = _createRoomCardData(room, images);
        
        // Kiểm tra nếu là promoted room, wrap với VisibilityDetector
        if (roomCardData is PromotedRoomCardData && roomCardData.promotedRoomId != null) {
          final String safePromotedRoomId = roomCardData.promotedRoomId!;
          return VisibilityDetector(
            key: Key('promoted_room_$safePromotedRoomId'),
            onVisibilityChanged: (visibilityInfo) {
              _handleRoomVisibilityChanged(roomCardData, visibilityInfo.visibleFraction);
            },
            child: RoomCard(
              imageUrl: roomCardData.imageUrl,
              isPromoted: safePromotedRoomId == _recommendationCubit.getPromotedRoomId(room.id ?? ''),
              roomName: roomCardData.name,
              price: roomCardData.price,
              address: roomCardData.address,
              squareMeters: roomCardData.squareMeters,
              onTap: () => _handleRoomTap(context, roomCardData),
            ),
          );
        }
        
        // Nếu không phải promoted room, hiển thị RoomCard bình thường
        return RoomCard(
          imageUrl: roomCardData.imageUrl,
          roomName: roomCardData.name,
          price: roomCardData.price,
          address: roomCardData.address,
          squareMeters: roomCardData.squareMeters,
          onTap: () => _handleRoomTap(context, roomCardData),
        );
      },
    );
  }

  // Phương thức phân phối promoted rooms đan xen vào danh sách
  List<Room> distributePromotedRooms(List<Room> allRooms) {
    // Tách danh sách thành promoted và non-promoted
    final List<Room> promotedRooms = [];
    final List<Room> normalRooms = [];
    final Map<String, double> roomScores = {}; // Lưu score cho từng room
    
    // Duyệt qua danh sách để phân loại phòng
    for (var room in allRooms) {
      final String? promotedRoomId = _recommendationCubit.getPromotedRoomId(room.id ?? '');
      if (promotedRoomId != null) {
        // Lấy score thực từ RecommendationCubit
        final score = _recommendationCubit.getPromotedRoomScore(room.id ?? '');
        roomScores[room.id ?? ''] = score;
        promotedRooms.add(room);
      } else {  
        normalRooms.add(room);
      }
    }
    
    // Sắp xếp promoted rooms theo score giảm dần
    promotedRooms.sort((a, b) {
      final scoreA = roomScores[a.id] ?? 0.0;
      final scoreB = roomScores[b.id] ?? 0.0;
      return scoreB.compareTo(scoreA);
    });
    
    // Phân bố promoted rooms vào các vị trí dựa trên score
    final result = List<Room>.from(normalRooms);
    
    // Xác định số lượng phòng thường giữa các promoted room
    final int spacing = math.max(1, normalRooms.length ~/ (promotedRooms.length + 1));
    
    // Chèn các promoted room vào kết quả
    for (int i = 0; i < promotedRooms.length; i++) {
      // Vị trí chèn dựa trên score - phòng có score cao hơn sẽ xuất hiện sớm hơn
      // Nhưng vẫn đảm bảo không liên tục
      int insertPosition = math.min(i * (spacing + 1), result.length);
      
      // Thêm một yếu tố ngẫu nhiên nhỏ trong phạm vi được cho phép
      if (insertPosition > 0 && insertPosition < result.length && spacing > 1) {
        // Tạo độ dao động ngẫu nhiên nhỏ xung quanh vị trí dự kiến
        final randomOffset = math.Random().nextInt(math.min(3, spacing)) - 1;
        insertPosition = math.max(0, math.min(result.length, insertPosition + randomOffset));
      }
      
      // Chèn promoted room vào vị trí đã tính
      result.insert(insertPosition, promotedRooms[i]);
    }
    
    // Debug để kiểm tra
    debugPrint('💡 Distributed ${promotedRooms.length} promoted rooms into ${result.length} total rooms');
    for (int i = 0; i < result.length; i++) {
      final room = result[i];
      final isPromoted = _recommendationCubit.getPromotedRoomId(room.id ?? '') != null;
      if (isPromoted) {
        debugPrint('  📍 Position $i: Promoted Room ${room.id} (Score: ${roomScores[room.id] ?? 'N/A'})');
      }
    }
    
    return result;
  }
} 