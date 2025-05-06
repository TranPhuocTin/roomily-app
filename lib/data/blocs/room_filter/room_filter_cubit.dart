import 'package:bloc/bloc.dart';
import 'package:roomily/data/blocs/room_filter/room_filter_state.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:get_it/get_it.dart';

class RoomFilterCubit extends Cubit<RoomFilterState> {
  final RoomRepository _roomRepository;

  RoomFilterCubit() : 
    _roomRepository = GetIt.instance<RoomRepository>(),
    super(RoomFilterState.initial()) {
    print('RoomFilterCubit initialized');
    print('Repository instance: $_roomRepository');
    print('GetIt has RoomRepository: ${GetIt.instance.isRegistered<RoomRepository>()}');
  }

  // Tải phòng với filter mặc định hoặc filter được chỉ định
  Future<void> loadRooms({RoomFilter? customFilter}) async {
    try {
      // Sử dụng filter tùy chỉnh nếu được cung cấp, nếu không sử dụng filter mặc định
      final filter = customFilter ?? RoomFilter.defaultFilter();
      print('Loading rooms with filter: ${filter.toJson()}');
      
      // Emit trạng thái loading
      emit(state.copyWith(
        status: RoomFilterStatus.loading,
        filter: filter,
        rooms: [], // Reset danh sách phòng khi tải mới
        hasReachedMax: false, // Reset hasReachedMax
        errorMessage: null, // Reset lỗi
      ));
      print('Emitted loading state');

      // Gọi repository để lấy dữ liệu
      print('Calling repository.getRoomsWithFilter');
      final result = await _roomRepository.getRoomsWithFilter(filter);
      print('Repository returned result: $result');
      
      switch (result) {
        case Success(data: final rooms):
          print('Success with ${rooms.length} rooms');
          if (rooms.isEmpty) {
            print('No rooms found, emitting empty state');
            print('Filter details: City=${filter.city}, District=${filter.district}, Type=${filter.type}');
            emit(state.copyWith(
              status: RoomFilterStatus.empty,
              rooms: rooms,
              filter: filter, // Đảm bảo filter được lưu lại
            ));
            print('RoomFilterCubit Change { currentState: ${state.toString()}, nextState: ${state.copyWith(status: RoomFilterStatus.empty, rooms: rooms, filter: filter).toString()} }');
          } else {
            print('Emitting loaded state with ${rooms.length} rooms');
            emit(state.copyWith(
              status: RoomFilterStatus.loaded,
              rooms: rooms,
              hasReachedMax: rooms.length < (filter.limit ?? 10),
            ));
          }
        case Failure(message: final message):
          print('Repository returned failure: $message');
          emit(state.copyWith(
            status: RoomFilterStatus.error,
            errorMessage: message,
          ));
      }
    } catch (e) {
      print('Error in loadRooms: $e');
      emit(state.copyWith(
        status: RoomFilterStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Tải thêm phòng (pagination)
  Future<void> loadMoreRooms() async {
    // Không làm gì nếu đã đạt đến giới hạn hoặc đang trong quá trình tải
    if (state.hasReachedMax || 
        state.status == RoomFilterStatus.loadingMore || 
        state.status == RoomFilterStatus.loading) {
      print('Skipping loadMoreRooms: hasReachedMax=$hasReachedMax, status=${state.status}');
      return;
    }

    try {
      // Emit trạng thái đang tải thêm
      emit(state.copyWith(
        status: RoomFilterStatus.loadingMore,
      ));
      print('Emitted loadingMore state');

      // Lấy phòng cuối cùng để làm pivot
      final lastRoom = state.rooms.isNotEmpty ? state.rooms.last : null;
      print('Last room: ${lastRoom?.id}');
      
      // Nếu không có phòng nào, không thể load thêm
      if (lastRoom == null) {
        print('No last room found, cannot load more');
        emit(state.copyWith(
          status: RoomFilterStatus.loaded,
          hasReachedMax: true,
        ));
        return;
      }

      // Tạo filter mới cho pagination dựa trên filter hiện tại và phòng cuối cùng
      final paginationFilter = RoomFilter.paginationFilter(
        pivotId: lastRoom.id ?? '',
        timestamp: lastRoom.updatedAt.toIso8601String(),
        city: state.filter.city,
        district: state.filter.district,
        ward: state.filter.ward,
        type: state.filter.type,
        minPrice: state.filter.minPrice,
        maxPrice: state.filter.maxPrice,
        minPeople: state.filter.minPeople,
        maxPeople: state.filter.maxPeople,
        limit: state.filter.limit,
        tagIds: state.filter.tagIds,
      );
      print('Created pagination filter: ${paginationFilter.toJson()}');

      // Gọi repository để lấy thêm dữ liệu
      print('Calling repository for more rooms');
      final result = await _roomRepository.getRoomsWithFilter(paginationFilter);
      print('Repository returned pagination result: $result');
      
      switch (result) {
        case Success(data: final moreRooms):
          print('Pagination success with ${moreRooms.length} more rooms');
          if (moreRooms.isEmpty) {
            print('No more rooms, setting hasReachedMax=true');
            emit(state.copyWith(
              status: RoomFilterStatus.loaded,
              hasReachedMax: true,
            ));
          } else {
            print('Adding ${moreRooms.length} more rooms to list');
            emit(state.copyWith(
              status: RoomFilterStatus.loaded,
              rooms: [...state.rooms, ...moreRooms],
              hasReachedMax: moreRooms.length < (paginationFilter.limit ?? 10),
            ));
          }
        case Failure(message: final message):
          print('Pagination failed: $message');
          emit(state.copyWith(
            status: RoomFilterStatus.error,
            errorMessage: message,
          ));
      }
    } catch (e) {
      print('Error in loadMoreRooms: $e');
      emit(state.copyWith(
        status: RoomFilterStatus.error,
        errorMessage: e.toString(),
      ));
    }
  }

  // Áp dụng filter mới và tải lại danh sách phòng
  Future<void> applyFilter(RoomFilter filter) async {
    print('Applying new filter: ${filter.toJson()}');
    await loadRooms(customFilter: filter);
  }

  bool get hasReachedMax => state.hasReachedMax;
} 