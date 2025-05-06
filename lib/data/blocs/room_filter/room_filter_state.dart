import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/models.dart';

// Enum định nghĩa các trạng thái có thể có của RoomFilterState
enum RoomFilterStatus {
  initial, // Trạng thái ban đầu
  loading, // Đang tải dữ liệu
  loaded, // Đã tải xong dữ liệu
  loadingMore, // Đang tải thêm dữ liệu (pagination)
  error, // Có lỗi xảy ra
  empty, // Không có kết quả nào
}

class RoomFilterState extends Equatable {
  final RoomFilterStatus status;
  final List<Room> rooms;
  final RoomFilter filter;
  final String? errorMessage;
  final bool hasReachedMax;

  const RoomFilterState({
    this.status = RoomFilterStatus.initial,
    this.rooms = const <Room>[],
    required this.filter,
    this.errorMessage,
    this.hasReachedMax = false,
  });

  // Trạng thái ban đầu của RoomFilterState
  factory RoomFilterState.initial() {
    return RoomFilterState(
      filter: RoomFilter.defaultFilter(),
    );
  }

  RoomFilterState copyWith({
    RoomFilterStatus? status,
    List<Room>? rooms,
    RoomFilter? filter,
    String? errorMessage,
    bool? hasReachedMax,
  }) {
    return RoomFilterState(
      status: status ?? this.status,
      rooms: rooms ?? this.rooms,
      filter: filter ?? this.filter,
      errorMessage: errorMessage ?? this.errorMessage,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
    );
  }

  @override
  List<Object?> get props => [status, rooms, filter, errorMessage, hasReachedMax];
} 