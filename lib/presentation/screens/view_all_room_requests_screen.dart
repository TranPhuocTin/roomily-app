// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:intl/intl.dart';
// import 'package:roomily/data/blocs/rented_room/rental_requests_cubit.dart';
// import 'package:roomily/data/blocs/rented_room/rental_requests_state.dart';
// import 'package:roomily/data/models/rental_request.dart';
// import 'package:roomily/data/repositories/rented_room_repository_impl.dart';
// import 'package:roomily/presentation/screens/chat_room_screen.dart';
//
// class ViewAllRoomRequestsScreen extends StatefulWidget {
//   const ViewAllRoomRequestsScreen({Key? key}) : super(key: key);
//
//   @override
//   State<ViewAllRoomRequestsScreen> createState() => _ViewAllRoomRequestsScreenState();
// }
//
// class _ViewAllRoomRequestsScreenState extends State<ViewAllRoomRequestsScreen> {
//   late final RentalRequestsCubit _rentalRequestsCubit;
//
//   @override
//   void initState() {
//     super.initState();
//     _rentalRequestsCubit = RentalRequestsCubit(
//       rentedRoomRepository: RentedRoomRepositoryImpl(),
//     );
//     _loadRentalRequests();
//   }
//
//   @override
//   void dispose() {
//     _rentalRequestsCubit.close();
//     super.dispose();
//   }
//
//   Future<void> _loadRentalRequests() async {
//     await _rentalRequestsCubit.getLandlordRentalRequests();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Yêu cầu thuê phòng'),
//         backgroundColor: const Color(0xFF9575CD),
//         elevation: 0,
//       ),
//       body: BlocProvider.value(
//         value: _rentalRequestsCubit,
//         child: _buildContent(),
//       ),
//     );
//   }
//
//   Widget _buildContent() {
//     return RefreshIndicator(
//       onRefresh: _loadRentalRequests,
//       child: BlocBuilder<RentalRequestsCubit, RentalRequestsState>(
//         builder: (context, state) {
//           if (state is RentalRequestsLoading) {
//             return const Center(
//               child: CircularProgressIndicator(),
//             );
//           } else if (state is RentalRequestsLoaded) {
//             final requests = state.rentalRequests;
//
//             if (requests.isEmpty) {
//               return _buildEmptyState();
//             }
//
//             // Sort requests: PENDING first, then by expiration date
//             final sortedRequests = List<RentalRequest>.from(requests);
//             sortedRequests.sort((a, b) {
//               // PENDING requests come first
//               if (a.status == RentalRequestStatus.PENDING && b.status != RentalRequestStatus.PENDING) {
//                 return -1;
//               } else if (a.status != RentalRequestStatus.PENDING && b.status == RentalRequestStatus.PENDING) {
//                 return 1;
//               }
//
//               // Then sort by expiration date (most recent first)
//               return b.expiresAt.compareTo(a.expiresAt);
//             });
//
//             return ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: sortedRequests.length,
//               itemBuilder: (context, index) => _buildRequestItem(context, sortedRequests[index]),
//             );
//           } else if (state is RentalRequestsError) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Text(
//                     'Không thể tải yêu cầu: ${state.error}',
//                     style: const TextStyle(color: Colors.red),
//                     textAlign: TextAlign.center,
//                   ),
//                   const SizedBox(height: 16),
//                   ElevatedButton(
//                     onPressed: _loadRentalRequests,
//                     child: const Text('Thử lại'),
//                   ),
//                 ],
//               ),
//             );
//           }
//
//           // Initial state
//           return const Center(
//             child: CircularProgressIndicator(),
//           );
//         },
//       ),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.inbox_outlined,
//             size: 64,
//             color: Colors.grey[400],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Không có yêu cầu thuê phòng nào',
//             style: TextStyle(
//               fontSize: 16,
//               color: Colors.grey[600],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRequestItem(BuildContext context, RentalRequest request) {
//     // Format thời gian hết hạn
//     final formatter = DateFormat('HH:mm, dd/MM/yyyy');
//     final expiresTime = formatter.format(request.expiresAt);
//
//     return Container(
//       padding: const EdgeInsets.all(14),
//       margin: const EdgeInsets.only(bottom: 12),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.05),
//             blurRadius: 10,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Row(
//             children: [
//               CircleAvatar(
//                 radius: 24,
//                 backgroundImage: NetworkImage(
//                   // Placeholder image, ideally you'd use user profile image
//                   'https://randomuser.me/api/portraits/men/${request.id.hashCode % 100}.jpg',
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       'Yêu cầu thuê phòng', // Should get user name if available
//                       style: const TextStyle(
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Phòng ID: ${request.roomId}', // Should get room name if available
//                       style: TextStyle(
//                         color: Colors.grey[700],
//                         fontSize: 14,
//                       ),
//                     ),
//                     const SizedBox(height: 4),
//                     Text(
//                       'Hết hạn: $expiresTime',
//                       style: TextStyle(
//                         color: Colors.grey[500],
//                         fontSize: 12,
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               _buildStatusChip(request.status),
//             ],
//           ),
//           const SizedBox(height: 10),
//           if (request.status == RentalRequestStatus.PENDING)
//             Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 // Button to chat with the requester
//                 TextButton.icon(
//                   onPressed: () {
//                     // Navigate to chat
//                     Navigator.push(
//                       context,
//                       MaterialPageRoute(
//                         builder: (context) => ChatRoomScreen(),
//                       ),
//                     );
//                   },
//                   icon: const Icon(Icons.chat_bubble_outline, size: 18),
//                   label: const Text('Nhắn tin'),
//                   style: TextButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     foregroundColor: Colors.blue,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 // Button to reject request
//                 TextButton.icon(
//                   onPressed: () {
//                     _showConfirmationDialog(
//                       context,
//                       'Từ chối yêu cầu',
//                       'Bạn có chắc chắn muốn từ chối yêu cầu này?',
//                       () => _rejectRequest(context, request.id),
//                     );
//                   },
//                   icon: const Icon(Icons.cancel_outlined, size: 18),
//                   label: const Text('Từ chối'),
//                   style: TextButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     foregroundColor: Colors.red,
//                   ),
//                 ),
//                 const SizedBox(width: 8),
//                 // Button to accept request
//                 TextButton.icon(
//                   onPressed: () {
//                     _showConfirmationDialog(
//                       context,
//                       'Chấp nhận yêu cầu',
//                       'Bạn có chắc chắn muốn chấp nhận yêu cầu này?',
//                       () => _acceptRequest(context, request.id),
//                     );
//                   },
//                   icon: const Icon(Icons.check_circle_outline, size: 18),
//                   label: const Text('Chấp nhận'),
//                   style: TextButton.styleFrom(
//                     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//                     foregroundColor: Colors.green,
//                   ),
//                 ),
//               ],
//             ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusChip(RentalRequestStatus status) {
//     late Color color;
//     late String label;
//
//     switch (status) {
//       case RentalRequestStatus.PENDING:
//         color = Colors.orange;
//         label = 'Chờ duyệt';
//         break;
//       case RentalRequestStatus.APPROVED:
//         color = Colors.green;
//         label = 'Đã duyệt';
//         break;
//       case RentalRequestStatus.REJECTED:
//         color = Colors.red;
//         label = 'Từ chối';
//         break;
//       case RentalRequestStatus.CANCELED:
//         color = Colors.grey;
//         label = 'Đã hủy';
//         break;
//     }
//
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
//       decoration: BoxDecoration(
//         color: color.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(20),
//         border: Border.all(color: color.withOpacity(0.3)),
//       ),
//       child: Text(
//         label,
//         style: TextStyle(
//           color: color,
//           fontSize: 12,
//           fontWeight: FontWeight.w500,
//         ),
//       ),
//     );
//   }
//
//   Future<void> _showConfirmationDialog(
//     BuildContext context,
//     String title,
//     String message,
//     VoidCallback onConfirm,
//   ) async {
//     return showDialog<void>(
//       context: context,
//       barrierDismissible: false,
//       builder: (BuildContext dialogContext) {
//         return AlertDialog(
//           title: Text(title),
//           content: SingleChildScrollView(
//             child: ListBody(
//               children: <Widget>[
//                 Text(message),
//               ],
//             ),
//           ),
//           actions: <Widget>[
//             TextButton(
//               child: const Text('Hủy'),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//               },
//             ),
//             TextButton(
//               child: const Text('Xác nhận'),
//               onPressed: () {
//                 Navigator.of(dialogContext).pop();
//                 onConfirm();
//               },
//             ),
//           ],
//         );
//       },
//     );
//   }
//
//   Future<void> _acceptRequest(BuildContext context, String chatRoomId) async {
//     await _rentalRequestsCubit.acceptRentRequest(chatRoomId);
//
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Đã chấp nhận yêu cầu thuê phòng'),
//           backgroundColor: Colors.green,
//         ),
//       );
//     }
//   }
//
//   Future<void> _rejectRequest(BuildContext context, String chatRoomId) async {
//     await _rentalRequestsCubit.rejectRentRequest(chatRoomId);
//
//     if (mounted) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Đã từ chối yêu cầu thuê phòng'),
//           backgroundColor: Colors.red,
//         ),
//       );
//     }
//   }
// }