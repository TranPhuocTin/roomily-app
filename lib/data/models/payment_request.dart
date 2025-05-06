import 'package:json_annotation/json_annotation.dart';

part 'payment_request.g.dart';

@JsonSerializable()
class PaymentRequest {
  final String productName;
  final String description;
  final String rentedRoomId;
  final int amount;
  final bool inAppWallet;

  PaymentRequest({
    required this.productName,
    required this.description,
    required this.rentedRoomId,
    required this.amount,
    required this.inAppWallet,
  });

  factory PaymentRequest.fromJson(Map<String, dynamic> json) => 
      _$PaymentRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$PaymentRequestToJson(this);
}