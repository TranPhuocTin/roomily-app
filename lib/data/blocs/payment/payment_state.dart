import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/models.dart';

abstract class PaymentResponseState extends Equatable {
  const PaymentResponseState();

  @override
  List<Object?> get props => [];
}

class PaymentResponseInitial extends PaymentResponseState {}

class PaymentResponseLoading extends PaymentResponseState {}

class PaymentResponseSuccess extends PaymentResponseState {
  final PaymentResponse paymentResponse;

  const PaymentResponseSuccess(this.paymentResponse);

  @override
  List<Object?> get props => [paymentResponse];
}

class PaymentResponseFailure extends PaymentResponseState {
  final String error;

  const PaymentResponseFailure(this.error);

  @override
  List<Object?> get props => [error];
}