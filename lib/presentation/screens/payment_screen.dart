import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/models/payment_request.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';

import '../../data/blocs/payment/payment_cubit.dart';
import '../../data/blocs/payment/payment_state.dart';
import '../../data/repositories/payment_repository_impl.dart';
import 'payment_input_screen.dart';

class PaymentScreen extends StatelessWidget {
  final String? rentedRoomId;
  final bool inAppWallet;
  final bool isLandlordDashboard;
  
  const PaymentScreen({
    Key? key, 
    this.rentedRoomId,
    this.inAppWallet = false,
    this.isLandlordDashboard = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => PaymentCubit(
        paymentRepository: PaymentRepositoryImpl(),
      ),
      child: PaymentInputScreen(
        rentedRoomId: rentedRoomId,
        inAppWallet: inAppWallet,
        isLandlordDashboard: isLandlordDashboard,
      ),
    );
  }
}
