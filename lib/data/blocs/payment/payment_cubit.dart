import 'package:bloc/bloc.dart';
import 'package:roomily/data/blocs/payment/payment_state.dart';
import 'package:roomily/data/repositories/payment_repository.dart';

import '../../models/payment_request.dart';

class PaymentCubit extends Cubit<PaymentResponseState> {
  final PaymentRepository _paymentRepository;

  PaymentCubit({required PaymentRepository paymentRepository})
      : _paymentRepository = paymentRepository,
        super(PaymentResponseInitial());

  Future<void> createPayment({required PaymentRequest paymentRequest}) async {
    emit(PaymentResponseLoading());

    final result = await _paymentRepository.createPayment(paymentRequest);

    result.when(
      success: (paymentResponse) {
        print('Received PaymentResponse: ${paymentResponse.toJson()}');
        emit(PaymentResponseSuccess(paymentResponse));
      },
      failure: (error) => emit(PaymentResponseFailure(error)),
    );
  }

  Future<void> getCheckout({required String checkoutId}) async {
    emit(PaymentResponseLoading());

    final result = await _paymentRepository.getCheckout(checkoutId);

    result.when(
      success: (paymentResponse) {
        print('Received Checkout Info: ${paymentResponse.toJson()}');
        emit(PaymentResponseSuccess(paymentResponse));
      },
      failure: (error) => emit(PaymentResponseFailure(error)),
    );
  }
  
  // Phương thức để khôi phục trạng thái ban đầu
  void resetState() {
    emit(PaymentResponseInitial());
  }
}