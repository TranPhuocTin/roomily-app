import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RoomLocationMap extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String? title;
  final String? address;
  final double height;
  final VoidCallback? onMapTap;

  const RoomLocationMap({
    Key? key,
    required this.latitude,
    required this.longitude,
    this.title,
    this.address,
    this.height = 200,
    this.onMapTap,
  }) : super(key: key);

  @override
  State<RoomLocationMap> createState() => _RoomLocationMapState();
}

class _RoomLocationMapState extends State<RoomLocationMap> {
  final Completer<GoogleMapController> _controller = Completer<GoogleMapController>();
  Set<Marker> _markers = {};
  
  @override
  void initState() {
    super.initState();
    _setMarkers();
  }
  
  void _setMarkers() {
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('room_location'),
          position: LatLng(widget.latitude, widget.longitude),
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
            color: Colors.grey.withOpacity(0.3),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: GestureDetector(
        onTap: widget.onMapTap,
        child: GoogleMap(
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
      ),
    );
  }
} 