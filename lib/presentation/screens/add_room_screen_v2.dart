import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:dio/dio.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';


import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/repositories/room_image_repository.dart';
import 'package:roomily/data/repositories/tag_repository.dart';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/models/room_image.dart';

// Widgets
import 'package:roomily/presentation/widgets/add_room_v2/basic_info_step.dart';
import 'package:roomily/presentation/widgets/add_room_v2/location_step.dart';
import 'package:roomily/presentation/widgets/add_room_v2/pricing_step.dart';
import 'package:roomily/presentation/widgets/add_room_v2/amenities_step.dart';
import 'package:roomily/presentation/widgets/add_room_v2/images_step.dart';
import 'package:roomily/presentation/widgets/add_room_v2/step_indicator.dart';
import 'package:roomily/presentation/widgets/add_room_v2/navigation_buttons.dart';

import '../../data/blocs/auth/auth_cubit.dart';
import '../../data/blocs/home/room_create_cubit.dart';
import '../../data/blocs/home/room_create_state.dart';
import '../../data/blocs/home/room_image_cubit.dart';
import '../../data/blocs/home/room_image_state.dart';
import '../../data/blocs/tag/tag_cubit.dart';

// Define color scheme for different steps
class RoomColorScheme {
  // App general colors
  static const Color primary = Color(0xFF0075FF); // Bright blue primary color
  static const Color accent = Color(0xFF0062D2);
  static const Color background = Color(0xFFF8F9FA); // Light off-white background
  static const Color surface = Colors.white; // Surface color
  static const Color text = Color(0xFF263238); // Text color

  // Vibrant step colors for more visual impact
  static const Color basicInfo = Color(0xFF2196F3); // Fresh green
  static const Color location = Color(0xFF2196F3);   // Bright blue
  static const Color pricing = Color(0xFF2196F3);    // Vibrant orange
  static const Color amenities = Color(0xFF2196F3); // Rich purple
  static const Color images = Color(0xFF2196F3);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE57373);
  static const Color warning = Color(0xFFFFA726);
}

class AddRoomScreenV2 extends StatefulWidget {
  final Room? room; // Thêm tham số để truyền vào phòng cần cập nhật (null nếu tạo mới)
  
  const AddRoomScreenV2({Key? key, this.room}) : super(key: key);

  @override
  State<AddRoomScreenV2> createState() => _AddRoomScreenV2State();
}

class _AddRoomScreenV2State extends State<AddRoomScreenV2> with SingleTickerProviderStateMixin {
  final _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  final currencyFormatter = NumberFormat.currency(locale: 'vi_VN', symbol: 'đ');
  
  // Store BLoC instances as fields to maintain them throughout widget lifecycle
  late RoomCreateCubit _roomCreateCubit;
  late RoomImageCubit _roomImageCubit;
  late TagCubit _tagCubit;
  
  // Animation controller for transitions
  late AnimationController _animationController;
  late Animation<double> _animation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  bool _isForwardTransition = true;
  
  int _currentStep = 0;
  final int _totalSteps = 5;
  bool _isLoading = false;

  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _districtController = TextEditingController();
  final _wardController = TextEditingController();
  final _priceController = TextEditingController();
  final _electricPriceController = TextEditingController();
  final _waterPriceController = TextEditingController();
  final _maxPeopleController = TextEditingController();
  final _squareMetersController = TextEditingController();
  final _depositController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  // Room data
  String _selectedRoomType = 'ROOM';
  final List<String> _selectedTagIds = [];
  final List<File> _selectedImages = [];
  List<RoomImage> _remoteImages = [];
  final List<String> _deletedImageIds = []; // Track deleted image IDs

  bool get _isUpdateMode => widget.room != null;
  String get _actionButtonText => _isUpdateMode ? 'Cập nhật' : 'Hoàn thành';

  // Get current step color
  Color get _currentStepColor {
    switch (_currentStep) {
      case 0:
        return RoomColorScheme.basicInfo;
      case 1:
        return RoomColorScheme.location;
      case 2:
        return RoomColorScheme.pricing;
      case 3:
        return RoomColorScheme.amenities;
      case 4:
        return RoomColorScheme.images;
      default:
        return RoomColorScheme.primary;
    }
  }

  // Get icon for current step
  IconData get _currentStepIcon {
    switch (_currentStep) {
      case 0:
        return Icons.info_outline;
      case 1:
        return Icons.location_on_outlined;
      case 2:
        return Icons.attach_money;
      case 3:
        return Icons.hotel_outlined;
      case 4:
        return Icons.photo_library_outlined;
      default:
        return Icons.home_outlined;
    }
  }

  @override
  void initState() {
    super.initState();
    
    // Initialize BLoCs once in initState
    _roomCreateCubit = RoomCreateCubit(GetIt.instance<RoomRepository>());
    _roomImageCubit = RoomImageCubit(GetIt.instance<RoomImageRepository>());
    _tagCubit = TagCubit(tagRepository: GetIt.instance<TagRepository>());
    
    // Initialize tags
    _tagCubit.getAllTags();
    
    // Initialize animation controller
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutQuint,
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(_animation);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animation);
    
    _animationController.forward();

    // Nếu đang ở chế độ cập nhật, điền giá trị mặc định từ room
    if (_isUpdateMode) {
      _fillFormWithExistingRoomData();
      // When in update mode, fetch room images
      _fetchRoomImages();
    }
  }

  // Điền dữ liệu vào form từ room hiện có
  void _fillFormWithExistingRoomData() {
    final room = widget.room!;
    
    // Điền các trường thông tin cơ bản
    _titleController.text = room.title;
    _descriptionController.text = room.description;
    _addressController.text = room.address;
    _cityController.text = room.city;
    _districtController.text = room.district;
    _wardController.text = room.ward;
    
    // Điền thông tin giá cả
    _priceController.text = room.price.toString();
    _electricPriceController.text = room.electricPrice.toString();
    _waterPriceController.text = room.waterPrice.toString();
    if (room.deposit != null) {
      _depositController.text = room.deposit.toString();
    }
    
    // Điền thông tin phòng
    _maxPeopleController.text = room.maxPeople.toString();
    _squareMetersController.text = room.squareMeters.toString();
    
    // Loại phòng
    _selectedRoomType = room.type;

    // Tọa độ (nếu có)
    if (room.latitude != null) {
      _latitudeController.text = room.latitude.toString();
    }
    if (room.longitude != null) {
      _longitudeController.text = room.longitude.toString();
    }
    
    // Tags
    _selectedTagIds.clear();
    for (final tag in room.tags) {
      _selectedTagIds.add(tag.id);
    }
  }

  // Function to fetch room images when in update mode
  Future<void> _fetchRoomImages() async {
    if (widget.room != null && widget.room!.id != null) {
      try {
        await _roomImageCubit.fetchRoomImages(widget.room!.id!);
      } catch (e) {
        print('Error fetching room images: $e');
        _showErrorMessage('Không thể tải hình ảnh phòng: $e');
      }
    }
  }

  @override
  void dispose() {
    // Close BLoCs when widget is disposed
    _roomCreateCubit.close();
    _roomImageCubit.close();
    _tagCubit.close();
    
    _pageController.dispose();
    _animationController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _wardController.dispose();
    _priceController.dispose();
    _electricPriceController.dispose();
    _waterPriceController.dispose();
    _maxPeopleController.dispose();
    _squareMetersController.dispose();
    _depositController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  // Validate current step
  bool _validateCurrentStep() {
    switch (_currentStep) {
      case 0: // Basic Info
        return _titleController.text.isNotEmpty &&
               _descriptionController.text.isNotEmpty &&
               _squareMetersController.text.isNotEmpty &&
               _maxPeopleController.text.isNotEmpty;
        // return true;
      case 1: // Location
        return _addressController.text.isNotEmpty &&
               _cityController.text.isNotEmpty &&
               _districtController.text.isNotEmpty &&
               _wardController.text.isNotEmpty;
        // return true;
      case 2: // Pricing
        return _priceController.text.isNotEmpty &&
               _electricPriceController.text.isNotEmpty &&
               _waterPriceController.text.isNotEmpty;
      case 3: // Amenities
        print("DEBUG: Validating amenities step. Selected tags: $_selectedTagIds");
        return _selectedTagIds.isNotEmpty;
      case 4: // Images
        return _selectedImages.isNotEmpty || _remoteImages.isNotEmpty;
      default:
        return false;
    }
  }

  void _nextStep() {
    if (_validateCurrentStep()) {
      if (_currentStep < _totalSteps - 1) {
        // Check if we are moving from location step (index 1) to pricing step (index 2)
        if (_currentStep == 1) {
          // Get recommended tags based on latitude and longitude
          final double? latitude = double.tryParse(_latitudeController.text);
          final double? longitude = double.tryParse(_longitudeController.text);
          
          if (latitude != null && longitude != null) {
            _tagCubit.getRecommendedTags(
              latitude: latitude,
              longitude: longitude,
            );
          }
        }
        
        setState(() {
          _isForwardTransition = true;
          _currentStep++;
          
          // Reset animation and run forward
          _animationController.reset();
          _animationController.forward();
          
          _pageController.nextPage(
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        });
      } else {
        _submitForm();
      }
    } else {
      _showValidationError();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _isForwardTransition = false;
        _currentStep--;
        
        // Reset animation and run forward
        _animationController.reset();
        _animationController.forward();
        
        _pageController.previousPage(
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  void _showValidationError() {
    String message;
    switch (_currentStep) {
      case 0:
        message = 'Vui lòng điền đầy đủ thông tin cơ bản';
        break;
      case 1:
        message = 'Vui lòng điền đầy đủ thông tin địa chỉ';
        break;
      case 2:
        message = 'Vui lòng điền đầy đủ thông tin giá cả';
        break;
      case 3:
        message = 'Vui lòng chọn ít nhất một tiện ích';
        break;
      case 4:
        message = 'Vui lòng thêm ít nhất một hình ảnh';
        break;
      default:
        message = 'Vui lòng điền đầy đủ thông tin';
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: RoomColorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        elevation: 4,
      ),
    );
  }

  Future<void> _pickImages() async {
    final ImagePicker picker = ImagePicker();
    final List<XFile> images = await picker.pickMultiImage();
    
    if (images.isNotEmpty) {
      setState(() {
        _selectedImages.addAll(images.map((image) => File(image.path)).toList());
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  void _handleTagToggle(bool selected, String tagId) {
    print("DEBUG: Tag ${selected ? 'selected' : 'deselected'}: $tagId");
    print("DEBUG: Selected tags before update: $_selectedTagIds");
    
    setState(() {
      if (selected) {
        _selectedTagIds.add(tagId);
      } else {
        _selectedTagIds.remove(tagId);
      }
    });
    
    print("DEBUG: Selected tags after update: $_selectedTagIds");
  }

  void _handleImagesSelected(List<File> images) {
    setState(() {
      _selectedImages.addAll(images);
    });
  }

  void _handleImageRemoved(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  // Handle remote image removal
  void _handleRemoteImageRemoved(int index, String imageId) {
    setState(() {
      _remoteImages.removeAt(index);
      _deletedImageIds.add(imageId); // Store the ID for later deletion
    });
  }

  void _submitForm() async {
    if (!_validateCurrentStep()) {
      _showValidationError();
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Only proceed with room creation if we're on the final step
      if (_currentStep == _totalSteps - 1) {
        // We don't need a nested try/catch anymore since the BlocListener will handle
        // both success and error states
        final List<String> tagIdsToSubmit = List<String>.from(_selectedTagIds);
        print("DEBUG: Tag IDs to submit: $tagIdsToSubmit");

        if (_isUpdateMode) {
          // Cập nhật phòng hiện có
          await _roomCreateCubit.updateRoom(
            roomId: widget.room!.id!,
            title: _titleController.text,
            description: _descriptionController.text,
            address: _addressController.text,
            price: double.tryParse(_priceController.text) ?? 0,
            city: _cityController.text,
            district: _districtController.text,
            ward: _wardController.text,
            electricPrice: double.tryParse(_electricPriceController.text) ?? 0,
            waterPrice: double.tryParse(_waterPriceController.text) ?? 0,
            type: _selectedRoomType,
            maxPeople: int.tryParse(_maxPeopleController.text) ?? 1,
            tagIds: tagIdsToSubmit,
            squareMeters: double.tryParse(_squareMetersController.text) ?? 0,
            deposit: _depositController.text.isNotEmpty ? double.tryParse(_depositController.text) : null,
            latitude: _latitudeController.text.isNotEmpty ? double.tryParse(_latitudeController.text) : null,
            longitude: _longitudeController.text.isNotEmpty ? double.tryParse(_longitudeController.text) : null,
          );
          
          // Delete any remote images that were removed
          if (_deletedImageIds.isNotEmpty) {
            print("DEBUG: Deleting ${_deletedImageIds.length} remote images");
            await _roomImageCubit.deleteRoomImages(widget.room!.id!, _deletedImageIds);
          }
        } else {
          // Tạo phòng mới
          await _roomCreateCubit.createRoom(
            title: _titleController.text,
            description: _descriptionController.text,
            address: _addressController.text,
            price: double.tryParse(_priceController.text) ?? 0,
            city: _cityController.text,
            district: _districtController.text,
            ward: _wardController.text,
            electricPrice: double.tryParse(_electricPriceController.text) ?? 0,
            waterPrice: double.tryParse(_waterPriceController.text) ?? 0,
            type: _selectedRoomType,
            maxPeople: int.tryParse(_maxPeopleController.text) ?? 1,
            tagIds: tagIdsToSubmit,
            squareMeters: double.tryParse(_squareMetersController.text) ?? 0,
            deposit: _depositController.text.isNotEmpty ? double.tryParse(_depositController.text) : null,
            latitude: _latitudeController.text.isNotEmpty ? double.tryParse(_latitudeController.text) : null,
            longitude: _longitudeController.text.isNotEmpty ? double.tryParse(_longitudeController.text) : null,
          );
        }
        
        // No need to handle the response here, the BlocListener will take care of it
      } else {
        // If not on the final step, just move to the next step
        _nextStep();
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      _showErrorMessage('Đã xảy ra lỗi: $e');
      print('Error in _submitForm: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _uploadImages(String roomId) async {
    // Check for invalid roomId format
    if (roomId.isEmpty) {
      throw Exception("Invalid room ID");
    }
    
    // Convert File list to MultipartFile list
    final List<MultipartFile> imageFiles = [];
    for (File image in _selectedImages) {
      final filename = image.path.split('/').last;
      final multipartFile = await MultipartFile.fromFile(
        image.path,
        filename: filename,
      );
      imageFiles.add(multipartFile);
    }

    // Upload images using the cubit
    await _roomImageCubit.uploadRoomImages(roomId, imageFiles);
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Phòng đã được tạo thành công',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: RoomColorScheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 4,
      ),
    );
    Navigator.pop(context, true); // Close the screen and return to the previous one
  }

  // New method to show success message without closing the screen
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: RoomColorScheme.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        elevation: 4,
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: RoomColorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        elevation: 4,
      ),
    );
  }

  void _showWarningMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: RoomColorScheme.warning,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        elevation: 4,
      ),
    );
  }

  String _getStepTitle(int step) {
    switch (step) {
      case 0:
        return 'Thông tin cơ bản';
      case 1:
        return 'Vị trí';
      case 2:
        return 'Giá cả';
      case 3:
        return 'Tiện ích';
      case 4:
        return 'Hình ảnh';
      default:
        return '';
    }
  }

  // Handle navigation after successful room creation
  void _navigateAfterSuccess() {
    // Use a delayed navigation to allow time for any messages to be seen
    Future.delayed(const Duration(seconds: 1), () {
      // Only navigate if the widget is still mounted
      if (mounted) {
        // Make sure there's a route to go back to
        if (Navigator.canPop(context)) {
          Navigator.pop(context, true); // Return true to indicate success
        } else {
          // If can't pop, navigate to another appropriate screen
          // Replace with your actual dashboard route
          Navigator.pushReplacementNamed(context, '/landlord_dashboard');
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<RoomCreateCubit>.value(
          value: _roomCreateCubit,
        ),
        BlocProvider<RoomImageCubit>.value(
          value: _roomImageCubit,
        ),
        BlocProvider<TagCubit>.value(
          value: _tagCubit,
        ),
      ],
      child: Scaffold(
        backgroundColor: RoomColorScheme.background,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(70.0),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  _currentStepColor,
                  _currentStepColor.withOpacity(0.8),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: _currentStepColor.withOpacity(0.4),
                  offset: const Offset(0, 2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                      onPressed: () {
                        if (_currentStep > 0) {
                          _previousStep();
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.3),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_currentStepIcon, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _isUpdateMode ? 'Cập nhật phòng' : 'Thêm phòng mới',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 18,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _getStepTitle(_currentStep),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(width: 40), // Balance the layout
                  ],
                ),
              ),
            ),
          ),
        ),
        body: BlocListener<RoomCreateCubit, RoomCreateState>(
          listener: (context, state) {
            if (state is RoomCreateLoading) {
              setState(() {
                _isLoading = true;
              });
            } else if (state is RoomCreateLoaded) {
              setState(() {
                _isLoading = false;
              });
              
              // Handle image uploads first if there are any
              if (_selectedImages.isNotEmpty) {
                try {
                  _uploadImages(state.roomId).then((_) {
                    // Show success message after images are uploaded
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Phòng và hình ảnh đã được tạo thành công'),
                        backgroundColor: RoomColorScheme.success,
                        duration: Duration(seconds: 2),
                      ),
                    );
                    
                    // Then handle navigation
                    _navigateAfterSuccess();
                  }).catchError((error) {
                    // Show success with warning about images
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Phòng đã được tạo nhưng không thể tải lên hình ảnh: $error'),
                        backgroundColor: RoomColorScheme.warning,
                        duration: Duration(seconds: 3),
                      ),
                    );
                    
                    _navigateAfterSuccess();
                  });
                } catch (e) {
                  // Handle any synchronous errors
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Phòng đã được tạo nhưng có lỗi khi tải lên hình ảnh: $e'),
                      backgroundColor: RoomColorScheme.warning,
                      duration: Duration(seconds: 3),
                    ),
                  );
                  
                  _navigateAfterSuccess();
                }
              } else {
                // No images to upload, just show success and navigate
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Phòng đã được tạo thành công'),
                    backgroundColor: RoomColorScheme.success,
                    duration: Duration(seconds: 2),
                  ),
                );
                
                _navigateAfterSuccess();
              }
            } else if (state is RoomUpdateLoaded) {
              setState(() {
                _isLoading = false;
              });
              
              // Xử lý ảnh nếu có (bước này sẽ phát triển sau)
              
              // Hiển thị thông báo thành công
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Phòng đã được cập nhật thành công'),
                  backgroundColor: RoomColorScheme.success,
                  duration: Duration(seconds: 2),
                ),
              );
              
              // Quay lại màn hình trước đó
              _navigateAfterSuccess();
            } else if (state is RoomCreateError) {
              setState(() {
                _isLoading = false;
              });
              _showErrorMessage('Lỗi: ${state.message}');
            }
          },
          child: BlocListener<RoomImageCubit, RoomImageState>(
            listener: (context, state) {
              if (state is RoomImageUploading || state is RoomImageDeleting) {
                setState(() {
                  _isLoading = true;
                });
              } else if (state is RoomImageLoaded) {
                setState(() {
                  _isLoading = false;
                  // Store the loaded images when RoomImageLoaded state is received
                  _remoteImages = state.images;
                });
                // Don't show success message or close screen when just loading images in edit mode
                // Only show success message when actually uploading new images
                if (state.roomId != widget.room?.id) {
                  _showSuccessMessage();
                }
              } else if (state is RoomImageDeleteSuccess) {
                setState(() {
                  _isLoading = false;
                });
                _showMessage('Xóa hình ảnh thành công');
              } else if (state is RoomImageUploadError || state is RoomImageDeleteError) {
                setState(() {
                  _isLoading = false;
                });
                final errorMessage = state is RoomImageUploadError 
                    ? state.message 
                    : (state as RoomImageDeleteError).message;
                _showErrorMessage('Lỗi: $errorMessage');
              }
            },
            child: Stack(
              children: [
                Column(
                  children: [
                    // Enhanced step indicator
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            _currentStepColor.withOpacity(0.8),
                            _currentStepColor.withOpacity(0.6),
                          ],
                        ),
                        borderRadius: const BorderRadius.only(
                          bottomLeft: Radius.circular(30),
                          bottomRight: Radius.circular(30),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _currentStepColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 25),
                      child: Column(
                        children: [
                          // Progress indicator
                          Padding(
                            padding: const EdgeInsets.only(top: 5, bottom: 15),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: LinearProgressIndicator(
                                value: (_currentStep + 1) / _totalSteps,
                                backgroundColor: Colors.white.withOpacity(0.3),
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          
                          // Step indicator dots with labels
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_totalSteps, (index) {
                              final bool isActive = _currentStep == index;
                              final bool isCompleted = _currentStep > index;
                              
                              return Column(
                                children: [
                                  AnimatedContainer(
                                    duration: const Duration(milliseconds: 300),
                                    width: isActive ? 28 : 20,
                                    height: isActive ? 28 : 20,
                                    decoration: BoxDecoration(
                                      color: isActive || isCompleted 
                                          ? Colors.white 
                                          : Colors.white.withOpacity(0.4),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                      boxShadow: isActive ? [
                                        BoxShadow(
                                          color: Colors.white.withOpacity(0.5),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ] : null,
                                    ),
                                    child: Center(
                                      child: isCompleted
                                          ? const Icon(Icons.check, color: Colors.green, size: 14)
                                          : Text(
                                              (index + 1).toString(),
                                              style: TextStyle(
                                                color: isActive ? _currentStepColor : Colors.white.withOpacity(0.7),
                                                fontWeight: FontWeight.bold,
                                                fontSize: isActive ? 14 : 12,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _getStepShortTitle(index),
                                    style: TextStyle(
                                      color: isActive ? Colors.white : Colors.white.withOpacity(0.7),
                                      fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                    
                    // Form content with enhanced animations
                    Expanded(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: ScaleTransition(
                          scale: _scaleAnimation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: _isForwardTransition 
                                  ? const Offset(0.3, 0.0) 
                                  : const Offset(-0.3, 0.0),
                              end: Offset.zero,
                            ).animate(_animation),
                            child: Form(
                              key: _formKey,
                              child: PageView(
                                controller: _pageController,
                                physics: const NeverScrollableScrollPhysics(),
                                onPageChanged: (index) {
                                  setState(() {
                                    _currentStep = index;
                                  });
                                },
                                children: [
                                  BasicInfoStep(
                                    titleController: _titleController,
                                    descriptionController: _descriptionController,
                                    squareMetersController: _squareMetersController,
                                    maxPeopleController: _maxPeopleController,
                                    selectedRoomType: _selectedRoomType,
                                    onRoomTypeChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _selectedRoomType = value;
                                        });
                                      }
                                    },
                                  ),
                                  LocationStep(
                                    addressController: _addressController,
                                    cityController: _cityController,
                                    districtController: _districtController,
                                    wardController: _wardController,
                                    latitudeController: _latitudeController,
                                    longitudeController: _longitudeController,
                                    onLoadingChanged: (isLoading) {
                                      setState(() {
                                        _isLoading = isLoading;
                                      });
                                    },
                                  ),
                                  PricingStep(
                                    priceController: _priceController,
                                    depositController: _depositController,
                                    electricPriceController: _electricPriceController,
                                    waterPriceController: _waterPriceController,
                                  ),
                                  AmenitiesStep(
                                    selectedTagIds: _selectedTagIds,
                                    onTagToggle: _handleTagToggle,
                                  ),
                                  ImagesStep(
                                    selectedImages: _selectedImages,
                                    remoteImages: _remoteImages,
                                    onImagesSelected: _handleImagesSelected,
                                    onImageRemoved: _handleImageRemoved,
                                    onRemoteImageRemoved: _handleRemoteImageRemoved,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    
                    // Enhanced navigation buttons with animations
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: _currentStepColor.withOpacity(0.2),
                            spreadRadius: 1,
                            blurRadius: 10,
                            offset: const Offset(0, -3),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (_currentStep > 0)
                            TextButton.icon(
                              onPressed: _previousStep,
                              icon: const Icon(Icons.arrow_back_ios, size: 14),
                              label: const Text('Trở lại'),
                              style: TextButton.styleFrom(
                                foregroundColor: Colors.grey[600],
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            )
                          else
                            const SizedBox(width: 90), // Placeholder
                          
                          ElevatedButton(
                            onPressed: _nextStep,
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: _currentStepColor,
                              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                              elevation: 4,
                              shadowColor: _currentStepColor.withOpacity(0.4),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _currentStep == _totalSteps - 1 ? _actionButtonText : 'Tiếp theo',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  _currentStep == _totalSteps - 1 ? Icons.check_circle : Icons.arrow_forward,
                                  size: 18,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                // Enhanced loading overlay with animation
                if (_isLoading)
                  Container(
                    color: Colors.black.withOpacity(0.6),
                    child: Center(
                      child: TweenAnimationBuilder<double>(
                        tween: Tween<double>(begin: 0.0, end: 1.0),
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutQuad,
                        builder: (context, value, child) {
                          return Transform.scale(
                            scale: value,
                            child: Card(
                              elevation: 12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Container(
                                padding: const EdgeInsets.all(28),
                                width: 200,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    SizedBox(
                                      width: 64,
                                      height: 64,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 6,
                                        valueColor: AlwaysStoppedAnimation<Color>(_currentStepColor),
                                      ),
                                    ),
                                    const SizedBox(height: 24),
                                    const Text(
                                      'Đang xử lý...',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Vui lòng đợi trong giây lát',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Get short title for steps indicator
  String _getStepShortTitle(int step) {
    switch (step) {
      case 0: return 'Cơ bản';
      case 1: return 'Vị trí';
      case 2: return 'Giá cả';
      case 3: return 'Tiện ích';
      case 4: return 'Hình ảnh';
      default: return '';
    }
  }
} 