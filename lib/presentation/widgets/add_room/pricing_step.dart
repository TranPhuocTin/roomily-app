// import 'package:flutter/material.dart';
// import 'package:roomily/presentation/screens/add_room_screen.dart';
// import 'package:roomily/presentation/widgets/add_room/header_card.dart';
// import 'package:roomily/presentation/widgets/add_room/room_tip_card.dart';
//
// class PricingStep extends StatelessWidget {
//   final TextEditingController priceController;
//   final TextEditingController depositController;
//   final TextEditingController electricPriceController;
//   final TextEditingController waterPriceController;
//   final GlobalKey<FormState> formKey;
//   final FocusNode? priceFocusNode;
//
//   const PricingStep({
//     Key? key,
//     required this.priceController,
//     required this.depositController,
//     required this.electricPriceController,
//     required this.waterPriceController,
//     required this.formKey,
//     this.priceFocusNode,
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
//               title: 'Thông tin giá cả',
//               subtitle: 'Nhập các chi phí liên quan đến phòng của bạn',
//               icon: Icons.attach_money,
//               stepIndex: 2, // Pricing là step thứ 3 (index 2)
//             ),
//             const SizedBox(height: 24),
//
//             // Room price
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: RoomColors.pricing.withOpacity(0.3),
//                     spreadRadius: 1,
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TextFormField(
//                 controller: priceController,
//                 focusNode: priceFocusNode,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Giá thuê phòng',
//                   hintText: 'Ví dụ: 3000000',
//                   suffixText: 'VND',
//                   prefixIcon: Icon(Icons.price_check, color: RoomColors.pricing),
//                   filled: true,
//                   fillColor: RoomColors.pricing.withOpacity(0.05),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: RoomColors.pricing.withOpacity(0.3)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: RoomColors.pricing,
//                       width: 2,
//                     ),
//                   ),
//                   errorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: Colors.red, width: 1),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   floatingLabelStyle: TextStyle(color: RoomColors.pricing),
//                 ),
//                 style: TextStyle(fontSize: 16, color: RoomColors.formText),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Vui lòng nhập giá phòng';
//                   }
//                   if (double.tryParse(value) == null) {
//                     return 'Vui lòng nhập số hợp lệ';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // Deposit
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: RoomColors.deposit.withOpacity(0.3),
//                     spreadRadius: 1,
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TextFormField(
//                 controller: depositController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Tiền đặt cọc',
//                   hintText: 'Ví dụ: 3000000',
//                   suffixText: 'VND',
//                   prefixIcon: Icon(Icons.account_balance_wallet, color: RoomColors.deposit),
//                   filled: true,
//                   fillColor: RoomColors.deposit.withOpacity(0.05),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: RoomColors.deposit.withOpacity(0.3)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: RoomColors.deposit,
//                       width: 2,
//                     ),
//                   ),
//                   errorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: Colors.red, width: 1),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   floatingLabelStyle: TextStyle(color: RoomColors.deposit),
//                 ),
//                 style: TextStyle(fontSize: 16, color: RoomColors.formText),
//                 validator: (value) {
//                   if (value != null && value.isNotEmpty && double.tryParse(value) == null) {
//                     return 'Vui lòng nhập số hợp lệ';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // Electric Price
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: RoomColors.electricity.withOpacity(0.3),
//                     spreadRadius: 1,
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TextFormField(
//                 controller: electricPriceController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Giá điện',
//                   hintText: 'Ví dụ: 3500',
//                   suffixText: 'VND/kWh',
//                   prefixIcon: Icon(Icons.bolt, color: RoomColors.electricity),
//                   filled: true,
//                   fillColor: RoomColors.electricity.withOpacity(0.05),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: RoomColors.electricity.withOpacity(0.3)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: RoomColors.electricity,
//                       width: 2,
//                     ),
//                   ),
//                   errorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: Colors.red, width: 1),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   floatingLabelStyle: TextStyle(color: RoomColors.electricity),
//                 ),
//                 style: TextStyle(fontSize: 16, color: RoomColors.formText),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Vui lòng nhập giá điện';
//                   }
//                   if (double.tryParse(value) == null) {
//                     return 'Vui lòng nhập số hợp lệ';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             const SizedBox(height: 20),
//
//             // Water Price
//             Container(
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 borderRadius: BorderRadius.circular(12),
//                 boxShadow: [
//                   BoxShadow(
//                     color: RoomColors.water.withOpacity(0.3),
//                     spreadRadius: 1,
//                     blurRadius: 4,
//                     offset: const Offset(0, 2),
//                   ),
//                 ],
//               ),
//               child: TextFormField(
//                 controller: waterPriceController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   labelText: 'Giá nước',
//                   hintText: 'Ví dụ: 20000',
//                   suffixText: 'VND/m³',
//                   prefixIcon: Icon(Icons.water_drop, color: RoomColors.water),
//                   filled: true,
//                   fillColor: RoomColors.water.withOpacity(0.05),
//                   enabledBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(color: RoomColors.water.withOpacity(0.3)),
//                   ),
//                   focusedBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: BorderSide(
//                       color: RoomColors.water,
//                       width: 2,
//                     ),
//                   ),
//                   errorBorder: OutlineInputBorder(
//                     borderRadius: BorderRadius.circular(12),
//                     borderSide: const BorderSide(color: Colors.red, width: 1),
//                   ),
//                   contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
//                   floatingLabelStyle: TextStyle(color: RoomColors.water),
//                 ),
//                 style: TextStyle(fontSize: 16, color: RoomColors.formText),
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Vui lòng nhập giá nước';
//                   }
//                   if (double.tryParse(value) == null) {
//                     return 'Vui lòng nhập số hợp lệ';
//                   }
//                   return null;
//                 },
//               ),
//             ),
//             const SizedBox(height: 24),
//
//             // Tips for pricing
//             RoomTipCard(
//               title: 'Mẹo đặt giá hợp lý',
//               content: 'Kiểm tra giá các phòng tương tự trong khu vực để có mức giá cạnh tranh. Đảm bảo giá bạn đề xuất phù hợp với tiện nghi được cung cấp.',
//               icon: Icons.lightbulb,
//               color: RoomColors.pricing,
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }