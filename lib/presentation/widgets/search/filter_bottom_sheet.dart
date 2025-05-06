import 'package:flutter/material.dart';
import 'package:roomily/core/services/location_service.dart';
import 'package:roomily/core/services/tag_service.dart';
import 'package:roomily/core/utils/room_type.dart';
import 'package:roomily/core/utils/tag_category.dart';
import 'package:roomily/data/models/models.dart';
import 'package:get_it/get_it.dart';

class FilterBottomSheet extends StatefulWidget {
  final RoomFilter initialFilter;
  final Function(RoomFilter) onApplyFilter;
  final VoidCallback onClose;

  const FilterBottomSheet({
    Key? key,
    required this.initialFilter,
    required this.onApplyFilter,
    required this.onClose,
  }) : super(key: key);

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> with SingleTickerProviderStateMixin {
  late RoomFilter _filter;
  late AnimationController _animationController;
  late Animation<double> _animation;
  
  // Controllers cho các trường nhập liệu
  final TextEditingController _minPriceController = TextEditingController();
  final TextEditingController _maxPriceController = TextEditingController();
  
  // Range slider values cho giá
  RangeValues _priceRange = const RangeValues(0, 10000000);
  double _maxPriceValue = 10000000; // 10 triệu đồng
  
  // Thêm biến để theo dõi trạng thái của filter tìm người ở ghép
  bool _hasFindPartnerPost = false;
  
  // Danh sách các loại phòng với giá trị RoomType tương ứng và màu sắc
  final List<Map<String, dynamic>> _roomTypes = [
    {'display': 'TẤT CẢ', 'value': RoomType.ALL, 'icon': Icons.home_outlined, 'color': const Color(0xFF3F51B5)},
    {'display': 'PHÒNG TRỌ', 'value': RoomType.ROOM, 'icon': Icons.hotel_outlined, 'color': const Color(0xFF3F51B5)},
    {'display': 'CHUNG CƯ', 'value': RoomType.APARTMENT, 'icon': Icons.apartment_outlined, 'color': const Color(0xFF3F51B5)},
    {'display': 'NHÀ NGUYÊN CĂN', 'value': RoomType.HOUSE, 'icon': Icons.house_outlined, 'color': const Color(0xFF3F51B5)},
  ];
  
  // Màu chủ đạo cho tất cả các tiêu đề section - Indigo 500 - Main primary color
  final Color _primaryColor = const Color(0xFF3F51B5);
  // Màu thứ hai - Indigo 100 - Lighter shade for backgrounds
  final Color _secondaryColor = const Color(0xFFC5CAE9);
  // Màu nút Apply - Deep Orange 500 - Accent color for CTA buttons
  final Color _accentColor = const Color(0xFFFF5722);
  
  // Amenity colors - Carefully chosen shades that complement the primary color
  final Map<String, Color> _amenityColors = {
    'wifi': const Color(0xFF3F51B5),           // Indigo
    'air_conditioner': const Color(0xFF00BCD4), // Cyan
    'washing_machine': const Color(0xFF009688), // Teal
    'refrigerator': const Color(0xFF4CAF50),    // Green
    'parking': const Color(0xFF8BC34A),         // Light Green
    'security': const Color(0xFFCDDC39),        // Lime
    'private_bathroom': const Color(0xFFFFC107), // Amber
    'pet_friendly': const Color(0xFFFF9800),     // Orange
    'kitchen': const Color(0xFFFF5722),          // Deep Orange
    'window': const Color(0xFF795548),           // Brown
  };
  
  // Service để lấy dữ liệu địa điểm
  late LocationService _locationService;
  
  // Service để lấy dữ liệu tiện ích
  late TagService _tagService;
  
  // Danh sách tiện ích từ API
  List<RoomTag> _inRoomFeatures = [];
  List<RoomTag> _inBuildingFeatures = [];
  List<RoomTag> _nearbyPoi = [];
  List<RoomTag> _policy = [];
  
  // Trạng thái loading tiện ích
  bool _isLoadingAmenities = false;
  
  // Danh sách tỉnh/thành phố, quận/huyện, phường/xã từ API
  List<Map<String, dynamic>> _provincesData = [];
  List<Map<String, dynamic>> _districtsData = [];
  List<Map<String, dynamic>> _wardsData = [];
  
  // Danh sách tên tỉnh/thành phố, quận/huyện, phường/xã để hiển thị
  List<String> _cities = [];
  List<String> _districts = [];
  List<String> _wards = [];
  
  // Map để lưu mã code của tỉnh/thành phố, quận/huyện đã chọn
  Map<String, int> _selectedCodes = {};
  
  // Trạng thái loading
  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
    
    // Khởi tạo LocationService
    _locationService = GetIt.instance<LocationService>();
    
    // Khởi tạo TagService
    _tagService = GetIt.instance<TagService>();
    
    // Khởi tạo filter từ initialFilter và chuẩn hóa
    _filter = widget.initialFilter.normalize();
    
    // Khởi tạo giá trị cho các controller
    _minPriceController.text = _filter.minPrice?.toString() ?? '';
    _maxPriceController.text = _filter.maxPrice?.toString() ?? '';
    
    // Khởi tạo giá trị cho tìm người ở ghép
    _hasFindPartnerPost = _filter.hasFindPartnerPost ?? false;
    
    // Khởi tạo range slider
    if (_filter.minPrice != null) {
      double minVal = _filter.minPrice!;
      double maxVal = _filter.maxPrice ?? _maxPriceValue;
      _priceRange = RangeValues(minVal, maxVal);
    } else if (_filter.maxPrice != null) {
      _priceRange = RangeValues(0, _filter.maxPrice!);
    }
    
    // Tải danh sách tỉnh/thành phố từ API
    _loadProvinces();
    
    // Tải danh sách tiện ích từ API
    _loadAmenities();
  }

  @override
  void dispose() {
    _minPriceController.dispose();
    _maxPriceController.dispose();
    _animationController.dispose();
    super.dispose();
  }
  
  // Tải danh sách tiện ích từ API
  Future<void> _loadAmenities() async {
    setState(() {
      _isLoadingAmenities = true;
    });
    
    try {
      final amenities = await _tagService.getAllTags();
      
      setState(() {
        _inRoomFeatures = amenities.where((tag) => tag.category == TagCategory.IN_ROOM_FEATURE).toList();
        _inBuildingFeatures = amenities.where((tag) => tag.category == TagCategory.BUILDING_FEATURE).toList();
        _nearbyPoi = amenities.where((tag) => tag.category == TagCategory.NEARBY_POI).toList();
        _policy = amenities.where((tag) => tag.category == TagCategory.POLICY).toList();
        _isLoadingAmenities = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingAmenities = false;
      });
      debugPrint('Error loading amenities: $e');
    }
  }
  
  // Tải danh sách tỉnh/thành phố từ API
  Future<void> _loadProvinces() async {
    setState(() {
      _isLoadingProvinces = true;
    });
    
    try {
      _provincesData = await _locationService.getProvinces();
      
      setState(() {
        // Lấy danh sách tên tỉnh/thành phố đã được xử lý (không có tiền tố "Thành phố" hoặc "Tỉnh")
        _cities = _provincesData.map((p) => p['name'] as String).toList();
        _isLoadingProvinces = false;
        
        // Nếu đã có city trong filter, tìm code và tải districts
        if (_filter.city != null && _filter.city!.isNotEmpty) {
          // Tìm tỉnh/thành phố trong danh sách
          final province = _provincesData.firstWhere(
            (p) => p['name'].toString().toLowerCase() == _filter.city!.toLowerCase(),
            orElse: () => {'code': 0, 'name': _filter.city},
          );
          
          if (province['code'] != 0) {
            _selectedCodes['province'] = province['code'] as int;
            _loadDistricts(province['code'] as int);
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingProvinces = false;
      });
      debugPrint('Error loading provinces: $e');
    }
  }
  
  // Tải danh sách quận/huyện từ API
  Future<void> _loadDistricts(int provinceCode) async {
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _wards = [];
    });
    
    try {
      _districtsData = await _locationService.getDistricts(provinceCode);
      
      setState(() {
        _districts = _districtsData.map((d) => d['name'] as String).toList();
        _isLoadingDistricts = false;
        
        // Nếu đã có district trong filter, tìm code và tải wards
        if (_filter.district != null && _filter.district!.isNotEmpty) {
          final district = _districtsData.firstWhere(
            (d) => d['name'].toString().toLowerCase() == _filter.district!.toLowerCase(),
            orElse: () => {'code': 0, 'name': _filter.district},
          );
          
          if (district['code'] != 0) {
            _selectedCodes['district'] = district['code'] as int;
            _loadWards(district['code'] as int);
          }
        }
      });
    } catch (e) {
      setState(() {
        _isLoadingDistricts = false;
      });
      debugPrint('Error loading districts: $e');
    }
  }
  
  // Tải danh sách phường/xã từ API
  Future<void> _loadWards(int districtCode) async {
    setState(() {
      _isLoadingWards = true;
      _wards = [];
    });
    
    try {
      _wardsData = await _locationService.getWards(districtCode);
      
      setState(() {
        _wards = _wardsData.map((w) => w['name'] as String).toList();
        _isLoadingWards = false;
      });
    } catch (e) {
      setState(() {
        _isLoadingWards = false;
      });
      debugPrint('Error loading wards: $e');
    }
  }

  // Format giá tiền để hiển thị (vd: 1,000,000)
  String _formatPrice(double price) {
    return price.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]},'
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return FadeTransition(
          opacity: _animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.1),
              end: Offset.zero,
            ).animate(_animation),
            child: Container(
              height: MediaQuery.of(context).size.height * 0.85,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    spreadRadius: 1,
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Handle indicator
                  Center(
                    child: Container(
                      margin: const EdgeInsets.only(top: 8, bottom: 4),
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  
                  // Header
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            // Reset filter về giá trị ban đầu
                            setState(() {
                              _filter = RoomFilter.defaultFilter();
                              _minPriceController.text = '';
                              _maxPriceController.text = '';
                              _priceRange = const RangeValues(0, 10000000);
                            });
                          },
                          icon: const Icon(Icons.refresh_rounded),
                          label: const Text('Đặt lại'),
                          style: TextButton.styleFrom(
                            foregroundColor: const Color(0xFFF44336), // Red 500 for reset
                          ),
                        ),
                        Text(
                          'Bộ lọc',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _primaryColor,
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () {
                            widget.onClose();
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close_rounded),
                          label: const Text('Đóng'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.black54, // Softer black for close
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  const Divider(height: 1),
                  
                  // Filter content
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Phần Loại phòng
                          _buildSectionTitle('Loại phòng', Icons.home_rounded, _primaryColor),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, // Giảm khoảng cách giữa các chip
                            runSpacing: 8, // Giảm khoảng cách giữa các hàng
                            children: _roomTypes.map((typeData) {
                              final bool isSelected = typeData['value'] == RoomType.ALL 
                                  ? _filter.type == RoomType.ALL 
                                  : _filter.type == typeData['value'];
                              
                              final Color typeColor = typeData['color'] as Color;
                              
                              return ChoiceChip(
                                avatar: Icon(
                                  typeData['icon'] as IconData,
                                  size: 18,
                                  color: isSelected ? Colors.white : typeColor,
                                ),
                                label: Text(
                                  typeData['display'] as String,
                                  style: TextStyle(
                                    color: isSelected ? Colors.white : Colors.black87,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                selected: isSelected,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _filter = _filter.copyWith(type: typeData['value']);
                                    });
                                  }
                                },
                                backgroundColor: Colors.white,
                                selectedColor: typeColor,
                                elevation: isSelected ? 2 : 0,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  side: BorderSide(
                                    color: isSelected ? typeColor : Colors.grey.shade300,
                                    width: 1,
                                  ),
                                ),
                                pressElevation: 4,
                              );
                            }).toList(),
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Phần Khoảng giá
                          _buildSectionTitle('Khoảng giá', Icons.attach_money_rounded, _primaryColor),
                          const SizedBox(height: 12),
                          
                          // Range Slider cho giá
                          Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${_formatPrice(_priceRange.start)} VNĐ',
                                      style: TextStyle(
                                        color: _primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      '${_formatPrice(_priceRange.end)} VNĐ',
                                      style: TextStyle(
                                        color: _primaryColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              SliderTheme(
                                data: SliderThemeData(
                                  showValueIndicator: ShowValueIndicator.never, // Không hiển thị tooltip
                                ),
                                child: RangeSlider(
                                  values: _priceRange,
                                  min: 0,
                                  max: _maxPriceValue,
                                  divisions: 100,
                                  onChanged: (RangeValues values) {
                                    setState(() {
                                      _priceRange = values;
                                      _minPriceController.text = values.start.toStringAsFixed(0);
                                      _maxPriceController.text = values.end.toStringAsFixed(0);
                                      
                                      _filter = _filter.copyWith(
                                        minPrice: values.start > 0 ? values.start : null,
                                        maxPrice: values.end < _maxPriceValue ? values.end : null,
                                      );
                                    });
                                  },
                                  activeColor: _primaryColor,
                                  inactiveColor: _secondaryColor,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: _minPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Từ',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        prefixIcon: Icon(Icons.money, color: _primaryColor),
                                        suffixText: 'VNĐ',
                                        suffixIcon: _filter.minPrice != null ? IconButton(
                                          icon: Icon(Icons.clear, size: 18, color: _primaryColor),
                                          onPressed: () {
                                            setState(() {
                                              _minPriceController.clear();
                                              _priceRange = RangeValues(0, _priceRange.end);
                                              _filter = _filter.copyWith(minPrice: null);
                                            });
                                          },
                                        ) : null,
                                      ),
                                      onChanged: (value) {
                                        final price = double.tryParse(value);
                                        setState(() {
                                          if (price != null) {
                                            _priceRange = RangeValues(price, _priceRange.end);
                                          }
                                          _filter = _filter.copyWith(
                                            minPrice: value.isNotEmpty ? double.tryParse(value) : null,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: TextField(
                                      controller: _maxPriceController,
                                      keyboardType: TextInputType.number,
                                      decoration: InputDecoration(
                                        hintText: 'Đến',
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide(color: Colors.grey.shade300),
                                        ),
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                        prefixIcon: Icon(Icons.money, color: _primaryColor),
                                        suffixText: 'VNĐ',
                                        suffixIcon: _filter.maxPrice != null ? IconButton(
                                          icon: Icon(Icons.clear, size: 18, color: _primaryColor),
                                          onPressed: () {
                                            setState(() {
                                              _maxPriceController.clear();
                                              _priceRange = RangeValues(_priceRange.start, _maxPriceValue);
                                              _filter = _filter.copyWith(maxPrice: null);
                                            });
                                          },
                                        ) : null,
                                      ),
                                      onChanged: (value) {
                                        final price = double.tryParse(value);
                                        setState(() {
                                          if (price != null) {
                                            _priceRange = RangeValues(_priceRange.start, price);
                                          }
                                          _filter = _filter.copyWith(
                                            maxPrice: value.isNotEmpty ? double.tryParse(value) : null,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Thành phố
                          _buildSectionTitle('Địa điểm', Icons.location_on_rounded, _primaryColor),
                          const SizedBox(height: 12),
                          _buildDropdownField(
                            label: 'Tỉnh/Thành phố',
                            isLoading: _isLoadingProvinces,
                            value: _filter.city?.isNotEmpty == true && _cities.contains(_filter.city) 
                                  ? _filter.city 
                                  : null,
                            items: _cities,
                            hint: 'Chọn tỉnh/thành phố',
                            iconColor: _primaryColor,
                            onChanged: (value) {
                              if (value == null) {
                                setState(() {
                                  _filter = _filter.copyWith(
                                    city: '',
                                    district: '',
                                    ward: '',
                                  );
                                  _districts = [];
                                  _wards = [];
                                });
                                return;
                              }
                              
                              setState(() {
                                _filter = _filter.copyWith(
                                  city: value,
                                  district: '',
                                  ward: '',
                                );
                                
                                // Tìm province code và tải districts
                                final province = _provincesData.firstWhere(
                                  (p) => p['name'] == value,
                                  orElse: () => {'code': 0},
                                );
                                
                                if (province['code'] != 0) {
                                  _selectedCodes['province'] = province['code'] as int;
                                  _loadDistricts(province['code'] as int);
                                }
                              });
                            },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Quận/Huyện
                          _buildDropdownField(
                            label: 'Quận/Huyện',
                            isLoading: _isLoadingDistricts,
                            value: _filter.district?.isNotEmpty == true && _districts.contains(_filter.district) 
                                  ? _filter.district 
                                  : null,
                            items: _districts,
                            hint: 'Chọn quận/huyện',
                            iconColor: _primaryColor,
                            onChanged: _districts.isEmpty 
                                ? null 
                                : (value) {
                                    if (value == null) {
                                      setState(() {
                                        _filter = _filter.copyWith(
                                          district: '',
                                          ward: '',
                                        );
                                        _wards = [];
                                      });
                                      return;
                                    }
                                    
                                    setState(() {
                                      _filter = _filter.copyWith(
                                        district: value,
                                        ward: '',
                                      );
                                      
                                      // Tìm district code và tải wards
                                      final district = _districtsData.firstWhere(
                                        (d) => d['name'] == value,
                                        orElse: () => {'code': 0},
                                      );
                                      
                                      if (district['code'] != 0) {
                                        _selectedCodes['district'] = district['code'] as int;
                                        _loadWards(district['code'] as int);
                                      }
                                    });
                                  },
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Phường/Xã
                          _buildDropdownField(
                            label: 'Phường/Xã',
                            isLoading: _isLoadingWards,
                            value: _filter.ward?.isNotEmpty == true && _wards.contains(_filter.ward) 
                                  ? _filter.ward 
                                  : null,
                            items: _wards,
                            hint: 'Chọn phường/xã',
                            iconColor: _primaryColor,
                            onChanged: _wards.isEmpty
                                ? null
                                : (value) {
                                    setState(() {
                                      _filter = _filter.copyWith(ward: value);
                                    });
                                  },
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Số người ở
                          _buildSectionTitle('Số người ở', Icons.people_alt_rounded, _primaryColor),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Tối thiểu',
                                  value: _filter.minPeople,
                                  items: List.generate(10, (index) => (index + 1).toString()),
                                  itemValue: (value) => int.parse(value),
                                  hint: 'Tối thiểu',
                                  iconColor: _primaryColor,
                                  onChanged: (value) {
                                    setState(() {
                                      final intValue = value != null ? int.parse(value) : null;
                                      _filter = _filter.copyWith(minPeople: intValue);
                                      // Đảm bảo maxPeople >= minPeople
                                      if (_filter.maxPeople != null && intValue != null && _filter.maxPeople! < intValue) {
                                        _filter = _filter.copyWith(maxPeople: intValue);
                                      }
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDropdownField(
                                  label: 'Tối đa',
                                  value: _filter.maxPeople,
                                  items: List.generate(10, (index) => (index + 1).toString()),
                                  itemValue: (value) => int.parse(value),
                                  hint: 'Tối đa',
                                  iconColor: _primaryColor,
                                  onChanged: (value) {
                                    setState(() {
                                      final intValue = value != null ? int.parse(value) : null;
                                      _filter = _filter.copyWith(maxPeople: intValue);
                                      // Đảm bảo minPeople <= maxPeople
                                      if (_filter.minPeople != null && intValue != null && _filter.minPeople! > intValue) {
                                        _filter = _filter.copyWith(minPeople: intValue);
                                      }
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Thêm phần tìm người ở ghép với switch tích hợp ngay bên cạnh tiêu đề
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: _buildSectionTitle('Tìm người ở ghép', Icons.people_outlined, _primaryColor),
                              ),

                                  Switch(
                                    value: _hasFindPartnerPost,
                                    onChanged: (value) {
                                      setState(() {
                                        _hasFindPartnerPost = value;
                                        _filter = _filter.copyWith(hasFindPartnerPost: value);
                                      });
                                    },
                                    activeColor: Colors.deepPurple,
                                    activeTrackColor: Colors.deepPurple.withOpacity(0.4),

                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 24),
                          
                          // Tiện ích (Tags)
                          _buildSectionTitle('Tiện ích và Chính sách', Icons.star_rounded, _primaryColor),
                          const SizedBox(height: 12),
                          
                          // Replace individual tag sections with expansion panels
                          _buildTagExpansionPanel(
                            title: 'Tiện ích trong phòng',
                            icon: Icons.bed_outlined,
                            tags: _inRoomFeatures,
                            initiallyExpanded: false,
                          ),
                          
                          _buildTagExpansionPanel(
                            title: 'Tiện ích của tòa nhà',
                            icon: Icons.apartment_outlined,
                            tags: _inBuildingFeatures,
                            initiallyExpanded: false,
                          ),
                          
                          _buildTagExpansionPanel(
                            title: 'Địa điểm lân cận',
                            icon: Icons.place_outlined,
                            tags: _nearbyPoi,
                            initiallyExpanded: false,
                          ),
                          
                          _buildTagExpansionPanel(
                            title: 'Chính sách',
                            icon: Icons.policy_outlined,
                            tags: _policy,
                            initiallyExpanded: false,
                          ),
                          
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ),
                  
                  // Apply button
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, -1),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          // Build the RoomFilter object
                          final filter = RoomFilter(
                            city: _filter.city,
                            district: _filter.district,
                            ward: _filter.ward,
                            type: _filter.type,
                            minPrice: _filter.minPrice,
                            maxPrice: _filter.maxPrice,
                            minPeople: _filter.minPeople,
                            maxPeople: _filter.maxPeople,
                            tagIds: _filter.tagIds?.isNotEmpty == true ? List.from(_filter.tagIds!) : null,
                            hasFindPartnerPost: _hasFindPartnerPost,
                            limit: 20,
                          );
                          
                          debugPrint('FilterBottomSheet: Applying filter with city=${_filter.city}, district=${_filter.district}, type=${_filter.type}');
                          
                          // Close the bottom sheet
                          Navigator.pop(context);
                          
                          // Call the callback with the filter
                          widget.onApplyFilter(filter);
                          
                          debugPrint('FilterBottomSheet: onApplyFilter called, bottom sheet closed');
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor: Colors.white,
                          backgroundColor: _accentColor, // Use accent color for CTA
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 3,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.filter_list_rounded),
                            const SizedBox(width: 8),
                            Text(
                              'Áp dụng',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // Xây dựng tiêu đề section với màu sắc
  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _secondaryColor.withOpacity(0.7), // Sử dụng màu secondary cho background
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  // Xây dựng dropdown field với màu sắc
  Widget _buildDropdownField<T>({
    required String label,
    required List<String> items,
    required String hint,
    required T? value,
    required Function(String?)? onChanged,
    bool isLoading = false,
    T Function(String)? itemValue,
    Color iconColor = Colors.blue,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _primaryColor, // Use primary color consistently
          ),
        ),
        const SizedBox(height: 6),
        isLoading
            ? LinearProgressIndicator(
                backgroundColor: _secondaryColor,
                valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _primaryColor.withOpacity(0.3)),
                  color: onChanged == null ? Colors.grey.shade100 : Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  value: value is String ? (items.contains(value) ? value : null) : 
                         value != null ? items.firstWhere(
                           (item) => (itemValue?.call(item) ?? item) == value,
                           orElse: () => '', 
                         ).isEmpty ? null : items.firstWhere(
                           (item) => (itemValue?.call(item) ?? item) == value,
                           orElse: () => '',
                         ) : null,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: Icon(Icons.search, color: _primaryColor),
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 13),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: onChanged == null ? Colors.grey.shade400 : _primaryColor,
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                ),
              ),
      ],
    );
  }

  // Xây dựng danh sách các tiện ích với màu sắc
  List<Widget> _buildAmenityTags(List<RoomTag> roomTags) {
    // Map des icônes pour les tiện ích courants
    final Map<String, IconData> amenityIcons = {
      'Air Conditioning': Icons.ac_unit,
      'Balcony': Icons.balcony,
      'Bed': Icons.bed,
      'Fridge': Icons.kitchen,
      'Internet': Icons.wifi,
      'Kitchen': Icons.restaurant,
      'Laundry': Icons.local_laundry_service,
      'Microwave': Icons.microwave,
      'Parking': Icons.local_parking,
      'TV': Icons.tv,
      'Water Heater': Icons.hot_tub,
      // Valeurs par défaut pour les autres tiện ích
      'default': Icons.star,
    };

    if (_isLoadingAmenities) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: CircularProgressIndicator(),
          ),
        )
      ];
    }
    
    if (roomTags.isEmpty) {
      return [
        const Center(
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Text('Không có tiện ích nào'),
          ),
        )
      ];
    }
    
    return roomTags.map((amenity) {
      final isSelected = _filter.tagIds?.contains(amenity.id) ?? false;

      final Color amenityColor = _getColorForAmenity(amenity.name);

      final IconData amenityIcon = amenityIcons[amenity.name] ?? amenityIcons['default']!;

      return ChoiceChip(
        avatar: Icon(
          amenityIcon,
          size: 18,
          color: isSelected ? Colors.white : amenityColor,
        ),
        label: Text(
          amenity.displayName ?? amenity.name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w500,
            fontSize: 13,
          ),
        ),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            final List<String> tagIds = List.from(_filter.tagIds ?? []);
            if (selected) {
              tagIds.add(amenity.id);
            } else {
              tagIds.remove(amenity.id);
            }
            _filter = _filter.copyWith(tagIds: tagIds);
          });
        },
        backgroundColor: Colors.white,
        selectedColor: amenityColor,
        showCheckmark: false,
        elevation: isSelected ? 2 : 0,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: isSelected ? amenityColor : Colors.grey.shade300,
            width: 1,
          ),
        ),
        pressElevation: 4,
      );
    }).toList();
  }
  
  // Méthode pour obtenir une couleur basée sur le nom de l'amenity
  Color _getColorForAmenity(String name) {
    // Map des couleurs prédéfinies pour certains tiện ích
    final Map<String, Color> predefinedColors = {
      'Air Conditioning': const Color(0xFF00BCD4), // Cyan
      'Balcony': const Color(0xFF9C27B0),          // Purple
      'Bed': const Color(0xFF795548),              // Brown
      'Fridge': const Color(0xFF4CAF50),           // Green
      'Internet': const Color(0xFF3F51B5),         // Indigo
      'Kitchen': const Color(0xFFFF5722),          // Deep Orange
      'Laundry': const Color(0xFF009688),          // Teal
      'Microwave': const Color(0xFFE91E63),        // Pink
      'Parking': const Color(0xFF8BC34A),          // Light Green
      'TV': const Color(0xFF673AB7),               // Deep Purple
      'Water Heater': const Color(0xFFFF9800),     // Orange
    };
    
    // Retourner la couleur prédéfinie si elle existe, sinon générer une couleur basée sur le nom
    return predefinedColors[name] ?? _generateColorFromString(name);
  }
  
  // Méthode pour générer une couleur basée sur une chaîne de caractères
  Color _generateColorFromString(String input) {
    // Calculer un hash simple à partir de la chaîne
    int hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = input.codeUnitAt(i) + ((hash << 5) - hash);
    }
    
    // Convertir le hash en une couleur HSL avec une saturation et une luminosité fixes
    final double hue = (hash % 360).abs().toDouble();
    
    // Convertir HSL en RGB
    return HSLColor.fromAHSL(1.0, hue, 0.7, 0.5).toColor();
  }

  // Add new method to build expansion panels for tag categories
  Widget _buildTagExpansionPanel({
    required String title,
    required IconData icon,
    required List<RoomTag> tags,
    bool initiallyExpanded = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(icon, color: _primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _primaryColor,
                ),
              ),
              const SizedBox(width: 8),
              if (_filter.tagIds?.any((id) => tags.any((tag) => tag.id == id)) ?? false)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _secondaryColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${_filter.tagIds?.where((id) => tags.any((tag) => tag.id == id)).length ?? 0}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                ),
            ],
          ),
          initiallyExpanded: initiallyExpanded,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.grey.shade50,
          iconColor: _primaryColor,
          collapsedIconColor: Colors.grey.shade600,
          children: [
            _isLoadingAmenities
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : tags.isEmpty
                    ? const Center(
                        child: Padding(
                          padding: EdgeInsets.all(16.0),
                          child: Text('Không có tiện ích nào'),
                        ),
                      )
                    : Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _buildAmenityTags(tags),
                      ),
          ],
        ),
      ),
    );
  }
} 