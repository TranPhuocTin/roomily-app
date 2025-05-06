import 'package:flutter/material.dart';

class MapBottomControls extends StatelessWidget {
  final VoidCallback onLocationPressed;
  final VoidCallback onMapTypePressed;
  final VoidCallback on3DModePressed;
  final bool isSatelliteMode;
  final bool is3DMode;
  
  const MapBottomControls({
    super.key,
    required this.onLocationPressed,
    required this.onMapTypePressed,
    required this.on3DModePressed,
    required this.isSatelliteMode,
    required this.is3DMode,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FloatingActionButton(
          mini: true,
          heroTag: 'location',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          onPressed: onLocationPressed,
          child: const Icon(Icons.my_location),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: 'mapType',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          onPressed: onMapTypePressed,
          child: Icon(isSatelliteMode ? Icons.map : Icons.satellite),
        ),
        const SizedBox(height: 8),
        FloatingActionButton(
          mini: true,
          heroTag: '3D',
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          onPressed: on3DModePressed,
          child: Icon(is3DMode ? Icons.view_in_ar : Icons.view_in_ar_outlined),
        ),
      ],
    );
  }
}

