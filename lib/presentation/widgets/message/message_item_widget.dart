// import 'package:flutter/material.dart';
// import 'package:roomily/core/config/text_styles.dart';

// class MessageItemWidget extends StatelessWidget {
//   final String avatarUrl;
//   final String name;
//   final String message;
//   final String time;
//   final int unreadCount;
//   final VoidCallback onDelete;
//   final VoidCallback onTap;

//   const MessageItemWidget({
//     Key? key,
//     required this.avatarUrl,
//     required this.name,
//     required this.message,
//     required this.time,
//     this.unreadCount = 0,
//     required this.onDelete,
//     required this.onTap,
//   }) : super(key: key);

//   @override
//   Widget build(BuildContext context) {
//     return Dismissible(
//       key: Key(name), // Unique key for each message
//       direction: DismissDirection.endToStart, // Only swipe from right to left
//       onDismissed: (_) => onDelete(),
//       background: Container(
//         alignment: Alignment.centerRight,
//         padding: const EdgeInsets.only(right: 20),
//         color: Colors.red,
//         child: const Icon(
//           Icons.delete,
//           color: Colors.white,
//         ),
//       ),
//       child: InkWell(
//         onTap: onTap,
//         child: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(20),
//           ),
//           child: Row(
//             children: [
//               // Avatar
//               Container(
//                 width: 50,
//                 height: 50,
//                 decoration: BoxDecoration(
//                   shape: BoxShape.circle,
//                   color: Colors.white,
//                   boxShadow: [
//                     BoxShadow(
//                       color: Colors.black.withOpacity(0.1),
//                       blurRadius: 8,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: Stack(
//                   children: [
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(25),
//                       child: Image.network(
//                         avatarUrl,
//                         fit: BoxFit.cover,
//                         width: 50,
//                         height: 50,
//                         errorBuilder: (context, error, stackTrace) {
//                           return const Icon(Icons.person, size: 30, color: Colors.grey);
//                         },
//                       ),
//                     ),
//                     Positioned(
//                       right: 0,
//                       bottom: 0,
//                       child: Container(
//                         width: 12,
//                         height: 12,
//                         decoration: BoxDecoration(
//                           color: Colors.green,
//                           shape: BoxShape.circle,
//                           border: Border.all(color: Colors.white, width: 2),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(width: 12),
              
//               // Message content
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                       children: [
//                         Text(
//                           name,
//                           style: AppTextStyles.bodyLargeSemiBold.copyWith(
//                             color: Colors.black87,
//                           ),
//                         ),
//                         Text(
//                           time,
//                           style: AppTextStyles.bodySmallRegular.copyWith(
//                             color: Colors.grey[600],
//                           ),
//                         ),
//                       ],
//                     ),
//                     const SizedBox(height: 4),
//                     Row(
//                       children: [
//                         Expanded(
//                           child: Text(
//                             message,
//                             style: AppTextStyles.bodyMediumRegular.copyWith(
//                               color: Colors.grey[600],
//                             ),
//                             maxLines: 1,
//                             overflow: TextOverflow.ellipsis,
//                           ),
//                         ),
//                         if (unreadCount > 0) ...[
//                           const SizedBox(width: 8),
//                           Container(
//                             padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//                             decoration: BoxDecoration(
//                               color: Colors.green,
//                               borderRadius: BorderRadius.circular(10),
//                             ),
//                             child: Text(
//                               unreadCount.toString(),
//                               style: AppTextStyles.bodySmallSemiBold.copyWith(
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ],
//                     ),
//                   ],
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// } 