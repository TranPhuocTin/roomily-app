import 'package:json_annotation/json_annotation.dart';
part 'withdraw_info.g.dart';

@JsonSerializable()
class WithdrawInfo {
  final String id;
  final String bankName;
  final String accountNumber;
  final String accountName;
  final String? lastWithdrawDate;
  final String userId;

  WithdrawInfo({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
    this.lastWithdrawDate,
    required this.userId,
  });

  factory WithdrawInfo.fromJson(Map<String, dynamic> json) => _$WithdrawInfoFromJson(json);
  Map<String, dynamic> toJson() => _$WithdrawInfoToJson(this);
}