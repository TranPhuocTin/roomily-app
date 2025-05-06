import 'package:equatable/equatable.dart';
import 'package:geolocator/geolocator.dart';
import 'package:roomily/core/services/search_service.dart';

enum MapStatus { initial, loading, loaded, error }

class MapState extends Equatable {
  final MapStatus status;
  final Position? currentPosition;
  final String? errorMessage;
  final bool isMapInitialized;
  
  // Camera state
  final double? lastZoom;
  final double? lastBearing;
  final double? lastPitch;
  final bool is3DMode;
  
  // Map style state
  final String? mapStyle;
  final bool isSatelliteMode;
  
  // Search results state
  final List<SearchResult> searchResults;
  final SearchResult? selectedLocation;
  final bool isSearching;
  
  // Marker state
  final double? markerLatitude;
  final double? markerLongitude;

  const MapState({
    this.status = MapStatus.initial,
    this.currentPosition,
    this.errorMessage,
    this.isMapInitialized = false,
    this.lastZoom,
    this.lastBearing,
    this.lastPitch,
    this.is3DMode = false,
    this.mapStyle,
    this.isSatelliteMode = false,
    this.searchResults = const [],
    this.selectedLocation,
    this.isSearching = false,
    this.markerLatitude,
    this.markerLongitude,
  });

  MapState copyWith({
    MapStatus? status,
    Position? currentPosition,
    String? errorMessage,
    bool? isMapInitialized,
    double? lastZoom,
    double? lastBearing,
    double? lastPitch,
    bool? is3DMode,
    String? mapStyle,
    bool? isSatelliteMode,
    List<SearchResult>? searchResults,
    SearchResult? selectedLocation,
    bool? isSearching,
    double? markerLatitude,
    double? markerLongitude,
  }) {
    return MapState(
      status: status ?? this.status,
      currentPosition: currentPosition ?? this.currentPosition,
      errorMessage: errorMessage ?? this.errorMessage,
      isMapInitialized: isMapInitialized ?? this.isMapInitialized,
      lastZoom: lastZoom ?? this.lastZoom,
      lastBearing: lastBearing ?? this.lastBearing,
      lastPitch: lastPitch ?? this.lastPitch,
      is3DMode: is3DMode ?? this.is3DMode,
      mapStyle: mapStyle ?? this.mapStyle,
      isSatelliteMode: isSatelliteMode ?? this.isSatelliteMode,
      searchResults: searchResults ?? this.searchResults,
      selectedLocation: selectedLocation ?? this.selectedLocation,
      isSearching: isSearching ?? this.isSearching,
      markerLatitude: markerLatitude ?? this.markerLatitude,
      markerLongitude: markerLongitude ?? this.markerLongitude,
    );
  }

  @override
  List<Object?> get props => [
        status, 
        currentPosition, 
        errorMessage, 
        isMapInitialized,
        lastZoom,
        lastBearing,
        lastPitch,
        is3DMode,
        mapStyle,
        isSatelliteMode,
        searchResults,
        selectedLocation,
        isSearching,
        markerLatitude,
        markerLongitude,
      ];
} 