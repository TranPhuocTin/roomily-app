import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/services/location_service.dart';
import 'package:roomily/core/services/search_service.dart';
import 'package:roomily/core/services/user_location_service.dart';

import 'map_state.dart';

class MapCubit extends Cubit<MapState> {
  final LocationService _locationService;
  final UserLocationService _userLocationService;

  MapCubit({
    required LocationService locationService,
    required UserLocationService userLocationService,
  })  : _locationService = locationService,
        _userLocationService = userLocationService,
        super(const MapState());

  /// Lấy vị trí hiện tại của người dùng
  Future<void> getCurrentLocation() async {
    // Nếu đang loading, không thực hiện lại
    if (state.status == MapStatus.loading) return;
    
    // Nếu đã có vị trí và map đã được khởi tạo, chỉ cần điều hướng đến vị trí hiện tại
    if (state.currentPosition != null && state.isMapInitialized) {
      emit(state.copyWith(status: MapStatus.loading));
      try {
        // Sử dụng vị trí từ UserLocationService nếu có
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          emit(state.copyWith(
            status: MapStatus.loaded,
            currentPosition: position,
            markerLatitude: position.latitude,
            markerLongitude: position.longitude,
          ));
        } else {
          // Nếu không lấy được vị trí mới, giữ nguyên vị trí cũ
          emit(state.copyWith(
            status: MapStatus.loaded,
          ));
        }
      } catch (e) {
        // Nếu có lỗi, giữ nguyên vị trí cũ
        emit(state.copyWith(
          status: MapStatus.loaded,
        ));
      }
      return;
    }
    
    // Nếu chưa có vị trí hoặc map chưa được khởi tạo, thực hiện load từ đầu
    emit(state.copyWith(status: MapStatus.loading));

    try {
      // Ưu tiên sử dụng vị trí từ UserLocationService
      final position = await _locationService.getCurrentPosition();
      
      if (position != null) {
        emit(state.copyWith(
          status: MapStatus.loaded,
          currentPosition: position,
          markerLatitude: position.latitude,
          markerLongitude: position.longitude,
        ));
      } else {
        emit(state.copyWith(
          status: MapStatus.error,
          errorMessage: 'Không thể lấy vị trí hiện tại',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: MapStatus.error,
        errorMessage: 'Lỗi: $e',
      ));
    }
  }

  /// Đánh dấu map đã được khởi tạo
  void setMapInitialized() {
    emit(state.copyWith(isMapInitialized: true));
  }

  /// Lưu trạng thái camera của map
  void saveMapCameraState({double? zoom, double? bearing, double? pitch, bool? is3DMode}) {
    emit(state.copyWith(
      lastZoom: zoom,
      lastBearing: bearing,
      lastPitch: pitch,
      is3DMode: is3DMode,
    ));
  }
  
  /// Lưu kết quả tìm kiếm
  void saveSearchResults(List<SearchResult> results, {bool isSearching = false}) {
    emit(state.copyWith(
      searchResults: results,
      isSearching: isSearching,
    ));
  }
  
  /// Đặt trạng thái đang tìm kiếm
  void setSearching(bool isSearching) {
    emit(state.copyWith(isSearching: isSearching));
  }
  
  /// Lưu địa điểm đã chọn
  void saveSelectedLocation(SearchResult location) {
    emit(state.copyWith(
      selectedLocation: location,
      markerLatitude: location.latitude,
      markerLongitude: location.longitude,
    ));
  }
  
  /// Lưu vị trí marker
  void saveMarkerPosition(double latitude, double longitude) {
    emit(state.copyWith(
      markerLatitude: latitude,
      markerLongitude: longitude,
    ));
  }
  
  /// Đặt chế độ 3D
  void set3DMode(bool is3DMode) {
    emit(state.copyWith(is3DMode: is3DMode));
  }
  
  /// Xóa kết quả tìm kiếm
  void clearSearchResults() {
    emit(state.copyWith(
      searchResults: [],
      isSearching: false,
    ));
  }
  
  /// Đặt style map
  void setMapStyle(String styleUri) {
    emit(state.copyWith(
      mapStyle: styleUri,
      isSatelliteMode: styleUri.contains('satellite'),
    ));
  }
  
  /// Chuyển đổi giữa chế độ bản đồ thường và vệ tinh
  void toggleSatelliteMode(bool isSatellite) {
    emit(state.copyWith(isSatelliteMode: isSatellite));
  }
} 