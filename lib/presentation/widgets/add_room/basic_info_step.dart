// import 'package:flutter/material.dart';
// import 'package:roomily/presentation/screens/add_room_screen.dart';
// import 'package:roomily/presentation/widgets/add_room/header_card.dart';
// import 'package:roomily/presentation/widgets/add_room/room_tip_card.dart';
//
// class BasicInfoStep extends StatelessWidget {
//   final TextEditingController titleController;
//   final TextEditingController descriptionController;
//   final TextEditingController squareMetersController;
//   final TextEditingController maxPeopleController;
//   final String selectedRoomType;
//   final Function(String?) onRoomTypeChanged;
//   final GlobalKey<FormState> formKey;
//   final FocusNode? titleFocusNode;
//   final FocusNode? descriptionFocusNode;
//   final FocusNode? squareMetersFocusNode;
//   final FocusNode? maxPeopleFocusNode;
//
//   const BasicInfoStep({
//     Key? key,
//     required this.titleController,
//     required this.descriptionController,
//     required this.squareMetersController,
//     required this.maxPeopleController,
//     required this.selectedRoomType,
//     required this.onRoomTypeChanged,
//     required this.formKey,
//     this.titleFocusNode,
//     this.descriptionFocusNode,
//     this.squareMetersFocusNode,
//     this.maxPeopleFocusNode,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: formKey,
//       autovalidateMode: AutovalidateMode.disabled,
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             const HeaderCard(
//               title: 'Thông tin cơ bản',
//               subtitle: 'Nhập các thông tin chính về phòng của bạn',
//               icon: Icons.home_outlined,
//               stepIndex: 0, // Basic info là step đầu tiên (index 0)
//             ),
//             const SizedBox(height: 24),
//
//             // Title with animation
//             _buildAnimatedContainer(
//               color: RoomColors.basicInfo,
//               child: TextFormField(
//                 controller: titleController,
//                 focusNode: titleFocusNode,
//                 autovalidateMode: AutovalidateMode.disabled,
//                 decoration: InputDecoration(
//                   labelText: 'Tiêu đề phòng',
//                   hintText: 'Ví dụ: Phòng trọ cao cấp gần ĐH Bách Khoa',
//                   prefixIcon: Icon(Icons.title, color: RoomColors.basicInfo),
//                   filled: true,
//                   fillColor: RoomColors.basicInfo.withOpacity(0.05),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: RoomColors.basicInfo.withOpacity(0.3)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: RoomColors.basicInfo,
//                       width: 2,
//                     ),
//                   ),
//                   errorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: Colors.red, width: 1),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   floatingLabelStyle: TextStyle(color: RoomColors.basicInfo),
//                 ),
//                 style: TextStyle(fontSize: 16, color: RoomColors.formText),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Vui lòng nhập tiêu đề phòng';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // Description
//             _buildAnimatedContainer(
//               color: RoomColors.basicInfo,
//               child: TextFormField(
//                 controller: descriptionController,
//                 focusNode: descriptionFocusNode,
//                 maxLines: 4,
//                 autovalidateMode: AutovalidateMode.disabled,
//                 decoration: InputDecoration(
//                   labelText: 'Mô tả chi tiết',
//                   hintText: 'Mô tả đầy đủ về phòng, nội thất, tiện ích...',
//                   prefixIcon: Padding(
//                     padding: const EdgeInsets.only(bottom: 64),
//                     child: Icon(Icons.description, color: RoomColors.basicInfo),
//                   ),
//                   filled: true,
//                   fillColor: RoomColors.basicInfo.withOpacity(0.05),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: RoomColors.basicInfo.withOpacity(0.3)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: RoomColors.basicInfo,
//                       width: 2,
//                     ),
//                   ),
//                   errorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: Colors.red, width: 1),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   floatingLabelStyle: TextStyle(color: RoomColors.basicInfo),
//                   alignLabelWithHint: true,
//                 ),
//                 style: TextStyle(fontSize: 16, color: RoomColors.formText),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Vui lòng nhập mô tả';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // Room type dropdown with improved UI
//             _buildRoomTypeDropdown(),
//             const SizedBox(height: 20),
//
//             // Square meters and max people with enhanced UI
//             Row(
//               children: [
//                 // Square meters with animated container
//                 Expanded(
//                   child: _buildAnimatedContainer(
//                     color: RoomColors.area,
//                     child: TextFormField(
//                       controller: squareMetersController,
//                       focusNode: squareMetersFocusNode,
//                       keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                       autovalidateMode: AutovalidateMode.disabled,
//                       decoration: InputDecoration(
//                         labelText: 'Diện tích',
//                         hintText: 'Ví dụ: 20',
//                         suffixText: 'm²',
//                         prefixIcon: Icon(Icons.square_foot, color: RoomColors.area),
//                         filled: true,
//                         fillColor: RoomColors.area.withOpacity(0.05),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: RoomColors.area.withOpacity(0.3)),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(
//                             color: RoomColors.area,
//                             width: 2,
//                           ),
//                         ),
//                         errorBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(color: Colors.red, width: 1),
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                         floatingLabelStyle: TextStyle(color: RoomColors.area),
//                       ),
//                       style: TextStyle(fontSize: 16, color: RoomColors.formText),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Vui lòng nhập diện tích';
//                         }
//                         if (double.tryParse(value) == null) {
//                           return 'Vui lòng nhập số hợp lệ';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                 ),
//                 const SizedBox(width: 16),
//
//                 // Max people with animated container
//                 Expanded(
//                   child: _buildAnimatedContainer(
//                     color: RoomColors.people,
//                     child: TextFormField(
//                       controller: maxPeopleController,
//                       focusNode: maxPeopleFocusNode,
//                       keyboardType: TextInputType.number,
//                       autovalidateMode: AutovalidateMode.disabled,
//                       decoration: InputDecoration(
//                         labelText: 'Số người ở tối đa',
//                         hintText: 'Ví dụ: 2',
//                         prefixIcon: Icon(Icons.people, color: RoomColors.people),
//                         filled: true,
//                         fillColor: RoomColors.people.withOpacity(0.05),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(color: RoomColors.people.withOpacity(0.3)),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: BorderSide(
//                             color: RoomColors.people,
//                             width: 2,
//                           ),
//                         ),
//                         errorBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(12),
//                           borderSide: const BorderSide(color: Colors.red, width: 1),
//                         ),
//                         contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                         floatingLabelStyle: TextStyle(color: RoomColors.people),
//                       ),
//                       style: TextStyle(fontSize: 16, color: RoomColors.formText),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Vui lòng nhập số người tối đa';
//                         }
//                         if (int.tryParse(value) == null) {
//                           return 'Vui lòng nhập số nguyên';
//                         }
//                         return null;
//                       },
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//             const SizedBox(height: 20),
//
//             // Tips card
//             RoomTipCard(
//               title: 'Mẹo hiển thị phòng tốt',
//               content: 'Tiêu đề hấp dẫn và mô tả chi tiết sẽ giúp phòng của bạn nổi bật. Hãy mô tả đầy đủ về không gian, ánh sáng, tiện nghi của phòng.',
//               icon: Icons.lightbulb,
//               color: RoomColors.basicInfo,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Helper method to build animated container for form fields
//   Widget _buildAnimatedContainer({
//     required Widget child,
//     Color? color,
//   }) {
//     return Container(
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: (color ?? RoomColors.basicInfo).withOpacity(0.3),
//             spreadRadius: 1,
//             blurRadius: 4,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }
//
//   // Build room type dropdown
//   Widget _buildRoomTypeDropdown() {
//     return _buildAnimatedContainer(
//       color: RoomColors.basicInfo,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
//         decoration: BoxDecoration(
//           color: RoomColors.basicInfo.withOpacity(0.05),
//           borderRadius: BorderRadius.circular(12),
//           border: Border.all(color: RoomColors.basicInfo.withOpacity(0.3)),
//         ),
//         child: DropdownButtonFormField<String>(
//           value: selectedRoomType,
//           onChanged: onRoomTypeChanged,
//           decoration: InputDecoration(
//             labelText: 'Loại phòng',
//             prefixIcon: Icon(Icons.meeting_room, color: RoomColors.basicInfo),
//             border: InputBorder.none,
//             enabledBorder: InputBorder.none,
//             focusedBorder: InputBorder.none,
//             errorBorder: InputBorder.none,
//             floatingLabelStyle: TextStyle(color: RoomColors.basicInfo),
//             contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
//           ),
//           style: TextStyle(fontSize: 16, color: RoomColors.formText),
//           dropdownColor: Colors.white,
//           icon: Icon(Icons.arrow_drop_down, color: RoomColors.basicInfo),
//           validator: (value) {
//             if (value == null || value.isEmpty) {
//               return 'Vui lòng chọn loại phòng';
//             }
//             return null;
//           },
//           items: [
//             DropdownMenuItem<String>(
//               value: 'ROOM',
//               child: Row(
//                 children: [
//                   Icon(Icons.hotel, size: 18, color: RoomColors.basicInfo),
//                   const SizedBox(width: 8),
//                   const Text('Phòng trọ'),
//                 ],
//               ),
//             ),
//             DropdownMenuItem<String>(
//               value: 'APARTMENT',
//               child: Row(
//                 children: [
//                   Icon(Icons.apartment, size: 18, color: RoomColors.basicInfo),
//                   const SizedBox(width: 8),
//                   const Text('Căn hộ'),
//                 ],
//               ),
//             ),
//             DropdownMenuItem<String>(
//               value: 'HOUSE',
//               child: Row(
//                 children: [
//                   Icon(Icons.home, size: 18, color: RoomColors.basicInfo),
//                   const SizedBox(width: 8),
//                   const Text('Nhà nguyên căn'),
//                 ],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }