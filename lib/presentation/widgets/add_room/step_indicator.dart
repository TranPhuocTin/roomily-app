// import 'package:flutter/material.dart';
// import 'package:roomily/presentation/screens/add_room_screen.dart';
//
// class StepIndicator extends StatelessWidget {
//   final int currentStep;
//   final int stepIndex;
//   final String title;
//
//   const StepIndicator({
//     Key? key,
//     required this.currentStep,
//     required this.stepIndex,
//     required this.title,
//   }) : super(key: key);
//
//   // Get color for this step
//   Color _getStepColor() {
//     switch (stepIndex) {
//       case 0: return RoomColors.basicInfo;
//       case 1: return RoomColors.location;
//       case 2: return RoomColors.pricing;
//       case 3: return RoomColors.amenities;
//       case 4: return RoomColors.images;
//       default: return RoomColors.primary;
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final bool isActive = stepIndex == currentStep;
//     final bool isCompleted = stepIndex < currentStep;
//     final Color stepColor = _getStepColor();
//
//     return Column(
//       children: [
//         Container(
//           width: 36,
//           height: 36,
//           decoration: BoxDecoration(
//             color: isActive
//                 ? stepColor
//                 : isCompleted
//                     ? stepColor.withOpacity(0.7)
//                     : stepColor.withOpacity(0.2),
//             shape: BoxShape.circle,
//             border: Border.all(
//               color: isActive
//                   ? stepColor
//                   : isCompleted
//                       ? stepColor.withOpacity(0.8)
//                       : stepColor.withOpacity(0.3),
//               width: 2,
//             ),
//             boxShadow: isActive
//                 ? [
//                     BoxShadow(
//                       color: stepColor.withOpacity(0.4),
//                       blurRadius: 8,
//                       spreadRadius: 2,
//                     )
//                   ]
//                 : null,
//           ),
//           child: Center(
//             child: isCompleted
//                 ? const Icon(Icons.check, color: Colors.white, size: 18)
//                 : Text(
//                     (stepIndex + 1).toString(),
//                     style: TextStyle(
//                       color: isActive ? Colors.white : stepColor,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//           ),
//         ),
//         const SizedBox(height: 4),
//         Text(
//           title,
//           style: TextStyle(
//             fontSize: 10,
//             color: isActive
//                 ? stepColor
//                 : isCompleted
//                     ? stepColor.withOpacity(0.7)
//                     : stepColor.withOpacity(0.5),
//             fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
//           ),
//         ),
//       ],
//     );
//   }
// }