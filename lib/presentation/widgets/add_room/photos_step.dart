// import 'dart:io';
// import 'package:flutter/material.dart';
// import 'package:roomily/presentation/widgets/add_room/header_card.dart';
// import 'package:roomily/presentation/widgets/add_room/room_tip_card.dart';
// import 'package:roomily/presentation/widgets/room_image_uploader.dart';
//
// class PhotosStep extends StatelessWidget {
//   final List<File> selectedImages;
//   final Function(List<File>) onImagesSelected;
//   final GlobalKey<FormState> formKey;
//
//   const PhotosStep({
//     Key? key,
//     required this.selectedImages,
//     required this.onImagesSelected,
//     required this.formKey,
//   }) : super(key: key);
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
//             subtitle: 'Thêm hình ảnh chất lượng để nổi bật phòng của bạn',
//             icon: Icons.photo_camera,
//           ),
//           const SizedBox(height: 24),
//
//           // Upload images section
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: Colors.white,
//               borderRadius: BorderRadius.circular(12),
//               boxShadow: [
//                 BoxShadow(
//                   color: Colors.grey.withOpacity(0.1),
//                   spreadRadius: 1,
//                   blurRadius: 4,
//                   offset: const Offset(0, 2),
//                 ),
//               ],
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: [
//                     const Icon(Icons.file_upload, color: Color(0xFF9575CD)),
//                     const SizedBox(width: 8),
//                     const Text(
//                       'Tải hình ảnh lên',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF9575CD),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 16),
//
//                 // Custom uploader
//                 RoomImageUploader(
//                   onImagesSelected: onImagesSelected,
//                 ),
//
//                 const SizedBox(height: 16),
//
//                 // Status indicator
//                 Container(
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   decoration: BoxDecoration(
//                     color: selectedImages.isEmpty
//                         ? Colors.orange.withOpacity(0.1)
//                         : Colors.green.withOpacity(0.1),
//                     borderRadius: BorderRadius.circular(8),
//                     border: Border.all(
//                       color: selectedImages.isEmpty
//                         ? Colors.orange.withOpacity(0.3)
//                         : Colors.green.withOpacity(0.3),
//                     ),
//                   ),
//                   child: Row(
//                     children: [
//                       Icon(
//                         selectedImages.isEmpty
//                             ? Icons.warning_amber_rounded
//                             : Icons.check_circle_outline,
//                         color: selectedImages.isEmpty
//                             ? Colors.orange
//                             : Colors.green,
//                         size: 20,
//                       ),
//                       const SizedBox(width: 8),
//                       Expanded(
//                         child: Text(
//                           selectedImages.isEmpty
//                               ? 'Vui lòng chọn ít nhất 1 hình ảnh'
//                               : 'Đã chọn ${selectedImages.length} hình ảnh',
//                           style: TextStyle(
//                             color: selectedImages.isEmpty
//                                 ? Colors.orange.shade700
//                                 : Colors.green.shade700,
//                             fontSize: 14,
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//
//           // Preview section if images selected
//           if (selectedImages.isNotEmpty) ...[
//             const SizedBox(height: 20),
//             Container(
//               padding: const EdgeInsets.all(16),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.grey.withOpacity(0.1),
//                     spreadRadius: 1,
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(Icons.preview, color: Color(0xFF7E57C2)),
//                       const SizedBox(width: 8),
//                       const Text(
//                         'Xem trước hình ảnh',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: Color(0xFF7E57C2),
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Grid of selected images
//                   GridView.builder(
//                     shrinkWrap: true,
//                     physics: const NeverScrollableScrollPhysics(),
//                     gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
//                       crossAxisCount: 3,
//                       crossAxisSpacing: 8,
//                       mainAxisSpacing: 8,
//                       childAspectRatio: 1,
//                     ),
//                     itemCount: selectedImages.length,
//                     itemBuilder: (context, index) {
//                       return Stack(
//                         children: [
//                           Container(
//                             clipBehavior: Clip.antiAlias,
//                             decoration: BoxDecoration(
//                               borderRadius: BorderRadius.circular(8),
//                               border: Border.all(color: Colors.grey.shade300),
//                             ),
//                             child: Image.file(
//                               selectedImages[index],
//                               fit: BoxFit.cover,
//                               width: double.infinity,
//                               height: double.infinity,
//                             ),
//                           ),
//                           Positioned(
//                             top: 4,
//                             right: 4,
//                             child: InkWell(
//                               onTap: () {
//                                 final updatedImages = List<File>.from(selectedImages);
//                                 updatedImages.removeAt(index);
//                                 onImagesSelected(updatedImages);
//                               },
//                               child: Container(
//                                 padding: const EdgeInsets.all(4),
//                                 decoration: BoxDecoration(
//                                   color: Colors.black.withOpacity(0.5),
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: const Icon(
//                                   Icons.close,
//                                   color: Colors.white,
//                                   size: 16,
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//
//                   const SizedBox(height: 8),
//                   // Caption
//                   Center(
//                     child: Text(
//                       'Nhấn vào biểu tượng X để xóa ảnh',
//                       style: TextStyle(
//                         color: Colors.grey[600],
//                         fontSize: 12,
//                         fontStyle: FontStyle.italic,
//                       ),
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//           ],
//
//           const SizedBox(height: 20),
//           // Tips for photos
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: const Color(0xFFE1BEE7).withOpacity(0.3),
//               borderRadius: BorderRadius.circular(12),
//               border: Border.all(color: const Color(0xFFBA68C8).withOpacity(0.3)),
//             ),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Row(
//                   children: const [
//                     Icon(Icons.lightbulb_outline, color: Color(0xFF9575CD)),
//                     SizedBox(width: 8),
//                     Text(
//                       'Mẹo chụp ảnh đẹp',
//                       style: TextStyle(
//                         fontSize: 14,
//                         fontWeight: FontWeight.bold,
//                         color: Color(0xFF9575CD),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 12),
//
//                 // Tips cards
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           children: [
//                             Container(
//                               width: 40,
//                               height: 40,
//                               decoration: BoxDecoration(
//                                 color: Colors.amber.withOpacity(0.2),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(Icons.wb_sunny, color: Colors.amber[700]),
//                             ),
//                             const SizedBox(height: 8),
//                             const Text(
//                               'Chụp ảnh vào ban ngày để có đủ ánh sáng',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           children: [
//                             Container(
//                               width: 40,
//                               height: 40,
//                               decoration: BoxDecoration(
//                                 color: Colors.green.withOpacity(0.2),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(Icons.cleaning_services, color: Colors.green[700]),
//                             ),
//                             const SizedBox(height: 8),
//                             const Text(
//                               'Dọn dẹp gọn gàng trước khi chụp ảnh',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//                 const SizedBox(height: 8),
//                 Row(
//                   children: [
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           children: [
//                             Container(
//                               width: 40,
//                               height: 40,
//                               decoration: BoxDecoration(
//                                 color: Colors.blue.withOpacity(0.2),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(Icons.aspect_ratio, color: Colors.blue[700]),
//                             ),
//                             const SizedBox(height: 8),
//                             const Text(
//                               'Chụp đủ góc cạnh của phòng',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 8),
//                     Expanded(
//                       child: Container(
//                         padding: const EdgeInsets.all(12),
//                         decoration: BoxDecoration(
//                           color: Colors.white,
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Column(
//                           children: [
//                             Container(
//                               width: 40,
//                               height: 40,
//                               decoration: BoxDecoration(
//                                 color: Colors.purple.withOpacity(0.2),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(Icons.highlight, color: Colors.purple[700]),
//                             ),
//                             const SizedBox(height: 8),
//                             const Text(
//                               'Nhấn mạnh các đặc điểm nổi bật của phòng',
//                               textAlign: TextAlign.center,
//                               style: TextStyle(fontSize: 12),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }