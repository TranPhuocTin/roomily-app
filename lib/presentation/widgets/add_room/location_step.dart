// import 'package:flutter/material.dart';
// import 'package:roomily/core/services/location_service.dart';
// import 'package:roomily/presentation/widgets/add_room/header_card.dart';
// import 'package:roomily/presentation/widgets/add_room/room_tip_card.dart';
// import 'package:roomily/presentation/screens/add_room_screen.dart';
//
// class LocationStep extends StatefulWidget {
//   final TextEditingController addressController;
//   final TextEditingController cityController;
//   final TextEditingController districtController;
//   final TextEditingController wardController;
//   final TextEditingController latitudeController;
//   final TextEditingController longitudeController;
//   final TextEditingController nearbyAmenitiesController;
//   final GlobalKey<FormState> formKey;
//   final FocusNode? addressFocusNode;
//
//   const LocationStep({
//     Key? key,
//     required this.addressController,
//     required this.cityController,
//     required this.districtController,
//     required this.wardController,
//     required this.latitudeController,
//     required this.longitudeController,
//     required this.nearbyAmenitiesController,
//     required this.formKey,
//     this.addressFocusNode,
//   }) : super(key: key);
//
//   @override
//   State<LocationStep> createState() => _LocationStepState();
// }
//
// class _LocationStepState extends State<LocationStep> {
//   final LocationService _locationService = LocationService();
//
//   // Danh sách tỉnh/thành phố, quận/huyện, phường/xã
//   List<Map<String, dynamic>> _provinces = [];
//   List<Map<String, dynamic>> _districts = [];
//   List<Map<String, dynamic>> _wards = [];
//
//   // Các giá trị đã chọn
//   int? _selectedProvinceCode;
//   int? _selectedDistrictCode;
//
//   // Trạng thái loading
//   bool _isLoadingProvinces = false;
//   bool _isLoadingDistricts = false;
//   bool _isLoadingWards = false;
//
//   // Màu chính cho location step
//   final Color _primaryColor = RoomColors.location;
//
//   @override
//   void initState() {
//     super.initState();
//     _loadProvinces();
//   }
//
//   // Tải danh sách tỉnh/thành phố
//   Future<void> _loadProvinces() async {
//     setState(() {
//       _isLoadingProvinces = true;
//     });
//
//     try {
//       final provinces = await _locationService.getProvinces();
//       setState(() {
//         _provinces = provinces;
//         _isLoadingProvinces = false;
//       });
//
//       // Nếu đã có city, tìm province code tương ứng
//       if (widget.cityController.text.isNotEmpty) {
//         _setSelectedProvinceByName(widget.cityController.text);
//       }
//     } catch (e) {
//       setState(() {
//         _isLoadingProvinces = false;
//       });
//       print('Error loading provinces: $e');
//     }
//   }
//
//   // Tải danh sách quận/huyện dựa trên tỉnh/thành phố đã chọn
//   Future<void> _loadDistricts(int provinceCode) async {
//     setState(() {
//       _isLoadingDistricts = true;
//       _districts = [];
//       _wards = [];
//       _selectedDistrictCode = null;
//     });
//
//     try {
//       final districts = await _locationService.getDistricts(provinceCode);
//       setState(() {
//         _districts = districts;
//         _isLoadingDistricts = false;
//       });
//
//       // Nếu đã có district, tìm district code tương ứng
//       if (widget.districtController.text.isNotEmpty) {
//         _setSelectedDistrictByName(widget.districtController.text);
//       }
//     } catch (e) {
//       setState(() {
//         _isLoadingDistricts = false;
//       });
//       print('Error loading districts: $e');
//     }
//   }
//
//   // Tải danh sách phường/xã dựa trên quận/huyện đã chọn
//   Future<void> _loadWards(int districtCode) async {
//     setState(() {
//       _isLoadingWards = true;
//       _wards = [];
//     });
//
//     try {
//       final wards = await _locationService.getWards(districtCode);
//       setState(() {
//         _wards = wards;
//         _isLoadingWards = false;
//       });
//     } catch (e) {
//       setState(() {
//         _isLoadingWards = false;
//       });
//       print('Error loading wards: $e');
//     }
//   }
//
//   // Tìm province code dựa trên tên
//   void _setSelectedProvinceByName(String provinceName) {
//     for (var province in _provinces) {
//       if (province['name'].toString().toLowerCase() == provinceName.toLowerCase()) {
//         setState(() {
//           _selectedProvinceCode = province['code'];
//         });
//         _loadDistricts(_selectedProvinceCode!);
//         break;
//       }
//     }
//   }
//
//   // Tìm district code dựa trên tên
//   void _setSelectedDistrictByName(String districtName) {
//     for (var district in _districts) {
//       if (district['name'].toString().toLowerCase() == districtName.toLowerCase()) {
//         setState(() {
//           _selectedDistrictCode = district['code'];
//         });
//         _loadWards(_selectedDistrictCode!);
//         break;
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Form(
//       key: widget.formKey,
//       autovalidateMode: AutovalidateMode.disabled,
//       child: SingleChildScrollView(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Header
//             const HeaderCard(
//               title: 'Thông tin địa điểm',
//               subtitle: 'Nhập thông tin chi tiết về vị trí phòng của bạn',
//               icon: Icons.location_on,
//             ),
//             const SizedBox(height: 24),
//
//             // Main location fields
//             _buildAnimatedContainer(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: _primaryColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(Icons.home, color: _primaryColor),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Địa chỉ chính',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: _primaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Address
//                   TextFormField(
//                     controller: widget.addressController,
//                     focusNode: widget.addressFocusNode,
//                     autovalidateMode: AutovalidateMode.disabled,
//                     decoration: InputDecoration(
//                       labelText: 'Địa chỉ',
//                       hintText: 'Ví dụ: 268 Lý Thường Kiệt',
//                       prefixIcon: Icon(Icons.home, color: _primaryColor),
//                       filled: true,
//                       fillColor: Colors.grey[50],
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: _primaryColor,
//                           width: 2,
//                         ),
//                       ),
//                       errorBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: Colors.red, width: 1),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                       floatingLabelStyle: TextStyle(color: _primaryColor),
//                     ),
//                     style: const TextStyle(fontSize: 16),
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Vui lòng nhập địa chỉ';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//
//                   // City dropdown
//                   DropdownButtonFormField<int>(
//                     autovalidateMode: AutovalidateMode.disabled,
//                     decoration: InputDecoration(
//                       labelText: 'Thành phố / Tỉnh',
//                       prefixIcon: Icon(Icons.location_city, color: _primaryColor),
//                       filled: true,
//                       fillColor: Colors.grey[50],
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: _primaryColor,
//                           width: 2,
//                         ),
//                       ),
//                       errorBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: Colors.red, width: 1),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                       floatingLabelStyle: TextStyle(color: _primaryColor),
//                       suffixIcon: _isLoadingProvinces
//                           ? Container(
//                               height: 16,
//                               width: 16,
//                               margin: const EdgeInsets.all(12),
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: _primaryColor,
//                               ),
//                             )
//                           : null,
//                     ),
//                     isExpanded: true,
//                     value: _selectedProvinceCode,
//                     hint: const Text('Chọn Thành phố / Tỉnh'),
//                     items: _provinces.map((province) {
//                       return DropdownMenuItem<int>(
//                         value: province['code'],
//                         child: Text(province['name']),
//                       );
//                     }).toList(),
//                     onChanged: (value) {
//                       if (value != null) {
//                         setState(() {
//                           _selectedProvinceCode = value;
//                           // Tìm tên tỉnh/thành phố và cập nhật controller
//                           final provinceName = _provinces.firstWhere(
//                             (p) => p['code'] == value,
//                             orElse: () => {'name': ''},
//                           )['name'];
//                           widget.cityController.text = provinceName.toString();
//                           // Reset district và ward
//                           widget.districtController.text = '';
//                           widget.wardController.text = '';
//                         });
//                         _loadDistricts(value);
//                       }
//                     },
//                     validator: (value) {
//                       if (value == null) {
//                         return 'Vui lòng chọn thành phố / tỉnh';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//
//                   // District - now in full column
//                   DropdownButtonFormField<int>(
//                     autovalidateMode: AutovalidateMode.disabled,
//                     decoration: InputDecoration(
//                       labelText: 'Quận / Huyện',
//                       prefixIcon: Icon(Icons.location_on, color: _primaryColor),
//                       filled: true,
//                       fillColor: Colors.grey[50],
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: _primaryColor,
//                           width: 2,
//                         ),
//                       ),
//                       errorBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: Colors.red, width: 1),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                       floatingLabelStyle: TextStyle(color: _primaryColor),
//                       suffixIcon: _isLoadingDistricts
//                           ? Container(
//                               height: 16,
//                               width: 16,
//                               margin: const EdgeInsets.all(12),
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: _primaryColor,
//                               ),
//                             )
//                           : null,
//                     ),
//                     isExpanded: true,
//                     value: _selectedDistrictCode,
//                     hint: const Text('Chọn Quận / Huyện'),
//                     items: _districts.map((district) {
//                       return DropdownMenuItem<int>(
//                         value: district['code'],
//                         child: Text(district['name']),
//                       );
//                     }).toList(),
//                     onChanged: _selectedProvinceCode == null
//                         ? null
//                         : (value) {
//                             if (value != null) {
//                               setState(() {
//                                 _selectedDistrictCode = value;
//                                 // Tìm tên quận/huyện và cập nhật controller
//                                 final districtName = _districts.firstWhere(
//                                   (d) => d['code'] == value,
//                                   orElse: () => {'name': ''},
//                                 )['name'];
//                                 widget.districtController.text = districtName.toString();
//                                 // Reset ward
//                                 widget.wardController.text = '';
//                               });
//                               _loadWards(value);
//                             }
//                           },
//                     validator: (value) {
//                       if (value == null) {
//                         return 'Vui lòng chọn quận / huyện';
//                       }
//                       return null;
//                     },
//                   ),
//                   const SizedBox(height: 20),
//
//                   // Ward - now in full column
//                   DropdownButtonFormField<String>(
//                     autovalidateMode: AutovalidateMode.disabled,
//                     decoration: InputDecoration(
//                       labelText: 'Phường / Xã',
//                       prefixIcon: Icon(Icons.location_on, color: _primaryColor),
//                       filled: true,
//                       fillColor: Colors.grey[50],
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: _primaryColor,
//                           width: 2,
//                         ),
//                       ),
//                       errorBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: const BorderSide(color: Colors.red, width: 1),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                       floatingLabelStyle: TextStyle(color: _primaryColor),
//                       suffixIcon: _isLoadingWards
//                           ? Container(
//                               height: 16,
//                               width: 16,
//                               margin: const EdgeInsets.all(12),
//                               child: CircularProgressIndicator(
//                                 strokeWidth: 2,
//                                 color: _primaryColor,
//                               ),
//                             )
//                           : null,
//                     ),
//                     isExpanded: true,
//                     value: widget.wardController.text.isEmpty ? null : widget.wardController.text,
//                     hint: const Text('Chọn Phường / Xã'),
//                     items: _wards.map((ward) {
//                       return DropdownMenuItem<String>(
//                         value: ward['name'],
//                         child: Text(ward['name']),
//                       );
//                     }).toList(),
//                     onChanged: _selectedDistrictCode == null
//                         ? null
//                         : (value) {
//                             if (value != null) {
//                               setState(() {
//                                 widget.wardController.text = value;
//                               });
//                             }
//                           },
//                     validator: (value) {
//                       if (value == null || value.isEmpty) {
//                         return 'Vui lòng chọn phường / xã';
//                       }
//                       return null;
//                     },
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // Advanced location fields (optional)
//             _buildAnimatedContainer(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: _primaryColor.withOpacity(0.1),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: Icon(Icons.map, color: _primaryColor),
//                       ),
//                       const SizedBox(width: 12),
//                       Text(
//                         'Thông tin bản đồ (tùy chọn)',
//                         style: TextStyle(
//                           fontSize: 16,
//                           fontWeight: FontWeight.bold,
//                           color: _primaryColor,
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Latitude and Longitude
//                   Row(
//                     children: [
//                       Expanded(
//                         child: TextFormField(
//                           controller: widget.latitudeController,
//                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                           autovalidateMode: AutovalidateMode.disabled,
//                           decoration: InputDecoration(
//                             labelText: 'Vĩ độ',
//                             hintText: 'Ví dụ: 10.7730',
//                             prefixIcon: Icon(Icons.north, color: _primaryColor),
//                             filled: true,
//                             fillColor: Colors.grey[50],
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: Colors.grey.shade300),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(
//                                 color: _primaryColor,
//                                 width: 2,
//                               ),
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                             floatingLabelStyle: TextStyle(color: _primaryColor),
//                           ),
//                           style: const TextStyle(fontSize: 16),
//                           validator: (value) {
//                             if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
//                               return 'Vui lòng nhập số hợp lệ';
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                       const SizedBox(width: 16),
//
//                       Expanded(
//                         child: TextFormField(
//                           controller: widget.longitudeController,
//                           keyboardType: const TextInputType.numberWithOptions(decimal: true),
//                           autovalidateMode: AutovalidateMode.disabled,
//                           decoration: InputDecoration(
//                             labelText: 'Kinh độ',
//                             hintText: 'Ví dụ: 106.6946',
//                             prefixIcon: Icon(Icons.east, color: _primaryColor),
//                             filled: true,
//                             fillColor: Colors.grey[50],
//                             enabledBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(color: Colors.grey.shade300),
//                             ),
//                             focusedBorder: OutlineInputBorder(
//                               borderRadius: BorderRadius.circular(12),
//                               borderSide: BorderSide(
//                                 color: _primaryColor,
//                                 width: 2,
//                               ),
//                             ),
//                             contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                             floatingLabelStyle: TextStyle(color: _primaryColor),
//                           ),
//                           style: const TextStyle(fontSize: 16),
//                           validator: (value) {
//                             if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
//                               return 'Vui lòng nhập số hợp lệ';
//                             }
//                             return null;
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                   const SizedBox(height: 16),
//
//                   // Nearby amenities
//                   TextFormField(
//                     controller: widget.nearbyAmenitiesController,
//                     maxLines: 3,
//                     autovalidateMode: AutovalidateMode.disabled,
//                     decoration: InputDecoration(
//                       labelText: 'Tiện ích xung quanh',
//                       hintText: 'Ví dụ: Gần trường học, siêu thị, công viên...',
//                       prefixIcon: Padding(
//                         padding: const EdgeInsets.only(bottom: 64),
//                         child: Icon(Icons.location_on, color: _primaryColor),
//                       ),
//                       filled: true,
//                       fillColor: Colors.grey[50],
//                       enabledBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(color: Colors.grey.shade300),
//                       ),
//                       focusedBorder: OutlineInputBorder(
//                         borderRadius: BorderRadius.circular(12),
//                         borderSide: BorderSide(
//                           color: _primaryColor,
//                           width: 2,
//                         ),
//                       ),
//                       contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                       floatingLabelStyle: TextStyle(color: _primaryColor),
//                       alignLabelWithHint: true,
//                     ),
//                     style: const TextStyle(fontSize: 16),
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(height: 20),
//             // Location tip
//             _buildAnimatedTipCard(
//               child: RoomTipCard(
//                 title: 'Mẹo hay về địa chỉ',
//                 content: '• Cung cấp địa chỉ chính xác để người thuê dễ dàng tìm thấy\n'
//                   '• Mô tả rõ các tiện ích xung quanh sẽ thu hút người thuê\n'
//                   '• Thông tin tọa độ giúp hiển thị chính xác vị trí trên bản đồ',
//                 icon: Icons.tips_and_updates,
//                 color: _primaryColor,
//               ),
//             ),
//
//             // Nút tự động lấy vị trí hiện tại
//             const SizedBox(height: 16),
//             _buildGetLocationButton(),
//           ],
//         ),
//       ),
//     );
//   }
//
//   // Nút lấy vị trí hiện tại
//   Widget _buildGetLocationButton() {
//     return Center(
//       child: ElevatedButton.icon(
//         onPressed: _getCurrentLocation,
//         icon: const Icon(Icons.my_location, color: Colors.white),
//         label: const Text('Lấy vị trí hiện tại',
//           style: TextStyle(color: Colors.white),
//         ),
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _primaryColor,
//           padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(12),
//           ),
//           elevation: 2,
//         ),
//       ),
//     );
//   }
//
//   // Lấy vị trí hiện tại
//   Future<void> _getCurrentLocation() async {
//     try {
//       final position = await _locationService.getCurrentPosition();
//       if (position != null) {
//         setState(() {
//           widget.latitudeController.text = position.latitude.toString();
//           widget.longitudeController.text = position.longitude.toString();
//         });
//
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: const Text('Đã cập nhật vị trí hiện tại'),
//             backgroundColor: _primaryColor,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       } else {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Không thể lấy vị trí hiện tại. Vui lòng đảm bảo bạn đã cấp quyền truy cập vị trí.'),
//             backgroundColor: Colors.red,
//             behavior: SnackBarBehavior.floating,
//           ),
//         );
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text('Lỗi: $e'),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     }
//   }
//
//   // Animated container wrapper
//   Widget _buildAnimatedContainer({required Widget child}) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       padding: const EdgeInsets.all(16),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.grey.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }
//
//   // Animated tip card
//   Widget _buildAnimatedTipCard({required Widget child}) {
//     return AnimatedContainer(
//       duration: const Duration(milliseconds: 200),
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(12),
//         boxShadow: [
//           BoxShadow(
//             color: _primaryColor.withOpacity(0.1),
//             spreadRadius: 1,
//             blurRadius: 6,
//             offset: const Offset(0, 3),
//           ),
//         ],
//       ),
//       child: child,
//     );
//   }
// }