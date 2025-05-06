// import 'package:flutter/material.dart';

// class ProfileStatsBar extends StatelessWidget {
//   final int favoritesCount;
//   final int bookingsCount;
//   final int reviewsCount;
//   final Function()? onFavoritesPressed;
//   final Function()? onBookingsPressed;
//   final Function()? onReviewsPressed;
  
//   const ProfileStatsBar({
//     Key? key, 
//     required this.favoritesCount, 
//     required this.bookingsCount, 
//     required this.reviewsCount,
//     this.onFavoritesPressed,
//     this.onBookingsPressed,
//     this.onReviewsPressed,
//   }) : super(key: key);
  
//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: const EdgeInsets.symmetric(vertical: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 5,
//             spreadRadius: 1,
//           ),
//         ],
//       ),
//       child: Row(
//         mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//         children: [
//           _buildStatItem(
//             context, 
//             favoritesCount, 
//             'Yêu thích', 
//             Icons.favorite,
//             onFavoritesPressed,
//           ),
//           _buildDivider(),
//           _buildStatItem(
//             context, 
//             bookingsCount, 
//             'Đặt phòng', 
//             Icons.home,
//             onBookingsPressed,
//           ),
//           _buildDivider(),
//           _buildStatItem(
//             context, 
//             reviewsCount, 
//             'Đánh giá', 
//             Icons.star,
//             onReviewsPressed,
//           ),
//         ],
//       ),
//     );
//   }
  
//   Widget _buildStatItem(
//     BuildContext context, 
//     int count, 
//     String label, 
//     IconData icon,
//     Function()? onPressed,
//   ) {
//     return InkWell(
//       onTap: onPressed,
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
//         child: Column(
//           children: [
//             Icon(icon, color: Theme.of(context).colorScheme.primary),
//             const SizedBox(height: 8),
//             Text(
//               count.toString(),
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 18,
//               ),
//             ),
//             const SizedBox(height: 4),
//             Text(
//               label,
//               style: TextStyle(
//                 color: Colors.grey[600],
//                 fontSize: 12,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
  
//   Widget _buildDivider() {
//     return Container(
//       height: 40,
//       width: 1,
//       color: Colors.grey[300],
//     );
//   }
// } 