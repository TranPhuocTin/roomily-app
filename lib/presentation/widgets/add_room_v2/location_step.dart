import 'package:flutter/material.dart';
import 'dart:math';
import 'package:get_it/get_it.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:roomily/core/services/location_service.dart';
import 'package:roomily/core/services/google_places_service.dart';
import 'package:roomily/core/services/province_mapper.dart';
import 'package:roomily/data/repositories/google_places_repository.dart';
import 'package:roomily/data/models/place_autocomplete_result.dart';
import 'package:roomily/data/models/place_details.dart';

// Import color scheme
import 'package:roomily/presentation/screens/add_room_screen_v2.dart';

class LocationStep extends StatefulWidget {
  final TextEditingController addressController;
  final TextEditingController cityController;
  final TextEditingController districtController;
  final TextEditingController wardController;
  
  // These controllers still store the coordinates, but they're not displayed in the UI
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  
  final Function(bool isLoading)? onLoadingChanged;
  
  // UI Constants
  static const Color primaryColor = RoomColorScheme.location;
  static const Color textColor = RoomColorScheme.text;
  static const Color surfaceColor = RoomColorScheme.surface;

  const LocationStep({
    Key? key,
    required this.addressController,
    required this.cityController,
    required this.districtController,
    required this.wardController,
    required this.latitudeController,
    required this.longitudeController,
    this.onLoadingChanged,
  }) : super(key: key);

  @override
  State<LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<LocationStep> {
  bool _isGettingLocation = false;
  bool _isSearching = false;
  String? _locationError;
  LatLng? _selectedLocation;
  final TextEditingController _searchController = TextEditingController();
  List<PlaceAutocompleteResult> _searchResults = [];
  bool _showSearchResults = false;
  
  late GooglePlacesService _googlePlacesService;
  late ProvinceMapper _provinceMapper;
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  
  // Province selection state
  List<Map<String, dynamic>> _provinces = [];
  List<Map<String, dynamic>> _districts = [];
  List<Map<String, dynamic>> _wards = [];
  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;
  
  @override
  void initState() {
    super.initState();
    _initGooglePlacesService();
    _initProvinceMapper();
    _loadProvinces();
    
    // Initialize the map with coordinates if available
    if (widget.latitudeController.text.isNotEmpty && 
        widget.longitudeController.text.isNotEmpty) {
      _selectedLocation = LatLng(
        double.parse(widget.latitudeController.text),
        double.parse(widget.longitudeController.text)
      );
      _updateMarkers();
    }
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
    
    // Khôi phục dữ liệu quận/huyện và phường/xã nếu đã có
    _restoreLocationData();
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _mapController?.dispose();
    super.dispose();
  }
  
  void _initGooglePlacesService() {
    final googlePlacesRepository = GetIt.instance<GooglePlacesRepository>();
    _googlePlacesService = GooglePlacesService(repository: googlePlacesRepository);
  }
  
  void _initProvinceMapper() {
    _provinceMapper = GetIt.instance<ProvinceMapper>();
  }
  
  // Load provinces for dropdowns
  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingProvinces = true;
    });
    
    try {
      final locationService = GetIt.instance<LocationService>();
      final provinces = await locationService.getProvinces();
      
      setState(() {
        _provinces = provinces;
        _isLoadingProvinces = false;
      });
      
      // Nếu đang trong chế độ cập nhật (đã có dữ liệu địa chỉ), khôi phục dữ liệu
      if (widget.cityController.text.isNotEmpty) {
        // Đợi một chút để đảm bảo UI đã cập nhật
        await Future.delayed(Duration(milliseconds: 100));
        _restoreProvinceData();
      }
    } catch (e) {
      setState(() {
        _isLoadingProvinces = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể tải danh sách tỉnh/thành phố: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  
  // Load districts for a province
  Future<void> _loadDistricts(int provinceCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _wards = [];
    });
    
    try {
      final locationService = GetIt.instance<LocationService>();
      final districts = await locationService.getDistricts(provinceCode);
      
      setState(() {
        _districts = districts;
        _isLoadingDistricts = false;
      });
      
      // Nếu đã có dữ liệu quận/huyện trong controller, tìm và chọn lại
      if (widget.districtController.text.isNotEmpty) {
        // Đợi một chút để đảm bảo UI đã cập nhật danh sách quận/huyện
        await Future.delayed(Duration(milliseconds: 100));
        
        print("DEBUG: In _loadDistricts - Looking for district: '${widget.districtController.text}' among ${districts.length} districts");
        
        // Tìm chính xác
        var matchingDistrict = _districts.firstWhere(
          (district) => district['name'].toString().trim().toLowerCase() == widget.districtController.text.trim().toLowerCase(),
          orElse: () => {},
        );
        
        // Nếu không tìm thấy chính xác, thử tìm kiếm tương đối
        if (matchingDistrict.isEmpty) {
          print("DEBUG: Exact match not found, trying partial match for district");
          final similarDistricts = _districts.where(
            (district) => district['name'].toString().toLowerCase().contains(
              widget.districtController.text.trim().toLowerCase()
            ) || widget.districtController.text.trim().toLowerCase().contains(
              district['name'].toString().toLowerCase()
            )
          ).toList();
          
          if (similarDistricts.isNotEmpty) {
            matchingDistrict = similarDistricts.first;
            print("DEBUG: Found similar district: ${matchingDistrict['name']}");
            
            // Cập nhật controller với tên chính xác từ API
            setState(() {
              widget.districtController.text = matchingDistrict['name'].toString();
            });
          }
        }
        
        if (matchingDistrict.isNotEmpty && matchingDistrict.containsKey('code')) {
          print("DEBUG: Loading wards for district: ${matchingDistrict['name']} (${matchingDistrict['code']})");
          _loadWards(matchingDistrict['code']);
        } else {
          print("DEBUG: No matching district found for '${widget.districtController.text}'");
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingDistricts = false;
      });
      print('Error loading districts: $e');
    }
  }
  
  // Load wards for a district
  Future<void> _loadWards(int districtCode) async {
    setState(() {
      _isLoadingWards = true;
      _wards = [];
    });
    
    try {
      final locationService = GetIt.instance<LocationService>();
      final wards = await locationService.getWards(districtCode);
      
      setState(() {
        _wards = wards;
        _isLoadingWards = false;
      });
      
      // Nếu đã có dữ liệu phường/xã trong controller, chọn lại
      if (widget.wardController.text.isNotEmpty) {
        // Đợi một chút để đảm bảo UI đã cập nhật danh sách phường/xã
        await Future.delayed(Duration(milliseconds: 100));
        
        print("DEBUG: In _loadWards - Looking for ward: '${widget.wardController.text}' among ${wards.length} wards");
        
        // Tìm chính xác
        var matchingWard = _wards.firstWhere(
          (ward) => ward['name'].toString().trim().toLowerCase() == widget.wardController.text.trim().toLowerCase(),
          orElse: () => {},
        );
        
        // Nếu không tìm thấy chính xác, thử tìm kiếm tương đối
        if (matchingWard.isEmpty) {
          print("DEBUG: Exact match not found, trying partial match for ward");
          final similarWards = _wards.where(
            (ward) => ward['name'].toString().toLowerCase().contains(
              widget.wardController.text.trim().toLowerCase()
            ) || widget.wardController.text.trim().toLowerCase().contains(
              ward['name'].toString().toLowerCase()
            )
          ).toList();
          
          if (similarWards.isNotEmpty) {
            matchingWard = similarWards.first;
            print("DEBUG: Found similar ward: ${matchingWard['name']}");
            
            // Cập nhật controller với tên chính xác từ API
            setState(() {
              widget.wardController.text = matchingWard['name'].toString();
            });
          } else {
            print("DEBUG: No similar ward found for '${widget.wardController.text}'");
          }
        } else {
          print("DEBUG: Found exact matching ward: ${matchingWard['name']}");
        }
      }
    } catch (e) {
      setState(() {
        _isLoadingWards = false;
      });
      print('Error loading wards: $e');
    }
  }
  
  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _searchPlaces(_searchController.text);
    } else {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
    }
  }
  
  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) return;
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await _googlePlacesService.getPlaceAutocomplete(query);
      setState(() {
        _searchResults = results;
        _showSearchResults = results.isNotEmpty;
        _isSearching = false;
      });
    } catch (e) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
    }
  }
  
  Future<void> _onLocationSelected(PlaceAutocompleteResult result) async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
      _showSearchResults = false;
    });
    
    if (widget.onLoadingChanged != null) {
      widget.onLoadingChanged!(true);
    }
    
    try {
      final details = await _googlePlacesService.getPlaceDetails(result.placeId);
      if (details != null) {
        // Only update the map and coordinates
        _updateLocationDetails(details);
      }
    } catch (e) {
      setState(() {
        _locationError = 'Không thể lấy chi tiết địa điểm: $e';
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
      
      if (widget.onLoadingChanged != null) {
        widget.onLoadingChanged!(false);
      }
    }
  }

  // Lấy vị trí hiện tại và thực hiện reverse geocoding
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
    });
    
    if (widget.onLoadingChanged != null) {
      widget.onLoadingChanged!(true);
    }

    try {
      // Get current location
      final locationService = GetIt.instance<LocationService>();
      final position = await locationService.getCurrentPosition();
      
      if (position == null) {
        setState(() {
          _locationError = 'Không thể lấy vị trí hiện tại. Vui lòng kiểm tra quyền vị trí và GPS.';
          _isGettingLocation = false;
        });
        if (widget.onLoadingChanged != null) {
          widget.onLoadingChanged!(false);
        }
        return;
      }
      
      // Update latitude and longitude
      widget.latitudeController.text = position.latitude.toString();
      widget.longitudeController.text = position.longitude.toString();
      
      // Update selected location on map
      _selectedLocation = LatLng(position.latitude, position.longitude);
      _updateMarkers();
      _animateCameraToLocation(_selectedLocation!);
      
      // Perform reverse geocoding only to get a possible address - but not to fill dropdowns
      try {
        final placeDetails = await _googlePlacesService.reverseGeocode(position.latitude, position.longitude);
        
        if (placeDetails != null) {
          // Only update the map and coordinates
          _updateLocationDetails(placeDetails);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Đã lấy tọa độ nhưng không thể xác định địa chỉ. Vui lòng nhập thông tin địa chỉ thủ công.'),
              backgroundColor: RoomColorScheme.warning,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        _locationError = 'Lỗi khi xác định địa chỉ: $e';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Không thể xác định địa chỉ từ vị trí. Vui lòng nhập thông tin địa chỉ thủ công.'),
            backgroundColor: RoomColorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _locationError = 'Lỗi: $e';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Không thể lấy vị trí: $e'),
          backgroundColor: RoomColorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
      
      if (widget.onLoadingChanged != null) {
        widget.onLoadingChanged!(false);
      }
    }
  }
  
  void _updateLocationDetails(PlaceDetails details) async {
    // Only update latitude, longitude and map marker
    widget.latitudeController.text = details.latitude.toString();
    widget.longitudeController.text = details.longitude.toString();
    
    // Update map marker
    _selectedLocation = LatLng(details.latitude, details.longitude);
    _updateMarkers();
    _animateCameraToLocation(_selectedLocation!);
    
    // Notify user to manually enter address
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Đã cập nhật vị trí. Vui lòng nhập thông tin địa chỉ thủ công.'),
        backgroundColor: RoomColorScheme.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  
  void _onMapTap(LatLng position) async {
    setState(() {
      _isGettingLocation = true;
      _locationError = null;
      _selectedLocation = position;
    });
    
    if (widget.onLoadingChanged != null) {
      widget.onLoadingChanged!(true);
    }
    
    _updateMarkers();
    
    try {
      widget.latitudeController.text = position.latitude.toString();
      widget.longitudeController.text = position.longitude.toString();
      
      final placeDetails = await _googlePlacesService.reverseGeocode(position.latitude, position.longitude);
      
      if (placeDetails != null) {
        // Only update the map and coordinates
        _updateLocationDetails(placeDetails);
      } else {
        // If reverse geocoding fails, still keep the coordinates
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Đã lấy tọa độ nhưng không thể xác định địa chỉ. Vui lòng nhập thông tin địa chỉ thủ công.'),
            backgroundColor: RoomColorScheme.warning,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _locationError = 'Lỗi khi xác định địa chỉ: $e';
      });
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
      
      if (widget.onLoadingChanged != null) {
        widget.onLoadingChanged!(false);
      }
    }
  }
  
  void _updateMarkers() {
    if (_selectedLocation == null) return;
    
    setState(() {
      _markers = {
        Marker(
          markerId: const MarkerId('selected_location'),
          position: _selectedLocation!,
          infoWindow: InfoWindow(
            title: 'Vị trí đã chọn',
            snippet: widget.addressController.text,
          ),
        ),
      };
    });
  }
  
  void _animateCameraToLocation(LatLng location) {
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: location,
          zoom: 16.0,
        ),
      ),
    );
  }
  
  // Phân tích chuỗi địa chỉ thành các thành phần riêng biệt
  Map<String, String> _parseAddress(String fullAddress) {
    final result = <String, String>{};
    final parts = fullAddress.split(', ');
    
    debugPrint('🔍 Parsing address: "$fullAddress"');
    debugPrint('🔍 Parts: ${parts.join(' | ')}');
    
    // Mảng lưu thông tin địa chỉ theo thứ tự từ nhỏ đến lớn
    // Thường theo định dạng: [số nhà + đường], [phường/xã], [quận/huyện], [thành phố/tỉnh], [quốc gia]
    if (parts.length >= 4) {
      // Thành phố thường là phần áp chót (trước quốc gia)
      String city = parts[parts.length - 2];
      // Loại bỏ mã bưu điện (thường là các chữ số ở cuối)
      city = _removePostalCode(city);
      result['city'] = city;
      
      // Quận/huyện thường là phần trước thành phố
      result['district'] = parts[parts.length - 3];
      
      // Phường/xã thường là phần trước quận/huyện
      if (parts.length >= 5) {
        result['ward'] = parts[parts.length - 4];
        
        // Địa chỉ chi tiết là phần còn lại (nếu có)
        if (parts.length > 5) {
          result['address'] = parts.sublist(0, parts.length - 4).join(', ');
        } else {
          result['address'] = parts[0];
        }
      } else {
        // Trường hợp ít thông tin hơn, kiểm tra nếu phần đầu có dấu hiệu của phường/xã
        final firstPart = parts[0].toLowerCase();
        if (firstPart.contains('phường') || firstPart.contains('phuong') || 
            firstPart.contains('xã') || firstPart.contains('xa') ||
            firstPart.contains('ward')) {
          result['ward'] = parts[0];
          // Địa chỉ là phần thứ hai nếu có
          if (parts.length > 1) {
            result['address'] = parts[1];
          } else {
            result['address'] = '';
          }
        } else {
          result['address'] = parts[0];
        }
      }
    } else if (parts.length == 3) {
      // Trường hợp ít thông tin hơn
      String city = parts[2];
      city = _removePostalCode(city);
      result['city'] = city;
      
      // Phần giữa có thể là quận/huyện hoặc phường/xã
      final middlePart = parts[1].toLowerCase();
      if (middlePart.contains('quận') || middlePart.contains('quan') || 
          middlePart.contains('huyện') || middlePart.contains('huyen') ||
          middlePart.contains('district')) {
        result['district'] = parts[1];
      } else if (middlePart.contains('phường') || middlePart.contains('phuong') || 
                middlePart.contains('xã') || middlePart.contains('xa') ||
                middlePart.contains('ward')) {
        result['ward'] = parts[1];
      }
      
      result['address'] = parts[0];
    } else if (parts.length == 2) {
      String city = parts[1];
      city = _removePostalCode(city);
      result['city'] = city;
      result['address'] = parts[0];
    } else {
      result['address'] = fullAddress;
    }
    
    // Log final parsed components
    debugPrint('📍 Parsed address components:');
    debugPrint('   - City: "${result['city'] ?? 'N/A'}"');
    debugPrint('   - District: "${result['district'] ?? 'N/A'}"');
    debugPrint('   - Ward: "${result['ward'] ?? 'N/A'}"');
    debugPrint('   - Address: "${result['address'] ?? 'N/A'}"');
    
    return result;
  }
  
  // Loại bỏ mã bưu điện khỏi tên thành phố
  String _removePostalCode(String cityWithPostalCode) {
    // Tách chuỗi bởi khoảng trắng
    final parts = cityWithPostalCode.split(' ');
    
    // Nếu phần cuối cùng là số, có thể đó là mã bưu điện
    if (parts.isNotEmpty && _isNumeric(parts.last)) {
      // Loại bỏ phần cuối và ghép lại
      return parts.sublist(0, parts.length - 1).join(' ');
    }
    
    return cityWithPostalCode;
  }
  
  // Kiểm tra chuỗi có phải là số không
  bool _isNumeric(String str) {
    if (str.isEmpty) return false;
    return int.tryParse(str) != null;
  }
  
  // Mở map ở chế độ toàn màn hình
  void _openFullscreenMap() {
    // Clear any previous search data
    _searchController.clear();
    
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => _FullscreenMapPicker(
          initialLocation: _selectedLocation ?? LatLng(
            double.tryParse(widget.latitudeController.text) ?? 10.7769,
            double.tryParse(widget.longitudeController.text) ?? 106.7009,
          ),
          onLocationSelected: (LatLng location) async {
            setState(() {
              _isGettingLocation = true;
              _locationError = null;
              _selectedLocation = location;
            });
            
            if (widget.onLoadingChanged != null) {
              widget.onLoadingChanged!(true);
            }
            
            _updateMarkers();
            
            try {
              widget.latitudeController.text = location.latitude.toString();
              widget.longitudeController.text = location.longitude.toString();
              
              final placeDetails = await _googlePlacesService.reverseGeocode(location.latitude, location.longitude);
              
              if (placeDetails != null) {
                // Only update the map and coordinates
                _updateLocationDetails(placeDetails);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Đã lấy tọa độ nhưng không thể xác định địa chỉ. Vui lòng nhập thông tin địa chỉ thủ công.'),
                    backgroundColor: RoomColorScheme.warning,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            } catch (e) {
              setState(() {
                _locationError = 'Lỗi khi xác định địa chỉ: $e';
              });
            } finally {
              setState(() {
                _isGettingLocation = false;
              });
              
              if (widget.onLoadingChanged != null) {
                widget.onLoadingChanged!(false);
              }
            }
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionTitle('Thông tin vị trí'),
          
          // Interactive map
          _buildInteractiveMap(),
          const SizedBox(height: 16),
          
          if (_locationError != null)
            Container(
              margin: EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RoomColorScheme.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: RoomColorScheme.error.withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: RoomColorScheme.error),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _locationError!,
                      style: TextStyle(color: RoomColorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          
          _buildInputField(
            controller: widget.addressController,
            labelText: 'Địa chỉ',
            hintText: 'Nhập địa chỉ chi tiết',
            icon: Icons.location_on,
            required: true,
          ),
          
          // Province dropdown (Flow 1)
          _buildProvinceDropdown(),
          
          // District dropdown (Flow 1)
          _buildDistrictDropdown(),
          
          // Ward dropdown (Flow 1)
          _buildWardDropdown(),
        ],
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: LocationStep.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.location_on, color: LocationStep.primaryColor),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: LocationStep.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildInteractiveMap() {
    final initialLat = widget.latitudeController.text.isNotEmpty 
      ? double.tryParse(widget.latitudeController.text) 
      : 10.7769;
    final initialLng = widget.longitudeController.text.isNotEmpty 
      ? double.tryParse(widget.longitudeController.text) 
      : 106.7009;
    
    final initialPosition = LatLng(
      initialLat ?? 10.7769, // Default to Ho Chi Minh City
      initialLng ?? 106.7009
    );
    
    return Container(
      height: 250,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.3),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: initialPosition,
                zoom: 15,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false,
              zoomControlsEnabled: false,
              onMapCreated: (controller) {
                _mapController = controller;
                
                if (_selectedLocation != null) {
                  _updateMarkers();
                } else if (initialLat != null && initialLng != null) {
                  _selectedLocation = initialPosition;
                  _updateMarkers();
                }
              },
              onTap: _onMapTap,
            ),
            
            // Current location button
            Positioned(
              right: 16,
              top: 16,
              child: FloatingActionButton(
                mini: true,
                backgroundColor: Colors.white,
                foregroundColor: LocationStep.primaryColor,
                onPressed: _isGettingLocation ? null : _getCurrentLocation,
                child: _isGettingLocation
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: LocationStep.primaryColor,
                        ),
                      )
                    : Icon(Icons.my_location, size: 20),
              ),
            ),
            
            // Map loading indicator
            if (_isGettingLocation)
              Center(
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: LocationStep.primaryColor,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Đang xác định vị trí...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Instructions and fullscreen button
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: Colors.black.withOpacity(0.6),
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Chạm vào bản đồ để chọn vị trí',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Nhấn nút "Toàn màn hình" để tìm kiếm địa điểm',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _openFullscreenMap,
                      icon: Icon(Icons.search, color: Colors.white),
                      label: Text('Toàn màn hình', style: TextStyle(color: Colors.white)),
                      style: TextButton.styleFrom(
                        backgroundColor: LocationStep.primaryColor.withOpacity(0.8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required String hintText,
    required IconData icon,
    bool required = false,
    TextInputType? keyboardType,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main container with border
          Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: LocationStep.primaryColor.withOpacity(0.5),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextFormField(
              controller: controller,
              keyboardType: keyboardType,
              decoration: InputDecoration(
                hintText: hintText,
                prefixIcon: Icon(icon, color: LocationStep.primaryColor),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                isDense: true,
              ),
              style: TextStyle(fontSize: 15),
              validator: required
                  ? (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập $labelText';
                      }
                      return null;
                    }
                  : null,
            ),
          ),
          
          // Floating label
          Positioned(
            top: -10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.white,
              child: Text(
                labelText,
                style: TextStyle(
                  color: LocationStep.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Province dropdown for Flow 1
  Widget _buildProvinceDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main container with border
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: LocationStep.primaryColor.withOpacity(0.5),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.location_city,
                    color: LocationStep.primaryColor,
                  ),
                ),
                Expanded(
                  child: _isLoadingProvinces
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: LocationStep.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: Text('Chọn tỉnh/thành phố'),
                              value: _provinces.any((p) => p['name'] == widget.cityController.text)
                                  ? widget.cityController.text
                                  : null,
                              onChanged: (String? newValue) {
                                if (newValue != null) {
                                  setState(() {
                                    widget.cityController.text = newValue;
                                    widget.districtController.clear();
                                    widget.wardController.clear();
                                  });
                                  
                                  // Find province code and load districts
                                  final selectedProvince = _provinces.firstWhere(
                                    (province) => province['name'] == newValue,
                                    orElse: () => {'code': null},
                                  );
                                  
                                  final provinceCode = selectedProvince['code'] as int?;
                                  if (provinceCode != null) {
                                    _loadDistricts(provinceCode);
                                    
                                    // Flow 1: Find coordinates of the selected province and move camera
                                    _searchProvinceAndMoveCameraToLocation(newValue);
                                  }
                                }
                              },
                              items: _provinces.map<DropdownMenuItem<String>>((province) {
                                return DropdownMenuItem<String>(
                                  value: province['name'] as String,
                                  child: Text(
                                    province['name'] as String,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              isDense: true,
                              icon: Icon(Icons.arrow_drop_down, size: 28),
                              menuMaxHeight: 300,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          
          // Floating label
          Positioned(
            top: -10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.white,
              child: Text(
                'Tỉnh/Thành phố',
                style: TextStyle(
                  color: LocationStep.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // District dropdown for Flow 1
  Widget _buildDistrictDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main container with border
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: LocationStep.primaryColor.withOpacity(0.5),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.map,
                    color: LocationStep.primaryColor,
                  ),
                ),
                Expanded(
                  child: _isLoadingDistricts
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: LocationStep.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: Text(_districts.isEmpty
                                  ? 'Vui lòng chọn tỉnh/thành phố trước'
                                  : 'Chọn quận/huyện'),
                              value: _districts.any((d) => d['name'] == widget.districtController.text)
                                  ? widget.districtController.text
                                  : null,
                              onChanged: _districts.isEmpty
                                  ? null
                                  : (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          widget.districtController.text = newValue;
                                          widget.wardController.clear();
                                        });
                                        
                                        // Find district code and load wards
                                        final selectedDistrict = _districts.firstWhere(
                                          (district) => district['name'] == newValue,
                                          orElse: () => {'code': null},
                                        );
                                        
                                        final districtCode = selectedDistrict['code'] as int?;
                                        if (districtCode != null) {
                                          _loadWards(districtCode);
                                          
                                          // Flow 1: Find coordinates of the selected district and move camera
                                          final provinceName = widget.cityController.text;
                                          _searchDistrictAndMoveCameraToLocation(provinceName, newValue);
                                        }
                                      }
                                    },
                              items: _districts.map<DropdownMenuItem<String>>((district) {
                                return DropdownMenuItem<String>(
                                  value: district['name'] as String,
                                  child: Text(
                                    district['name'] as String,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              isDense: true,
                              icon: Icon(Icons.arrow_drop_down, size: 28),
                              menuMaxHeight: 300,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          
          // Floating label
          Positioned(
            top: -10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.white,
              child: Text(
                'Quận/Huyện',
                style: TextStyle(
                  color: LocationStep.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Ward dropdown for Flow 1
  Widget _buildWardDropdown() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main container with border
          Container(
            padding: const EdgeInsets.only(top: 10, bottom: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: LocationStep.primaryColor.withOpacity(0.5),
                width: 1.0,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Icon(
                    Icons.place,
                    color: LocationStep.primaryColor,
                  ),
                ),
                Expanded(
                  child: _isLoadingWards
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: LocationStep.primaryColor,
                              ),
                            ),
                          ),
                        )
                      : DropdownButtonHideUnderline(
                          child: ButtonTheme(
                            alignedDropdown: true,
                            child: DropdownButton<String>(
                              isExpanded: true,
                              hint: Text(_wards.isEmpty
                                  ? 'Vui lòng chọn quận/huyện trước'
                                  : 'Chọn phường/xã'),
                              value: _wards.any((w) => w['name'] == widget.wardController.text)
                                  ? widget.wardController.text
                                  : null,
                              onChanged: _wards.isEmpty
                                  ? null
                                  : (String? newValue) {
                                      if (newValue != null) {
                                        setState(() {
                                          widget.wardController.text = newValue;
                                        });
                                        
                                        // Flow 1: Find coordinates of the selected ward and move camera
                                        final provinceName = widget.cityController.text;
                                        final districtName = widget.districtController.text;
                                        _searchWardAndMoveCameraToLocation(
                                          provinceName, 
                                          districtName, 
                                          newValue
                                        );
                                      }
                                    },
                              items: _wards.map<DropdownMenuItem<String>>((ward) {
                                return DropdownMenuItem<String>(
                                  value: ward['name'] as String,
                                  child: Text(
                                    ward['name'] as String,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                );
                              }).toList(),
                              padding: const EdgeInsets.symmetric(vertical: 2),
                              isDense: true,
                              icon: Icon(Icons.arrow_drop_down, size: 28),
                              menuMaxHeight: 300,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
          
          // Floating label
          Positioned(
            top: -10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              color: Colors.white,
              child: Text(
                'Phường/Xã',
                style: TextStyle(
                  color: LocationStep.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Flow 1: Search for a province and move camera to its location
  Future<void> _searchProvinceAndMoveCameraToLocation(String provinceName) async {
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      final results = await _googlePlacesService.getPlaceAutocomplete('$provinceName, Vietnam');
      
      if (results.isNotEmpty) {
        final placeId = results.first.placeId;
        final details = await _googlePlacesService.getPlaceDetails(placeId);
        
        if (details != null) {
          // Update latitude and longitude
          widget.latitudeController.text = details.latitude.toString();
          widget.longitudeController.text = details.longitude.toString();
          
          // Update map
          _selectedLocation = LatLng(details.latitude, details.longitude);
          _updateMarkers();
          _animateCameraToLocation(_selectedLocation!);
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi tìm kiếm vị trí tỉnh/thành phố: $e');
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }
  
  // Flow 1: Search for a district and move camera to its location
  Future<void> _searchDistrictAndMoveCameraToLocation(String provinceName, String districtName) async {
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      final results = await _googlePlacesService.getPlaceAutocomplete('$districtName, $provinceName, Vietnam');
      
      if (results.isNotEmpty) {
        final placeId = results.first.placeId;
        final details = await _googlePlacesService.getPlaceDetails(placeId);
        
        if (details != null) {
          // Update latitude and longitude
          widget.latitudeController.text = details.latitude.toString();
          widget.longitudeController.text = details.longitude.toString();
          
          // Update map
          _selectedLocation = LatLng(details.latitude, details.longitude);
          _updateMarkers();
          _animateCameraToLocation(_selectedLocation!);
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi tìm kiếm vị trí quận/huyện: $e');
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }
  
  // Flow 1: Search for a ward and move camera to its location
  Future<void> _searchWardAndMoveCameraToLocation(String provinceName, String districtName, String wardName) async {
    setState(() {
      _isGettingLocation = true;
    });
    
    try {
      final results = await _googlePlacesService.getPlaceAutocomplete('$wardName, $districtName, $provinceName, Vietnam');
      
      if (results.isNotEmpty) {
        final placeId = results.first.placeId;
        final details = await _googlePlacesService.getPlaceDetails(placeId);
        
        if (details != null) {
          // Update latitude and longitude
          widget.latitudeController.text = details.latitude.toString();
          widget.longitudeController.text = details.longitude.toString();
          
          // Update map
          _selectedLocation = LatLng(details.latitude, details.longitude);
          _updateMarkers();
          _animateCameraToLocation(_selectedLocation!);
        }
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi tìm kiếm vị trí phường/xã: $e');
    } finally {
      setState(() {
        _isGettingLocation = false;
      });
    }
  }

  // Phương thức khôi phục dữ liệu quận/huyện và phường/xã
  void _restoreLocationData() {
    // Thay vì sử dụng delay cố định, kiểm tra _provinces đã có dữ liệu chưa
    if (_provinces.isEmpty) {
      // Nếu _provinces chưa có dữ liệu, đăng ký một listener để kiểm tra khi nào _provinces được cập nhật
      Future.doWhile(() async {
        await Future.delayed(Duration(milliseconds: 100));
        return _provinces.isEmpty && mounted;
      }).then((_) {
        if (mounted) {
          _restoreProvinceData();
        }
      });
    } else {
      // Nếu _provinces đã có dữ liệu, tiến hành khôi phục dữ liệu ngay
      _restoreProvinceData();
    }
  }

  // Phương thức khôi phục dữ liệu tỉnh/thành phố
  void _restoreProvinceData() {
    if (!mounted || widget.cityController.text.isEmpty) return;
    
    print("DEBUG: Attempting to restore province data. Available provinces: ${_provinces.length}");
    print("DEBUG: Looking for province: '${widget.cityController.text}'");
    
    // Tìm tỉnh/thành phố tương ứng
    final selectedProvince = _provinces.firstWhere(
      (province) => province['name'].toString().trim() == widget.cityController.text.trim(),
      orElse: () {
        // Thử tìm kiếm phần tương đồng nếu không tìm thấy chính xác
        final similarProvinces = _provinces.where(
          (province) => province['name'].toString().toLowerCase().contains(
            widget.cityController.text.trim().toLowerCase()
          )
        ).toList();
        
        if (similarProvinces.isNotEmpty) {
          print("DEBUG: Found similar province: ${similarProvinces.first['name']}");
          return similarProvinces.first;
        }
        
        print("DEBUG: No matching province found for '${widget.cityController.text}'");
        return <String, dynamic>{};
      },
    );
    
    // Nếu tìm thấy tỉnh/thành phố và có ID
    if (selectedProvince.isNotEmpty && selectedProvince.containsKey('code')) {
      print("DEBUG: Found matching province: ${selectedProvince['name']} with code: ${selectedProvince['code']}");
      
      // Đảm bảo cityController có giá trị chính xác từ dropdown
      if (widget.cityController.text.trim() != selectedProvince['name'].toString().trim()) {
        widget.cityController.text = selectedProvince['name'].toString();
      }
      
      // Tải danh sách quận/huyện
      _loadDistricts(selectedProvince['code']).then((_) {
        // Chỉ tiếp tục nếu widget vẫn mounted và có dữ liệu quận/huyện
        if (!mounted || widget.districtController.text.isEmpty) return;
        
        print("DEBUG: Loaded districts: ${_districts.length}");
        print("DEBUG: Looking for district: '${widget.districtController.text}'");
        
        // Tìm quận/huyện tương ứng
        final selectedDistrict = _districts.firstWhere(
          (district) => district['name'].toString().trim() == widget.districtController.text.trim(),
          orElse: () {
            // Thử tìm kiếm phần tương đồng nếu không tìm thấy chính xác
            final similarDistricts = _districts.where(
              (district) => district['name'].toString().toLowerCase().contains(
                widget.districtController.text.trim().toLowerCase()
              )
            ).toList();
            
            if (similarDistricts.isNotEmpty) {
              print("DEBUG: Found similar district: ${similarDistricts.first['name']}");
              return similarDistricts.first;
            }
            
            print("DEBUG: No matching district found for '${widget.districtController.text}'");
            return <String, dynamic>{};
          },
        );
        
        // Nếu tìm thấy quận/huyện và có ID
        if (selectedDistrict.isNotEmpty && selectedDistrict.containsKey('code')) {
          print("DEBUG: Found matching district: ${selectedDistrict['name']} with code: ${selectedDistrict['code']}");
          
          // Đảm bảo districtController có giá trị chính xác từ dropdown
          if (widget.districtController.text.trim() != selectedDistrict['name'].toString().trim()) {
            setState(() {
              widget.districtController.text = selectedDistrict['name'].toString();
            });
          }
          
          // Tải danh sách phường/xã
          _loadWards(selectedDistrict['code']).then((_) {
            if (!mounted || widget.wardController.text.isEmpty) return;
            
            print("DEBUG: Loaded wards: ${_wards.length}");
            print("DEBUG: Looking for ward: '${widget.wardController.text}'");
            
            // Tìm phường/xã tương ứng
            final selectedWard = _wards.firstWhere(
              (ward) => ward['name'].toString().trim() == widget.wardController.text.trim(),
              orElse: () {
                // Thử tìm kiếm phần tương đồng nếu không tìm thấy chính xác
                final similarWards = _wards.where(
                  (ward) => ward['name'].toString().toLowerCase().contains(
                    widget.wardController.text.trim().toLowerCase()
                  )
                ).toList();
                
                if (similarWards.isNotEmpty) {
                  print("DEBUG: Found similar ward: ${similarWards.first['name']}");
                  return similarWards.first;
                }
                
                print("DEBUG: No matching ward found for '${widget.wardController.text}'");
                return <String, dynamic>{};
              },
            );
            
            // Nếu tìm thấy phường/xã, cập nhật UI
            if (selectedWard.isNotEmpty) {
              print("DEBUG: Found matching ward: ${selectedWard['name']}");
              
              // Đảm bảo wardController có giá trị chính xác từ dropdown
              if (widget.wardController.text.trim() != selectedWard['name'].toString().trim()) {
                setState(() {
                  widget.wardController.text = selectedWard['name'].toString();
                });
              }
            }
          });
        }
      });
    } else {
      print("DEBUG: No matching province found with code");
    }
  }
}

// Widget màn hình bản đồ toàn màn hình
class _FullscreenMapPicker extends StatefulWidget {
  final LatLng initialLocation;
  final Function(LatLng) onLocationSelected;

  const _FullscreenMapPicker({
    Key? key,
    required this.initialLocation,
    required this.onLocationSelected,
  }) : super(key: key);

  @override
  State<_FullscreenMapPicker> createState() => _FullscreenMapPickerState();
}

class _FullscreenMapPickerState extends State<_FullscreenMapPicker> with SingleTickerProviderStateMixin {
  late CameraPosition _cameraPosition;
  GoogleMapController? _mapController;
  late LatLng _targetLocation;
  final TextEditingController _searchController = TextEditingController();
  List<PlaceAutocompleteResult> _searchResults = [];
  bool _showSearchResults = false;
  bool _isSearching = false;
  late GooglePlacesService _googlePlacesService;
  
  // Animation for search results
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  @override
  void initState() {
    super.initState();
    _targetLocation = widget.initialLocation;
    _cameraPosition = CameraPosition(
      target: widget.initialLocation,
      zoom: 16.0,
    );
    _initGooglePlacesService();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    
    // Add listener to search controller
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _mapController?.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  void _initGooglePlacesService() {
    final googlePlacesRepository = GetIt.instance<GooglePlacesRepository>();
    _googlePlacesService = GooglePlacesService(repository: googlePlacesRepository);
  }
  
  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _searchPlaces(_searchController.text);
    } else {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
      });
      _animationController.reverse();
    }
  }
  
  Future<void> _searchPlaces(String query) async {
    if (query.length < 3) return;
    
    setState(() {
      _isSearching = true;
    });
    
    try {
      final results = await _googlePlacesService.getPlaceAutocomplete(query);
      setState(() {
        _searchResults = results;
        _showSearchResults = results.isNotEmpty;
        _isSearching = false;
      });
      
      if (results.isNotEmpty) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    } catch (e) {
      setState(() {
        _searchResults = [];
        _showSearchResults = false;
        _isSearching = false;
      });
      _animationController.reverse();
    }
  }
  
  Future<void> _onLocationSelected(PlaceAutocompleteResult result) async {
    setState(() {
      _isSearching = true;
      _showSearchResults = false;
    });
    _animationController.reverse();
    
    try {
      final details = await _googlePlacesService.getPlaceDetails(result.placeId);
      if (details != null) {
        setState(() {
          _targetLocation = LatLng(details.latitude, details.longitude);
        });
        
        _mapController?.animateCamera(
          CameraUpdate.newCameraPosition(
            CameraPosition(
              target: _targetLocation,
              zoom: 17,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('❌ Lỗi khi lấy chi tiết địa điểm: $e');
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _onCameraMove(CameraPosition position) {
    _targetLocation = position.target;
  }

  void _selectLocation() {
    widget.onLocationSelected(_targetLocation);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false, // Avoid resizing when keyboard appears
      appBar: AppBar(
        title: Text('Tìm kiếm và chọn vị trí'),
        backgroundColor: LocationStep.primaryColor,
        elevation: 0,
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: _cameraPosition,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            mapToolbarEnabled: false,
            zoomControlsEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onCameraMove: _onCameraMove,
            onCameraIdle: () {
              // Có thể thêm logic khi camera dừng di chuyển
            },
          ),
          
          // Search box at the top
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: Column(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Tìm kiếm địa điểm...',
                      prefixIcon: Icon(Icons.search, color: LocationStep.primaryColor),
                      suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    onChanged: (value) {
                      // Search triggered by listener
                    },
                  ),
                ),
                
                // Search results with animation
                if (_showSearchResults)
                  SizeTransition(
                    sizeFactor: _animation,
                    axis: Axis.vertical,
                    child: Container(
                      margin: EdgeInsets.only(top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      constraints: BoxConstraints(
                        maxHeight: 250,
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.length,
                        separatorBuilder: (_, __) => Divider(height: 1),
                        itemBuilder: (context, index) {
                          final result = _searchResults[index];
                          return ListTile(
                            dense: true,
                            title: Text(
                              result.mainText,
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              result.secondaryText,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            leading: Icon(Icons.location_on, color: LocationStep.primaryColor),
                            onTap: () {
                              _onLocationSelected(result);
                              _searchController.text = "${result.mainText}, ${result.secondaryText}";
                              FocusScope.of(context).unfocus();
                            },
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
          
          // Current location button
          Positioned(
            right: 16,
            top: _showSearchResults ? 310 : 80,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              foregroundColor: LocationStep.primaryColor,
              onPressed: _isSearching ? null : () async {
                final locationService = GetIt.instance<LocationService>();
                final position = await locationService.getCurrentPosition();
                
                if (position != null) {
                  _mapController?.animateCamera(
                    CameraUpdate.newLatLng(
                      LatLng(position.latitude, position.longitude),
                    ),
                  );
                }
              },
              child: _isSearching
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: LocationStep.primaryColor,
                      ),
                    )
                  : Icon(Icons.my_location, size: 20),
            ),
          ),
          
          // Search loading indicator
          if (_isSearching)
            Positioned(
              top: 32,
              right: 32,
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: LocationStep.primaryColor,
                  strokeWidth: 2,
                ),
              ),
            ),
          
          // Marker cố định ở giữa màn hình
          Center(
            child: TweenAnimationBuilder<double>(
              duration: Duration(milliseconds: 300),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, value, child) {
                return Transform.translate(
                  offset: Offset(0, -10 * value),
                  child: child,
                );
              },
              child: Container(
                padding: EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_pin,
                  color: LocationStep.primaryColor,
                  size: 36,
                ),
              ),
            ),
          ),
          
          // Nút xác nhận vị trí
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: _selectLocation,
                icon: Icon(Icons.check),
                label: Text('Chọn vị trí này'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: LocationStep.primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 