// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:image_picker/image_picker.dart';
// import 'package:roomily/presentation/widgets/add_room/header_card.dart';
//
// class ImagesStep extends StatefulWidget {
//   final List<File> selectedImages;
//   final Function(List<File>) onImagesSelected;
//
//   const ImagesStep({
//     Key? key,
//     required this.selectedImages,
//     required this.onImagesSelected,
//   }) : super(key: key);
//
//   @override
//   State<ImagesStep> createState() => _ImagesStepState();
// }
//
// class _ImagesStepState extends State<ImagesStep> {
//   final ImagePicker _imagePicker = ImagePicker();
//
//   // Define consistent colors
//   final Color primaryColor = const Color(0xFF9575CD);
//   final Color secondaryColor = const Color(0xFFE1BEE7);
//   final Color accentColor = const Color(0xFF7E57C2);
//   final Color backgroundColor = const Color(0xFFF3E5F5);
//
//   Future<void> _selectImages() async {
//     final List<XFile>? pickedImages = await _imagePicker.pickMultiImage();
//
//     if (pickedImages != null && pickedImages.isNotEmpty) {
//       final List<File> newImages = pickedImages.map((XFile image) => File(image.path)).toList();
//       final List<File> updatedList = List.from(widget.selectedImages)..addAll(newImages);
//       widget.onImagesSelected(updatedList);
//     }
//   }
//
//   Future<void> _captureImage() async {
//     final XFile? capturedImage = await _imagePicker.pickImage(source: ImageSource.camera);
//
//     if (capturedImage != null) {
//       final File newImage = File(capturedImage.path);
//       final List<File> updatedList = List.from(widget.selectedImages)..add(newImage);
//       widget.onImagesSelected(updatedList);
//     }
//   }
//
//   void _removeImage(int index) {
//     final List<File> updatedList = List.from(widget.selectedImages);
//     updatedList.removeAt(index);
//     widget.onImagesSelected(updatedList);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SingleChildScrollView(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Header
//           const HeaderCard(
//             title: 'Hình ảnh phòng',
//             subtitle: 'Thêm ít nhất một ảnh về phòng của bạn',
//             icon: Icons.photo_camera_outlined,
//           ),
//           const SizedBox(height: 24),
//
//           // Selected images grid
//           if (widget.selectedImages.isNotEmpty)
//             Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   'Đã chọn ${widget.selectedImages.length} ảnh',
//                   style: TextStyle(
//                     fontSize: 16,
//                     fontWeight: FontWeight.bold,
//                     color: accentColor,
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 GridView.builder(
//                   shrinkWrap: true,
//                   physics: const NeverScrollableScrollPhysics(),
//                   gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                     crossAxisCount: 3,
//                     crossAxisSpacing: 8,
//                     mainAxisSpacing: 8,
//                     childAspectRatio: 1,
//                   ),
//                   itemCount: widget.selectedImages.length,
//                   itemBuilder: (context, index) {
//                     return Stack(
//                       children: [
//                         Container(
//                           decoration: BoxDecoration(
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: secondaryColor, width: 2),
//                             image: DecorationImage(
//                               image: FileImage(widget.selectedImages[index]),
//                               fit: BoxFit.cover,
//                             ),
//                           ),
//                         ),
//                         Positioned(
//                           right: 4,
//                           top: 4,
//                           child: GestureDetector(
//                             onTap: () => _removeImage(index),
//                             child: Container(
//                               decoration: BoxDecoration(
//                                 color: accentColor.withOpacity(0.8),
//                                 shape: BoxShape.circle,
//                               ),
//                               padding: const EdgeInsets.all(4),
//                               child: const Icon(
//                                 Icons.close,
//                                 size: 14,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ],
//                     );
//                   },
//                 ),
//                 const SizedBox(height: 24),
//               ],
//             ),
//
//           // Upload button
//           Center(
//             child: Container(
//               width: double.infinity,
//               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
//               decoration: BoxDecoration(
//                 color: secondaryColor.withOpacity(0.2),
//                 borderRadius: BorderRadius.circular(12),
//                 border: Border.all(color: primaryColor.withOpacity(0.5), width: 1.5),
//                 boxShadow: [
//                   BoxShadow(
//                     color: primaryColor.withOpacity(0.1),
//                     spreadRadius: 1,
//                     blurRadius: 5,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 children: [
//                   Icon(
//                     Icons.cloud_upload_outlined,
//                     size: 60,
//                     color: accentColor,
//                   ),
//                   const SizedBox(height: 16),
//                   Text(
//                     'Thêm hình ảnh phòng của bạn',
//                     style: TextStyle(
//                       fontSize: 16,
//                       fontWeight: FontWeight.bold,
//                       color: primaryColor,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     'Hãy chọn những hình ảnh đẹp và rõ ràng để thu hút người thuê',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       fontSize: 14,
//                       color: Colors.grey.shade700,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.center,
//                     children: [
//                       ElevatedButton.icon(
//                         onPressed: _captureImage,
//                         icon: const Icon(Icons.camera_alt),
//                         label: const Text('Chụp ảnh'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: primaryColor,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           elevation: 2,
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       ElevatedButton.icon(
//                         onPressed: _selectImages,
//                         icon: const Icon(Icons.add_photo_alternate),
//                         label: const Text('Chọn từ thư viện'),
//                         style: ElevatedButton.styleFrom(
//                           backgroundColor: accentColor,
//                           foregroundColor: Colors.white,
//                           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           elevation: 2,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//
//           const SizedBox(height: 16),
//
//           // Tips
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: secondaryColor.withOpacity(0.15),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(
//                 color: primaryColor.withOpacity(0.3),
//                 width: 1.5,
//               ),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     Icon(
//                       Icons.lightbulb,
//                       color: accentColor,
//                       size: 20,
//                     ),
//                     const SizedBox(width: 8),
//                     Text(
//                       'Mẹo chụp ảnh đẹp:',
//                       style: TextStyle(
//                         fontSize: 15,
//                         fontWeight: FontWeight.bold,
//                         color: accentColor,
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//                 _buildTipItem('Chụp ảnh trong điều kiện ánh sáng tốt'),
//                 _buildTipItem('Chụp cả phòng tắm, nhà bếp và các tiện ích khác'),
//                 _buildTipItem('Chụp ảnh góc rộng để thấy toàn bộ không gian'),
//                 _buildTipItem('Dọn dẹp phòng gọn gàng trước khi chụp'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildTipItem(String text) {
//     return Padding(
//       padding: const EdgeInsets.only(bottom: 8),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Icon(
//             Icons.check_circle,
//             color: accentColor,
//             size: 16,
//           ),
//           const SizedBox(width: 8),
//           Expanded(
//             child: Text(
//               text,
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Colors.grey.shade700,
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }