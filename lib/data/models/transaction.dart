// lib/data/models/transaction.dart
import 'package:json_annotation/json_annotation.dart';
import 'package:roomily/core/utils/transaction_type.dart';
part 'transaction.g.dart';

@JsonSerializable()
class Transaction {
  final String id;
  final String amount;
  final String status;

  @JsonKey(unknownEnumValue: TransactionType.DEPOSIT)
  final TransactionType type;

  @JsonKey(fromJson: _dateTimeFromString, toJson: _dateTimeToString)
  final DateTime createdAt;

  @JsonKey(fromJson: _dateTimeFromString, toJson: _dateTimeToString)
  final DateTime updatedAt;

  final String userId;
  final String userName;
  final String? checkoutResponseId;

  Transaction({
    required this.id,
    required this.amount,
    required this.status,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    required this.userName,
    this.checkoutResponseId,
  });

  factory Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  Map<String, dynamic> toJson() => _$TransactionToJson(this);

  static DateTime _dateTimeFromString(String date) => DateTime.parse(date);
  static String _dateTimeToString(DateTime date) => date.toIso8601String();
}