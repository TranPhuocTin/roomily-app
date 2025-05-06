// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:intl/intl.dart';
//
// class LandlordReviewsScreen extends StatefulWidget {
//   const LandlordReviewsScreen({Key? key}) : super(key: key);
//
//   @override
//   State<LandlordReviewsScreen> createState() => _LandlordReviewsScreenState();
// }
//
// class _LandlordReviewsScreenState extends State<LandlordReviewsScreen> with SingleTickerProviderStateMixin {
//   late TabController _tabController;
//   final TextEditingController _searchController = TextEditingController();
//   String _searchQuery = '';
//   String _selectedFilterOption = 'Tất cả đánh giá';
//   int _selectedRatingFilter = 0;
//
//   @override
//   void initState() {
//     super.initState();
//     _tabController = TabController(length: 2, vsync: this);
//   }
//
//   @override
//   void dispose() {
//     _tabController.dispose();
//     _searchController.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[100],
//       appBar: AppBar(
//         backgroundColor: const Color(0xFF9575CD),
//         systemOverlayStyle: SystemUiOverlayStyle.light,
//         elevation: 0,
//         title: const Text(
//           'Quản lý đánh giá',
//           style: TextStyle(
//             color: Colors.white,
//             fontWeight: FontWeight.bold,
//           ),
//         ),
//         bottom: PreferredSize(
//           preferredSize: const Size.fromHeight(kToolbarHeight),
//           child: Container(
//             color: Colors.white,
//             child: TabBar(
//               controller: _tabController,
//               labelColor: const Color(0xFF9575CD),
//               unselectedLabelColor: Colors.grey[600],
//               indicatorColor: const Color(0xFF9575CD),
//               tabs: const [
//                 Tab(text: 'Tất cả đánh giá'),
//                 Tab(text: 'Chưa phản hồi'),
//               ],
//             ),
//           ),
//         ),
//       ),
//       body: Column(
//         children: [
//           _buildSearchBar(),
//           _buildFilterOptions(),
//           Expanded(
//             child: TabBarView(
//               controller: _tabController,
//               children: [
//                 _buildAllReviewsTab(),
//                 _buildUnrespondedReviewsTab(),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildSearchBar() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: TextField(
//         controller: _searchController,
//         onChanged: (value) {
//           setState(() {
//             _searchQuery = value;
//           });
//         },
//         decoration: InputDecoration(
//           hintText: 'Tìm kiếm đánh giá...',
//           prefixIcon: const Icon(Icons.search),
//           suffixIcon: _searchQuery.isNotEmpty
//               ? IconButton(
//                   icon: const Icon(Icons.clear),
//                   onPressed: () {
//                     setState(() {
//                       _searchController.clear();
//                       _searchQuery = '';
//                     });
//                   },
//                 )
//               : null,
//           filled: true,
//           fillColor: Colors.white,
//           contentPadding: const EdgeInsets.symmetric(vertical: 0),
//           border: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(30),
//             borderSide: BorderSide.none,
//           ),
//           enabledBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(30),
//             borderSide: BorderSide.none,
//           ),
//           focusedBorder: OutlineInputBorder(
//             borderRadius: BorderRadius.circular(30),
//             borderSide: BorderSide(color: Colors.grey.shade300),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildFilterOptions() {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Filter by dropdown
//           Row(
//             children: [
//               const Text(
//                 'Lọc theo: ',
//                 style: TextStyle(
//                   fontWeight: FontWeight.w500,
//                   fontSize: 14,
//                 ),
//               ),
//               const SizedBox(width: 8),
//               DropdownButton<String>(
//                 value: _selectedFilterOption,
//                 underline: const SizedBox(),
//                 items: const [
//                   DropdownMenuItem(
//                     value: 'Tất cả đánh giá',
//                     child: Text('Tất cả đánh giá'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'Mới nhất',
//                     child: Text('Mới nhất'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'Cũ nhất',
//                     child: Text('Cũ nhất'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'Đánh giá cao nhất',
//                     child: Text('Đánh giá cao nhất'),
//                   ),
//                   DropdownMenuItem(
//                     value: 'Đánh giá thấp nhất',
//                     child: Text('Đánh giá thấp nhất'),
//                   ),
//                 ],
//                 onChanged: (value) {
//                   if (value != null) {
//                     setState(() {
//                       _selectedFilterOption = value;
//                     });
//                   }
//                 },
//               ),
//             ],
//           ),
//
//           const SizedBox(height: 12),
//
//           // Rating filter
//           SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: Row(
//               children: [
//                 _buildRatingFilterChip(0, 'Tất cả'),
//                 _buildRatingFilterChip(5, '5 sao'),
//                 _buildRatingFilterChip(4, '4 sao'),
//                 _buildRatingFilterChip(3, '3 sao'),
//                 _buildRatingFilterChip(2, '2 sao'),
//                 _buildRatingFilterChip(1, '1 sao'),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRatingFilterChip(int rating, String label) {
//     final isSelected = _selectedRatingFilter == rating;
//
//     return Padding(
//       padding: const EdgeInsets.only(right: 8),
//       child: FilterChip(
//         label: Text(label),
//         selected: isSelected,
//         onSelected: (selected) {
//           setState(() {
//             _selectedRatingFilter = rating;
//           });
//         },
//         backgroundColor: Colors.white,
//         selectedColor: const Color(0xFF9575CD).withOpacity(0.2),
//         checkmarkColor: const Color(0xFF9575CD),
//         labelStyle: TextStyle(
//           color: isSelected ? const Color(0xFF9575CD) : Colors.black87,
//           fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
//         ),
//       ),
//     );
//   }
//
//   Widget _buildAllReviewsTab() {
//     // Mock data for demonstration
//     final reviews = [
//       {
//         'id': '1',
//         'userName': 'Nguyễn Văn A',
//         'userAvatar': 'https://randomuser.me/api/portraits/men/32.jpg',
//         'roomName': 'Phòng Hòa Vang',
//         'roomId': '101',
//         'rating': 5,
//         'comment': 'Phòng rất sạch sẽ, thoáng mát, đầy đủ tiện nghi. Chủ nhà thân thiện và nhiệt tình. Vị trí thuận tiện đi lại, gần chợ và trường học.',
//         'date': DateTime.now().subtract(const Duration(days: 2)),
//         'responded': true,
//         'response': 'Cảm ơn bạn đã đánh giá tích cực. Rất vui khi bạn hài lòng với phòng trọ của chúng tôi!',
//         'responseDate': DateTime.now().subtract(const Duration(days: 1)),
//         'images': [
//           'https://images.unsplash.com/photo-1522708323590-d24dbb6b0267',
//           'https://images.unsplash.com/photo-1502672260266-1c1ef2d93688',
//         ],
//       },
//       {
//         'id': '2',
//         'userName': 'Trần Thị B',
//         'userAvatar': 'https://randomuser.me/api/portraits/women/44.jpg',
//         'roomName': 'Phòng Tam Kỳ',
//         'roomId': '102',
//         'rating': 4,
//         'comment': 'Phòng ốc sạch sẽ, đầy đủ tiện nghi. Tuy nhiên hơi ồn vào buổi tối do gần đường lớn.',
//         'date': DateTime.now().subtract(const Duration(days: 5)),
//         'responded': false,
//         'response': '',
//         'responseDate': null,
//         'images': [],
//       },
//       {
//         'id': '3',
//         'userName': 'Lê Văn C',
//         'userAvatar': 'https://randomuser.me/api/portraits/men/65.jpg',
//         'roomName': 'Phòng Liên Chiểu',
//         'roomId': '103',
//         'rating': 3,
//         'comment': 'Phòng ở tạm được, không gian hơi chật. Giá cả hợp lý cho vị trí.',
//         'date': DateTime.now().subtract(const Duration(days: 10)),
//         'responded': true,
//         'response': 'Cảm ơn bạn đã góp ý. Chúng tôi sẽ cải thiện không gian phòng trong thời gian tới.',
//         'responseDate': DateTime.now().subtract(const Duration(days: 9)),
//         'images': [
//           'https://images.unsplash.com/photo-1493809842364-78817add7ffb',
//         ],
//       },
//       {
//         'id': '4',
//         'userName': 'Hoàng Thị D',
//         'userAvatar': 'https://randomuser.me/api/portraits/women/22.jpg',
//         'roomName': 'Phòng Sơn Trà',
//         'roomId': '104',
//         'rating': 2,
//         'comment': 'Phòng không như mô tả, thiếu nhiều tiện nghi. Điều hòa không hoạt động tốt.',
//         'date': DateTime.now().subtract(const Duration(days: 15)),
//         'responded': false,
//         'response': '',
//         'responseDate': null,
//         'images': [],
//       },
//       {
//         'id': '5',
//         'userName': 'Phan Văn E',
//         'userAvatar': 'https://randomuser.me/api/portraits/men/91.jpg',
//         'roomName': 'Phòng Hải Châu',
//         'roomId': '105',
//         'rating': 5,
//         'comment': 'Tuyệt vời! Phòng rộng rãi, sạch sẽ, đầy đủ tiện nghi. Chủ nhà rất tốt bụng và nhiệt tình hỗ trợ.',
//         'date': DateTime.now().subtract(const Duration(days: 20)),
//         'responded': true,
//         'response': 'Rất vui khi bạn hài lòng với dịch vụ của chúng tôi. Hẹn gặp lại bạn lần sau!',
//         'responseDate': DateTime.now().subtract(const Duration(days: 19)),
//         'images': [
//           'https://images.unsplash.com/photo-1560448204-603b3fc33ddc',
//           'https://images.unsplash.com/photo-1586023492125-27b2c045efd7',
//         ],
//       },
//     ];
//
//     // Filter reviews based on search query and rating filter
//     final filteredReviews = reviews.where((review) {
//       final matchesSearch = _searchQuery.isEmpty ||
//           (review['userName'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           (review['roomName'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
//           (review['comment'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
//
//       final matchesRating = _selectedRatingFilter == 0 || review['rating'] == _selectedRatingFilter;
//
//       return matchesSearch && matchesRating;
//     }).toList();
//
//     // Sort reviews based on selected filter option
//     switch (_selectedFilterOption) {
//       case 'Mới nhất':
//         filteredReviews.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
//         break;
//       case 'Cũ nhất':
//         filteredReviews.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
//         break;
//       case 'Đánh giá cao nhất':
//         filteredReviews.sort((a, b) => (b['rating'] as int).compareTo(a['rating'] as int));
//         break;
//       case 'Đánh giá thấp nhất':
//         filteredReviews.sort((a, b) => (a['rating'] as int).compareTo(b['rating'] as int));
//         break;
//       default:
//         filteredReviews.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
//     }
//
//     if (filteredReviews.isEmpty) {
//       return _buildEmptyState();
//     }
//
//     return ListView.builder(
//       padding: const EdgeInsets.all(16),
//       itemCount: filteredReviews.length,
//       itemBuilder: (context, index) {
//         final review = filteredReviews[index];
//         return _buildReviewCard(review);
//       },
//     );
//   }
//
//   Widget _buildUnrespondedReviewsTab() {
//     // This would be filtered to show only unresponded reviews
//     return _buildAllReviewsTab();
//   }
//
//   Widget _buildReviewCard(Map<String, dynamic> review) {
//     final dateFormat = DateFormat('dd/MM/yyyy');
//     final formattedDate = dateFormat.format(review['date'] as DateTime);
//     final images = review['images'] as List<String>;
//     final hasImages = images.isNotEmpty;
//
//     return Card(
//       margin: const EdgeInsets.only(bottom: 16),
//       elevation: 2,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           // Review header with user info
//           ListTile(
//             contentPadding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
//             leading: CircleAvatar(
//               backgroundImage: NetworkImage(review['userAvatar'] as String),
//             ),
//             title: Row(
//               children: [
//                 Text(
//                   review['userName'] as String,
//                   style: const TextStyle(
//                     fontWeight: FontWeight.bold,
//                   ),
//                 ),
//                 const Spacer(),
//                 _buildRatingStars(review['rating'] as int),
//               ],
//             ),
//             subtitle: Text(
//               '$formattedDate • ${review['roomName']}',
//               style: TextStyle(
//                 fontSize: 12,
//                 color: Colors.grey[600],
//               ),
//             ),
//           ),
//
//           // Review content
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 16),
//             child: Text(
//               review['comment'] as String,
//               style: const TextStyle(fontSize: 14),
//             ),
//           ),
//
//           // Review images if any
//           if (hasImages)
//             Padding(
//               padding: const EdgeInsets.all(16),
//               child: SizedBox(
//                 height: 80,
//                 child: ListView.builder(
//                   scrollDirection: Axis.horizontal,
//                   itemCount: images.length,
//                   itemBuilder: (context, index) {
//                     return Container(
//                       width: 80,
//                       height: 80,
//                       margin: const EdgeInsets.only(right: 8),
//                       decoration: BoxDecoration(
//                         borderRadius: BorderRadius.circular(8),
//                         image: DecorationImage(
//                           image: NetworkImage(
//                             '${images[index]}?ixlib=rb-4.0.3&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&w=200&q=80',
//                           ),
//                           fit: BoxFit.cover,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//               ),
//             ),
//
//           // Response section if already responded
//           if (review['responded'] as bool)
//             Container(
//               margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
//               padding: const EdgeInsets.all(12),
//               decoration: BoxDecoration(
//                 color: Colors.grey[100],
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       const Icon(
//                         Icons.reply,
//                         size: 16,
//                         color: Color(0xFF9575CD),
//                       ),
//                       const SizedBox(width: 8),
//                       const Text(
//                         'Phản hồi của bạn',
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 12,
//                           color: Color(0xFF9575CD),
//                         ),
//                       ),
//                       const Spacer(),
//                       Text(
//                         'Ngày ${dateFormat.format(review['responseDate'] as DateTime)}',
//                         style: TextStyle(
//                           fontSize: 10,
//                           color: Colors.grey[600],
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     review['response'] as String,
//                     style: const TextStyle(fontSize: 12),
//                   ),
//                 ],
//               ),
//             ),
//
//           // Action buttons
//           Padding(
//             padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.end,
//               children: [
//                 TextButton.icon(
//                   onPressed: () {
//                     // View room details
//                   },
//                   icon: const Icon(Icons.home, size: 16),
//                   label: const Text('Chi tiết phòng'),
//                   style: TextButton.styleFrom(
//                     foregroundColor: Colors.grey[700],
//                     padding: const EdgeInsets.symmetric(horizontal: 12),
//                   ),
//                 ),
//                 if (!(review['responded'] as bool))
//                   TextButton.icon(
//                     onPressed: () {
//                       _showResponseDialog(review);
//                     },
//                     icon: const Icon(Icons.reply, size: 16),
//                     label: const Text('Phản hồi'),
//                     style: TextButton.styleFrom(
//                       foregroundColor: const Color(0xFF9575CD),
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                   )
//                 else
//                   TextButton.icon(
//                     onPressed: () {
//                       _showResponseDialog(review, isEdit: true);
//                     },
//                     icon: const Icon(Icons.edit, size: 16),
//                     label: const Text('Chỉnh sửa'),
//                     style: TextButton.styleFrom(
//                       foregroundColor: Colors.blue,
//                       padding: const EdgeInsets.symmetric(horizontal: 12),
//                     ),
//                   ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRatingStars(int rating) {
//     return Row(
//       children: List.generate(5, (index) {
//         return Icon(
//           index < rating ? Icons.star : Icons.star_border,
//           color: index < rating ? Colors.amber : Colors.grey[400],
//           size: 18,
//         );
//       }),
//     );
//   }
//
//   Widget _buildEmptyState() {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Icon(
//             Icons.rate_review,
//             size: 80,
//             color: Colors.grey[300],
//           ),
//           const SizedBox(height: 16),
//           Text(
//             'Không tìm thấy đánh giá nào',
//             style: TextStyle(
//               fontSize: 18,
//               fontWeight: FontWeight.bold,
//               color: Colors.grey[700],
//             ),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             'Chưa có đánh giá nào hoặc không có đánh giá phù hợp với bộ lọc',
//             style: TextStyle(
//               fontSize: 14,
//               color: Colors.grey[600],
//             ),
//             textAlign: TextAlign.center,
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showResponseDialog(Map<String, dynamic> review, {bool isEdit = false}) {
//     final TextEditingController responseController = TextEditingController();
//     if (isEdit) {
//       responseController.text = review['response'] as String;
//     }
//
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         title: Text(isEdit ? 'Chỉnh sửa phản hồi' : 'Phản hồi đánh giá'),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(
//               '${review['userName']} - ${review['roomName']}',
//               style: const TextStyle(
//                 fontWeight: FontWeight.bold,
//                 fontSize: 14,
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Đánh giá: ${review['comment']}',
//               style: TextStyle(
//                 fontSize: 13,
//                 color: Colors.grey[700],
//               ),
//               maxLines: 2,
//               overflow: TextOverflow.ellipsis,
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: responseController,
//               maxLines: 4,
//               decoration: InputDecoration(
//                 hintText: 'Nhập phản hồi của bạn...',
//                 border: OutlineInputBorder(
//                   borderRadius: BorderRadius.circular(12),
//                 ),
//                 filled: true,
//                 fillColor: Colors.grey[50],
//               ),
//             ),
//           ],
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.pop(context),
//             child: const Text('Hủy'),
//           ),
//           ElevatedButton(
//             onPressed: () {
//               // Save response logic would go here
//               Navigator.pop(context);
//
//               // Show success toast
//               ScaffoldMessenger.of(context).showSnackBar(
//                 SnackBar(
//                   content: Text(isEdit
//                     ? 'Đã cập nhật phản hồi'
//                     : 'Đã gửi phản hồi thành công'
//                   ),
//                   backgroundColor: Colors.green,
//                 ),
//               );
//
//               // In a real app, we would update the data
//               setState(() {
//                 // This is just for demonstration
//               });
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: const Color(0xFF9575CD),
//             ),
//             child: Text(isEdit ? 'Cập nhật' : 'Gửi phản hồi'),
//           ),
//         ],
//       ),
//     );
//   }
// }