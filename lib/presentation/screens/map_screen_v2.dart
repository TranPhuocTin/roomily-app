import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roomily/core/services/location_service.dart';
import 'package:roomily/core/services/search_service.dart';
import 'package:roomily/core/services/google_places_service.dart';
import 'package:roomily/core/services/user_location_service.dart';
import 'package:roomily/core/utils/format_utils.dart';
import 'package:roomily/data/models/place_autocomplete_result.dart';
import 'package:roomily/data/models/place_details.dart';
import 'package:roomily/data/models/room_marker_info.dart';
import 'package:roomily/data/models/models.dart';
import 'package:roomily/presentation/screens/room_detail_screen.dart';
import 'package:roomily/presentation/widgets/map/map_bottom_controls.dart';
import 'package:roomily/presentation/widgets/map/map_search_bar.dart';
import 'package:roomily/presentation/widgets/map/map_search_results.dart';
import 'package:roomily/presentation/widgets/map/room_info_panel.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:url_launcher/url_launcher.dart';

import '../../data/blocs/map/map_cubit.dart';
import '../../data/blocs/room_filter/room_filter_cubit.dart';

class MapScreenV2 extends StatefulWidget {
  const MapScreenV2({super.key});

  @override
  State<MapScreenV2> createState() => _MapScreenV2State();
}

class _MapScreenV2State extends State<MapScreenV2> with AutomaticKeepAliveClientMixin, WidgetsBindingObserver {
  final LocationService _locationService = GetIt.instance<LocationService>();
  final UserLocationService _userLocationService = GetIt.instance<UserLocationService>();
  final SearchService _searchService = GetIt.instance<SearchService>();
  final GooglePlacesService _googlePlacesService = GetIt.instance<GooglePlacesService>();
  late final RoomFilterCubit _roomFilterCubit;
  
  // Completer để lấy controller sau khi bản đồ đã tạo
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  
  // State variables
  bool _isLoading = false;
  bool _isFirstLoad = true;
  bool _is3DMode = false;
  bool _isBackgroundLoading = false; // Biến theo dõi quá trình tải ngầm
  
  // Flag để theo dõi trạng thái lấy vị trí và khởi tạo map
  bool _pendingLocationFlyTo = false;
  double? _pendingLatitude;
  double? _pendingLongitude;
  
  // Camera state - sẽ được lưu vào Cubit
  double _currentTilt = 0.0;
  double _currentBearing = 0.0;
  
  // Map style state
  MapType _currentMapType = MapType.normal;
  bool _isSatelliteMode = false;
  
  // Search state - sẽ được lưu vào Cubit
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  List<SearchResult> _searchResults = [];
  List<PlaceAutocompleteResult> _autocompleteResults = [];
  bool _isSearching = false;
  bool _showSearchResults = false;


  
  // Marker management
  Set<Marker> _markers = {};
  RoomMarkerInfo? _selectedRoomMarker;
  bool _showRoomInfo = false;
  
  // Zoom threshold for showing room markers - only show when zoomed in this level or more
  double _zoomThresholdForMarkers = 13.5;
  double _currentZoom = 14.0; // Default zoom level
  bool _shouldShowRoomMarkers = true; // Default to true for initial rendering
  
  // Camera position tracking variables
  LatLng _lastFetchPosition = const LatLng(0, 0);
  double _minimumFetchDistanceInMeters = 500.0; // 500 meters
  double _fetchRadiusInMeters = 10000.0; // 10km
  Timer? _cameraMovementTimer; // Timer for debouncing

  // Cache for fetched rooms
  final Map<String, List<Room>> _roomsCache = {}; // Key is grid cell ID
  final double _gridCellSizeInMeters = 5000.0; // 5km grid size

  // Set to keep track of currently visible grid cells
  final Set<String> _visibleGridCells = {};
  
  // Mock data cho markers (có thể thay thế bằng dữ liệu thực từ API)
  // final List<RoomMarkerInfo> _mockRooms = [
  //   RoomMarkerInfo(
  //     latitude: 16.0673,
  //     longitude: 108.2097,
  //     price: 2.7,
  //     type: 'VIP',
  //     id: '1',
  //     title: 'Phòng đẹp gần chợ Thanh Khê',
  //     address: '123 Hải Phòng, Thanh Khê, Đà Nẵng',
  //     thumbnailUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
  //     area: 30,
  //     bedrooms: 1,
  //   ),
  //   RoomMarkerInfo(
  //     latitude: 16.0712,
  //     longitude: 108.2054,
  //     price: 2.3,
  //     type: 'GẦN',
  //     id: '2',
  //     title: 'Phòng giá rẻ gần đường Lê Duẩn',
  //     address: '45 Lê Duẩn, Thanh Khê, Đà Nẵng',
  //     thumbnailUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2',
  //     area: 25,
  //     bedrooms: 1,
  //   ),
  //   RoomMarkerInfo(
  //     latitude: 16.0654,
  //     longitude: 108.2145,
  //     price: 3.1,
  //     type: 'VIP',
  //     id: '3',
  //     title: 'Căn hộ cao cấp khu vực Hải Phòng',
  //     address: '78 Hải Phòng, Thanh Khê, Đà Nẵng',
  //     thumbnailUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688',
  //     area: 45,
  //     bedrooms: 2,
  //   ),
  // ];

  // Vị trí mặc định (Đà Nẵng)
  static const LatLng _defaultPosition = LatLng(16.0678, 108.2208);

  // Marker icons
  BitmapDescriptor _defaultIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor _vipIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
  BitmapDescriptor _nearbyIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  BitmapDescriptor _userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  Map<String, BitmapDescriptor> _customRoomMarkers = {};

  @override
  void initState() {
    super.initState();
    
    // Khởi tạo RoomFilterCubit
    _roomFilterCubit = context.read<RoomFilterCubit>();
    
    // Đăng ký observer để biết khi app chuyển trạng thái
    WidgetsBinding.instance.addObserver(this);
    
    // Hiển thị loading indicator ngay khi màn hình được tạo
    setState(() {
      _isLoading = true;
    });
    
    // Khởi tạo từ Cubit
    _initializeFromCubit();

    // Chuẩn bị custom icon markers
    // _loadMarkerIcons();

    _searchFocusNode.addListener(() {
      setState(() {
        _showSearchResults = _searchFocusNode.hasFocus && _autocompleteResults.isNotEmpty;
      });
    });
    
    // Lấy vị trí hiện tại ngay khi màn hình được tạo
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Lấy vị trí ngay lập tức
      _getCurrentLocationDirectly();
    });
  }
  
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Khi app quay lại foreground, cập nhật vị trí
    if (state == AppLifecycleState.resumed) {
      _getCurrentLocationDirectly();
    }
  }
  
  // Khởi tạo từ trạng thái đã lưu trong Cubit
  void _initializeFromCubit() {
    final mapState = context.read<MapCubit>().state;
    
    // Khôi phục trạng thái camera
    _currentTilt = mapState.lastPitch ?? 0.0;
    _currentBearing = mapState.lastBearing ?? 0.0;
    
    // Khôi phục trạng thái style map
    _isSatelliteMode = mapState.isSatelliteMode;
    _currentMapType = _isSatelliteMode ? MapType.satellite : MapType.normal;
    
    // Khôi phục kết quả tìm kiếm
    _searchResults = mapState.searchResults;
    _isSearching = mapState.isSearching;
    
    // Đánh dấu map đã được khởi tạo nếu cần
    if (!mapState.isMapInitialized) {
      context.read<MapCubit>().setMapInitialized();
      _isFirstLoad = true; // Đảm bảo hiệu ứng zoom từ xa khi mở lần đầu
    } else {
      _isFirstLoad = false;
    }
  }
  
  // Tải custom marker icons từ widget
  // Future<void> _loadMarkerIcons() async {
  //   try {
  //     // Sử dụng các marker có sẵn cho user location
  //     _userLocationIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);
  //
  //     // Đối với các loại phòng, tạo marker từ canvas
  //     for (var room in _mockRooms) {
  //       final customMarker = await _createCustomPriceMarker(room);
  //       _customRoomMarkers[room.id] = customMarker;
  //     }
  //   } catch (e) {
  //     print('Lỗi khi tải marker icons: $e');
  //     // Sử dụng các marker mặc định nếu có lỗi
  //     _vipIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
  //     _nearbyIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
  //   }
  // }
  
  // Tạo custom marker từ canvas hiển thị giá phòng
  Future<BitmapDescriptor> _createCustomPriceMarker(RoomMarkerInfo room) async {
    // Xác định màu dựa trên loại phòng
    Color markerColor;
    
    if (room.type == 'VIP') {
      markerColor = const Color(0xFF7E57C2); // Tím
    } else if (room.type == 'GẦN') {
      markerColor = const Color(0xFF26A69A); // Xanh lá
    } else {
      markerColor = const Color(0xFFEF5350); // Đỏ
    }
    
    // Định dạng giá phòng
    final String priceText = FormatUtils.formatCurrencyForMarker(room.price);
    
    // Khởi tạo canvas để vẽ marker
    final ui.PictureRecorder recorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(recorder);
    
    // Kích thước của marker
    const double width = 90.0;
    const double height = 45.0;
    const double pointerSize = 10.0;
    const double cornerRadius = 8.0;
    
    // Vẽ bóng đổ
    final Paint shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    
    final Path shadowPath = Path();
    shadowPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(2, 3, width, height),
        const Radius.circular(cornerRadius)
      )
    );
    shadowPath.moveTo(width / 2 - 8 + 2, height + 3);
    shadowPath.lineTo(width / 2 + 2, height + pointerSize + 3);
    shadowPath.lineTo(width / 2 + 8 + 2, height + 3);
    shadowPath.close();
    
    canvas.drawPath(shadowPath, shadowPaint);
    
    // Vẽ marker chính
    final Paint markerPaint = Paint()..color = Colors.white;
    
    final Path markerPath = Path();
    markerPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        Radius.circular(cornerRadius)
      )
    );
    markerPath.moveTo(width / 2 - 8, height);
    markerPath.lineTo(width / 2, height + pointerSize);
    markerPath.lineTo(width / 2 + 8, height);
    markerPath.close();
    
    canvas.drawPath(markerPath, markerPaint);
    
    // Vẽ viền màu cho marker
    final Paint borderPaint = Paint()
      ..color = markerColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    final Path borderPath = Path();
    borderPath.addRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(0, 0, width, height),
        Radius.circular(cornerRadius)
      )
    );
    
    canvas.drawPath(borderPath, borderPaint);
    
    // Vẽ giá phòng với font size lớn hơn
    final pricePainter = TextPainter(
      text: TextSpan(
        text: priceText,
        style: TextStyle(
          color: Colors.black.withOpacity(0.85),
          fontSize: 24, // Tăng kích thước font
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    pricePainter.layout();
    pricePainter.paint(
      canvas,
      Offset(
        (width - pricePainter.width) / 2,
        (height - pricePainter.height) / 2,
      ),
    );
    
    // Thêm đơn vị triệu
    final unitPainter = TextPainter(
      text: TextSpan(
        text: "tr",
        style: TextStyle(
          color: markerColor,
          fontSize: 14, // Tăng kích thước font cho đơn vị
          fontWeight: FontWeight.bold,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    
    unitPainter.layout();
    unitPainter.paint(
      canvas,
      Offset(
        (width + pricePainter.width) / 2 + 2,
        (height - unitPainter.height) / 2 + 8,
      ),
    );
    
    // Chuyển đổi canvas thành hình ảnh
    final ui.Picture picture = recorder.endRecording();
    final ui.Image image = await picture.toImage((width + 4).toInt(), (height + pointerSize + 6).toInt());
    final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    
    if (byteData != null) {
      return BitmapDescriptor.fromBytes(byteData.buffer.asUint8List());
    }
    
    // Fallback nếu không thể tạo được custom marker
    return room.type == 'VIP' 
        ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet)
        : (room.type == 'GẦN' 
            ? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen) 
            : BitmapDescriptor.defaultMarker);
  }
  
  // Thêm markers cho các phòng trọ với biểu tượng tùy chỉnh
  // void _addRoomMarkers() {
  //   // Nếu zoom level chưa đủ cao, không thêm room markers
  //   if (!_shouldShowRoomMarkers) {
  //     // Chỉ giữ lại marker vị trí người dùng
  //     final userMarker = _markers.where((marker) => marker.markerId.value == 'user_location' || marker.markerId.value == 'search_result');
  //     setState(() {
  //       _markers = {...userMarker};
  //     });
  //     return;
  //   }
  //
  //   final roomMarkers = _mockRooms.map((room) {
  //     // Sử dụng custom marker đã tạo hoặc fallback về marker mặc định
  //     final icon = _customRoomMarkers[room.id] ??
  //             (room.type == 'VIP' ? _vipIcon : _nearbyIcon);
  //
  //     return Marker(
  //       markerId: MarkerId(room.id),
  //       position: LatLng(room.latitude, room.longitude),
  //       icon: icon,
  //       onTap: () {
  //         setState(() {
  //           _selectedRoomMarker = room;
  //           _showRoomInfo = true;
  //         });
  //       },
  //     );
  //   }).toSet();
  //
  //   setState(() {
  //     // Giữ nguyên marker vị trí người dùng và marker tìm kiếm (nếu có)
  //     final preservedMarkers = _markers.where(
  //       (marker) => marker.markerId.value == 'user_location' || marker.markerId.value == 'search_result'
  //     );
  //     _markers = {...preservedMarkers, ...roomMarkers};
  //   });
  // }
  
  // Lấy vị trí hiện tại trực tiếp, không phụ thuộc vào trạng thái
  Future<void> _getCurrentLocationDirectly() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Ưu tiên sử dụng vị trí từ UserLocationService nếu có
      geo.Position? geoPosition;
      double? latitude, longitude;
      
      // Kiểm tra xem UserLocationService đã được khởi tạo chưa
      if (_userLocationService.isInitialized && _userLocationService.currentAddress != null) {
        // Lấy vị trí từ UserLocationService
        final address = _userLocationService.currentAddress!;
        if (address.latitude != null && address.longitude != null) {
          latitude = address.latitude;
          longitude = address.longitude;
        }
      }
      
      // Nếu không có vị trí từ UserLocationService, lấy vị trí mới
      if (latitude == null || longitude == null) {
        geoPosition = await _locationService.getCurrentPosition();
        if (geoPosition != null) {
          latitude = geoPosition.latitude;
          longitude = geoPosition.longitude;
        }
      }
      
      if (latitude != null && longitude != null && mounted) {
        // Lưu vị trí vào Cubit
        context.read<MapCubit>().saveMarkerPosition(latitude, longitude);
        
        // Di chuyển camera đến vị trí
        final GoogleMapController controller = await _controller.future;
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(latitude, longitude),
              zoom: 15.0,
              tilt: _currentTilt,
              bearing: _currentBearing,
            ),
          ),
        );
        
        // Cập nhật zoom hiện tại
        _currentZoom = 15.0; // Zoom level được set bên trên
        _shouldShowRoomMarkers = _currentZoom >= _zoomThresholdForMarkers;
        
        // Thêm marker vị trí người dùng
        _addUserLocationMarker(latitude, longitude);
        
        // Thêm các markers của phòng nếu zoom đủ lớn
        if (_shouldShowRoomMarkers) {
          // Thay thế _addRoomMarkers() bằng việc tải phòng thực tế
          _debouncedFetchRooms(LatLng(latitude, longitude), _currentZoom, true);
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể lấy vị trí hiện tại')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi lấy vị trí: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  // Thêm marker hiển thị vị trí người dùng
  void _addUserLocationMarker(double latitude, double longitude) {
    final userMarker = Marker(
      markerId: const MarkerId('user_location'),
      position: LatLng(latitude, longitude),
      icon: _userLocationIcon,
      infoWindow: const InfoWindow(title: 'Vị trí của bạn'),
    );
    
    setState(() {
      _markers.removeWhere((marker) => marker.markerId.value == 'user_location');
      _markers.add(userMarker);
    });
  }
  
  // Tìm kiếm địa điểm sử dụng Google Places Autocomplete
  Future<void> _searchPlaces(String query) async {
    debugPrint('🔎 Bắt đầu tìm kiếm địa điểm với query: "$query"');
    
    if (query.isEmpty) {
      debugPrint('⚠️ Query rỗng, xóa kết quả tìm kiếm');
      setState(() {
        _autocompleteResults = [];
        _showSearchResults = false;
      });
      return;
    }
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      debugPrint('⏳ Gọi GooglePlacesService.getPlaceAutocomplete()');
      final results = await _googlePlacesService.getPlaceAutocomplete(query);
      
      if (mounted) {
        debugPrint('✅ Nhận được ${results.length} kết quả tìm kiếm');
        
        setState(() {
          _autocompleteResults = results;
          _showSearchResults = _searchFocusNode.hasFocus && results.isNotEmpty;
          _isSearching = false;
        });
        
        debugPrint('📊 _autocompleteResults.length: ${_autocompleteResults.length}');
        debugPrint('📊 _showSearchResults: $_showSearchResults');
        
        // Log kết quả để debug
        if (results.isNotEmpty) {
          for (int i = 0; i < results.length; i++) {
            debugPrint('📍 Kết quả #$i: ${results[i].mainText} - ${results[i].secondaryText}');
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi tìm kiếm địa điểm: $e');
      if (mounted) {
        setState(() {
          _isSearching = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tìm kiếm: $e')),
        );
      }
    }
  }
  
  // Lấy chi tiết và điều hướng đến kết quả tìm kiếm được chọn
  Future<void> _navigateToPlaceResult(PlaceAutocompleteResult result) async {
    debugPrint('🔍 Bắt đầu lấy chi tiết địa điểm: ${result.mainText} (placeId: ${result.placeId})');
    
    try {
      // Lấy chi tiết địa điểm từ Place ID
      debugPrint('⏳ Gọi GooglePlacesService.getPlaceDetails()');
      final placeDetails = await _googlePlacesService.getPlaceDetails(result.placeId);
      
      if (placeDetails != null && mounted) {
        debugPrint('✅ Nhận được chi tiết địa điểm: ${placeDetails.name}');
        debugPrint('📍 Tọa độ: ${placeDetails.latitude}, ${placeDetails.longitude}');
        
        debugPrint('⏳ Lấy controller và điều hướng camera');
        final controller = await _controller.future;
        
        await controller.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: LatLng(placeDetails.latitude, placeDetails.longitude),
              zoom: 15.0,
              tilt: _currentTilt,
              bearing: _currentBearing,
            ),
          ),
        );
        
        debugPrint('✅ Đã điều hướng camera đến vị trí');
        
        // Đóng bàn phím và ẩn kết quả tìm kiếm
        FocusScope.of(context).unfocus();
        setState(() {
          _showSearchResults = false;
        });
        
        // Tạo marker tại vị trí tìm kiếm
        final searchMarker = Marker(
          markerId: const MarkerId('search_result'),
          position: LatLng(placeDetails.latitude, placeDetails.longitude),
          infoWindow: InfoWindow(title: placeDetails.name, snippet: placeDetails.formattedAddress),
        );
        
        setState(() {
          _markers.removeWhere((marker) => marker.markerId.value == 'search_result');
          _markers.add(searchMarker);
        });
        
        debugPrint('✅ Đã thêm marker tại vị trí tìm kiếm');
        
        // Lưu vị trí vào Cubit
        context.read<MapCubit>().saveMarkerPosition(placeDetails.latitude, placeDetails.longitude);
        debugPrint('✅ Đã lưu vị trí vào Cubit');
      } else {
        debugPrint('⚠️ Không lấy được chi tiết địa điểm hoặc widget đã bị dispose');
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi xử lý kết quả tìm kiếm: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi di chuyển đến vị trí: $e')),
      );
    }
  }
  
  // Chuyển đổi chế độ xem bản đồ
  void _toggleMapType() {
    setState(() {
      _isSatelliteMode = !_isSatelliteMode;
      _currentMapType = _isSatelliteMode ? MapType.satellite : MapType.normal;
    });
    
    // Lưu trạng thái vào Cubit
    context.read<MapCubit>().toggleSatelliteMode(_isSatelliteMode);
  }
  
  // Chuyển đổi chế độ xem 3D
  void _toggle3DMode() async {
    setState(() {
      _is3DMode = !_is3DMode;
      _currentTilt = _is3DMode ? 45.0 : 0.0;
    });
    
    try {
      final controller = await _controller.future;
      
      // Lấy vị trí từ marker hiện tại hoặc sử dụng vị trí mặc định
      final LatLng targetPosition = _markers.isNotEmpty 
          ? _markers.first.position 
          : _defaultPosition;
      
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: targetPosition,
            zoom: 15.0,
            tilt: _currentTilt,
            bearing: _currentBearing,
          ),
        ),
      );
      
      // Lưu trạng thái camera vào Cubit
      context.read<MapCubit>().saveMapCameraState(pitch: _currentTilt);
    } catch (e) {
      print('Lỗi khi chuyển đổi chế độ 3D: $e');
    }
  }

  @override
  void dispose() {
    // Hủy đăng ký observer
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    _searchFocusNode.dispose();
    _cameraMovementTimer?.cancel();
    super.dispose();
  }
  
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      body: Stack(
        children: [
          // Google Map
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _defaultPosition,
              zoom: 14.0,
              tilt: _currentTilt,
              bearing: _currentBearing,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            mapType: _currentMapType,
            markers: _markers,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
              
              // Nếu có vị trí đang chờ, di chuyển đến đó
              if (_pendingLocationFlyTo && _pendingLatitude != null && _pendingLongitude != null) {
                controller.animateCamera(
                  CameraUpdate.newCameraPosition(
                    CameraPosition(
                      target: LatLng(_pendingLatitude!, _pendingLongitude!),
                      zoom: 15.0,
                      tilt: _currentTilt,
                      bearing: _currentBearing,
                    ),
                  ),
                );
                
                // Cập nhật zoom hiện tại
                _currentZoom = 15.0; // Zoom level được set bên trên
                _shouldShowRoomMarkers = _currentZoom >= _zoomThresholdForMarkers;
                
                // Thêm marker vị trí người dùng
                _addUserLocationMarker(_pendingLatitude!, _pendingLongitude!);
                
                // Thêm các markers của phòng nếu zoom level đủ cao
                if (_shouldShowRoomMarkers) {
                  _debouncedFetchRooms(LatLng(_pendingLatitude!, _pendingLongitude!), _currentZoom, true);
                }
                
                _pendingLocationFlyTo = false;
              }
            },
            onCameraMove: (CameraPosition position) {
              // Lưu trạng thái camera
              _currentTilt = position.tilt;
              _currentBearing = position.bearing;
              _currentZoom = position.zoom;
              
              // Kiểm tra ngưỡng zoom để quyết định có hiển thị room markers hay không
              final newShouldShowMarkers = position.zoom >= _zoomThresholdForMarkers;
              
              // Chỉ cập nhật nếu trạng thái hiển thị thay đổi để tránh re-render không cần thiết
              if (newShouldShowMarkers != _shouldShowRoomMarkers) {
                setState(() {
                  _shouldShowRoomMarkers = newShouldShowMarkers;
                });
                
                if (!_shouldShowRoomMarkers) {
                  // Nếu zoom out quá mức, ẩn tất cả room markers
                  _hideRoomMarkers();
                } else if (_roomsCache.isNotEmpty) {
                  // Nếu zoom in và có cache, hiển thị ngay markers từ cache
                  // Xác định vùng hiển thị hiện tại (ước lượng)
                  _controller.future.then((controller) async {
                    final visibleRegion = await controller.getVisibleRegion();
                    final visibleCells = _getVisibleGridCells(visibleRegion);
                    final cachedRooms = _getRoomsFromCache(visibleCells);
                    
                    if (cachedRooms.isNotEmpty) {
                      _updateRoomMarkersFromRooms(cachedRooms);
                    }
                  });
                }
              }
              
              // Nếu camera di chuyển đủ xa và không đang loading, tải dữ liệu mới
              if (_shouldShowRoomMarkers && !_isLoading && !_isBackgroundLoading) {
                final currentPosition = LatLng(position.target.latitude, position.target.longitude);
                final distance = _calculateDistance(_lastFetchPosition, currentPosition);
                
                if (distance > _minimumFetchDistanceInMeters) {
                  // Chỉ debounce, không hiển thị loading indicator
                  _debouncedFetchRooms(currentPosition, position.zoom, false);
                }
              }
            },
            onCameraIdle: () {
              // Lưu trạng thái camera vào Cubit khi camera dừng di chuyển
              context.read<MapCubit>().saveMapCameraState(
                pitch: _currentTilt,
                bearing: _currentBearing,
              );
              
              // Lấy vị trí trung tâm camera hiện tại
              if (_controller.isCompleted) {
                _controller.future.then((controller) async {
                  final visibleRegion = await controller.getVisibleRegion();
                  final center = LatLng(
                    (visibleRegion.northeast.latitude + visibleRegion.southwest.latitude) / 2,
                    (visibleRegion.northeast.longitude + visibleRegion.southwest.longitude) / 2,
                  );
                  
                  // Lấy grid cells hiện đang hiển thị
                  final visibleCells = _getVisibleGridCells(visibleRegion);
                  
                  // Kiểm tra xem đã có dữ liệu trong cache cho khu vực này chưa
                  final cachedRooms = _getRoomsFromCache(visibleCells);
                  
                  // Khởi động quá trình tải phòng nếu zoom level đủ cao
                  if (_shouldShowRoomMarkers) {
                    if (cachedRooms.isNotEmpty) {
                      // Đã có dữ liệu trong cache, cập nhật markers mà không cần loading
                      _updateRoomMarkersFromRooms(cachedRooms);
                      
                      // Tải dữ liệu mới trong nền nếu vị trí đã di chuyển đủ xa
                      final distance = _calculateDistance(_lastFetchPosition, center);
                      if (distance > _minimumFetchDistanceInMeters) {
                        _debouncedFetchRooms(center, _currentZoom, false);
                      }
                    } else {
                      // Chưa có dữ liệu, cần tải và hiển thị loading
                      _debouncedFetchRooms(center, _currentZoom, true);
                    }
                  }
                });
              }
            },
          ),
          
          // Search bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: MapSearchBar(
              controller: _searchController,
              focusNode: _searchFocusNode,
              onChanged: (value) {
                if (value.length > 2) {
                  _searchPlaces(value);
                } else if (value.isEmpty) {
                  setState(() {
                    _autocompleteResults = [];
                    _showSearchResults = false;
                  });
                }
              },
              onClear: () {
                _searchController.clear();
                setState(() {
                  _autocompleteResults = [];
                  _showSearchResults = false;
                });
              },
            ),
          ),
          
          // Search results
          if (_showSearchResults)
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 16,
              right: 16,
              child: MapSearchResults(
                results: _autocompleteResults,
                onResultTap: _navigateToPlaceResult,
              ),
            ),
          
          // Map controls
          Positioned(
            right: 16,
            bottom: 250,
            child: MapBottomControls(
              onLocationPressed: _getCurrentLocationDirectly,
              onMapTypePressed: _toggleMapType,
              on3DModePressed: _toggle3DMode,
              isSatelliteMode: _isSatelliteMode,
              is3DMode: _is3DMode,
            ),
          ),
          
          // Room info panel
          if (_showRoomInfo && _selectedRoomMarker != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: RoomInfoPanel(
                room: _selectedRoomMarker!,
                onDirectionsPressed: () {
                  _openMapsWithDirections(_selectedRoomMarker!.latitude, _selectedRoomMarker!.longitude);
                },
                onDetailsPressed: () {
                  _navigateToRoomDetails(_selectedRoomMarker!.id);
                },
              ),
            ),
          
          // Loading indicator
          if (_isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  // Tính khoảng cách giữa hai tọa độ (theo Haversine formula)
  double _calculateDistance(LatLng p1, LatLng p2) {
    const double earthRadius = 6371000; // Bán kính trái đất (mét)
    final double lat1Rad = p1.latitude * math.pi / 180;
    final double lat2Rad = p2.latitude * math.pi / 180;
    final double deltaLatRad = (p2.latitude - p1.latitude) * math.pi / 180;
    final double deltaLngRad = (p2.longitude - p1.longitude) * math.pi / 180;

    final double a = math.sin(deltaLatRad / 2) * math.sin(deltaLatRad / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(deltaLngRad / 2) * math.sin(deltaLngRad / 2);
    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadius * c;
  }

  // Tạo ID cho một grid cell dựa trên vị trí
  String _getGridCellId(LatLng position) {
    // Tính toán cell ID dựa trên kích thước grid
    final int latCell = (position.latitude * 111000 / _gridCellSizeInMeters).floor();
    final int lngCell = (position.longitude * 111000 * math.cos(position.latitude * math.pi / 180) / _gridCellSizeInMeters).floor();
    return '$latCell-$lngCell';
  }

  // Lấy tất cả grid cells trong phạm vi nhìn thấy hiện tại của camera
  Set<String> _getVisibleGridCells(LatLngBounds bounds) {
    final Set<String> cells = {};
    
    // Tính toán số lượng grid cells cần trong vùng hiển thị
    final double latSpan = bounds.northeast.latitude - bounds.southwest.latitude;
    final double lngSpan = bounds.northeast.longitude - bounds.southwest.longitude;
    
    // Tính số điểm cần check theo mỗi hướng
    final int latPoints = (latSpan * 111000 / (_gridCellSizeInMeters / 2)).ceil();
    final int lngPoints = (lngSpan * 111000 * math.cos(bounds.southwest.latitude * math.pi / 180) / (_gridCellSizeInMeters / 2)).ceil();
    
    // Tạo grid points để sampling
    for (int i = 0; i <= latPoints; i++) {
      final double lat = bounds.southwest.latitude + (i * latSpan / latPoints);
      for (int j = 0; j <= lngPoints; j++) {
        final double lng = bounds.southwest.longitude + (j * lngSpan / lngPoints);
        cells.add(_getGridCellId(LatLng(lat, lng)));
      }
    }
    
    return cells;
  }

  // Kiểm tra cache và trả về danh sách phòng từ cache nếu có
  List<Room> _getRoomsFromCache(Set<String> gridCells) {
    final List<Room> rooms = [];
    
    for (final cellId in gridCells) {
      if (_roomsCache.containsKey(cellId)) {
        rooms.addAll(_roomsCache[cellId]!);
      }
    }
    
    // Loại bỏ các phòng trùng lặp
    return rooms.toSet().toList();
  }

  // Cập nhật cache với phòng mới
  void _updateRoomsCache(List<Room> rooms, LatLng centerPosition) {
    final String cellId = _getGridCellId(centerPosition);
    
    // Cập nhật cache cho cell hiện tại
    _roomsCache[cellId] = rooms;
    
    // Thông báo đã cập nhật cache
    print('Đã cập nhật cache cho cell $cellId với ${rooms.length} phòng');
    
    // In thông tin cache
    print('Cache hiện tại có ${_roomsCache.length} cells và tổng số ${_roomsCache.values.expand((rooms) => rooms).length} phòng');
  }

  // Tải phòng dựa trên vị trí hiện tại của camera
  Future<void> _fetchRoomsBasedOnCameraPosition(LatLng position, double zoom, [bool showLoadingIndicator = false]) async {
    // Không tải nếu zoom level không đủ cao
    if (zoom < _zoomThresholdForMarkers) {
      print('Zoom level ($zoom) thấp hơn ngưỡng (${_zoomThresholdForMarkers}), bỏ qua việc tải phòng');
      return;
    }
    
    // Tính khoảng cách từ vị trí cuối cùng tải dữ liệu
    final double distance = _calculateDistance(_lastFetchPosition, position);
    
    // Bỏ qua nếu vị trí thay đổi nhỏ hơn ngưỡng và không phải lần đầu tải
    if (distance < _minimumFetchDistanceInMeters && _lastFetchPosition != const LatLng(0, 0)) {
      print('Di chuyển chỉ $distance mét, chưa đủ ngưỡng tải lại (${_minimumFetchDistanceInMeters}m)');
      return;
    }
    
    print('Bắt đầu tải phòng cho vị trí (${position.latitude}, ${position.longitude})');
    
    // Đánh dấu trạng thái loading phù hợp
    setState(() {
      if (showLoadingIndicator) {
        _isLoading = true;
      } else {
        _isBackgroundLoading = true;
      }
    });
    
    try {
      // Sử dụng reverseGeocode để lấy thông tin địa chỉ từ tọa độ
      final placeDetails = await _googlePlacesService.reverseGeocode(
        position.latitude, 
        position.longitude
      );
      
      // Trích xuất và chuẩn hóa thông tin thành phố
      String? cityName;
      if (placeDetails != null) {
        // Đây là cách đơn giản để lấy thành phố từ formattedAddress
        final addressParts = placeDetails.formattedAddress.split(',');
        if (addressParts.length > 2) {
          // Thông thường, thành phố là phần áp chót (trước quốc gia)
          cityName = addressParts[addressParts.length - 2].trim();
          
          // Loại bỏ mã bưu chính và các số khỏi tên thành phố
          cityName = _cleanCityName(cityName);
        }
        
        print('Tìm thấy thành phố từ địa chỉ: $cityName');
      }
      

      // Tạo filter để tìm kiếm phòng với thành phố đã chuẩn hóa
      final filter = RoomFilter.initialFilter(
        city: cityName,
        // Bỏ limit để tải tất cả phòng 
        isSubscribed: true, // Chỉ lấy các phòng đã đăng ký
      );
      
      
      // Gọi API để lấy phòng
      await _roomFilterCubit.loadRooms(customFilter: filter);
      
      // Cập nhật vị trí cuối cùng đã tải
      _lastFetchPosition = position;
      
      // Cập nhật cache với kết quả mới
      final rooms = _roomFilterCubit.state.rooms;
      _updateRoomsCache(rooms, position);
      
      // Cập nhật markers chỉ khi không phải tải ngầm hoặc là lần tải đầu tiên
      if (showLoadingIndicator || (_lastFetchPosition == position && !_isBackgroundLoading)) {
        _updateRoomMarkersFromRooms(rooms);
      }
      
      print('Đã tải ${rooms.length} phòng cho vị trí hiện tại');
      
      // Tải trước dữ liệu cho các khu vực lân cận
      _preloadNearbyAreas(position);
    } catch (e) {
      print('Lỗi khi tải phòng: $e');
      if (showLoadingIndicator) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải phòng: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          if (showLoadingIndicator) {
            _isLoading = false;
          } else {
            _isBackgroundLoading = false;
          }
        });
      }
    }
  }

  // Cập nhật markers từ danh sách Room
  void _updateRoomMarkersFromRooms(List<Room> rooms) async {
    if (!_shouldShowRoomMarkers) {
      return; // Không hiển thị marker nếu zoom level không đủ cao
    }
    
    // Giữ lại các marker không phải phòng (marker vị trí người dùng, marker tìm kiếm)
    final preservedMarkers = _markers.where(
      (marker) => marker.markerId.value == 'user_location' || marker.markerId.value == 'search_result'
    ).toSet();
    
    // Tạo markers cho từng phòng
    final roomMarkers = <Marker>{};
    
    for (final room in rooms) {
      // Bỏ qua nếu không có tọa độ
      if (room.latitude == null || room.longitude == null) continue;
      
      // Lấy giá phòng, đảm bảo đơn vị là triệu đồng cho marker
      // Giả sử room.price đã được lưu dưới dạng triệu đồng (ví dụ: 3, 3.5, 4, ...)
      final double displayPrice = room.price;
      
      // Chuyển đổi Room thành RoomMarkerInfo
      final roomInfo = RoomMarkerInfo(
        id: room.id ?? '',
        latitude: room.latitude!,
        longitude: room.longitude!,
        title: room.title,
        address: room.address,
        price: displayPrice, // Giá được lưu dưới dạng triệu
        type: room.type == 'VIP' ? 'VIP' : 'GẦN', // Giả định
        thumbnailUrl: '', // Sẽ được cập nhật sau khi tải hình ảnh nếu có
        area: room.squareMeters.toInt(),
        bedrooms: room.maxPeople ~/ 2, // Giả định số phòng ngủ
      );
      
      // Tạo custom marker cho phòng
      BitmapDescriptor icon;
      if (_customRoomMarkers.containsKey(room.id)) {
        icon = _customRoomMarkers[room.id]!;
      } else {
        // Nếu chưa có custom marker, tạo mới
        icon = await _createCustomPriceMarker(roomInfo);
        if (room.id != null) {
          _customRoomMarkers[room.id!] = icon;
        }
      }
      
      // Tạo marker
      final marker = Marker(
        markerId: MarkerId(room.id ?? 'room_${room.title}_${room.latitude}_${room.longitude}'),
        position: LatLng(room.latitude!, room.longitude!),
        icon: icon,
        onTap: () {
          setState(() {
            _selectedRoomMarker = roomInfo;
            _showRoomInfo = true;
          });
        },
      );
      
      roomMarkers.add(marker);
    }
    
    // Cập nhật markers
    setState(() {
      _markers = {...preservedMarkers, ...roomMarkers};
    });
    
    print('Đã cập nhật ${roomMarkers.length} markers từ danh sách phòng');
  }

  // Hàm debounce để tránh gọi API quá nhiều lần
  void _debouncedFetchRooms(LatLng position, double zoom, [bool showLoadingIndicator = false]) {
    // Hủy timer cũ nếu có
    _cameraMovementTimer?.cancel();
    
    // Tạo timer mới
    _cameraMovementTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        _fetchRoomsBasedOnCameraPosition(position, zoom, showLoadingIndicator);
      }
    });
  }

  // Hàm ẩn tất cả room markers
  void _hideRoomMarkers() {
    // Giữ lại các marker không phải phòng
    final preservedMarkers = _markers.where(
      (marker) => marker.markerId.value == 'user_location' || marker.markerId.value == 'search_result'
    ).toSet();
    
    setState(() {
      _markers = preservedMarkers;
    });
  }

  
  // Hàm loại bỏ mã bưu chính và các số khỏi tên thành phố
  String _cleanCityName(String name) {
    // Loại bỏ mã bưu chính (thường là dãy số ở cuối)
    final cleanedName = name.replaceAll(RegExp(r'\s+\d+.*$'), '');
    
    // Loại bỏ phần phụ không cần thiết
    return cleanedName.replaceAll(RegExp(r'province|city|district|county', caseSensitive: false), '').trim();
  }

  // Tải trước dữ liệu cho các khu vực lân cận
  Future<void> _preloadNearbyAreas(LatLng centerPosition) async {
    // Mảng chứa các offset để tạo các điểm lân cận
    // Tạo 4 điểm theo 4 hướng chính: Bắc, Nam, Đông, Tây
    final offsets = [
      const Offset(0, 0.01),  // Bắc
      const Offset(0, -0.01), // Nam
      const Offset(0.01, 0),  // Đông
      const Offset(-0.01, 0), // Tây
    ];
    
    // Biến để theo dõi các grid cell đã tải
    final Set<String> preloadedCells = {};
    
    for (final offset in offsets) {
      // Tạo vị trí mới từ centerPosition
      final newPosition = LatLng(
        centerPosition.latitude + offset.dy,
        centerPosition.longitude + offset.dx,
      );
      
      // Lấy grid cell ID cho vị trí mới
      final cellId = _getGridCellId(newPosition);
      
      // Chỉ tải nếu chưa có trong cache và chưa được tải trước đó
      if (!_roomsCache.containsKey(cellId) && !preloadedCells.contains(cellId)) {
        preloadedCells.add(cellId);
        
        // Tính khoảng cách từ vị trí trung tâm
        final distance = _calculateDistance(centerPosition, newPosition);
        
        // Chỉ tải nếu vị trí mới cách xa vị trí cuối đủ xa
        if (distance > _minimumFetchDistanceInMeters) {
          print('Tải trước dữ liệu cho vị trí lân cận: (${newPosition.latitude}, ${newPosition.longitude})');
          
          // Sử dụng Future.delayed để không làm chậm UI thread
          Future.delayed(const Duration(milliseconds: 500), () {
            if (mounted) {
              _fetchRoomsBasedOnCameraPosition(newPosition, _currentZoom, false);
            }
          });
        }
      }
    }
  }

  // Mở ứng dụng bản đồ để chỉ đường đến vị trí phòng
  Future<void> _openMapsWithDirections(double latitude, double longitude) async {
    final url = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$latitude,$longitude'
    );
    
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không thể mở ứng dụng bản đồ')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi: $e')),
        );
      }
    }
  }

  // Điều hướng đến màn hình chi tiết phòng
  void _navigateToRoomDetails(String roomId) {
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => RoomDetailScreen(roomId: roomId),
        ),
      );
    }
  }
} 