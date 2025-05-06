// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:roomily/blocs/home/room_create_cubit.dart';
// import 'package:roomily/blocs/tag/tag_cubit.dart';
// import 'package:roomily/blocs/tag/tag_state.dart';
// import 'package:roomily/blocs/home/room_detail_cubit.dart';
// import 'package:roomily/blocs/home/room_detail_state.dart';
// import 'package:roomily/blocs/home/room_image_cubit.dart';
// import 'package:roomily/blocs/home/room_image_state.dart';
// import 'package:roomily/core/services/tag_service.dart';
// import 'package:roomily/data/models/room.dart';
// import 'package:roomily/data/repositories/room_repository.dart';
// import 'package:roomily/data/repositories/room_image_repository.dart';
// import 'package:roomily/data/repositories/tag_repository.dart';
// import 'package:roomily/presentation/widgets/add_room/steps_manager.dart';
// import 'package:get_it/get_it.dart';
// import 'package:dio/dio.dart';
//
// // Define color scheme for different steps
// class RoomColors {
//   // App general colors
//   static const Color primary = Color(0xFF4A6572); // Dark blue-gray for app main color
//   static const Color accent = Color(0xFF98BFCB); // Light blue-gray accent
//   static const Color background = Color(0xFFF5F7FA); // Light off-white background
//
//   // Step-specific colors
//   static const Color basicInfo = Color(0xFF4CAF50); // Green for basic information
//   static const Color location = Color(0xFF2196F3); // Blue for location
//   static const Color pricing = Color(0xFFFF9800); // Orange for pricing
//   static const Color amenities = Color(0xFF9C27B0); // Purple for amenities
//   static const Color images = Color(0xFFE91E63); // Pink for images
//
//   // Status colors
//   static const Color success = Color(0xFF4CAF50);
//   static const Color error = Color(0xFFE57373);
//   static const Color warning = Color(0xFFFFA726);
//
//   // Utility colors (for specific context icons)
//   static const Color electricity = Color(0xFFFFC107); // Yellow for electricity
//   static const Color water = Color(0xFF03A9F4); // Light blue for water
//   static const Color deposit = Color(0xFF8BC34A); // Light green for deposit
//   static const Color people = Color(0xFF9E9E9E); // Gray for people/occupancy
//   static const Color area = Color(0xFF795548); // Brown for square meters/area
//
//   // Form element colors
//   static const Color formBackground = Color(0xFFFAFAFA);
//   static const Color formBorder = Color(0xFFE0E0E0);
//   static const Color formFocused = Color(0xFF7986CB);
//   static const Color formText = Color(0xFF424242);
//   static const Color formHint = Color(0xFF9E9E9E);
// }
//
// class AddRoomScreen extends StatefulWidget {
//   final Room? room;
//
//   const AddRoomScreen({
//     Key? key,
//     this.room,
//   }) : super(key: key);
//
//   @override
//   State<AddRoomScreen> createState() => _AddRoomScreenState();
// }
//
// class _AddRoomScreenState extends State<AddRoomScreen> {
//   // Tạo FormKey riêng cho từng step
//   final _basicInfoFormKey = GlobalKey<FormState>();
//   final _locationFormKey = GlobalKey<FormState>();
//   final _pricingFormKey = GlobalKey<FormState>();
//   final _amenitiesFormKey = GlobalKey<FormState>();
//
//   final int _totalSteps = 5; // Total number of steps
//   int _currentStep = 0;
//   bool _isForwardTransition = true;
//   late BuildContext _blocContext;
//
//   // Form values
//   final TextEditingController _titleController = TextEditingController();
//   final TextEditingController _descriptionController = TextEditingController();
//   final TextEditingController _addressController = TextEditingController();
//   final TextEditingController _priceController = TextEditingController();
//   final TextEditingController _cityController = TextEditingController();
//   final TextEditingController _districtController = TextEditingController();
//   final TextEditingController _wardController = TextEditingController();
//   final TextEditingController _electricPriceController = TextEditingController();
//   final TextEditingController _waterPriceController = TextEditingController();
//   final TextEditingController _maxPeopleController = TextEditingController();
//   final TextEditingController _squareMetersController = TextEditingController();
//   final TextEditingController _depositController = TextEditingController();
//   final TextEditingController _nearbyAmenitiesController = TextEditingController();
//   final TextEditingController _latitudeController = TextEditingController();
//   final TextEditingController _longitudeController = TextEditingController();
//
//   String _selectedRoomType = 'ROOM'; // Default room type
//   final List<String> _selectedTagIds = [];
//   final List<File> _selectedImages = [];
//
//   final TagService _tagService = GetIt.instance<TagService>();
//   bool _isLoading = false;
//   String? _errorMessage;
//
//   // Create focus nodes for form fields
//   late FocusNode _titleFocusNode;
//   late FocusNode _descriptionFocusNode;
//   late FocusNode _addressFocusNode;
//   late FocusNode _priceFocusNode;
//   late FocusNode _maxPeopleFocusNode;
//   late FocusNode _squareMetersFocusNode;
//
//   // Get current step color
//   Color get _currentStepColor {
//     switch (_currentStep) {
//       case 0:
//         return RoomColors.basicInfo;
//       case 1:
//         return RoomColors.location;
//       case 2:
//         return RoomColors.pricing;
//       case 3:
//         return RoomColors.amenities;
//       case 4:
//         return RoomColors.images;
//       default:
//         return RoomColors.primary;
//     }
//   }
//
//   // Get icon for current step
//   IconData get _currentStepIcon {
//     switch (_currentStep) {
//       case 0:
//         return Icons.info_outline;
//       case 1:
//         return Icons.location_on_outlined;
//       case 2:
//         return Icons.attach_money;
//       case 3:
//         return Icons.hotel_outlined;
//       case 4:
//         return Icons.photo_library_outlined;
//       default:
//         return Icons.home_outlined;
//     }
//   }
//
//   @override
//   void initState() {
//     super.initState();
//     // Create focus nodes for form fields
//     _titleFocusNode = FocusNode();
//     _descriptionFocusNode = FocusNode();
//     _addressFocusNode = FocusNode();
//     _priceFocusNode = FocusNode();
//     _maxPeopleFocusNode = FocusNode();
//     _squareMetersFocusNode = FocusNode();
//     // Tags will be loaded by TagCubit when it's created
//   }
//
//   @override
//   void dispose() {
//     _titleController.dispose();
//     _descriptionController.dispose();
//     _addressController.dispose();
//     _priceController.dispose();
//     _cityController.dispose();
//     _districtController.dispose();
//     _wardController.dispose();
//     _electricPriceController.dispose();
//     _waterPriceController.dispose();
//     _maxPeopleController.dispose();
//     _squareMetersController.dispose();
//     _depositController.dispose();
//     _nearbyAmenitiesController.dispose();
//     _latitudeController.dispose();
//     _longitudeController.dispose();
//
//     // Dispose focus nodes
//     _titleFocusNode.dispose();
//     _descriptionFocusNode.dispose();
//     _addressFocusNode.dispose();
//     _priceFocusNode.dispose();
//     _maxPeopleFocusNode.dispose();
//     _squareMetersFocusNode.dispose();
//     super.dispose();
//   }
//
//   Future<bool> _validateCurrentStep() async {
//     bool isValid = false;
//     print("DEBUG: Validating step $_currentStep");
//
//     switch (_currentStep) {
//       case 0: // Basic Information
//         isValid = _basicInfoFormKey.currentState!.validate();
//         print("DEBUG: Step 0 validation result: $isValid");
//         return isValid;
//
//       case 1: // Location Information
//         isValid = _locationFormKey.currentState!.validate();
//         print("DEBUG: Step 1 validation result: $isValid");
//         return isValid;
//
//       case 2: // Pricing Information
//         isValid = _pricingFormKey.currentState!.validate();
//         print("DEBUG: Step 2 validation result: $isValid");
//         return isValid;
//
//       case 3: // Room Details - Amenities
//         isValid = _amenitiesFormKey.currentState!.validate();
//         // Kiểm tra thêm xem có chọn ít nhất một tag không
//         if (isValid && _selectedTagIds.isEmpty) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Vui lòng chọn ít nhất một thẻ cho phòng của bạn'),
//               backgroundColor: Colors.red,
//             ),
//           );
//           return false;
//         }
//         print("DEBUG: Step 3 validation result: $isValid");
//         return isValid;
//
//       case 4: // Images
//         if (_selectedImages.isEmpty) {
//           print("DEBUG: Step 4 validation failed: No images selected");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Vui lòng thêm ít nhất một hình ảnh'),
//               backgroundColor: Colors.red,
//             ),
//           );
//           return false;
//         }
//         print("DEBUG: Step 4 validation passed");
//         return true;
//
//       default:
//         print("DEBUG: Invalid step: $_currentStep");
//         return false;
//     }
//   }
//
//   void _nextStep() {
//     print("DEBUG: Next button pressed, current step: $_currentStep");
//
//     // Debug validation state
//     _debugFormValidation();
//
//     if (_currentStep < _totalSteps - 1) {
//       _validateCurrentStep().then((isValid) {
//         print("DEBUG: Validation result: $isValid");
//         if (isValid) {
//           setState(() {
//             _isForwardTransition = true;
//             _currentStep++;
//             print("DEBUG: Moving to next step: $_currentStep");
//
//             // Reset validation state for the new step
//             _resetValidationForCurrentStep();
//           });
//         } else {
//           print("DEBUG: Validation failed, staying on step: $_currentStep");
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Vui lòng điền đầy đủ thông tin'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       });
//     } else {
//       _validateCurrentStep().then((isValid) {
//         if (isValid) {
//           _submitForm();
//         } else {
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('Vui lòng hoàn thành tất cả các trường bắt buộc'),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       });
//     }
//   }
//
//   void _previousStep() {
//     if (_currentStep > 0) {
//       setState(() {
//         _isForwardTransition = false;
//         _currentStep--;
//
//         // Reset validation state for the previous step we're returning to
//         _resetValidationForCurrentStep();
//       });
//     }
//   }
//
//   // Reset validation state for the current step
//   void _resetValidationForCurrentStep() {
//     switch (_currentStep) {
//       case 0:
//         // Reset BasicInfoStep form
//         _basicInfoFormKey.currentState?.reset();
//         break;
//       case 1:
//         // Reset LocationStep form
//         _locationFormKey.currentState?.reset();
//         break;
//       case 2:
//         // Reset PricingStep form
//         _pricingFormKey.currentState?.reset();
//         break;
//       case 3:
//         // Reset AmenitiesStep form
//         _amenitiesFormKey.currentState?.reset();
//         break;
//       case 4:
//         // Images step doesn't have validation to reset
//         break;
//     }
//   }
//
//   void _onImagesSelected(List<File> images) {
//     setState(() {
//       _selectedImages.clear();
//       _selectedImages.addAll(images);
//     });
//   }
//
//   void _onTagSelected(String tagId) {
//     setState(() {
//       _selectedTagIds.add(tagId);
//     });
//   }
//
//   void _onTagRemoved(String tagId) {
//     setState(() {
//       _selectedTagIds.remove(tagId);
//     });
//   }
//
//   void _onRoomTypeChanged(String? newValue) {
//     if (newValue != null) {
//       setState(() {
//         _selectedRoomType = newValue;
//       });
//     }
//   }
//
//   void _submitForm() async {
//     // No need to validate again as we've already validated in _nextStep
//     setState(() {
//       _isLoading = true;
//       _errorMessage = null;
//     });
//
//     try {
//       print("DEBUG: Starting room creation with ${_selectedImages.length} images");
//
//       // Create room
//       await _blocContext.read<RoomCreateCubit>().createRoom(
//         title: _titleController.text,
//         description: _descriptionController.text,
//         address: _addressController.text,
//         price: double.parse(_priceController.text),
//         city: _cityController.text,
//         district: _districtController.text,
//         ward: _wardController.text,
//         electricPrice: double.parse(_electricPriceController.text),
//         waterPrice: double.parse(_waterPriceController.text),
//         type: _selectedRoomType,
//         maxPeople: int.parse(_maxPeopleController.text),
//         tagIds: _selectedTagIds,
//         squareMeters: double.parse(_squareMetersController.text),
//         deposit: _depositController.text.isNotEmpty ? double.parse(_depositController.text) : null,
//         nearbyAmenities: _nearbyAmenitiesController.text.isNotEmpty ? _nearbyAmenitiesController.text : null,
//         latitude: _latitudeController.text.isNotEmpty ? double.parse(_latitudeController.text) : null,
//         longitude: _longitudeController.text.isNotEmpty ? double.parse(_longitudeController.text) : null,
//       );
//
//       print("DEBUG: Room creation completed");
//
//       // Alternative approach: Direct API call to get room ID
//       print("DEBUG: Using room repository directly to get latest rooms");
//
//       try {
//         // Assuming RoomRepository is properly injected through GetIt
//         final roomRepository = GetIt.instance<RoomRepository>();
//
//         // Try to get the list of rooms (assuming the most recent is first)
//         final rooms = await roomRepository.getRooms();
//         print("DEBUG: Retrieved ${rooms.length} rooms");
//
//         if (rooms.isNotEmpty) {
//           // Assuming the most recently created room is first in the list
//           final roomId = rooms.first.id;
//           print("DEBUG: Using most recent room ID: $roomId for image upload");
//
//           if (roomId != null) {
//             // Convert File list to MultipartFile list
//             final List<MultipartFile> imageFiles = [];
//             for (File image in _selectedImages) {
//               final filename = image.path.split('/').last;
//               print("DEBUG: Converting image: $filename, path: ${image.path}");
//               final multipartFile = await MultipartFile.fromFile(
//                 image.path,
//                 filename: filename,
//               );
//               imageFiles.add(multipartFile);
//             }
//
//             print("DEBUG: Converted ${imageFiles.length} images to MultipartFile");
//
//             // Upload images using RoomImageCubit
//             print("DEBUG: Starting image upload to room ID: $roomId");
//             await _blocContext.read<RoomImageCubit>().uploadRoomImages(roomId, imageFiles);
//             print("DEBUG: Image upload completed");
//           } else {
//             print("DEBUG: Room ID is null");
//           }
//         } else {
//           print("DEBUG: No rooms retrieved");
//         }
//       } catch (roomError) {
//         print("DEBUG: Error getting rooms: $roomError");
//         // Still show success for room creation
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('Room added successfully but could not upload images')),
//         );
//       }
//
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(content: Text('Room added successfully')),
//       );
//       Navigator.pop(context);
//     } catch (e) {
//       print("DEBUG: Error in _submitForm: $e");
//       setState(() {
//         _errorMessage = 'Failed to add room: $e';
//       });
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(content: Text('Failed to add room: $e')),
//       );
//     } finally {
//       setState(() {
//         _isLoading = false;
//       });
//     }
//   }
//
//   void _debugFormValidation() {
//     if (_basicInfoFormKey.currentState == null ||
//         _locationFormKey.currentState == null ||
//         _pricingFormKey.currentState == null ||
//         _amenitiesFormKey.currentState == null) {
//       print("DEBUG: One or more FormState is null!");
//       return;
//     }
//
//     print("DEBUG: Form validation current state:");
//     print("DEBUG: Title: '${_titleController.text}'");
//     print("DEBUG: Description: '${_descriptionController.text}'");
//     print("DEBUG: Square meters: '${_squareMetersController.text}'");
//     print("DEBUG: Max people: '${_maxPeopleController.text}'");
//     print("DEBUG: Room type: '$_selectedRoomType'");
//
//     // Thử validate form và in kết quả
//     final isValid = _basicInfoFormKey.currentState!.validate() &&
//                     _locationFormKey.currentState!.validate() &&
//                     _pricingFormKey.currentState!.validate() &&
//                     _amenitiesFormKey.currentState!.validate();
//     print("DEBUG: Direct form validation result: $isValid");
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiBlocProvider(
//       providers: [
//         BlocProvider<TagCubit>(
//           create: (context) {
//             final cubit = TagCubit(
//               tagRepository: GetIt.instance<TagRepository>(),
//             );
//             // Fetch tags when cubit is created
//             cubit.getAllTags();
//             return cubit;
//           },
//         ),
//         BlocProvider<RoomCreateCubit>(
//           create: (context) => RoomCreateCubit(
//             GetIt.instance<RoomRepository>(),
//           ),
//         ),
//         BlocProvider<RoomDetailCubit>(
//           create: (context) => RoomDetailCubit(
//             GetIt.instance<RoomRepository>(),
//           ),
//         ),
//         BlocProvider<RoomImageCubit>(
//           create: (context) => RoomImageCubit(
//             GetIt.instance<RoomImageRepository>(),
//           ),
//         ),
//       ],
//       child: Builder(
//         builder: (context) {
//           _blocContext = context;
//           return MultiBlocListener(
//             listeners: [
//               BlocListener<RoomDetailCubit, RoomDetailState>(
//                 listener: (context, state) {
//                   if (state is RoomDetailLoading) {
//                     setState(() {
//                       _isLoading = true;
//                     });
//                   } else if (state is RoomDetailLoaded) {
//                     setState(() {
//                       _isLoading = false;
//                     });
//                     // No need to show success message here, it will be shown after image upload
//                   } else if (state is RoomDetailError) {
//                     setState(() {
//                       _isLoading = false;
//                     });
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Lỗi: ${state.message}'),
//                         backgroundColor: RoomColors.error,
//                       ),
//                     );
//                   }
//                 },
//               ),
//               BlocListener<RoomImageCubit, RoomImageState>(
//                 listener: (context, state) {
//                   print("DEBUG: RoomImageCubit state changed to: ${state.runtimeType}");
//                   if (state is RoomImageUploading) {
//                     print("DEBUG: Images uploading...");
//                     setState(() {
//                       _isLoading = true;
//                     });
//                   } else if (state is RoomImageLoaded) {
//                     print("DEBUG: Images uploaded successfully");
//                     setState(() {
//                       _isLoading = false;
//                     });
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       const SnackBar(
//                         content: Text('Phòng đã được tạo thành công'),
//                         backgroundColor: RoomColors.success,
//                       ),
//                     );
//                     Navigator.pop(context);
//                   } else if (state is RoomImageUploadError) {
//                     print("DEBUG: Image upload error: ${state.message}");
//                     setState(() {
//                       _isLoading = false;
//                     });
//                     ScaffoldMessenger.of(context).showSnackBar(
//                       SnackBar(
//                         content: Text('Phòng đã được tạo nhưng có lỗi khi tải lên ảnh: ${state.message}'),
//                         backgroundColor: RoomColors.warning,
//                       ),
//                     );
//                     // Still navigate back as the room was created
//                     Navigator.pop(context);
//                   }
//                 },
//               ),
//             ],
//             child: Scaffold(
//               backgroundColor: RoomColors.background,
//               appBar: AppBar(
//                 backgroundColor: _currentStepColor,
//                 elevation: 0,
//                 centerTitle: true,
//                 toolbarHeight: 48,
//                 systemOverlayStyle: SystemUiOverlayStyle(
//                   statusBarColor: _currentStepColor,
//                   statusBarIconBrightness: Brightness.light,
//                 ),
//                 title: Row(
//                   mainAxisSize: MainAxisSize.min,
//                   children: [
//                     Icon(_currentStepIcon, size: 20),
//                     const SizedBox(width: 8),
//                     const Text('Thêm phòng mới',
//                         style: TextStyle(
//                             color: Colors.white,
//                             fontWeight: FontWeight.bold,
//                             fontSize: 16)),
//                   ],
//                 ),
//                 iconTheme: const IconThemeData(color: Colors.white),
//               ),
//               body: _isLoading
//                   ? Center(child: CircularProgressIndicator(
//                       color: _currentStepColor,
//                     ))
//                   : Column(
//                       children: [
//                         // Progress indicator
//                         LinearProgressIndicator(
//                           value: (_currentStep + 1) / _totalSteps,
//                           backgroundColor: Colors.grey[200],
//                           valueColor: AlwaysStoppedAnimation<Color>(_currentStepColor),
//                         ),
//
//                         // Main content with steps
//                         Expanded(
//                           child: StepsManager(
//                             currentStep: _currentStep,
//                             totalSteps: _totalSteps,
//                             isForwardTransition: _isForwardTransition,
//                             basicInfoFormKey: _basicInfoFormKey,
//                             locationFormKey: _locationFormKey,
//                             pricingFormKey: _pricingFormKey,
//                             amenitiesFormKey: _amenitiesFormKey,
//                             titleController: _titleController,
//                             descriptionController: _descriptionController,
//                             addressController: _addressController,
//                             priceController: _priceController,
//                             cityController: _cityController,
//                             districtController: _districtController,
//                             wardController: _wardController,
//                             electricPriceController: _electricPriceController,
//                             waterPriceController: _waterPriceController,
//                             maxPeopleController: _maxPeopleController,
//                             squareMetersController: _squareMetersController,
//                             depositController: _depositController,
//                             nearbyAmenitiesController: _nearbyAmenitiesController,
//                             latitudeController: _latitudeController,
//                             longitudeController: _longitudeController,
//                             selectedRoomType: _selectedRoomType,
//                             selectedTagIds: _selectedTagIds,
//                             selectedImages: _selectedImages,
//                             onRoomTypeChanged: _onRoomTypeChanged,
//                             onTagSelected: _onTagSelected,
//                             onTagRemoved: _onTagRemoved,
//                             onImagesSelected: _onImagesSelected,
//                             titleFocusNode: _titleFocusNode,
//                             descriptionFocusNode: _descriptionFocusNode,
//                             addressFocusNode: _addressFocusNode,
//                             priceFocusNode: _priceFocusNode,
//                             maxPeopleFocusNode: _maxPeopleFocusNode,
//                             squareMetersFocusNode: _squareMetersFocusNode,
//                           ),
//                         ),
//
//                         // Bottom navigation
//                         Container(
//                           decoration: BoxDecoration(
//                             color: Colors.white,
//                             boxShadow: [
//                               BoxShadow(
//                                 color: _currentStepColor.withOpacity(0.2),
//                                 spreadRadius: 1,
//                                 blurRadius: 5,
//                                 offset: const Offset(0, -3),
//                               ),
//                             ],
//                           ),
//                           padding: const EdgeInsets.all(16.0),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               if (_currentStep > 0)
//                                 ElevatedButton.icon(
//                                   onPressed: _previousStep,
//                                   icon: const Icon(Icons.arrow_back_ios, size: 16),
//                                   label: const Text('Trở lại'),
//                                   style: ElevatedButton.styleFrom(
//                                     foregroundColor: Colors.white,
//                                     backgroundColor: RoomColors.accent,
//                                     padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                                     shape: RoundedRectangleBorder(
//                                       borderRadius: BorderRadius.circular(10),
//                                     ),
//                                     elevation: 2,
//                                   ),
//                                 )
//                               else
//                                 const SizedBox(width: 100), // Placeholder when no back button
//
//                               ElevatedButton.icon(
//                                 onPressed: _nextStep,
//                                 label: Text(
//                                   _currentStep == _totalSteps - 1 ? 'Hoàn thành' : 'Tiếp theo',
//                                 ),
//                                 icon: Icon(
//                                   _currentStep == _totalSteps - 1 ? Icons.check : Icons.arrow_forward_ios,
//                                   size: 16,
//                                 ),
//                                 style: ElevatedButton.styleFrom(
//                                   foregroundColor: Colors.white,
//                                   backgroundColor: _currentStepColor,
//                                   padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   elevation: 2,
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       ],
//                     ),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }