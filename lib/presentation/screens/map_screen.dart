// import 'package:flutter/material.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// import 'package:roomily/core/services/location_service.dart';
// import 'package:roomily/core/services/search_service.dart';
// import 'package:roomily/core/services/user_location_service.dart';
// import 'package:get_it/get_it.dart';
// import 'dart:typed_data';
// import 'dart:ui';
// import 'package:flutter/services.dart';
// import 'package:roomily/presentation/widgets/home/header_widget.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:roomily/blocs/map/map_cubit.dart';
// import 'package:roomily/blocs/map/map_state.dart';
// import 'package:roomily/core/services/marker_service.dart';
// import 'package:geolocator/geolocator.dart' as geo;
// import 'package:flutter/rendering.dart' as ui;
// import 'package:roomily/presentation/screens/map_screen_v2.dart';

// class MapScreen extends StatefulWidget {
//   const MapScreen({super.key});

//   @override
//   State<MapScreen> createState() => _MapScreenState();
// }

// class _MapScreenState extends State<MapScreen> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
//   final LocationService _locationService = GetIt.instance<LocationService>();
//   final UserLocationService _userLocationService = GetIt.instance<UserLocationService>();
//   final SearchService _searchService = GetIt.instance<SearchService>();
//   final MarkerService _markerService = GetIt.instance<MarkerService>();
  
//   bool _isLoading = false;
//   MapboxMap? _mapboxMap;
//   bool _isFirstLoad = true;
//   bool _is3DMode = false;
  
//   // Flag để theo dõi trạng thái lấy vị trí và khởi tạo map
//   bool _pendingLocationFlyTo = false;
//   double? _pendingLatitude;
//   double? _pendingLongitude;
  
//   // Camera state - sẽ được lưu vào Cubit
//   double _currentPitch = 0.0;
//   double _currentBearing = 0.0;
  
//   // Map style state
//   String _currentStyle = MapboxStyles.MAPBOX_STREETS;
//   bool _isSatelliteMode = false;
  
//   // Search state - sẽ được lưu vào Cubit
//   final TextEditingController _searchController = TextEditingController();
//   final FocusNode _searchFocusNode = FocusNode();
//   List<SearchResult> _searchResults = [];
//   bool _isSearching = false;
//   bool _showSearchResults = false;

//   // Structured search state
//   String? _houseNumber;
//   String? _street;
//   String? _neighborhood;
//   String? _district;
//   String? _place;
//   String? _region;
  
//   // State for selected room marker
//   RoomMarker? _selectedRoomMarker;
//   bool _showRoomInfo = false;

//   @override
//   void initState() {
//     super.initState();
    
//     // Đăng ký observer để biết khi app chuyển trạng thái
//     WidgetsBinding.instance.addObserver(this);
    
//     // Hiển thị loading indicator ngay khi màn hình được tạo
//     setState(() {
//       _isLoading = true;
//     });
    
//     // Khởi tạo từ Cubit
//     _initializeFromCubit();
    
//     _searchFocusNode.addListener(() {
//       setState(() {
//         _showSearchResults = _searchFocusNode.hasFocus && _searchResults.isNotEmpty;
//       });
//     });
    
//     // Lấy vị trí hiện tại ngay khi màn hình được tạo
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       // Lấy vị trí ngay lập tức
//       _getCurrentLocationDirectly();
//     });
//   }
  
//   @override
//   void didChangeAppLifecycleState(AppLifecycleState state) {
//     // Khi app quay lại foreground, cập nhật vị trí
//     if (state == AppLifecycleState.resumed) {
//       _getCurrentLocationDirectly();
//     }
//   }
  
//   // Khởi tạo từ trạng thái đã lưu trong Cubit
//   void _initializeFromCubit() {
//     final mapState = context.read<MapCubit>().state;
    
//     // Khôi phục trạng thái camera
//     _currentPitch = mapState.lastPitch ?? 0.0;
//     _currentBearing = mapState.lastBearing ?? 0.0;
    
//     // Khôi phục trạng thái style map
//     _currentStyle = mapState.mapStyle ?? MapboxStyles.MAPBOX_STREETS;
//     _isSatelliteMode = mapState.isSatelliteMode;
    
//     // Khôi phục kết quả tìm kiếm
//     _searchResults = mapState.searchResults;
//     _isSearching = mapState.isSearching;
    
//     // Đánh dấu map đã được khởi tạo nếu cần
//     if (!mapState.isMapInitialized) {
//       context.read<MapCubit>().setMapInitialized();
//       _isFirstLoad = true; // Đảm bảo hiệu ứng zoom từ xa khi mở lần đầu
//     } else {
//       _isFirstLoad = false;
//     }
//   }
  
//   // Lấy vị trí hiện tại trực tiếp, không phụ thuộc vào trạng thái
//   Future<void> _getCurrentLocationDirectly() async {
//     if (!mounted) return;
    
//     setState(() {
//       _isLoading = true;
//     });
    
//     try {
//       // Ưu tiên sử dụng vị trí từ UserLocationService nếu có
//       geo.Position? geoPosition;
//       double? latitude, longitude;
      
//       // Kiểm tra xem UserLocationService đã được khởi tạo chưa
//       if (_userLocationService.isInitialized && _userLocationService.currentAddress != null) {
//         // Lấy vị trí từ UserLocationService
//         final address = _userLocationService.currentAddress!;
//         if (address.latitude != null && address.longitude != null) {
//           latitude = address.latitude;
//           longitude = address.longitude;
//         }
//       }
      
//       // Nếu không có vị trí từ UserLocationService, lấy vị trí mới
//       if (latitude == null || longitude == null) {
//         geoPosition = await _locationService.getCurrentPosition();
//         if (geoPosition != null) {
//           latitude = geoPosition.latitude;
//           longitude = geoPosition.longitude;
//         }
//       }
      
//       if (latitude != null && longitude != null && mounted) {
//         // Lưu vị trí vào Cubit
//         context.read<MapCubit>().saveMarkerPosition(latitude, longitude);
        
//         // Nếu map đã được tạo, di chuyển camera đến vị trí
//         if (_mapboxMap != null) {
//           // Sử dụng animation để di chuyển camera đến vị trí người dùng
//           _flyToUserLocation(latitude, longitude);
          
//           // Thêm marker - không cần đợi hoàn thành
//           _addMarkerAtPosition(latitude, longitude);
//         } else {
//           // Lưu lại vị trí để sử dụng khi map được khởi tạo
//           _pendingLocationFlyTo = true;
//           _pendingLatitude = latitude;
//           _pendingLongitude = longitude;
//         }
//       } else if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Không thể lấy vị trí hiện tại')),
//         );
//       }
//     } catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Lỗi khi lấy vị trí: $e')),
//       );
//     } finally {
//       if (mounted) {
//         setState(() {
//           _isLoading = false;
//         });
//       }
//     }
//   }

//   @override
//   void dispose() {
//     // Hủy đăng ký observer
//     WidgetsBinding.instance.removeObserver(this);
//     _searchController.dispose();
//     _searchFocusNode.dispose();
//     _markerService.dispose();
//     super.dispose();
//   }

//   // Hàm này được gọi khi MapWidget được tạo
//   void _onMapCreated(MapboxMap mapboxMap) async {
//     _mapboxMap = mapboxMap;

//     // Khởi tạo MarkerService
//     await _markerService.initialize(mapboxMap);
    
//     // Thiết lập callback khi click vào marker
//     _markerService.setOnRoomMarkerClickListener(_onRoomMarkerClick);
    
//     // Cấu hình vị trí của scale bar và compass
//     await _mapboxMap!.compass.updateSettings(
//       CompassSettings(
//         enabled: true,
//         position: OrnamentPosition.TOP_RIGHT,
//         marginTop: 140.0,
//         marginRight: 16.0,
//       ),
//     );
    
//     await _mapboxMap!.scaleBar.updateSettings(
//       ScaleBarSettings(
//         enabled: true,
//         position: OrnamentPosition.BOTTOM_LEFT,
//         marginLeft: 16.0,
//         marginBottom: 40.0,
//       ),
//     );

//     // Lấy trạng thái từ Cubit
//     final mapState = context.read<MapCubit>().state;
    
//     // Tải style từ Cubit nếu có
//     if (mapState.mapStyle != null && mapState.mapStyle != await _mapboxMap!.style.getStyleURI()) {
//       try {
//         await _mapboxMap!.loadStyleURI(mapState.mapStyle!);
//         _currentStyle = mapState.mapStyle!;
//         _isSatelliteMode = mapState.isSatelliteMode;
//       } catch (e) {
//         print('Không thể tải style map: $e');
//       }
//     }

//     // Đợi style được load hoàn toàn
//     await _mapboxMap!.style.getStyleURI();
        
//     try {
//       // Bật hiển thị tòa nhà 3D
//       await _mapboxMap!.style.setStyleLayerProperty(
//         "building",
//         "fill-extrusion-height",
//         {"value": ["get", "height"]}
//       );
//     } catch (e) {
//       print('Không thể cấu hình layer building 3D: $e');
//     }
    
//     // Hiển thị các room markers
//     await _updateMarkersWithCurrentZoom();
    
//     // Đánh dấu đã khởi tạo map
//     context.read<MapCubit>().setMapInitialized();
    
//     // ƯU TIÊN NHẤT: Nếu có yêu cầu chuyển vị trí đang chờ xử lý
//     if (_pendingLocationFlyTo && _pendingLatitude != null && _pendingLongitude != null) {
//       await _flyToUserLocation(_pendingLatitude!, _pendingLongitude!);
//       await _addMarkerAtPosition(_pendingLatitude!, _pendingLongitude!);
//       _pendingLocationFlyTo = false;
//     }
//     // Tiếp theo: Nếu có vị trí đã lưu trong cubit, di chuyển đến đó
//     else if (mapState.markerLatitude != null && mapState.markerLongitude != null) {
//       // Khôi phục trạng thái camera từ Cubit
//       if (mapState.lastPitch != null || mapState.lastBearing != null || mapState.lastZoom != null) {
//         await _restoreCameraState();
//       }
      
//       // Nếu map mới được load lần đầu, bay đến vị trí người dùng với animation
//       if (_isFirstLoad) {
//         await _flyToUserLocation(mapState.markerLatitude!, mapState.markerLongitude!);
//       } else {
//         // Khôi phục marker theo cách thông thường
//         await _restoreMarker();
//       }
//     } 
//     // Cuối cùng: Nếu không có gì cả, lấy vị trí hiện tại
//     else {
//       _getCurrentLocationDirectly();
//     }
//   }
  
//   // Callback khi click vào room marker
//   void _onRoomMarkerClick(RoomMarker roomMarker) {
//     setState(() {
//       _selectedRoomMarker = roomMarker;
//       _showRoomInfo = true;
//     });
//   }
  
//   // Đóng bottom sheet thông tin phòng
//   void _closeRoomInfo() {
//     setState(() {
//       _showRoomInfo = false;
//     });
//   }
  
//   // Cập nhật marker dựa trên zoom level hiện tại
//   Future<void> _updateMarkersWithCurrentZoom() async {
//     if (_mapboxMap == null) return;
    
//     try {
//       final cameraState = await _mapboxMap!.getCameraState();
//       final zoom = cameraState.zoom;
//       await _markerService.showRoomMarkers(zoom: zoom);
//     } catch (e) {
//       print('Lỗi khi cập nhật markers: $e');
//     }
//   }
  
//   // Khôi phục trạng thái camera từ Cubit
//   Future<void> _restoreCameraState() async {
//     if (_mapboxMap == null) return;
    
//     final mapState = context.read<MapCubit>().state;
//     final cameraState = await _mapboxMap!.getCameraState();
    
//     // Tạo CameraOptions từ state đã lưu
//     await _mapboxMap!.setCamera(
//       CameraOptions(
//         center: cameraState.center,
//         zoom: mapState.lastZoom ?? cameraState.zoom,
//         pitch: mapState.lastPitch ?? 0.0,
//         bearing: mapState.lastBearing ?? 0.0,
//       ),
//     );
    
//     // Cập nhật biến local
//     _currentPitch = mapState.lastPitch ?? 0.0;
//     _currentBearing = mapState.lastBearing ?? 0.0;
//     setState(() {
//       _is3DMode = mapState.is3DMode;
//     });
//   }
  
//   // Khôi phục marker từ Cubit
//   Future<void> _restoreMarker() async {
//     final mapState = context.read<MapCubit>().state;
    
//     if (mapState.markerLatitude != null && mapState.markerLongitude != null) {
//       await _addMarkerAtPosition(mapState.markerLatitude!, mapState.markerLongitude!);
//     } else if (mapState.currentPosition != null) {
//       await _addMarkerAtPosition(mapState.currentPosition!.latitude, mapState.currentPosition!.longitude);
//     }
//   }
  
//   // Cập nhật trạng thái camera hiện tại
//   Future<void> _updateCameraState() async {
//     if (_mapboxMap == null) return;
    
//     try {
//       CameraState cameraState = await _mapboxMap!.getCameraState();
//       _currentPitch = cameraState.pitch;
//       _currentBearing = cameraState.bearing;
      
//       bool is3DMode = _currentPitch > 0;
//       setState(() {
//         _is3DMode = is3DMode;
//       });
      
//       // Lưu vào Cubit
//       context.read<MapCubit>().saveMapCameraState(
//         zoom: cameraState.zoom,
//         bearing: _currentBearing,
//         pitch: _currentPitch,
//         is3DMode: is3DMode,
//       );
//     } catch (e) {
//       print('Lỗi khi cập nhật trạng thái camera: $e');
//     }
//   }

//   // Hàm này tạo hiệu ứng bay từ quả địa cầu đến vị trí người dùng
//   Future<void> _flyToUserLocation(double latitude, double longitude) async {
//     if (_mapboxMap == null || !mounted) return;
    
//     try {
//       // Đặt camera ở vị trí quả địa cầu (zoom thấp) nếu đây là lần đầu tiên
//       if (_isFirstLoad) {
//         // Đặt camera ở góc nhìn toàn cầu - giảm thời gian delay
//         await _mapboxMap!.setCamera(
//           CameraOptions(
//             center: Point(
//               coordinates: Position(longitude, latitude),
//             ),
//             zoom: 5.0, // Zoom cao hơn để animation nhanh hơn
//             pitch: 0.0,
//             bearing: 0.0,
//           ),
//         );
        
//         // Giảm thời gian delay
//         await Future.delayed(const Duration(milliseconds: 100));
//       }
      
//       // Sử dụng flyTo để tạo hiệu ứng bay đến vị trí - giảm thời gian animation
//       await _mapboxMap!.flyTo(
//         CameraOptions(
//           center: Point(
//             coordinates: Position(longitude, latitude),
//           ),
//           zoom: 14.0,
//           pitch: _currentPitch,
//           bearing: _currentBearing,
//         ),
//         MapAnimationOptions(
//           duration: 800, // Giảm thời gian animation để nhanh hơn
//           startDelay: 0,
//         ),
//       );
      
//       _isFirstLoad = false;

//       // Cập nhật markers sau khi bay đến vị trí mới
//       _updateMarkersWithCurrentZoom();
      
//       // Cập nhật trạng thái camera - không cần đợi
//       _updateCameraState();
//     } catch (e) {
//       print('Lỗi khi bay đến vị trí người dùng: $e');
//       // Fallback nếu animation không hoạt động
//       await _mapboxMap!.setCamera(
//         CameraOptions(
//           center: Point(
//             coordinates: Position(longitude, latitude),
//           ),
//           zoom: 14.0,
//           pitch: _currentPitch,
//           bearing: _currentBearing,
//         ),
//       );
//       _updateMarkersWithCurrentZoom();
//     }
//   }

//   // Cập nhật nút vị trí hiện tại để sử dụng _getCurrentLocationDirectly thay vì logic riêng
//   Future<void> _getLocation() async {
//     _getCurrentLocationDirectly();
//   }

//   // Hàm cập nhật chế độ 3D
//   Future<void> _toggle3DMode() async {
//     if (_mapboxMap == null) return;
    
//     bool newIs3DMode = !_is3DMode;
//     setState(() {
//       _is3DMode = newIs3DMode;
//     });
    
//     // Cập nhật góc nghiêng (pitch) cho chế độ 3D
//     double newPitch = _is3DMode ? 60.0 : 0.0;
    
//     // Lấy vị trí camera hiện tại
//     CameraState cameraState = await _mapboxMap!.getCameraState();
    
//     // Cập nhật camera với góc nghiêng mới
//     await _mapboxMap!.setCamera(
//       CameraOptions(
//         center: cameraState.center,
//         zoom: cameraState.zoom,
//         pitch: newPitch,
//         bearing: _currentBearing,
//       ),
//     );
    
//     // Cập nhật trạng thái camera và markers
//     await _updateCameraState();
//     await _updateMarkersWithCurrentZoom();
//   }
  
//   // Hàm xoay bản đồ
//   Future<void> _rotatemap(double deltaBearing) async {
//     if (_mapboxMap == null) return;
    
//     // Lấy vị trí camera hiện tại
//     CameraState cameraState = await _mapboxMap!.getCameraState();
    
//     // Cập nhật góc xoay
//     _currentBearing = (_currentBearing + deltaBearing) % 360;
    
//     // Cập nhật camera với góc xoay mới
//     await _mapboxMap!.setCamera(
//       CameraOptions(
//         center: cameraState.center,
//         zoom: cameraState.zoom,
//         pitch: _currentPitch,
//         bearing: _currentBearing,
//       ),
//     );
    
//     // Cập nhật trạng thái camera và markers
//     await _updateCameraState();
//     await _updateMarkersWithCurrentZoom();
//   }
  
//   // Điều chỉnh góc nghiêng
//   Future<void> _adjustPitch(double deltaPitch) async {
//     if (_mapboxMap == null) return;
    
//     // Giới hạn góc nghiêng từ 0 đến 60 độ
//     double newPitch = (_currentPitch + deltaPitch).clamp(0.0, 60.0);
    
//     // Nếu góc nghiêng không thay đổi, không cần cập nhật
//     if (newPitch == _currentPitch) return;
    
//     // Lấy vị trí camera hiện tại
//     CameraState cameraState = await _mapboxMap!.getCameraState();
    
//     // Cập nhật camera với góc nghiêng mới
//     await _mapboxMap!.setCamera(
//       CameraOptions(
//         center: cameraState.center,
//         zoom: cameraState.zoom,
//         pitch: newPitch,
//         bearing: _currentBearing,
//       ),
//     );
    
//     // Cập nhật trạng thái camera và markers
//     await _updateCameraState();
//     await _updateMarkersWithCurrentZoom();
//   }
  
//   // Đặt lại hướng bản đồ về mặc định (hướng Bắc)
//   Future<void> _resetMapOrientation() async {
//     if (_mapboxMap == null) return;
    
//     // Lấy vị trí camera hiện tại
//     CameraState cameraState = await _mapboxMap!.getCameraState();
    
//     // Đặt lại góc xoay và góc nghiêng
//     _currentBearing = 0.0;
//     _currentPitch = 0.0;
    
//     // Cập nhật camera
//     await _mapboxMap!.setCamera(
//       CameraOptions(
//         center: cameraState.center,
//         zoom: cameraState.zoom,
//         pitch: 0.0,
//         bearing: 0.0,
//       ),
//     );
    
//     // Cập nhật trạng thái camera và markers
//     await _updateCameraState();
//     await _updateMarkersWithCurrentZoom();
//   }

//   // Cập nhật các hàm sử dụng marker để dùng MarkerService
//   Future<void> _addMarkerAtPosition(double latitude, double longitude) async {
//     try {
//       await _markerService.addLocationMarker(latitude, longitude);
//       // Lưu vị trí marker vào Cubit
//       context.read<MapCubit>().saveMarkerPosition(latitude, longitude);
//     } catch (e) {
//       print('Lỗi khi tạo marker: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Không thể tạo marker: $e')),
//       );
//     }
//   }

//   // Hàm tìm kiếm địa chỉ
//   Future<void> _performSearch(String query) async {
//     if (query.isEmpty) {
//       setState(() {
//         _searchResults = [];
//         _isSearching = false;
//         _showSearchResults = false;
//       });
      
//       // Xóa kết quả tìm kiếm trong Cubit
//       context.read<MapCubit>().clearSearchResults();
//       return;
//     }

//     setState(() {
//       _isSearching = true;
//       _showSearchResults = true;
//     });
    
//     // Cập nhật trạng thái tìm kiếm trong Cubit
//     context.read<MapCubit>().setSearching(true);

//     try {
//       final results = await _searchService.searchPlaces(query);
//       setState(() {
//         _searchResults = results;
//         _isSearching = false;
//       });
      
//       // Lưu kết quả tìm kiếm vào Cubit
//       context.read<MapCubit>().saveSearchResults(results);
//     } catch (e) {
//       print('Lỗi tìm kiếm: $e');
//       setState(() {
//         _searchResults = [];
//         _isSearching = false;
//       });
      
//       // Xóa kết quả tìm kiếm trong Cubit
//       context.read<MapCubit>().clearSearchResults();
//     }
//   }

//   // Hàm tìm kiếm cấu trúc (phù hợp với địa chỉ Việt Nam)
//   Future<void> _performStructuredSearch() async {
//     // Kiểm tra xem có ít nhất một trường dữ liệu được nhập
//     if ((_houseNumber == null || _houseNumber!.isEmpty) &&
//         (_street == null || _street!.isEmpty) &&
//         (_district == null || _district!.isEmpty) &&
//         (_place == null || _place!.isEmpty)) {
//       return;
//     }

//     setState(() {
//       _isSearching = true;
//       _showSearchResults = true;
//     });
    
//     // Cập nhật trạng thái tìm kiếm trong Cubit
//     context.read<MapCubit>().setSearching(true);

//     try {
//       final results = await _searchService.searchStructured(
//         houseNumber: _houseNumber,
//         street: _street,
//         neighborhood: _neighborhood,
//         district: _district,
//         place: _place,
//         region: _region,
//       );
      
//       setState(() {
//         _searchResults = results;
//         _isSearching = false;
//       });
      
//       // Lưu kết quả tìm kiếm vào Cubit
//       context.read<MapCubit>().saveSearchResults(results);
//     } catch (e) {
//       print('Lỗi tìm kiếm cấu trúc: $e');
//       setState(() {
//         _searchResults = [];
//         _isSearching = false;
//       });
      
//       // Xóa kết quả tìm kiếm trong Cubit
//       context.read<MapCubit>().clearSearchResults();
//     }
//   }

//   // Xử lý khi chọn một kết quả tìm kiếm
//   void _onSearchResultSelected(SearchResult result) {
//     if (_mapboxMap != null) {
//       _mapboxMap!.setCamera(
//         CameraOptions(
//           center: Point(
//             coordinates: Position(result.longitude, result.latitude),
//           ),
//           zoom: 15.0,
//           pitch: _currentPitch, // Giữ nguyên góc nghiêng hiện tại
//           bearing: _currentBearing, // Giữ nguyên hướng xoay hiện tại
//         ),
//       );
//       _addMarkerAtPosition(result.latitude, result.longitude);
      
//       // Lưu địa điểm đã chọn vào Cubit
//       context.read<MapCubit>().saveSelectedLocation(result);
//     }
    
//     // Đóng kết quả tìm kiếm
//     _searchFocusNode.unfocus();
//     setState(() {
//       _showSearchResults = false;
//     });
//   }

//   @override
//   Widget build(BuildContext context) {
//     super.build(context);
//     return BlocBuilder<MapCubit, MapState>(
//       buildWhen: (previous, current) => 
//           previous.is3DMode != current.is3DMode || 
//           previous.selectedLocation != current.selectedLocation ||
//           previous.searchResults != current.searchResults ||
//           previous.isSatelliteMode != current.isSatelliteMode,
//       builder: (context, state) {
//         if (state.is3DMode != _is3DMode) {
//           _is3DMode = state.is3DMode;
//         }
        
//         if (state.isSatelliteMode != _isSatelliteMode) {
//           _isSatelliteMode = state.isSatelliteMode;
//         }
        
//         return Scaffold(
//           body: Stack(
//             children: [
//               MapWidget(
//                 key: const ValueKey('mapWidget'),
//                 styleUri: _currentStyle,
//                 onMapCreated: _onMapCreated,
//               ),
//               if (_isLoading)
//                 const Center(
//                   child: CircularProgressIndicator(),
//                 ),
              
//               // Map controls
//               Positioned(
//                 right: 16,
//                 bottom: 150,
//                 child: Column(
//                   children: [
//                     FloatingActionButton(
//                       mini: true,
//                       heroTag: 'location',
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.black,
//                       onPressed: _getCurrentLocationDirectly,
//                       child: const Icon(Icons.my_location),
//                     ),
//                     const SizedBox(height: 8),
//                     FloatingActionButton(
//                       mini: true,
//                       heroTag: 'mapType',
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.black,
//                       onPressed: _toggleMapStyle,
//                       child: Icon(_isSatelliteMode ? Icons.map : Icons.satellite),
//                     ),
//                     const SizedBox(height: 8),
//                     FloatingActionButton(
//                       mini: true,
//                       heroTag: '3D',
//                       backgroundColor: Colors.white,
//                       foregroundColor: Colors.black,
//                       onPressed: _toggle3DMode,
//                       child: Icon(_is3DMode ? Icons.view_in_ar : Icons.view_in_ar_outlined),
//                     ),
//                     const SizedBox(height: 8),
//                     FloatingActionButton(
//                       mini: true,
//                       heroTag: 'googlemap',
//                       backgroundColor: Colors.blue,
//                       foregroundColor: Colors.white,
//                       onPressed: () {
//                         Navigator.of(context).push(
//                           MaterialPageRoute(
//                             builder: (context) => const MapScreenV2(),
//                           ),
//                         );
//                       },
//                       child: const Icon(Icons.map_outlined),
//                       tooltip: 'Google Maps',
//                     ),
//                   ],
//                 ),
//               ),
              
//               // Custom search bar
//               Positioned(
//                 top: MediaQuery.of(context).padding.top + 10,
//                 left: 10,
//                 right: 10,
//                 child: Material(
//                   color: Colors.transparent,
//                   child: HeaderWidget(
//                     avatarUrl: '',
//                     searchHint: 'Tìm kiếm địa chỉ tại Việt Nam...',
//                     onNotificationPressed: () {
//                       // Handle notification press if needed
//                     },
//                     onSearchResultSelected: _onSearchResultSelected,
//                     isSearch: true,
//                     showAvatar: false,
//                     leadingIcon: Image.asset(
//                       'assets/icons/map_active_icon.png',
//                       width: 24,
//                       height: 24,
//                     ),
//                     iconSize: 24,
//                     showNotification: false,
//                   ),
//                 ),
//               ),
              
//               // Bottom sheet hiển thị thông tin phòng khi click vào marker
//               if (_showRoomInfo && _selectedRoomMarker != null)
//                 _buildRoomInfoBottomSheet(),
//             ],
//           ),
//         );
//       },
//     );
//   }

//   IconData _getIconForPlaceType(String placeType) {
//     switch (placeType) {
//       case 'address':
//         return Icons.home;
//       case 'street':
//         return Icons.add_road;
//       case 'neighborhood':
//         return Icons.location_city;
//       case 'district':
//         return Icons.account_balance;
//       case 'place':
//         return Icons.location_on;
//       case 'region':
//         return Icons.map;
//       case 'country':
//         return Icons.public;
//       default:
//         return Icons.place;
//     }
//   }

//   // Hàm hiển thị dialog tìm kiếm cấu trúc
//   void _showStructuredSearchDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: const Text('Tìm kiếm địa chỉ chi tiết'),
//         content: SingleChildScrollView(
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               TextField(
//                 decoration: const InputDecoration(labelText: 'Số nhà'),
//                 onChanged: (value) => _houseNumber = value.isEmpty ? null : value,
//               ),
//               TextField(
//                 decoration: const InputDecoration(labelText: 'Tên đường'),
//                 onChanged: (value) => _street = value.isEmpty ? null : value,
//               ),
//               TextField(
//                 decoration: const InputDecoration(labelText: 'Phường/Xã'),
//                 onChanged: (value) => _neighborhood = value.isEmpty ? null : value,
//               ),
//               TextField(
//                 decoration: const InputDecoration(labelText: 'Quận/Huyện'),
//                 onChanged: (value) => _district = value.isEmpty ? null : value,
//               ),
//               TextField(
//                 decoration: const InputDecoration(labelText: 'Thành phố'),
//                 onChanged: (value) => _place = value.isEmpty ? null : value,
//               ),
//               TextField(
//                 decoration: const InputDecoration(labelText: 'Tỉnh/Thành phố'),
//                 onChanged: (value) => _region = value.isEmpty ? null : value,
//               ),
//             ],
//           ),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Hủy'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.pop(context);
//               _performStructuredSearch();
//             },
//             child: const Text('Tìm kiếm'),
//           ),
//         ],
//       ),
//     );
//   }

//   // Thay đổi style map
//   Future<void> _toggleMapStyle() async {
//     if (_mapboxMap == null) return;
    
//     // Chọn style mới
//     String newStyle;
//     if (_isSatelliteMode) {
//       // Nếu đang ở chế độ vệ tinh, chuyển sang chế độ thường
//       newStyle = MapboxStyles.MAPBOX_STREETS;
//     } else {
//       // Nếu đang ở chế độ thường, chuyển sang chế độ vệ tinh
//       newStyle = MapboxStyles.SATELLITE_STREETS;
//     }
    
//     try {
//       // Lưu trạng thái trước khi thay đổi style
//       final cameraState = await _mapboxMap!.getCameraState();
      
//       // Thay đổi style
//       await _mapboxMap!.loadStyleURI(newStyle);
      
//       // Cập nhật biến local
//       setState(() {
//         _currentStyle = newStyle;
//         _isSatelliteMode = !_isSatelliteMode;
//       });
      
//       // Lưu style mới vào Cubit
//       context.read<MapCubit>().setMapStyle(newStyle);
      
//       // Khôi phục camera và markers sau khi thay đổi style
//       await _mapboxMap!.setCamera(
//         CameraOptions(
//           center: cameraState.center,
//           zoom: cameraState.zoom,
//           pitch: _currentPitch,
//           bearing: _currentBearing,
//         ),
//       );
      
//       // Khôi phục marker
//       await _restoreMarker();
      
//       // Cập nhật markers
//       await _updateMarkersWithCurrentZoom();
//     } catch (e) {
//       print('Lỗi khi thay đổi style map: $e');
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Không thể thay đổi style map: $e')),
//       );
//     }
//   }

//   // Tạo bottom sheet hiển thị thông tin phòng
//   Widget _buildRoomInfoBottomSheet() {
//     final room = _selectedRoomMarker!;
//     final theme = Theme.of(context);
//     final size = MediaQuery.of(context).size;
    
//     return Positioned(
//       left: 0,
//       right: 0,
//       bottom: 0,
//       child: Container(
//         decoration: BoxDecoration(
//           color: Colors.white.withOpacity(0.95),
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.15),
//               blurRadius: 12,
//               spreadRadius: 0,
//               offset: const Offset(0, -3),
//             ),
//           ],
//         ),
//         child: ClipRRect(
//           borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
//           child: BackdropFilter(
//             filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
//             child: Column(
//               mainAxisSize: MainAxisSize.min,
//               children: [
//                 // Header với handle và nút đóng
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
//                   child: Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       // Handle ở phía trái
//                       Container(
//                         width: 40,
//                         height: 5,
//                         decoration: BoxDecoration(
//                           color: Colors.grey[300],
//                           borderRadius: BorderRadius.circular(2.5),
//                         ),
//                       ),
                      
//                       // Nút đóng ở phía phải
//                       IconButton(
//                         onPressed: _closeRoomInfo,
//                         icon: const Icon(Icons.close, size: 18),
//                         padding: EdgeInsets.zero,
//                         constraints: const BoxConstraints(),
//                         visualDensity: VisualDensity.compact,
//                         style: IconButton.styleFrom(
//                           tapTargetSize: MaterialTapTargetSize.shrinkWrap,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Thông tin phòng (Hình ảnh và chi tiết)
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
//                   child: Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       // Hình ảnh phòng
//                       ClipRRect(
//                         borderRadius: BorderRadius.circular(10),
//                         child: SizedBox(
//                           width: size.width * 0.33,
//                           height: 110,
//                           child: Stack(
//                             fit: StackFit.expand,
//                             children: [
//                               room.thumbnailUrl != null
//                                 ? Image.network(
//                                     room.thumbnailUrl!,
//                                     fit: BoxFit.cover,
//                                     errorBuilder: (context, error, stackTrace) {
//                                       print('Lỗi tải ảnh: $error, URL: ${room.thumbnailUrl}');
//                                       return Container(
//                                         color: Colors.grey[200],
//                                         child: Column(
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           children: [
//                                             Icon(
//                                               Icons.error_outline,
//                                               size: 24,
//                                               color: Colors.grey[400],
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               'Lỗi tải ảnh',
//                                               style: TextStyle(
//                                                 fontSize: 10,
//                                                 color: Colors.grey[600],
//                                               ),
//                                               textAlign: TextAlign.center,
//                                             ),
//                                           ],
//                                         ),
//                                       );
//                                     },
//                                     loadingBuilder: (context, child, loadingProgress) {
//                                       if (loadingProgress == null) return child;
//                                       return Center(
//                                         child: Column(
//                                           mainAxisAlignment: MainAxisAlignment.center,
//                                           children: [
//                                             CircularProgressIndicator(
//                                               value: loadingProgress.expectedTotalBytes != null
//                                                 ? loadingProgress.cumulativeBytesLoaded / 
//                                                   loadingProgress.expectedTotalBytes!
//                                                 : null,
//                                               color: theme.primaryColor,
//                                               strokeWidth: 2,
//                                             ),
//                                             const SizedBox(height: 4),
//                                             Text(
//                                               'Đang tải...',
//                                               style: TextStyle(
//                                                 fontSize: 10,
//                                                 color: Colors.grey[600],
//                                               ),
//                                             ),
//                                           ],
//                                         ),
//                                       );
//                                     },
//                                   )
//                                 : Container(
//                                     color: Colors.grey[200],
//                                     child: Icon(
//                                       Icons.image_not_supported_outlined,
//                                       size: 30,
//                                       color: Colors.grey[400],
//                                     ),
//                                   ),
//                               // Overlay loại phòng
//                               Positioned(
//                                 top: 8,
//                                 left: 8,
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
//                                   decoration: BoxDecoration(
//                                     color: room.type == 'VIP' 
//                                       ? Colors.red.withOpacity(0.85) 
//                                       : const Color(0xFF00FF66).withOpacity(0.85),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Text(
//                                     room.type,
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 10,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                               // Giá phòng ở dưới góc phải
//                               Positioned(
//                                 bottom: 8,
//                                 right: 8,
//                                 child: Container(
//                                   padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                                   decoration: BoxDecoration(
//                                     color: Colors.black.withOpacity(0.7),
//                                     borderRadius: BorderRadius.circular(8),
//                                   ),
//                                   child: Text(
//                                     '${room.price} Tr',
//                                     style: const TextStyle(
//                                       color: Colors.white,
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 12,
//                                     ),
//                                   ),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
                      
//                       const SizedBox(width: 12),
                      
//                       // Thông tin phòng - chiếm phần còn lại
//                       Expanded(
//                         child: SizedBox(
//                           height: 110,
//                           child: Column(
//                             crossAxisAlignment: CrossAxisAlignment.start,
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               // Tiêu đề phòng
//                               Text(
//                                 room.title ?? 'Chi tiết phòng',
//                                 style: theme.textTheme.titleMedium?.copyWith(
//                                   fontWeight: FontWeight.bold,
//                                   fontSize: 15,
//                                 ),
//                                 maxLines: 1,
//                                 overflow: TextOverflow.ellipsis,
//                               ),
                              
//                               // Địa chỉ
//                               if (room.address != null) 
//                                 Row(
//                                   crossAxisAlignment: CrossAxisAlignment.start,
//                                   children: [
//                                     const Icon(Icons.location_on, size: 12, color: Colors.grey),
//                                     const SizedBox(width: 4),
//                                     Expanded(
//                                       child: Text(
//                                         room.address!,
//                                         style: TextStyle(
//                                           fontSize: 11,
//                                           color: Colors.grey[700],
//                                         ),
//                                         maxLines: 2,
//                                         overflow: TextOverflow.ellipsis,
//                                       ),
//                                     ),
//                                   ],
//                                 ),
                              
//                               // Thông tin bổ sung
//                               Row(
//                                 children: [
//                                   if (room.area != null)
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey[100],
//                                         borderRadius: BorderRadius.circular(6),
//                                         border: Border.all(color: Colors.grey[300]!),
//                                       ),
//                                       child: _buildInfoItem(Icons.square_foot, '${room.area} m²'),
//                                     ),
//                                   if (room.area != null && room.bedrooms != null)
//                                     const SizedBox(width: 8),
//                                   if (room.bedrooms != null)
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                                       decoration: BoxDecoration(
//                                         color: Colors.grey[100],
//                                         borderRadius: BorderRadius.circular(6),
//                                         border: Border.all(color: Colors.grey[300]!),
//                                       ),
//                                       child: _buildInfoItem(Icons.bed, '${room.bedrooms} PN'),
//                                     ),
//                                 ],
//                               ),
                              
//                               // Khung đánh giá & view
//                               Row(
//                                 children: [
//                                   Icon(Icons.star, size: 14, color: Colors.amber[700]),
//                                   Text(
//                                     " 4.8",
//                                     style: TextStyle(
//                                       fontSize: 12,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.grey[700],
//                                     ),
//                                   ),
//                                   Text(
//                                     " (64)",
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey[500],
//                                     ),
//                                   ),
//                                   const SizedBox(width: 12),
//                                   Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.grey[600]),
//                                   Text(
//                                     " 124 lượt xem",
//                                     style: TextStyle(
//                                       fontSize: 11,
//                                       color: Colors.grey[500],
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                             ],
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
                
//                 // Nút xem chi tiết và liên hệ - nằm dưới cùng, cạnh nhau
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
//                   child: Row(
//                     children: [
//                       // Nút xem chi tiết
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           icon: const Icon(Icons.info_outline, size: 16),
//                           label: const Text('Xem chi tiết', style: TextStyle(fontSize: 13)),
//                           onPressed: () {
//                             // Navigate to room detail screen
//                           },
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 10),
//                             backgroundColor: theme.primaryColor,
//                             foregroundColor: Colors.white,
//                             elevation: 1,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         ),
//                       ),
                      
//                       const SizedBox(width: 10),
                      
//                       // Nút liên hệ
//                       Expanded(
//                         child: ElevatedButton.icon(
//                           icon: const Icon(Icons.message_outlined, size: 16),
//                           label: const Text('Liên hệ', style: TextStyle(fontSize: 13)),
//                           onPressed: () {
//                             // Xử lý sự kiện khi nhấn nút liên hệ
//                           },
//                           style: ElevatedButton.styleFrom(
//                             padding: const EdgeInsets.symmetric(vertical: 10),
//                             backgroundColor: Colors.white,
//                             foregroundColor: theme.primaryColor,
//                             elevation: 1,
//                             side: BorderSide(color: theme.primaryColor),
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(8),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
  
//   // Helper để tạo các mục thông tin
//   Widget _buildInfoItem(IconData icon, String text) {
//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         Icon(icon, size: 12, color: Colors.grey[600]),
//         const SizedBox(width: 4),
//         Text(
//           text,
//           style: TextStyle(
//             fontSize: 11,
//             color: Colors.grey[700],
//           ),
//         ),
//       ],
//     );
//   }

//   @override
//   bool get wantKeepAlive => true;
// }
