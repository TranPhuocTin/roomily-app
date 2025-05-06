// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:roomily/presentation/widgets/add_room/basic_info_step.dart';
// import 'package:roomily/presentation/widgets/add_room/location_step.dart';
// import 'package:roomily/presentation/widgets/add_room/pricing_step.dart';
// import 'package:roomily/presentation/widgets/add_room/amenities_step.dart';
// import 'package:roomily/presentation/widgets/add_room/images_step.dart';
// import 'package:roomily/presentation/widgets/add_room/step_indicator.dart';
//
// class StepsManager extends StatelessWidget {
//   final int currentStep;
//   final int totalSteps;
//   final bool isForwardTransition;
//
//   // Form keys cho từng bước
//   final GlobalKey<FormState> basicInfoFormKey;
//   final GlobalKey<FormState> locationFormKey;
//   final GlobalKey<FormState> pricingFormKey;
//   final GlobalKey<FormState> amenitiesFormKey;
//
//   // Step 1: Basic Info
//   final TextEditingController titleController;
//   final TextEditingController descriptionController;
//   final TextEditingController squareMetersController;
//   final TextEditingController maxPeopleController;
//   final String selectedRoomType;
//   final Function(String?) onRoomTypeChanged;
//
//   // Step 2: Location
//   final TextEditingController addressController;
//   final TextEditingController cityController;
//   final TextEditingController districtController;
//   final TextEditingController wardController;
//   final TextEditingController latitudeController;
//   final TextEditingController longitudeController;
//   final TextEditingController nearbyAmenitiesController;
//
//   // Step 3: Pricing
//   final TextEditingController priceController;
//   final TextEditingController depositController;
//   final TextEditingController electricPriceController;
//   final TextEditingController waterPriceController;
//
//   // Step 4: Amenities
//   final List<String> selectedTagIds;
//   final Function(String) onTagSelected;
//   final Function(String) onTagRemoved;
//
//   // Step 5: Images
//   final List<File> selectedImages;
//   final Function(List<File>) onImagesSelected;
//
//   // Focus nodes
//   final FocusNode? titleFocusNode;
//   final FocusNode? descriptionFocusNode;
//   final FocusNode? addressFocusNode;
//   final FocusNode? priceFocusNode;
//   final FocusNode? maxPeopleFocusNode;
//   final FocusNode? squareMetersFocusNode;
//
//   const StepsManager({
//     Key? key,
//     required this.currentStep,
//     required this.totalSteps,
//     required this.isForwardTransition,
//     required this.basicInfoFormKey,
//     required this.locationFormKey,
//     required this.pricingFormKey,
//     required this.amenitiesFormKey,
//     required this.titleController,
//     required this.descriptionController,
//     required this.squareMetersController,
//     required this.maxPeopleController,
//     required this.selectedRoomType,
//     required this.onRoomTypeChanged,
//     required this.addressController,
//     required this.cityController,
//     required this.districtController,
//     required this.wardController,
//     required this.latitudeController,
//     required this.longitudeController,
//     required this.nearbyAmenitiesController,
//     required this.priceController,
//     required this.depositController,
//     required this.electricPriceController,
//     required this.waterPriceController,
//     required this.selectedTagIds,
//     required this.onTagSelected,
//     required this.onTagRemoved,
//     required this.selectedImages,
//     required this.onImagesSelected,
//     this.titleFocusNode,
//     this.descriptionFocusNode,
//     this.addressFocusNode,
//     this.priceFocusNode,
//     this.maxPeopleFocusNode,
//     this.squareMetersFocusNode,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       children: [
//         // Step indicators
//         Container(
//           padding: const EdgeInsets.only(top: 8, bottom: 8),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             boxShadow: [
//               BoxShadow(
//                 color: const Color(0xFFD1C4E9).withOpacity(0.3),  // Light purple shadow
//                 blurRadius: 4,
//                 spreadRadius: 1,
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//             children: List.generate(
//               totalSteps,
//               (index) => StepIndicator(
//                 currentStep: currentStep,
//                 stepIndex: index,
//                 title: _getStepShortName(index),
//               ),
//             ),
//           ),
//         ),
//
//         // Main content
//         Expanded(
//           child: IndexedStack(
//             index: currentStep,
//             children: [
//               // Step 1: Basic info
//               BasicInfoStep(
//                 titleController: titleController,
//                 descriptionController: descriptionController,
//                 squareMetersController: squareMetersController,
//                 maxPeopleController: maxPeopleController,
//                 selectedRoomType: selectedRoomType,
//                 onRoomTypeChanged: onRoomTypeChanged,
//                 formKey: basicInfoFormKey,
//                 titleFocusNode: titleFocusNode,
//                 descriptionFocusNode: descriptionFocusNode,
//                 squareMetersFocusNode: squareMetersFocusNode,
//                 maxPeopleFocusNode: maxPeopleFocusNode,
//               ),
//
//               // Step 2: Location
//               LocationStep(
//                 addressController: addressController,
//                 cityController: cityController,
//                 districtController: districtController,
//                 wardController: wardController,
//                 latitudeController: latitudeController,
//                 longitudeController: longitudeController,
//                 nearbyAmenitiesController: nearbyAmenitiesController,
//                 formKey: locationFormKey,
//                 addressFocusNode: addressFocusNode,
//               ),
//
//               // Step 3: Pricing
//               PricingStep(
//                 priceController: priceController,
//                 depositController: depositController,
//                 electricPriceController: electricPriceController,
//                 waterPriceController: waterPriceController,
//                 formKey: pricingFormKey,
//                 priceFocusNode: priceFocusNode,
//               ),
//
//               // Step 4: Amenities
//               AmenitiesStep(
//                 selectedTagIds: selectedTagIds,
//                 onTagSelected: onTagSelected,
//                 onTagRemoved: onTagRemoved,
//                 formKey: amenitiesFormKey,
//               ),
//
//               // Step 5: Images
//               ImagesStep(
//                 selectedImages: selectedImages,
//                 onImagesSelected: onImagesSelected,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
//
//   // Get full title for the current step
//   String _getStepTitle(int step) {
//     switch (step) {
//       case 0: return 'Thông tin cơ bản';
//       case 1: return 'Địa điểm';
//       case 2: return 'Giá cả';
//       case 3: return 'Tiện ích';
//       case 4: return 'Hình ảnh';
//       default: return '';
//     }
//   }
//
//   // Get short name for step indicators
//   String _getStepShortName(int step) {
//     switch (step) {
//       case 0: return 'Cơ bản';
//       case 1: return 'Địa điểm';
//       case 2: return 'Giá cả';
//       case 3: return 'Tiện ích';
//       case 4: return 'Hình ảnh';
//       default: return '';
//     }
//   }
// }