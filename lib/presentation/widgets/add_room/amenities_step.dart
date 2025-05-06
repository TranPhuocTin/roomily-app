// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:roomily/blocs/tag/tag_cubit.dart';
// import 'package:roomily/blocs/tag/tag_state.dart';
// import 'package:roomily/data/models/room.dart';
// import 'package:roomily/presentation/screens/add_room_screen.dart';
// import 'package:roomily/presentation/widgets/add_room/header_card.dart';
// import 'package:roomily/presentation/widgets/add_room/room_tip_card.dart';
//
// class AmenitiesStep extends StatelessWidget {
//   final List<String> selectedTagIds;
//   final Function(String) onTagSelected;
//   final Function(String) onTagRemoved;
//   final GlobalKey<FormState> formKey;
//
//   const AmenitiesStep({
//     Key? key,
//     required this.selectedTagIds,
//     required this.onTagSelected,
//     required this.onTagRemoved,
//     required this.formKey,
//   }) : super(key: key);
//
//   @override
//   Widget build(BuildContext context) {
//     return BlocBuilder<TagCubit, TagState>(
//       builder: (context, state) {
//         if (state.status == TagStatus.loading) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 CircularProgressIndicator(color: RoomColors.amenities),
//                 const SizedBox(height: 16),
//                 const Text('Đang tải danh sách tiện ích...'),
//               ],
//             ),
//           );
//         } else if (state.status == TagStatus.error) {
//           return Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 const Icon(Icons.error_outline, color: Colors.red, size: 48),
//                 const SizedBox(height: 16),
//                 Text('Lỗi: ${state.errorMessage}'),
//                 const SizedBox(height: 24),
//                 ElevatedButton.icon(
//                   onPressed: () {
//                     context.read<TagCubit>().getAllTags();
//                   },
//                   icon: const Icon(Icons.refresh),
//                   label: const Text('Thử lại'),
//                   style: ElevatedButton.styleFrom(
//                     foregroundColor: Colors.white,
//                     backgroundColor: RoomColors.amenities,
//                   ),
//                 ),
//               ],
//             ),
//           );
//         } else if (state.tags.isEmpty) {
//           return const Center(
//             child: Column(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(Icons.info_outline, color: Colors.amber, size: 48),
//                 SizedBox(height: 16),
//                 Text('Không có dữ liệu về tiện ích'),
//               ],
//             ),
//           );
//         } else if (state.status == TagStatus.loaded) {
//           return Form(
//             key: formKey,
//             autovalidateMode: AutovalidateMode.disabled,
//             child: SingleChildScrollView(
//               padding: const EdgeInsets.all(16.0),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   // Header
//                   const HeaderCard(
//                     title: 'Tiện ích phòng',
//                     subtitle: 'Chọn các tiện ích có sẵn cho phòng của bạn',
//                     icon: Icons.wifi_tethering,
//                     stepIndex: 3, // Amenities là step thứ 4 (index 3)
//                   ),
//                   const SizedBox(height: 24),
//
//                   // Card for selecting amenities
//                   Container(
//                     width: double.infinity,
//                     padding: const EdgeInsets.all(16),
//                     decoration: BoxDecoration(
//                       color: Colors.white,
//                       borderRadius: BorderRadius.circular(12),
//                       boxShadow: [
//                         BoxShadow(
//                           color: RoomColors.amenities.withOpacity(0.3),
//                           spreadRadius: 1,
//                           blurRadius: 4,
//                           offset: const Offset(0, 2),
//                         ),
//                       ],
//                     ),
//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Text(
//                           'Tiện ích trong phòng',
//                           style: TextStyle(
//                             fontSize: 16,
//                             fontWeight: FontWeight.bold,
//                             color: RoomColors.amenities,
//                           ),
//                         ),
//                         const SizedBox(height: 8),
//                         const Text(
//                           'Chọn các tiện ích có sẵn trong phòng của bạn',
//                           style: TextStyle(fontSize: 14, color: Colors.black54),
//                         ),
//                         const SizedBox(height: 16),
//
//                         // Tags selection
//                         Wrap(
//                           spacing: 8,
//                           runSpacing: 12,
//                           children: state.tags.map((tag) {
//                             final bool isSelected = selectedTagIds.contains(tag.id);
//                             return _buildTagChip(tag, isSelected);
//                           }).toList(),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                   const SizedBox(height: 24),
//
//                   // Selected tags section
//                   if (selectedTagIds.isNotEmpty) ...[
//                     Text(
//                       'Tiện ích đã chọn (${selectedTagIds.length})',
//                       style: TextStyle(
//                         fontSize: 16,
//                         fontWeight: FontWeight.bold,
//                         color: RoomColors.amenities,
//                       ),
//                     ),
//                     const SizedBox(height: 12),
//                     Wrap(
//                       spacing: 8,
//                       runSpacing: 12,
//                       children: selectedTagIds.map((tagId) {
//                         final tag = state.tags.firstWhere(
//                           (t) => t.id == tagId,
//                           orElse: () => RoomTag(
//                             id: tagId,
//                             name: 'Unknown',
//                           ),
//                         );
//                         return Chip(
//                           label: Text(tag.name),
//                           backgroundColor: RoomColors.amenities.withOpacity(0.2),
//                           deleteIconColor: RoomColors.amenities,
//                           labelStyle: TextStyle(color: RoomColors.formText),
//                           onDeleted: () => onTagRemoved(tagId),
//                         );
//                       }).toList(),
//                     ),
//                   ],
//
//                   const SizedBox(height: 24),
//
//                   // Tip card
//                   RoomTipCard(
//                     title: 'Mẹo về tiện ích',
//                     content: 'Chọn đầy đủ tiện ích có trong phòng giúp người thuê hiểu rõ hơn về nơi ở. Tiện ích càng nhiều, phòng bạn càng hấp dẫn.',
//                     icon: Icons.lightbulb,
//                     color: RoomColors.amenities,
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }
//
//         // Fallback UI
//         return const Center(
//           child: Text('Không thể tải tiện ích'),
//         );
//       },
//     );
//   }
//
//   Widget _buildTagChip(dynamic tag, bool isSelected) {
//     // Từ API tag có thể có field icon, nhưng trong model không có
//     // Chúng ta sẽ sử dụng hàm helper để tìm icon phù hợp dựa vào tên tag
//     final IconData iconData = _getIconForTagName(tag.name);
//
//     return FilterChip(
//       label: Text(tag.name),
//       avatar: Icon(
//         iconData,
//         size: 18,
//         color: isSelected ? Colors.white : RoomColors.amenities,
//       ),
//       selected: isSelected,
//       onSelected: (selected) {
//         if (selected) {
//           onTagSelected(tag.id!);
//         } else {
//           onTagRemoved(tag.id!);
//         }
//       },
//       selectedColor: RoomColors.amenities,
//       backgroundColor: RoomColors.amenities.withOpacity(0.1),
//       labelStyle: TextStyle(
//         color: isSelected ? Colors.white : RoomColors.formText,
//       ),
//       checkmarkColor: Colors.white,
//       showCheckmark: true,
//       elevation: isSelected ? 2 : 0,
//     );
//   }
//
//   // Lấy icon dựa trên tên của tag
//   IconData _getIconForTagName(String tagName) {
//     final String name = tagName.toLowerCase();
//
//     if (name.contains('wifi')) return Icons.wifi;
//     if (name.contains('điều hoà') || name.contains('điều hòa') || name.contains('máy lạnh')) return Icons.ac_unit;
//     if (name.contains('giặt')) return Icons.local_laundry_service;
//     if (name.contains('tivi') || name.contains('tv')) return Icons.tv;
//     if (name.contains('bếp') || name.contains('nấu ăn')) return Icons.kitchen;
//     if (name.contains('tắm') || name.contains('wc') || name.contains('nhà vệ sinh')) return Icons.bathtub;
//     if (name.contains('đỗ xe') || name.contains('để xe') || name.contains('parking')) return Icons.local_parking;
//     if (name.contains('an ninh') || name.contains('bảo vệ')) return Icons.security;
//     if (name.contains('ban công')) return Icons.balcony;
//     if (name.contains('hồ bơi') || name.contains('bể bơi')) return Icons.pool;
//     if (name.contains('gym') || name.contains('thể dục') || name.contains('thể hình')) return Icons.fitness_center;
//     if (name.contains('thú cưng') || name.contains('pet')) return Icons.pets;
//     if (name.contains('thang máy')) return Icons.elevator;
//
//     // Mặc định nếu không tìm thấy
//     return Icons.check_circle;
//   }
//
//   // Phương thức này không còn được sử dụng
//   IconData _getIconData(String? iconName) {
//     switch (iconName) {
//       case 'wifi': return Icons.wifi;
//       case 'ac_unit': return Icons.ac_unit;
//       case 'local_laundry_service': return Icons.local_laundry_service;
//       case 'tv': return Icons.tv;
//       case 'kitchen': return Icons.kitchen;
//       case 'bathtub': return Icons.bathtub;
//       case 'local_parking': return Icons.local_parking;
//       case 'security': return Icons.security;
//       case 'balcony': return Icons.balcony;
//       case 'pool': return Icons.pool;
//       case 'fitness_center': return Icons.fitness_center;
//       case 'pets': return Icons.pets;
//       case 'elevator': return Icons.elevator;
//       default: return Icons.check_circle;
//     }
//   }
// }