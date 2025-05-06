import 'package:json_annotation/json_annotation.dart';

part 'payment_response.g.dart';

@JsonSerializable()
class PaymentResponse {
  final String? id;
  final String? paymentLinkId;
  final String accountNumber;
  final String accountName;
  final int amount;
  final String description;
  final String checkoutUrl;
  final String qrCode;
  final int orderCode;
  final String status;
  final String? createdAt;
  @JsonKey(name: 'expiresAt')
  final String? expireAt;

  PaymentResponse({
    this.id,
    this.paymentLinkId,
    required this.accountNumber,
    required this.accountName,
    required this.amount,
    required this.description,
    required this.checkoutUrl,
    required this.qrCode,
    required this.orderCode,
    required this.status,
    this.createdAt,
    this.expireAt,
  });

  factory PaymentResponse.fromJson(Map<String, dynamic> json) =>
      _$PaymentResponseFromJson(json);

  Map<String, dynamic> toJson() => _$PaymentResponseToJson(this);
}
