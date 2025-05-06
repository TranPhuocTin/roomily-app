// import 'package:flutter/services.dart';
// import 'package:mapbox_maps_flutter/mapbox_maps_flutter.dart';
// import 'dart:typed_data';
// import 'package:flutter/material.dart';
// import 'dart:ui' as ui;

// class RoomMarker {
//   final double latitude;
//   final double longitude;
//   final double price; // Giá phòng (triệu VND)
//   final String type; // Loại phòng: 'VIP' hoặc 'GẦN'
//   final String id;
//   // Thêm các thông tin chi tiết khác của phòng
//   final String? title;
//   final String? address;
//   final String? thumbnailUrl;
//   final int? area; // Diện tích (m²)
//   final int? bedrooms; // Số phòng ngủ

//   RoomMarker({
//     required this.latitude,
//     required this.longitude,
//     required this.price,
//     required this.type,
//     required this.id,
//     this.title,
//     this.address,
//     this.thumbnailUrl,
//     this.area,
//     this.bedrooms,
//   });
// }

// typedef OnRoomMarkerClickCallback = void Function(RoomMarker roomMarker);

// // Custom implementation of OnPointAnnotationClickListener
// class RoomMarkerClickListener extends OnPointAnnotationClickListener {
//   final Function(PointAnnotation) onClickHandler;
  
//   RoomMarkerClickListener(this.onClickHandler);
  
//   @override
//   bool onPointAnnotationClick(PointAnnotation annotation) {
//     onClickHandler(annotation);
//     return true;
//   }
// }

// class MarkerService {
//   PointAnnotationManager? _pointAnnotationManager;
//   PointAnnotation? _currentLocationMarker;
//   // Lưu trữ ánh xạ từ id của marker tới RoomMarker
//   final Map<String, RoomMarker> _roomMarkersMap = {};
//   // Lưu trữ ánh xạ từ id của PointAnnotation tới id của RoomMarker
//   final Map<String, String> _annotationToRoomMap = {};
//   MapboxMap? _mapboxMap;
//   OnRoomMarkerClickCallback? _onRoomMarkerClick;

//   // Hằng số khống chế việc vẽ lại marker
//   static const double _ZOOM_THRESHOLD = 0.5; // Chỉ vẽ lại nếu zoom thay đổi lớn hơn ngưỡng này
//   double? _lastZoomLevel;
  
//   // Mở rộng viewport để hiển thị thêm marker ở viền
//   static const double _VIEWPORT_PADDING = 100.0; // Đơn vị pixel

//   // Mock data cho khu vực Thanh Khê
//   final List<RoomMarker> mockRooms = [
//     RoomMarker(
//       latitude: 16.0673, 
//       longitude: 108.2097, 
//       price: 2.7, 
//       type: 'VIP',
//       id: '1',
//       title: 'Phòng đẹp gần chợ Thanh Khê',
//       address: '123 Hải Phòng, Thanh Khê, Đà Nẵng',
//       thumbnailUrl: 'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8NHx8YXBhcnRtZW50fGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
//       area: 30,
//       bedrooms: 1,
//     ), // Gần chợ Thanh Khê
//     RoomMarker(
//       latitude: 16.0712, 
//       longitude: 108.2054, 
//       price: 2.3, 
//       type: 'GẦN',
//       id: '2',
//       title: 'Phòng giá rẻ gần đường Lê Duẩn',
//       address: '45 Lê Duẩn, Thanh Khê, Đà Nẵng',
//       thumbnailUrl: 'https://images.unsplash.com/photo-1560448204-e02f11c3d0e2?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MjN8fGFwYXJ0bWVudHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
//       area: 25,
//       bedrooms: 1,
//     ), // Gần đường Lê Duẩn
//     RoomMarker(
//       latitude: 16.0654, 
//       longitude: 108.2145, 
//       price: 3.1, 
//       type: 'VIP',
//       id: '3',
//       title: 'Căn hộ cao cấp khu vực Hải Phòng',
//       address: '78 Hải Phòng, Thanh Khê, Đà Nẵng',
//       thumbnailUrl: 'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8Mnx8YXBhcnRtZW50fGVufDB8fDB8fHww&auto=format&fit=crop&w=500&q=60',
//       area: 45,
//       bedrooms: 2,
//     ), // Khu vực Hải Phòng
//     RoomMarker(
//       latitude: 16.0689, 
//       longitude: 108.2078, 
//       price: 1.9, 
//       type: 'GẦN',
//       id: '4',
//       title: 'Phòng sinh viên gần trường THPT Thanh Khê',
//       address: '22 Nguyễn Tất Thành, Thanh Khê, Đà Nẵng',
//       thumbnailUrl: 'https://images.unsplash.com/photo-1493809842364-78817add7ffb?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MTF8fGFwYXJ0bWVudHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
//       area: 20,
//       bedrooms: 1,
//     ), // Gần trường THPT Thanh Khê
//     RoomMarker(
//       latitude: 16.0701, 
//       longitude: 108.2123, 
//       price: 2.5, 
//       type: 'VIP',
//       id: '5',
//       title: 'Căn hộ dịch vụ khu vực Nguyễn Tất Thành',
//       address: '56 Nguyễn Tất Thành, Thanh Khê, Đà Nẵng',
//       thumbnailUrl: 'https://images.unsplash.com/photo-1560185007-5f0bb1866cab?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxzZWFyY2h8MzR8fGFwYXJ0bWVudHxlbnwwfHwwfHx8MA%3D%3D&auto=format&fit=crop&w=500&q=60',
//       area: 35,
//       bedrooms: 1,
//     ), // Khu vực Nguyễn Tất Thành
//   ];

//   Future<void> initialize(MapboxMap mapboxMap) async {
//     _mapboxMap = mapboxMap;
//     _pointAnnotationManager = await mapboxMap.annotations.createPointAnnotationManager();
    
//     // Thêm listener cho sự kiện click vào marker
//     _setupClickListener();
//   }
  
//   void _setupClickListener() {
//     if (_pointAnnotationManager == null) return;
    
//     // Sử dụng lớp triển khai thực thay vì trực tiếp khởi tạo lớp trừu tượng
//     _pointAnnotationManager!.addOnPointAnnotationClickListener(
//       RoomMarkerClickListener(_handleMarkerClick)
//     );
//   }

//   // Thiết lập callback khi click vào room marker
//   void setOnRoomMarkerClickListener(OnRoomMarkerClickCallback callback) {
//     _onRoomMarkerClick = callback;
//   }

//   // Xử lý sự kiện click vào marker
//   void _handleMarkerClick(PointAnnotation annotation) {
//     final String? annotationId = annotation.id;
//     if (annotationId != null && _annotationToRoomMap.containsKey(annotationId)) {
//       final String roomId = _annotationToRoomMap[annotationId]!;
//       if (_roomMarkersMap.containsKey(roomId)) {
//         final RoomMarker roomMarker = _roomMarkersMap[roomId]!;
//         if (_onRoomMarkerClick != null) {
//           _onRoomMarkerClick!(roomMarker);
//         }
//       }
//     }
//   }

//   // Cập nhật nhóm rooms từ API
//   Future<void> updateRooms(List<RoomMarker> rooms) async {
//     // Cập nhật danh sách rooms mới
//     _roomMarkersMap.clear();
//     for (var room in rooms) {
//       _roomMarkersMap[room.id] = room;
//     }
    
//     // Vẽ lại markers với dữ liệu mới
//     if (_mapboxMap != null) {
//       final cameraState = await _mapboxMap!.getCameraState();
//       await _updateVisibleMarkers(cameraState.zoom);
//     }
//   }

//   // Tính toán kích thước marker dựa trên zoom level
//   double _calculateMarkerSize(double zoom) {
//     // Các mức zoom tham chiếu
//     const double minZoom = 10.0;
//     const double maxZoom = 18.0;
    
//     // Các kích thước marker tương ứng
//     const double minSize = 1.0; // Kích thước tối thiểu
//     const double maxSize = 4.0; // Kích thước tối đa
    
//     // Giới hạn zoom trong khoảng xác định
//     double currentZoom = zoom.clamp(minZoom, maxZoom);
    
//     // Tính toán kích thước dựa trên tỷ lệ zoom theo hàm mũ bậc 3
//     double zoomRatio = (currentZoom - minZoom) / (maxZoom - minZoom);
//     double size = minSize + (maxSize - minSize) * (zoomRatio * zoomRatio * zoomRatio);
    
//     return size;
//   }
  
//   // Kiểm tra xem có cần phải vẽ lại marker không dựa trên sự thay đổi zoom
//   bool _shouldRefreshMarkers(double zoom) {
//     if (_lastZoomLevel == null) {
//       return true;
//     }
    
//     if ((zoom - _lastZoomLevel!).abs() > _ZOOM_THRESHOLD) {
//       return true;
//     }
    
//     return false;
//   }

//   // Lọc các markers trong viewport hiện tại (đơn giản hóa)
//   // Trong thực tế, nếu có nhiều dữ liệu, nên mở rộng và thực hiện lọc dữ liệu ở phía server
//   List<RoomMarker> _filterVisibleRooms(List<RoomMarker> rooms) {
//     if (rooms.length <= 50) {
//       // Nếu số lượng marker ít, hiển thị tất cả để đảm bảo không bị thiếu
//       return rooms;
//     }
    
//     // Nếu số lượng marker nhiều, thực hiện lọc theo tiêu chí (ví dụ: ưu tiên VIP)
//     final vipRooms = rooms.where((room) => room.type == 'VIP').toList();
//     final normalRooms = rooms.where((room) => room.type != 'VIP').toList();
    
//     // Giới hạn số lượng marker hiển thị
//     const int maxMarkersToShow = 50;
    
//     // Ưu tiên hiển thị VIP
//     final result = <RoomMarker>[];
    
//     // Thêm tất cả phòng VIP
//     result.addAll(vipRooms);
    
//     // Nếu còn chỗ, thêm các phòng thường
//     if (result.length < maxMarkersToShow) {
//       result.addAll(normalRooms.take(maxMarkersToShow - result.length));
//     }
    
//     return result;
//   }

//   // Cập nhật các marker trong vùng nhìn thấy
//   Future<void> _updateVisibleMarkers(double zoom) async {
//     if (_pointAnnotationManager == null) {
//       throw Exception('PointAnnotationManager chưa được khởi tạo');
//     }
    
//     // Kiểm tra xem có cần cập nhật không
//     if (!_shouldRefreshMarkers(zoom)) {
//       return;
//     }
    
//     // Cập nhật biến tracking
//     _lastZoomLevel = zoom;
    
//     // Tính toán kích thước marker dựa trên zoom
//     double markerSize = _calculateMarkerSize(zoom);
    
//     // Xóa tất cả marker hiện tại
//     await _pointAnnotationManager!.deleteAll();
//     _annotationToRoomMap.clear();
    
//     // Lấy danh sách rooms từ mock data nếu chưa có danh sách từ API
//     final roomsToDisplay = _roomMarkersMap.isEmpty 
//         ? mockRooms 
//         : _roomMarkersMap.values.toList();
    
//     // Lọc các rooms sẽ hiển thị
//     final visibleRooms = _filterVisibleRooms(roomsToDisplay);
    
//     // Thêm các room markers trong vùng hiển thị
//     for (var room in visibleRooms) {
//       try {
//         // Tạo hình ảnh cho marker
//         final Uint8List markerImage = await _createRoomMarkerImage(
//           price: room.price,
//           type: room.type,
//         );

//         final options = PointAnnotationOptions(
//           geometry: Point(coordinates: Position(room.longitude, room.latitude)),
//           image: markerImage,
//           iconSize: markerSize,
//           iconOffset: [0, -20],
//           iconAnchor: IconAnchor.BOTTOM,
//         );

//         final marker = await _pointAnnotationManager!.create(options);
        
//         // Lưu ánh xạ từ annotation id tới room id
//         if (marker.id != null) {
//           _annotationToRoomMap[marker.id!] = room.id;
//         }
        
//         // Nếu room chưa có trong map, thêm vào
//         if (!_roomMarkersMap.containsKey(room.id)) {
//           _roomMarkersMap[room.id] = room;
//         }
//       } catch (e) {
//         print('Lỗi khi tạo room marker: $e');
//       }
//     }
//   }

//   // Cập nhật markers khi camera thay đổi
//   Future<void> updateCameraPosition(double zoom) async {
//     await _updateVisibleMarkers(zoom);
//   }

//   // Phương thức tương thích với cách gọi cũ
//   Future<void> showRoomMarkers({double? zoom}) async {
//     if (_mapboxMap == null) return;
    
//     final currentZoom = zoom ?? (await _mapboxMap!.getCameraState()).zoom;
//     await _updateVisibleMarkers(currentZoom);
//   }

//   Future<void> addLocationMarker(double latitude, double longitude) async {
//     if (_pointAnnotationManager == null) {
//       throw Exception('PointAnnotationManager chưa được khởi tạo');
//     }

//     // Xóa marker cũ nếu có
//     if (_currentLocationMarker != null) {
//       await _pointAnnotationManager!.delete(_currentLocationMarker!);
//     }

//     try {
//       final ByteData bytes = await rootBundle.load('assets/icons/map_active_icon.png');
//       final Uint8List markerIcon = bytes.buffer.asUint8List();

//       final options = PointAnnotationOptions(
//         geometry: Point(coordinates: Position(longitude, latitude)),
//         image: markerIcon,
//         iconSize: 1.0,
//       );

//       _currentLocationMarker = await _pointAnnotationManager!.create(options);
//     } catch (e) {
//       print('Lỗi khi tạo marker vị trí: $e');
//       throw Exception('Không thể tạo marker vị trí: $e');
//     }
//   }

//   Future<Uint8List> _createRoomMarkerImage({
//     required double price,
//     required String type,
//   }) async {
//     // Kích thước tổng thể của marker
//     const double width = 240;
//     const double height = 80;
//     const double circleSize = 80; // Kích thước phần tròn bên trái
//     const double arrowSize = 15; // Kích thước mũi tên ở dưới
    
//     final recorder = ui.PictureRecorder();
//     final canvas = Canvas(recorder);
    
//     // Tạo đường dẫn cho toàn bộ marker (hình chữ nhật với góc bo tròn)
//     final path = Path();
    
//     // Vẽ hình chữ nhật chính với góc bo tròn
//     final rrect = RRect.fromRectAndRadius(
//       Rect.fromLTWH(0, 0, width, height),
//       const Radius.circular(20), // Bo tròn góc lớn hơn
//     );
    
//     // Vẽ mũi tên ở dưới
//     path.addRRect(rrect);
//     path.moveTo(width / 2 - arrowSize, height);
//     path.lineTo(width / 2, height + arrowSize);
//     path.lineTo(width / 2 + arrowSize, height);
//     path.close();
    
//     // Vẽ đổ bóng
//     canvas.drawShadow(path, Colors.black.withOpacity(0.3), 8, true);
    
//     // Vẽ nền chính của marker (màu trắng với viền xanh lá)
//     final borderPaint = Paint()
//       ..color = type == 'VIP' ? Colors.red : Color(0xFF00FF66) // Màu xanh lá cho GẦN
//       ..style = PaintingStyle.stroke
//       ..strokeWidth = 3;
    
//     final bgPaint = Paint()
//       ..color = Colors.white
//       ..style = PaintingStyle.fill;
    
//     canvas.drawPath(path, bgPaint);
//     canvas.drawRRect(rrect, borderPaint);
    
//     // Vẽ đường viền cho mũi tên
//     final arrowPath = Path();
//     arrowPath.moveTo(width / 2 - arrowSize, height);
//     arrowPath.lineTo(width / 2, height + arrowSize);
//     arrowPath.lineTo(width / 2 + arrowSize, height);
//     canvas.drawPath(arrowPath, borderPaint);
    
//     // Vẽ hình tròn bên trái
//     final circlePaint = Paint()
//       ..color = type == 'VIP' ? Colors.red.withOpacity(0.1) : Color(0xFFE6FFF0) // Màu nền nhạt cho hình tròn
//       ..style = PaintingStyle.fill;
    
//     canvas.drawCircle(
//       Offset(circleSize / 2, height / 2),
//       circleSize / 2 - 10, // Giảm bán kính để tạo khoảng cách với viền
//       circlePaint
//     );
    
//     // Vẽ text "GẦN" hoặc "VIP" trong hình tròn
//     final typeTextPainter = TextPainter(
//       text: TextSpan(
//         text: type,
//         style: TextStyle(
//           color: type == 'VIP' ? Colors.red : Color(0xFF00FF66),
//           fontSize: 24,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       textAlign: TextAlign.center,
//       textDirection: TextDirection.ltr,
//     );
    
//     typeTextPainter.layout();
//     typeTextPainter.paint(
//       canvas,
//       Offset(
//         circleSize / 2 - typeTextPainter.width / 2,
//         height / 2 - typeTextPainter.height / 2
//       ),
//     );
    
//     // Vẽ text giá bên phải
//     // Tách phần nguyên và phần thập phân của giá
//     int priceInt = price.toInt();
//     int priceDecimal = ((price - priceInt) * 10).round();
    
//     final priceTextPainter = TextPainter(
//       text: TextSpan(
//         text: '$priceInt Triệu $priceDecimal',
//         style: const TextStyle(
//           color: Colors.black,
//           fontSize: 24,
//           fontWeight: FontWeight.bold,
//         ),
//       ),
//       textAlign: TextAlign.center,
//       textDirection: TextDirection.ltr,
//     );
    
//     priceTextPainter.layout(
//       minWidth: width - circleSize - 20,
//       maxWidth: width - circleSize - 20,
//     );
    
//     priceTextPainter.paint(
//       canvas,
//       Offset(
//         circleSize + 10,
//         height / 2 - priceTextPainter.height / 2
//       ),
//     );
    
//     // Chuyển đổi thành hình ảnh
//     final picture = recorder.endRecording();
//     final img = await picture.toImage(width.toInt(), (height + arrowSize).toInt());
//     final pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);
    
//     return pngBytes!.buffer.asUint8List();
//   }

//   void dispose() {
//     _pointAnnotationManager = null;
//     _currentLocationMarker = null;
//     _roomMarkersMap.clear();
//     _annotationToRoomMap.clear();
//     _mapboxMap = null;
//     _onRoomMarkerClick = null;
//   }
// }