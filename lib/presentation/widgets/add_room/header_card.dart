// import 'package:flutter/material.dart';
// import 'package:roomily/presentation/screens/add_room_screen.dart';
//
// class HeaderCard extends StatelessWidget {
//   final String title;
//   final String subtitle;
//   final IconData icon;
//   final int? stepIndex; // Optional step index to determine color
//
//   const HeaderCard({
//     Key? key,
//     required this.title,
//     required this.subtitle,
//     required this.icon,
//     this.stepIndex,
//   }) : super(key: key);
//
//   // Get color based on current step or default to primary
//   Color _getStepColor() {
//     if (stepIndex == null) {
//       // Thử đoán bước từ tiêu đề
//       if (title.contains('cơ bản')) return RoomColors.basicInfo;
//       if (title.contains('địa') || title.contains('vị trí')) return RoomColors.location;
//       if (title.contains('giá') || title.contains('chi phí')) return RoomColors.pricing;
//       if (title.contains('tiện ích') || title.contains('tiện nghi')) return RoomColors.amenities;
//       if (title.contains('hình') || title.contains('ảnh')) return RoomColors.images;
//       return RoomColors.primary;
//     } else {
//       switch (stepIndex) {
//         case 0: return RoomColors.basicInfo;
//         case 1: return RoomColors.location;
//         case 2: return RoomColors.pricing;
//         case 3: return RoomColors.amenities;
//         case 4: return RoomColors.images;
//         default: return RoomColors.primary;
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final Color stepColor = _getStepColor();
//     final Color lighterColor = Color.lerp(stepColor, Colors.white, 0.3)!;
//
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         gradient: LinearGradient(
//           colors: [
//             lighterColor,
//             stepColor,
//           ],
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//         ),
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: stepColor.withOpacity(0.3),
//             blurRadius: 8,
//             spreadRadius: 2,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: Row(
//         children: [
//           Container(
//             height: 50,
//             width: 50,
//             decoration: BoxDecoration(
//               color: Colors.white.withOpacity(0.2),
//               borderRadius: BorderRadius.circular(12),
//             ),
//             child: Center(
//               child: Icon(
//                 icon,
//                 size: 30,
//                 color: Colors.white,
//               ),
//             ),
//           ),
//           const SizedBox(width: 16),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     fontSize: 20,
//                     fontWeight: FontWeight.bold,
//                     color: Colors.white,
//                   ),
//                 ),
//                 const SizedBox(height: 4),
//                 Text(
//                   subtitle,
//                   style: TextStyle(
//                     color: Colors.white.withOpacity(0.9),
//                     fontSize: 13,
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }