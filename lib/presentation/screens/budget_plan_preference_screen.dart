import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'dart:math';
import 'package:roomily/core/config/app_colors.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_cubit.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_state.dart';
import 'package:roomily/data/blocs/tag/tag_cubit.dart';
import 'package:roomily/data/blocs/tag/tag_state.dart';
import 'package:roomily/core/utils/tag_category.dart';
import 'package:roomily/core/utils/room_type.dart';
import 'package:roomily/data/models/budget_plan_preference.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/repositories/budget_plan_repository.dart';
import 'package:roomily/data/repositories/budget_plan_repository_impl.dart';
import 'package:roomily/data/repositories/tag_repository.dart';
import 'package:roomily/presentation/screens/budget_planner_results_screen.dart';
import 'package:roomily/presentation/widgets/common/custom_bottom_navigation_bar.dart';
// import 'package:flutter_animate/flutter_animate.dart';
import 'package:roomily/core/services/location_service.dart';
import 'package:roomily/core/services/province_mapper.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class BudgetPlanPreferenceScreen extends StatefulWidget {
  final BudgetPlanPreference? initialPreference;
  
  const BudgetPlanPreferenceScreen({
    Key? key, 
    this.initialPreference,
  }) : super(key: key);

  @override
  State<BudgetPlanPreferenceScreen> createState() => _BudgetPlanPreferenceScreenState();
}

class _BudgetPlanPreferenceScreenState extends State<BudgetPlanPreferenceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  int _currentPage = 0;

  // Form fields
  String _roomType = RoomType.APARTMENT.name;
  String _city = '';
  String _district = '';
  String _ward = '';
  int _monthlySalary = 0;
  int _maxBudget = 0;
  final List<String> _mustHaveTagIds = [];
  final List<String> _niceToHaveTagIds = [];
  
  // Flags to track one-time operations
  bool _mustHaveTagsProcessed = false;
  bool _niceToHaveTagsProcessed = false;

  // Room types - filtering out the ALL option which isn't relevant for budget planning
  final List<String> _roomTypes = RoomType.values.where((e) => e != RoomType.ALL).map((e) => e.name).toList();

  // Location data and service
  late LocationService _locationService;
  late ProvinceMapper _provinceMapper;
  List<String> _cities = [];
  List<String> _districts = [];
  List<String> _wards = [];
  List<Map<String, dynamic>> _provincesData = [];
  List<Map<String, dynamic>> _districtsData = [];
  List<Map<String, dynamic>> _wardsData = [];
  Map<String, int> _selectedCodes = {};
  bool _isLoadingProvinces = false;
  bool _isLoadingDistricts = false;
  bool _isLoadingWards = false;

  // UI helpers
  final List<String> _steps = [
    "Thông tin cơ bản",
    "Ngân sách",
    "Tiện ích bắt buộc",
    "Tiện ích nên có"
  ];

  // Repository
  late BudgetPlanRepository _budgetPlanRepository;

  // Loading state
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _locationService = GetIt.instance<LocationService>();
    _provinceMapper = ProvinceMapper(locationService: _locationService);
    _budgetPlanRepository = BudgetPlanRepositoryImpl();
    _loadProvinces();
    
    // Initialize form with data from initialPreference if provided
    if (widget.initialPreference != null) {
      setState(() {
        _isSaving = true; // Show loading indicator during initialization
      });
      
      // Initialize with a slight delay to allow UI to render
      Future.delayed(const Duration(milliseconds: 300), () {
        _initializeFromPreference().then((_) {
          setState(() {
            _isSaving = false; // Hide loading indicator when done
          });
          
          // Show all tags for debug purposes
          Future.delayed(const Duration(seconds: 1), () {
            _debugPrintAllTags();
          });
        }).catchError((error) {
          debugPrint('❌ Error initializing preferences: $error');
          setState(() {
            _isSaving = false; // Hide loading indicator on error
          });
        });
      });
    }
  }
  
  Future<void> _initializeFromPreference() async {
    if (widget.initialPreference != null) {
      // Log nhận được dữ liệu để debug
      debugPrint('📊 Initializing with preference data: ${widget.initialPreference!.toJson()}');
      
      if (!mounted) return;  // Add check for mounted
      
      setState(() {
        _roomType = widget.initialPreference!.roomType;
        _monthlySalary = widget.initialPreference!.monthlySalary ?? 0;
        _maxBudget = widget.initialPreference!.maxBudget ?? 0;
        
        // Debug thông tin tài chính
        debugPrint('💰 Financial info - Salary: $_monthlySalary, Budget: $_maxBudget');
        
        // Handle mustHave and niceToHave tags (they'll be populated more completely after tags are loaded)
        if (widget.initialPreference!.mustHaveTagIds != null) {
          _mustHaveTagIds.clear();
          _mustHaveTagIds.addAll(widget.initialPreference!.mustHaveTagIds!);
        }
        
        if (widget.initialPreference!.niceToHaveTagIds != null) {
          _niceToHaveTagIds.clear();
          _niceToHaveTagIds.addAll(widget.initialPreference!.niceToHaveTagIds!);
        }
      });
      
      // Handle location data
      await _initializeLocationData();
    }
  }
  
  Future<void> _initializeLocationData() async {
    if (!mounted) return;  // Add check for mounted
    
    if (widget.initialPreference != null && widget.initialPreference!.city.isNotEmpty) {
      debugPrint('🌍 Initializing location data for city: ${widget.initialPreference!.city}');
      if (widget.initialPreference!.district != null) {
        debugPrint('🏙️ District from preference: ${widget.initialPreference!.district}');
      }
      if (widget.initialPreference!.ward != null) {
        debugPrint('🏘️ Ward from preference: ${widget.initialPreference!.ward}');
      }
      
      try {
        // Use ProvinceMapper to match the city name
        final matchedProvince = await _provinceMapper.mapProvinceNameToApi(widget.initialPreference!.city);
        debugPrint('🔍 Matched province: ${matchedProvince?['name']}');
        
        if (matchedProvince != null) {
          // Wait until provinces are loaded with a timeout to prevent infinite waiting
          bool provincesLoaded = false;
          
          // Instead of using Future.doWhile which can block, check if provinces are loaded
          // with a timeout to prevent freezing
          if (_isLoadingProvinces) {
            await Future.delayed(const Duration(milliseconds: 500));
            // If still loading after timeout, just proceed with what we have
            if (_isLoadingProvinces) {
              debugPrint('⚠️ Provinces still loading after timeout, proceeding anyway');
              provincesLoaded = false;
            } else {
              provincesLoaded = true;
            }
          } else {
            provincesLoaded = true;
          }
          
          if (!mounted) return;  // Add check for mounted
          
          setState(() {
            _city = matchedProvince['name'] as String;
            debugPrint('🔄 Set city to: $_city');
          });
          
          // Load districts for this province
          final provinceCode = matchedProvince['code'] as int;
          _selectedCodes['province'] = provinceCode;
          
          try {
            await _loadDistricts(provinceCode);
            debugPrint('📍 Loaded ${_districts.length} districts for province $provinceCode');
            
            // Handle district if provided
            if (!mounted) return;  // Add check for mounted
            
            if (widget.initialPreference!.district != null && widget.initialPreference!.district!.isNotEmpty) {
              // Try to find a matching district
              final districtName = widget.initialPreference!.district!;
              await _findAndSetDistrict(districtName);
              
              // Handle ward if provided
              if (!mounted) return;  // Add check for mounted
              
              if (widget.initialPreference!.ward != null && widget.initialPreference!.ward!.isNotEmpty) {
                final wardName = widget.initialPreference!.ward!;
                _findAndSetWard(wardName);
              }
            }
          } catch (e) {
            debugPrint('❌ Error loading district data: $e');
          }
        }
      } catch (e) {
        debugPrint('❌ Error initializing location data: $e');
      }
    }
  }
  
  Future<void> _findAndSetDistrict(String districtName) async {
    debugPrint('🔍 Finding district match for: $districtName');
    
    // Clean up district name for better matching
    final cleanDistrictName = _cleanLocationName(districtName);
    
    // Simple fuzzy matching for district name
    String bestMatch = '';
    int bestScore = 0;
    
    for (final district in _districts) {
      // Clean up district name for comparison
      final cleanDistrict = _cleanLocationName(district);
      
      // Calculate similarity score
      final score = _calculateSimilarity(cleanDistrict, cleanDistrictName);
      debugPrint('🔢 District similarity score: $score for "$district" vs "$districtName"');
      
      if (score > bestScore) {
        bestScore = score;
        bestMatch = district;
      }
    }
    
    // If we have a decent match, set it and load wards
    if (bestScore > 50 && bestMatch.isNotEmpty && mounted) {
      debugPrint('✅ Found district match: "$bestMatch" for "$districtName" with score: $bestScore');
      
      setState(() {
        _district = bestMatch;
      });
      
      // Find district code and load wards
      final district = _districtsData.firstWhere(
        (d) => d['name'] == bestMatch,
        orElse: () => {'code': 0},
      );
      
      if (district['code'] != 0) {
        _selectedCodes['district'] = district['code'] as int;
        await _loadWards(district['code'] as int);
        
        if (!mounted) return; // Add check after async operation
      }
    } else {
      debugPrint('⚠️ No good district match found. Best match: "$bestMatch" with score: $bestScore');
    }
  }
  
  void _findAndSetWard(String wardName) {
    if (!mounted) return;
    
    debugPrint('🔍 Finding ward match for: $wardName');
    
    // Clean up ward name for better matching
    final cleanWardName = _cleanLocationName(wardName);
    
    // Simple fuzzy matching for ward name
    String bestMatch = '';
    int bestScore = 0;
    
    for (final ward in _wards) {
      // Clean up ward name for comparison
      final cleanWard = _cleanLocationName(ward);
      
      // Calculate similarity score
      final score = _calculateSimilarity(cleanWard, cleanWardName);
      debugPrint('🔢 Ward similarity score: $score for "$ward" vs "$wardName"');
      
      if (score > bestScore) {
        bestScore = score;
        bestMatch = ward;
      }
    }
    
    // If we have a decent match, set it
    if (bestScore > 50 && bestMatch.isNotEmpty) {
      debugPrint('✅ Found ward match: "$bestMatch" for "$wardName" with score: $bestScore');
      
      setState(() {
        _ward = bestMatch;
      });
    } else {
      debugPrint('⚠️ No good ward match found. Best match: "$bestMatch" with score: $bestScore');
    }
  }
  
  // Clean location name to improve matching
  String _cleanLocationName(String name) {
    // Convert to lowercase
    String cleaned = name.toLowerCase();
    
    // Remove common prefixes
    cleaned = cleaned.replaceAll('quận ', '');
    cleaned = cleaned.replaceAll('huyện ', '');
    cleaned = cleaned.replaceAll('phường ', '');
    cleaned = cleaned.replaceAll('xã ', '');
    cleaned = cleaned.replaceAll('thị trấn ', '');
    cleaned = cleaned.replaceAll('district ', '');
    cleaned = cleaned.replaceAll('ward ', '');
    
    // Remove special characters and extra spaces
    cleaned = cleaned.replaceAll(RegExp(r'[^\w\s]'), '');
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();
    
    return cleaned;
  }
  
  // Improved similarity calculation
  int _calculateSimilarity(String str1, String str2) {
    // For empty strings
    if (str1.isEmpty || str2.isEmpty) return 0;
    
    // If the strings are identical
    if (str1 == str2) return 100;
    
    // If one string contains the other
    if (str1.contains(str2)) return 80;
    if (str2.contains(str1)) return 80;
    
    // Count matching characters
    int matches = 0;
    final minLength = str1.length < str2.length ? str1.length : str2.length;
    
    for (int i = 0; i < minLength; i++) {
      if (str1[i] == str2[i]) matches++;
    }
    
    // Calculate percentage
    return ((matches / minLength) * 100).round();
  }
  
  // For handling tag names instead of IDs
  void _initializeTagsFromNames(List<String> tagNames, {required bool isMustHave}) {
    // This should be called once the tags are loaded
    final tagsState = context.read<TagCubit>().state;
    if (tagsState.tags.isEmpty) return;
    
    final targetList = isMustHave ? _mustHaveTagIds : _niceToHaveTagIds;
    final tagNameList = List<String>.from(tagNames); // Create a copy to avoid modifying the original
    
    // Debug tags
    debugPrint('🏷️ Processing ${tagNameList.length} tag names: $tagNameList');
    
    // Limit the number of tags to process to prevent performance issues
    if (tagNameList.length > 10) {
      debugPrint('⚠️ Too many tag names to process (${tagNameList.length}), limiting to 10');
      tagNameList.length = 10;
    }
    
    // Process tag names using the extracted method
    _processApiTagNames(tagNameList, isMustHave, tagsState.tags);
  }

  Future<void> _loadProvinces() async {
    try {
      setState(() {
        _isLoadingProvinces = true;
      });

      final provinces = await _locationService.getProvinces();
      
      if (!mounted) return; // Add mounted check here
      
      setState(() {
        _provincesData = provinces;
        _cities = provinces.map((p) => p['name'] as String).toList();
        _isLoadingProvinces = false;
      });
    } catch (e) {
      if (!mounted) return; // Add mounted check before error handling
      
      setState(() {
        _isLoadingProvinces = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load provinces: $e')),
      );
    }
  }

  // Tải danh sách quận/huyện từ API
  Future<void> _loadDistricts(int provinceCode) async {
    debugPrint('🔄 Loading districts for province code: $provinceCode');
    
    if (!mounted) return;  // Add check for mounted before any setState calls
    
    setState(() {
      _isLoadingDistricts = true;
      _districts = [];
      _wards = [];
      _district = '';
      _ward = '';
    });

    try {
      _districtsData = await _locationService.getDistricts(provinceCode);
      debugPrint('✅ Loaded ${_districtsData.length} districts');

      if (mounted) {
        setState(() {
          _districts = _districtsData.map((d) => d['name'] as String).toList();
          _isLoadingDistricts = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading districts: $e');
      if (mounted) {
        setState(() {
          _isLoadingDistricts = false;
        });
      }
    }
  }

  // Tải danh sách phường/xã từ API
  Future<void> _loadWards(int districtCode) async {
    debugPrint('🔄 Loading wards for district code: $districtCode');
    
    if (!mounted) return;  // Add check for mounted before any setState calls
    
    setState(() {
      _isLoadingWards = true;
      _wards = [];
      _ward = '';
    });

    try {
      _wardsData = await _locationService.getWards(districtCode);
      debugPrint('✅ Loaded ${_wardsData.length} wards');

      if (mounted) {
        setState(() {
          _wards = _wardsData.map((w) => w['name'] as String).toList();
          _isLoadingWards = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading wards: $e');
      if (mounted) {
        setState(() {
          _isLoadingWards = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    // Validate current page before proceeding
    if (_currentPage == 0) {
      // Validate room type and city
      if (_city.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng chọn thành phố'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    } else if (_currentPage == 1) {
      // Validate budget info
      if (_monthlySalary <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập thu nhập hàng tháng hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      if (_maxBudget <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Vui lòng nhập ngân sách tối đa hợp lệ'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    if (_currentPage < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    } else {
      _submitForm(context);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => TagCubit(
            tagRepository: GetIt.instance<TagRepository>(),
          )..getAllTags(),
        ),
      ],
      child: Scaffold(
        body: Builder(
          builder: (context) {
            return Stack(
              children: [
                // Background gradient
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade800,
                        Colors.blue.shade500,
                      ],
                    ),
                  ),
                ),

                SafeArea(
                  child: Column(
                    children: [
                      _buildAppBar(),
                      _buildProgressIndicator(),

                      Expanded(
                        child: Form(
                          key: _formKey,
                          child: PageView(
                            controller: _pageController,
                            physics: const NeverScrollableScrollPhysics(),
                            onPageChanged: (int page) {
                              setState(() {
                                _currentPage = page;
                              });
                            },
                            children: [
                              _buildBasicInfoPage(),
                              _buildBudgetPage(),
                              _buildMustHaveAmenitiesPage(),
                              _buildNiceToHaveAmenitiesPage(),
                            ],
                          ),
                        ),
                      ),

                      _buildNavButtons(),
                    ],
                  ),
                ),

                if (_isSaving)
                  Container(
                    color: Colors.black.withOpacity(0.5),
                    child: const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircularProgressIndicator(
                        color: Colors.white,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Đang xử lý...',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              if (_currentPage == 0) {
                Navigator.pop(context);
              } else {
                _previousPage();
              }
            },
          ),
          const Expanded(
            child: Text(
              'Tùy chỉnh kế hoạch ngân sách',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // if (widget.initialPreference != null)
          //   IconButton(
          //     icon: const Icon(Icons.preview, color: Colors.white),
          //     onPressed: () => _navigateToResults(),
          //     tooltip: 'Xem kết quả ngay',
          //   ),
          // if (widget.initialPreference == null)
          // const SizedBox(width: 48), // Balance the layout
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(
              _steps.length,
              (index) => _buildStepIndicator(index),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: (_currentPage + 1) / _steps.length,
              backgroundColor: Colors.white.withOpacity(0.3),
              color: Colors.white,
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _steps[_currentPage],
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int index) {
    final bool isActive = index <= _currentPage;

    return Column(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Icon(
              _getStepIcon(index),
              color: isActive ? Colors.blue.shade800 : Colors.white,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  IconData _getStepIcon(int step) {
    switch (step) {
      case 0:
        return Icons.home;
      case 1:
        return Icons.wallet;
      case 2:
        return Icons.star;
      case 3:
        return Icons.star;
      default:
        return Icons.circle;
    }
  }

  Widget _buildBasicInfoPage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.home_work,
                size: 48,
                color: Colors.blue.shade800,
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Loại phòng bạn muốn tìm?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),
          _buildRoomTypeSelector(),

          const SizedBox(height: 30),
          const Text(
            'Bạn muốn thuê ở đâu?',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),
          _buildLocationFields(),
        ],
      ),
    );
  }

  Widget _buildBudgetPage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.account_balance_wallet,
                size: 48,
                color: Colors.green.shade700,
              ),
            ),
          ),

          const SizedBox(height: 20),
          const Text(
            'Thông tin tài chính của bạn',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 24),
          _buildNumberField(
            label: 'Thu nhập hàng tháng (VND)',
            hint: 'Nhập thu nhập hàng tháng của bạn',
            initialValue: _monthlySalary > 0 ? _monthlySalary.toString() : '',
            onChanged: (value) {
              setState(() {
                _monthlySalary = int.tryParse(value) ?? 0;
                debugPrint('💰 Updated monthly salary: $_monthlySalary');
              });
            },
            icon: Icons.account_balance_wallet,
            color: Colors.green.shade700,
            errorText: 'Vui lòng nhập thu nhập hàng tháng (chỉ nhập số)',
          ),

          const SizedBox(height: 24),
          _buildNumberField(
            label: 'Ngân sách tối đa (VND)',
            hint: 'Nhập ngân sách tối đa cho việc thuê nhà',
            initialValue: _maxBudget > 0 ? _maxBudget.toString() : '',
            onChanged: (value) {
              setState(() {
                _maxBudget = int.tryParse(value) ?? 0;
                debugPrint('💰 Updated max budget: $_maxBudget');
              });
            },
            icon: Icons.money,
            color: Colors.green.shade700,
            errorText: 'Vui lòng nhập ngân sách tối đa (chỉ nhập số)',
          ),

          const SizedBox(height: 20),
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.lightbulb, color: Colors.amber.shade700, size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Mẹo tiết kiệm',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Ngân sách tiêu chuẩn cho thuê nhà nên chiếm khoảng 30% thu nhập hàng tháng của bạn.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMustHaveAmenitiesPage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: _buildMustHaveTagSelector(),
    );
  }

  Widget _buildNiceToHaveAmenitiesPage() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: _buildNiceToHaveTagSelector(),
    );
  }

  Widget _buildMustHaveTagSelector() {
    return BlocBuilder<TagCubit, TagState>(
      builder: (context, state) {
        if (state.status == TagStatus.loading) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.green.shade700,
            ),
          );
        }

        if (state.tags.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có tiện ích nào',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Map tag names to tag IDs if we have preferences from speech recognition
        // This is only done once when tags are first loaded
        if (!_mustHaveTagsProcessed && 
            widget.initialPreference != null && 
            widget.initialPreference!.mustHaveTagIds != null && 
            widget.initialPreference!.mustHaveTagIds!.isNotEmpty) {
          
          _mustHaveTagsProcessed = true; // Mark as processed to avoid repeated processing
          
          // Get the tag IDs/names from preferences
          final tagIdsOrNames = List<String>.from(widget.initialPreference!.mustHaveTagIds!);
          debugPrint('🔍 Received mustHaveTagIds/names: $tagIdsOrNames');
          
          // Process tags after the build is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            
            // Clear existing tags first
            setState(() {
              _mustHaveTagIds.clear();
            });
            
            // Process API tag names with the current state
            _processApiTagNames(tagIdsOrNames, true, state.tags);
            
            // Update UI after processing
            setState(() {});
          });
        }

        // Organize tags by category
        final Map<TagCategory, List<RoomTag>> tagsByCategory = {
          for (var category in TagCategory.values)
            category: state.tags.where((tag) => tag.category == category).toList()
        };

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              // Add a debug button to show all tag IDs
              if (widget.initialPreference != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: OutlinedButton(
                    onPressed: () => _showAllTagsDialog(state.tags),
                    child: const Text('Debug: Show all tags'),
                  ),
                ),
              
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    size: 48,
                    color: Colors.green.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Tiện ích bắt buộc phải có',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),
              const Text(
                'Chọn các tiện ích không thể thiếu đối với bạn',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Section title for must-have
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.green.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green.shade700),
                    const SizedBox(width: 8),
                    Text(
                      "TIỆN ÍCH BẮT BUỘC CÓ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    const Spacer(),
                    if (_mustHaveTagIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.green.shade700,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_mustHaveTagIds.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Nearby points of interest - display first (MUST HAVE only)
              if (tagsByCategory[TagCategory.NEARBY_POI]!.isNotEmpty)
                _buildTagPanel(
                  title: 'Tiện ích xung quanh',
                  icon: Icons.location_on,
                  tags: tagsByCategory[TagCategory.NEARBY_POI]!,
                  initiallyExpanded: true,
                  isMustHave: true,
                ),

              const SizedBox(height: 8),

              // Room features section (MUST HAVE only)
              if (tagsByCategory[TagCategory.IN_ROOM_FEATURE]!.isNotEmpty)
                _buildTagPanel(
                  title: 'Tiện ích trong phòng',
                  icon: Icons.hotel,
                  tags: tagsByCategory[TagCategory.IN_ROOM_FEATURE]!,
                  initiallyExpanded: false,
                  isMustHave: true,
                ),

              const SizedBox(height: 8),

              // Building features section (MUST HAVE only)
              if (tagsByCategory[TagCategory.BUILDING_FEATURE]!.isNotEmpty)
                _buildTagPanel(
                  title: 'Tiện ích tòa nhà',
                  icon: Icons.apartment,
                  tags: tagsByCategory[TagCategory.BUILDING_FEATURE]!,
                  initiallyExpanded: false,
                  isMustHave: true,
                ),

              const SizedBox(height: 8),

              // Policies (MUST HAVE only)
              if (tagsByCategory[TagCategory.POLICY]!.isNotEmpty)
                _buildTagPanel(
                  title: 'Chính sách',
                  icon: Icons.gavel,
                  tags: tagsByCategory[TagCategory.POLICY]!,
                  initiallyExpanded: false,
                  isMustHave: true,
                ),

              // Add some padding at the bottom to ensure all content is visible
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNiceToHaveTagSelector() {
    return BlocBuilder<TagCubit, TagState>(
      builder: (context, state) {
        if (state.status == TagStatus.loading) {
          return Center(
            child: CircularProgressIndicator(
              color: Colors.blue.shade700,
            ),
          );
        }

        if (state.tags.isEmpty) {
          return SizedBox(
            height: 200,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.category_outlined,
                    size: 48,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Không có tiện ích nào',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        
        // Map tag names to tag IDs if we have preferences from speech recognition
        // This is only done once when tags are first loaded
        if (!_niceToHaveTagsProcessed &&
            widget.initialPreference != null && 
            widget.initialPreference!.niceToHaveTagIds != null && 
            widget.initialPreference!.niceToHaveTagIds!.isNotEmpty) {
            
          _niceToHaveTagsProcessed = true; // Mark as processed to avoid repeated processing
          
          // Get the tag IDs/names from preferences
          final tagIdsOrNames = List<String>.from(widget.initialPreference!.niceToHaveTagIds!);
          debugPrint('🔍 Received niceToHaveTagIds/names: $tagIdsOrNames');
          
          // Process tags after the build is complete
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            
            // Clear existing tags first
            setState(() {
              _niceToHaveTagIds.clear();
            });
            
            // Process API tag names with the current state
            _processApiTagNames(tagIdsOrNames, false, state.tags);
            
            // Update UI after processing
            setState(() {});
          });
        }

        // Organize tags by category
        final Map<TagCategory, List<RoomTag>> tagsByCategory = {
          for (var category in TagCategory.values)
            category: state.tags.where((tag) => tag.category == category).toList()
        };

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Column(
            children: [
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.star,
                    size: 48,
                    color: Colors.blue.shade700,
                  ),
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                'Tiện ích nên có',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 10),
              const Text(
                'Chọn các tiện ích bạn mong muốn nhưng không bắt buộc',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.black54,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 24),

              // Section title for nice-to-have
              Container(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Colors.blue.shade700),
                    const SizedBox(width: 8),
                    Text(
                      "TIỆN ÍCH NÊN CÓ",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                    const Spacer(),
                    if (_niceToHaveTagIds.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade700,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          '${_niceToHaveTagIds.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Nearby points of interest
              if (tagsByCategory[TagCategory.NEARBY_POI]!.isNotEmpty)
                _buildTagPanel(
                  title: 'Tiện ích xung quanh',
                  icon: Icons.location_on,
                  tags: tagsByCategory[TagCategory.NEARBY_POI]!,
                  initiallyExpanded: true,
                  isMustHave: false,
                ),

              const SizedBox(height: 8),

              // Room features section
              if (tagsByCategory[TagCategory.IN_ROOM_FEATURE]!.isNotEmpty)
                _buildTagPanel(
                  title: 'Tiện ích trong phòng',
                  icon: Icons.hotel,
                  tags: tagsByCategory[TagCategory.IN_ROOM_FEATURE]!,
                  initiallyExpanded: false,
                  isMustHave: false,
                ),

              const SizedBox(height: 8),

              // Building features section
              if (tagsByCategory[TagCategory.BUILDING_FEATURE]!.isNotEmpty)
                _buildTagPanel(
                  title: 'Tiện ích tòa nhà',
                  icon: Icons.apartment,
                  tags: tagsByCategory[TagCategory.BUILDING_FEATURE]!,
                  initiallyExpanded: false,
                  isMustHave: false,
                ),

              const SizedBox(height: 8),

              // Policies
              if (tagsByCategory[TagCategory.POLICY]!.isNotEmpty)
                _buildTagPanel(
                  title: 'Chính sách',
                  icon: Icons.gavel,
                  tags: tagsByCategory[TagCategory.POLICY]!,
                  initiallyExpanded: false,
                  isMustHave: false,
                ),

              // Add some padding at the bottom to ensure all content is visible
              const SizedBox(height: 40),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTagPanel({
    required String title,
    required IconData icon,
    required List<RoomTag> tags,
    bool initiallyExpanded = false,
    required bool isMustHave,
  }) {
    // Get the appropriate tag list based on whether this is for must-have or nice-to-have
    final tagList = isMustHave ? _mustHaveTagIds : _niceToHaveTagIds;
    final otherTagList = isMustHave ? _niceToHaveTagIds : _mustHaveTagIds;

    // Filter out tags that are already in the must-have list if this is nice-to-have section
    List<RoomTag> filteredTags = tags;
    if (!isMustHave) {
      filteredTags = tags.where((tag) => !_mustHaveTagIds.contains(tag.id)).toList();
      // If all tags are filtered out, show a message instead
      if (filteredTags.isEmpty) {
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade200),
            borderRadius: BorderRadius.circular(10),
          ),
          margin: const EdgeInsets.only(bottom: 4),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ExpansionTile(
              title: Row(
                children: [
                  Icon(icon, color: _getCategoryColor(tags.first.category), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getCategoryColor(tags.first.category),
                    ),
                  ),
                ],
              ),
              initiallyExpanded: initiallyExpanded,
              childrenPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              collapsedBackgroundColor: Colors.white,
              backgroundColor: Colors.grey.shade50,
              iconColor: _getCategoryColor(tags.first.category),
              collapsedIconColor: Colors.grey.shade600,
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Text(
                      "Tất cả tiện ích đã được chọn trong mục tiện ích bắt buộc",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    }

    // Count selected tags in this category
    final int selectedCount = tagList.where((id) =>
      filteredTags.any((tag) => tag.id == id)
    ).length;

    // Theme colors
    final baseColor = isMustHave ? Colors.green : Colors.blue;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(10),
      ),
      margin: const EdgeInsets.only(bottom: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ExpansionTile(
          title: Row(
            children: [
              Icon(icon, color: _getCategoryColor(filteredTags.first.category), size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: _getCategoryColor(filteredTags.first.category),
                ),
              ),
              const SizedBox(width: 8),
              if (selectedCount > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: baseColor.shade100,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '$selectedCount',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: baseColor.shade700,
                    ),
                  ),
                ),
            ],
          ),
          initiallyExpanded: initiallyExpanded,
          childrenPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          collapsedBackgroundColor: Colors.white,
          backgroundColor: Colors.grey.shade50,
          iconColor: _getCategoryColor(filteredTags.first.category),
          collapsedIconColor: Colors.grey.shade600,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Wrap(
                spacing: 6.0,
                runSpacing: 8.0,
                alignment: WrapAlignment.start,
                children: _buildTagChips(filteredTags, isMustHave),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildTagChips(List<RoomTag> tags, bool isMustHave) {
    final color = isMustHave ? Colors.green.shade700 : Colors.blue.shade700;
    final mainTagList = isMustHave ? _mustHaveTagIds : _niceToHaveTagIds;
    final otherTagList = isMustHave ? _niceToHaveTagIds : _mustHaveTagIds;

    debugPrint('🏷️ Building ${isMustHave ? "Must Have" : "Nice to Have"} tag chips. Selected: $mainTagList');

    return tags.map((tag) {
      final isSelected = mainTagList.contains(tag.id);
      final isInOtherList = otherTagList.contains(tag.id);

      // Debug selection state
      if (isSelected) {
        debugPrint('✅ Tag selected: ${tag.name} (ID: ${tag.id}, Display: ${tag.displayName})');
      }

      return Material(
        color: isSelected ? color : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (!mainTagList.contains(tag.id)) {
                // Add to this list
                mainTagList.add(tag.id);
                debugPrint('➕ Added tag: ${tag.name} (ID: ${tag.id}) to ${isMustHave ? "Must Have" : "Nice to Have"}');
                // Remove from other list if present
                otherTagList.remove(tag.id);
              } else {
                // Remove from this list
                mainTagList.remove(tag.id);
                debugPrint('➖ Removed tag: ${tag.name} (ID: ${tag.id}) from ${isMustHave ? "Must Have" : "Nice to Have"}');
              }
            });
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? color : Colors.grey.shade300,
                width: isSelected ? 1 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getIconForTag(tag),
                  size: 16,
                  color: isSelected ? Colors.white : color,
                ),
                const SizedBox(width: 6),
                Text(
                  tag.displayName ?? tag.name,
                  style: TextStyle(
                    fontSize: 13,
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }).toList();
  }

  // Get appropriate icon for a tag
  IconData _getIconForTag(RoomTag tag) {
    // Map common tags to icons
    final Map<String, IconData> tagIcons = {
      // Room features
      'Air Conditioning': Icons.ac_unit,
      'Wifi': Icons.wifi,
      'TV': Icons.tv,
      'Bed': Icons.bed,
      'Kitchen': Icons.kitchen,
      'Fridge': Icons.kitchen,
      'Washing Machine': Icons.local_laundry_service,
      'Balcony': Icons.balcony,
      'Window': Icons.window,
      'Private Bathroom': Icons.bathroom,

      // Building features
      'Elevator': Icons.elevator,
      'Parking': Icons.local_parking,
      'Security': Icons.security,
      'CCTV': Icons.videocam,
      'Swimming Pool': Icons.pool,
      'Gym': Icons.fitness_center,

      // Nearby POI
      'Hospital': Icons.local_hospital,
      'School': Icons.school,
      'University': Icons.school,
      'Park': Icons.park,
      'Supermarket': Icons.shopping_cart,
      'Bus Stop': Icons.directions_bus,
      'Market': Icons.shopping_basket,

      // Policies
      'Pet Friendly': Icons.pets,
      'No Smoking': Icons.smoke_free,
      'No Alcohol': Icons.no_drinks,
      'Curfew': Icons.nightlight_round,
    };

    // Check if the tag name exists in the map
    for (var entry in tagIcons.entries) {
      if (tag.name.toLowerCase().contains(entry.key.toLowerCase())) {
        return entry.value;
      }
    }

    // Default icon based on category
    switch (tag.category) {
      case TagCategory.IN_ROOM_FEATURE:
        return Icons.hotel;
      case TagCategory.BUILDING_FEATURE:
        return Icons.apartment;
      case TagCategory.NEARBY_POI:
        return Icons.location_on;
      case TagCategory.POLICY:
        return Icons.gavel;
      default:
        return Icons.star;
    }
  }

  // Get color for a tag category
  Color _getCategoryColor(TagCategory category) {
    switch (category) {
      case TagCategory.IN_ROOM_FEATURE:
        return Colors.blue;
      case TagCategory.NEARBY_POI:
        return Colors.green;
      case TagCategory.POLICY:
        return Colors.purple;
      case TagCategory.BUILDING_FEATURE:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  void _submitForm(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      final preference = BudgetPlanPreference(
        roomType: _roomType,
        city: _city,
        district: _district,
        ward: _ward,
        monthlySalary: _monthlySalary,
        maxBudget: _maxBudget,
        mustHaveTagIds: _mustHaveTagIds,
        niceToHaveTagIds: _niceToHaveTagIds,
      );

      try {
        // Set loading state
        setState(() {
          _isSaving = true;
        });

        // Save directly using repository
        final result = await _budgetPlanRepository.saveBudgetPlanPreference(preference);

        // End loading
        setState(() {
          _isSaving = false;
        });

        if (result) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lưu thành công!'),
              backgroundColor: Colors.green,
            ),
          );

          // Navigate to results screen
          // Navigator.pushReplacement(
          //   context,
          //   MaterialPageRoute(
          //     builder: (context) => BudgetPlannerResultsScreen(
          //       preference: preference,
          //       title: 'Kết quả kế hoạch ngân sách',
          //     ),
          //   ),
          // );
          if(!context.mounted) return;
          Navigator.pop(context, true);

        } else {
          // Show error message
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Không thể lưu, vui lòng thử lại'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        // End loading
        setState(() {
          _isSaving = false;
        });

        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getRoomTypeDisplayName(String type) {
    switch (type) {
      case 'APARTMENT':
        return 'Căn hộ';
      case 'ROOM':
        return 'Phòng trọ';
      case 'HOUSE':
        return 'Nhà nguyên căn';
      case 'DORMITORY':
        return 'Ký túc xá';
      default:
        return type;
    }
  }

  Widget _buildNavButtons() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton.icon(
            onPressed: _currentPage > 0 ? _previousPage : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Quay lại'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: _currentPage > 0
                  ? Colors.white.withOpacity(0.2)
                  : Colors.transparent,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),

          ElevatedButton.icon(
            onPressed: _nextPage,
            icon: Icon(_currentPage < 3 ? Icons.arrow_forward : Icons.done),
            label: Text(_currentPage < 3 ? 'Tiếp theo' : 'Hoàn thành'),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.blue.shade800,
              backgroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoomTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _roomTypes.map((type) {
              final bool isSelected = _roomType == type;

              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      _roomType = type;
                    });
                  },
                  child: Container(
                    width: 110,
                    height: 90,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.blue.shade50 : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? Colors.blue.shade400 : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Colors.blue.shade200.withOpacity(0.3),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: Stack(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _getRoomTypeIcon(type),
                                size: 32,
                                color: isSelected ? Colors.blue.shade700 : Colors.grey.shade600,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _getRoomTypeDisplayName(type),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected ? Colors.blue.shade700 : Colors.grey.shade800,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade400,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _getRoomTypeIcon(String type) {
    switch (type) {
      case 'APARTMENT':
        return Icons.apartment;
      case 'ROOM':
        return Icons.hotel;
      case 'HOUSE':
        return Icons.home;
      case 'DORMITORY':
        return Icons.hotel;
      default:
        return Icons.home_work;
    }
  }

  Widget _buildLocationFields() {
    return Column(
      children: [
        _buildDropdownField(
          label: 'Thành phố',
          items: _cities,
          hint: 'Chọn thành phố',
          value: _city.isNotEmpty ? _city : null,
          onChanged: _isLoadingProvinces ? null : (String? newValue) {
            if (newValue != null) {
              setState(() {
                _city = newValue;
                _district = '';
                _ward = '';
              });

              // Tìm province code và tải districts
              final province = _provincesData.firstWhere(
                (p) => p['name'] == newValue,
                orElse: () => {'code': 0},
              );

              if (province['code'] != 0) {
                _selectedCodes['province'] = province['code'] as int;
                _loadDistricts(province['code'] as int);
              }
            }
          },
          isLoading: _isLoadingProvinces,
          prefixIcon: Icons.location_city,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Quận/Huyện',
          items: _districts,
          hint: 'Chọn quận/huyện',
          value: _district.isNotEmpty ? _district : null,
          onChanged: _districts.isEmpty || _isLoadingDistricts ? null : (String? newValue) {
            if (newValue != null) {
              setState(() {
                _district = newValue;
                _ward = '';
              });

              // Tìm district code và tải wards
              final district = _districtsData.firstWhere(
                (d) => d['name'] == newValue,
                orElse: () => {'code': 0},
              );

              if (district['code'] != 0) {
                _selectedCodes['district'] = district['code'] as int;
                _loadWards(district['code'] as int);
              }
            }
          },
          isLoading: _isLoadingDistricts,
          prefixIcon: Icons.location_on,
        ),
        const SizedBox(height: 16),
        _buildDropdownField(
          label: 'Phường/Xã',
          items: _wards,
          hint: 'Chọn phường/xã',
          value: _ward.isNotEmpty ? _ward : null,
          onChanged: _wards.isEmpty || _isLoadingWards ? null : (String? newValue) {
            if (newValue != null) {
              setState(() {
                _ward = newValue;
              });
            }
          },
          isLoading: _isLoadingWards,
          prefixIcon: Icons.location_on_outlined,
        ),
      ],
    );
  }

  Widget _buildDropdownField({
    required String label,
    required List<String> items,
    required String hint,
    required String? value,
    required Function(String?)? onChanged,
    bool isLoading = false,
    IconData prefixIcon = Icons.list,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.blue.shade800,
          ),
        ),
        const SizedBox(height: 6),
        isLoading
            ? LinearProgressIndicator(
                backgroundColor: Colors.blue.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.blue.shade800),
              )
            : Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade800.withOpacity(0.3)),
                  color: onChanged == null ? Colors.grey.shade100 : Colors.white,
                ),
                child: DropdownButtonFormField<String>(
                  value: value,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                    prefixIcon: Icon(prefixIcon, color: Colors.blue.shade800),
                  ),
                  items: items.map((item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(
                        item,
                        style: const TextStyle(fontSize: 14),
                      ),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: onChanged == null ? Colors.grey.shade400 : Colors.blue.shade800,
                  ),
                  isExpanded: true,
                  dropdownColor: Colors.white,
                  validator: (value) {
                    if (label == 'Thành phố' && (value == null || value.isEmpty)) {
                      return 'Vui lòng chọn thành phố';
                    }
                    return null;
                  },
                ),
              ),
      ],
    );
  }

  Widget _buildNumberField({
    required String label,
    required String hint,
    String initialValue = '',
    required Function(String) onChanged,
    required IconData icon,
    required Color color,
    String errorText = 'Vui lòng nhập giá trị số hợp lệ',
  }) {
    // If there's an initial value, make sure it's properly formatted
    if (initialValue.isNotEmpty) {
      debugPrint('📝 Setting initial value for $label: $initialValue');
    }
    
    // Format with thousand separators for display
    String displayValue = '';
    if (initialValue.isNotEmpty) {
      final value = int.tryParse(initialValue);
      if (value != null && value > 0) {
        displayValue = _formatNumberWithCommas(value);
      }
    }
    
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(icon, color: color),
        filled: true,
        fillColor: Colors.grey.shade50,
        errorStyle: const TextStyle(color: Colors.red),
      ),
      initialValue: displayValue,
      keyboardType: TextInputType.number,
      onChanged: (value) {
        // Remove all non-digit characters for processing
        final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
        
        if (digitsOnly.isNotEmpty) {
          onChanged(digitsOnly);
        } else {
          onChanged('0');
        }
      },
      // Custom formatter to display thousand separators
      inputFormatters: [
        ThousandsSeparatorInputFormatter(),
      ],
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Vui lòng nhập $label';
        }
        
        // Extract digits for validation
        final digitsOnly = value.replaceAll(RegExp(r'[^\d]'), '');
        if (digitsOnly.isEmpty || int.tryParse(digitsOnly) == null) {
          return errorText;
        }
        if (int.tryParse(digitsOnly)! <= 0) {
          return 'Giá trị phải lớn hơn 0';
        }
        return null;
      },
    );
  }

  // Format a number with thousand separators
  String _formatNumberWithCommas(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
  }

  // Navigate directly to results with current preference
  void _navigateToResults() {
    // Create a preference with current values
    final preference = BudgetPlanPreference(
      roomType: _roomType,
      city: _city,
      district: _district,
      ward: _ward,
      monthlySalary: _monthlySalary,
      maxBudget: _maxBudget, 
      mustHaveTagIds: _mustHaveTagIds,
      niceToHaveTagIds: _niceToHaveTagIds,
    );
    
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => BudgetPlannerResultsScreen(
          preference: preference,
          title: 'Kết quả kế hoạch ngân sách',
        ),
      ),
    );
  }
  
  Widget _buildInfoItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(value),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTagList(List<String> tagIds) {
    final tagsState = context.read<TagCubit>().state;
    
    return Wrap(
      spacing: 4,
      runSpacing: 4,
      children: tagIds.map((tagId) {
        // Tìm tag từ ID
        final tag = tagsState.tags.firstWhere(
          (tag) => tag.id == tagId,
          orElse: () => RoomTag(
            id: tagId,
            name: tagId, // Nếu không tìm thấy, dùng ID làm tên
            category: TagCategory.IN_ROOM_FEATURE,
          ),
        );
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            tag.displayName ?? tag.name,
            style: TextStyle(
              fontSize: 12,
              color: Colors.blue.shade800,
            ),
          ),
        );
      }).toList(),
    );
  }
  
  // Định dạng số tiền thành chuỗi có phân tách hàng nghìn
  String _formatCurrency(int amount) {
    if (amount == 0) return 'Chưa xác định';
    
    final formatted = _formatNumberWithCommas(amount);
    
    return '$formatted VND';
  }

  // Debug method to print all available tags
  void _debugPrintAllTags() {
    if (!mounted) return;
    
    try {
      final tagsState = context.read<TagCubit>().state;
      if (tagsState.tags.isEmpty) {
        debugPrint('❌ No tags available for debugging');
        return;
      }
      
      debugPrint('🔍 DEBUG: All available tags (${tagsState.tags.length})');
      for (final tag in tagsState.tags) {
        final displayPart = tag.displayName != null ? ' (Display: ${tag.displayName})' : '';
        debugPrint('  • [${tag.category}] ${tag.name}$displayPart (ID: ${tag.id})');
      }
      
      // Print selected tags
      debugPrint('✅ Selected must-have tags: $_mustHaveTagIds');
      debugPrint('✅ Selected nice-to-have tags: $_niceToHaveTagIds');
    } catch (e) {
      debugPrint('❌ Error in _debugPrintAllTags: $e');
      // Do not rethrow the error - just log it and continue
    }
  }

  // Process the tag IDs to find if they're actual IDs or just names
  void _processApiTagNames(List<String> tagIdsOrNames, bool isMustHave, List<RoomTag> availableTags) {
    if (availableTags.isEmpty) return;
    
    // Target list to modify
    final targetList = isMustHave ? _mustHaveTagIds : _niceToHaveTagIds;
    
    // Manual map for common API tags - EMERGENCY SOLUTION
    final Map<String, String> manualTagMap = {};
    
    // Populate the map based on available tags
    for (final tag in availableTags) {
      manualTagMap[tag.name.toUpperCase()] = tag.id;
    }
    
    debugPrint('📋 Manual tag map has ${manualTagMap.length} entries');
    
    // Process each item
    for (final item in tagIdsOrNames) {
      // Check if this is a valid tag ID
      if (availableTags.any((tag) => tag.id == item)) {
        if (!targetList.contains(item)) {
          targetList.add(item);
          debugPrint('✅ Added valid tag ID: $item');
        }
      } 
      // Check if we have a manual mapping
      else if (manualTagMap.containsKey(item.toUpperCase())) {
        final tagId = manualTagMap[item.toUpperCase()];
        if (tagId != null && !targetList.contains(tagId)) {
          targetList.add(tagId);
          debugPrint('✅ Mapped API tag name: $item to ID: $tagId');
        }
      }
      // Otherwise, use fuzzy matching
      else {
        debugPrint('🔄 Tag "$item" not found in manual map, using fuzzy matching');
        
        // First, try exact match ignoring case
        bool found = false;
        for (final tag in availableTags) {
          if (tag.name.toUpperCase() == item.toUpperCase()) {
            if (!targetList.contains(tag.id)) {
              targetList.add(tag.id);
              debugPrint('✅ Exact match for: $item -> ${tag.id}');
              found = true;
              break;
            }
          }
        }
        
        // If not found, use substring matching
        if (!found) {
          for (final tag in availableTags) {
            if (tag.name.toUpperCase().contains(item.toUpperCase()) ||
                item.toUpperCase().contains(tag.name.toUpperCase())) {
              if (!targetList.contains(tag.id)) {
                targetList.add(tag.id);
                debugPrint('✅ Substring match for: $item -> ${tag.id}');
                found = true;
                break;
              }
            }
          }
        }
        
        if (!found) {
          debugPrint('⚠️ No match found for tag: $item');
        }
      }
    }
    
    // Log results
    final listType = isMustHave ? "must-have" : "nice-to-have";
    debugPrint('📋 Final $listType tag IDs: $targetList');
  }

  // Show dialog with all available tags for debugging
  void _showAllTagsDialog(List<RoomTag> tags) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('All Available Tags'),
          content: SizedBox(
            width: double.maxFinite,
            height: 400, // Fixed height to prevent overflow
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: tags.length,
              itemBuilder: (context, index) {
                final tag = tags[index];
                return ListTile(
                  title: Text(tag.name),
                  subtitle: Text('Display: ${tag.displayName ?? "N/A"}\nCategory: ${tag.category}'),
                  trailing: Text('ID: ${tag.id.substring(0, min(8, tag.id.length))}...'),
                  dense: true,
                );
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }
}

// Custom input formatter for thousand separators
class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  static final NumberFormat _numberFormat = NumberFormat.decimalPattern('vi')
    ..maximumFractionDigits = 0;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Remove all non-digit characters
    final digitsOnly = newValue.text.replaceAll(RegExp(r'[^\d]'), '');
    
    if (digitsOnly.isEmpty) {
      return TextEditingValue(
        text: '',
        selection: const TextSelection.collapsed(offset: 0),
      );
    }
    
    // Parse the digits as a number
    final number = int.tryParse(digitsOnly);
    if (number == null) {
      return oldValue;
    }
    
    // Format the number with thousand separators
    final formattedText = number.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match match) => '${match[1]}.',
    );
    
    // Determine the new cursor position
    int cursorPosition = newValue.selection.end;
    int oldValueLength = oldValue.text.length;
    int newValueLength = formattedText.length;
    
    // Adjust cursor position when text length changes
    if (oldValueLength != newValueLength) {
      int lengthDiff = newValueLength - oldValueLength;
      cursorPosition += lengthDiff;
    }
    
    // Make sure the cursor position is valid
    if (cursorPosition < 0) {
      cursorPosition = 0;
    } else if (cursorPosition > formattedText.length) {
      cursorPosition = formattedText.length;
    }
    
    return TextEditingValue(
      text: formattedText,
      selection: TextSelection.collapsed(offset: cursorPosition),
    );
  }
}