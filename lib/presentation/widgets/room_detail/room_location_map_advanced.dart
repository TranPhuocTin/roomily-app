import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roomily/data/models/room_marker_info.dart';

class RoomLocationMapAdvanced extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? title;
  final String? address;
  final String? price;
  final double height;
  final VoidCallback? onMapTap;
  final String? markerIconAssetPath;

  const RoomLocationMapAdvanced({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.title,
    this.address,
    this.price,
    this.height = 200,
    this.onMapTap,
    this.markerIconAssetPath,
  }) : super(key: key);

  @override
  State<RoomLocationMapAdvanced> createState() => _RoomLocationMapAdvancedState();
}

class _RoomLocationMapAdvancedState extends State<RoomLocationMapAdvanced> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  BitmapDescriptor? _customMarkerIcon;
  
  @override
  void initState() {
    super.initState();
    _loadMarkerIcon();
  }
  
  Future<void> _loadMarkerIcon() async {
    try {
      if (widget.markerIconAssetPath != null) {
        // Sử dụng icon từ assets
        final Uint8List markerIconBytes = await _getBytesFromAsset(
          widget.markerIconAssetPath!,
          width: 120,
        );
        _customMarkerIcon = BitmapDescriptor.fromBytes(markerIconBytes);
      } else if (widget.price != null) {
        // Tạo custom marker với giá
        _customMarkerIcon = await _createCustomPriceMarker(widget.price!);
      } else {
        // Sử dụng default marker với màu đỏ mặc định
        _customMarkerIcon = BitmapDescriptor.defaultMarker;
      }
    } catch (e) {
      debugPrint('Error loading marker icon: $e');
      _customMarkerIcon = BitmapDescriptor.defaultMarker;
    } finally {
      _setMarkers();
    }
  }
  
  Future<Uint8List> _getBytesFromAsset(String path, {required int width}) async {
    ByteData data = await rootBundle.load(path);
    ui.Codec codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
    );
    ui.FrameInfo fi = await codec.getNextFrame();
    return (await fi.image.toByteData(format: ui.ImageByteFormat.png))!
        .buffer.asUint8List();
  }
  
  Future<BitmapDescriptor> _createCustomPriceMarker(String price) async {
    // Tạo một TextPainter để vẽ text
    TextSpan span = TextSpan(
      style: const TextStyle(
        color: Colors.white,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      text: price,
    );

    TextPainter painter = TextPainter(
      text: span,
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );
    painter.layout();

    // Tạo một Canvas để vẽ marker
    final ui.PictureRecorder pictureRecorder = ui.PictureRecorder();
    final Canvas canvas = Canvas(pictureRecorder);
    
    // Vẽ hình chữ nhật bo tròn góc màu tím
    final Paint bgPaint = Paint()..color = Colors.purple;
    final Rect rect = Rect.fromLTWH(0, 0, painter.width + 24, 30);
    final RRect rRect = RRect.fromRectAndRadius(
      rect,
      const Radius.circular(15),
    );
    canvas.drawRRect(rRect, bgPaint);
    
    // Vẽ tam giác nhỏ phía dưới để tạo hình khung chat
    final Paint trianglePaint = Paint()..color = Colors.purple;
    final Path trianglePath = Path();
    trianglePath.moveTo(painter.width / 2 + 6, 30);
    trianglePath.lineTo(painter.width / 2 + 16, 30);
    trianglePath.lineTo(painter.width / 2 + 12, 40);
    trianglePath.close();
    canvas.drawPath(trianglePath, trianglePaint);
    
    // Vẽ text
    painter.paint(canvas, const Offset(12, 8));

    // Chuyển đổi thành hình ảnh và trả về BitmapDescriptor
    final ui.Image image = await pictureRecorder.endRecording().toImage(
      (painter.width + 24).ceil(),
      40,
    );
    final ByteData? byteData = await image.toByteData(
      format: ui.ImageByteFormat.png,
    );
    
    return BitmapDescriptor.fromBytes(byteData!.buffer.asUint8List());
  }
  
  void _setMarkers() {
    if (!mounted) return;
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('room_location'),
          position: LatLng(widget.latitude, widget.longitude),
          icon: _customMarkerIcon ?? BitmapDescriptor.defaultMarker,
          infoWindow: InfoWindow(
            title: widget.title ?? 'Vị trí phòng',
            snippet: widget.address,
          ),
        ),
      };
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          GoogleMap(
            mapType: MapType.normal,
            initialCameraPosition: CameraPosition(
              target: LatLng(widget.latitude, widget.longitude),
              zoom: 16,
            ),
            markers: _markers,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            myLocationButtonEnabled: false,
            compassEnabled: false,
            onMapCreated: (GoogleMapController controller) {
              _controller.complete(controller);
            },
          ),
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onMapTap,
                highlightColor: Colors.transparent,
                splashColor: Colors.black.withOpacity(0.1),
              ),
            ),
          ),
          Positioned(
            right: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.fullscreen, size: 16, color: Colors.black54),
                  SizedBox(width: 4),
                  Text(
                    'Xem bản đồ lớn',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 