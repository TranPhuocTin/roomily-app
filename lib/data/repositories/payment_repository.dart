import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/payment_request.dart';
import 'package:roomily/data/models/payment_response.dart';

abstract class PaymentRepository {
  // Create a new payment
  Future<Result<PaymentResponse>> createPayment(PaymentRequest request);
  
  // Get payment checkout information
  Future<Result<PaymentResponse>> getCheckout(String checkoutId);
} 