import 'package:json_annotation/json_annotation.dart';
part 'withdraw_info_create.g.dart';

@JsonSerializable()
class WithdrawInfoCreate {
  final String bankName;
  final String accountNumber;
  final String accountName;

  WithdrawInfoCreate({
    required this.bankName,
    required this.accountNumber,
    required this.accountName,
  });

  factory WithdrawInfoCreate.fromJson(Map<String, dynamic> json) =>
      _$WithdrawInfoCreateFromJson(json);

  Map<String, dynamic> toJson() => _$WithdrawInfoCreateToJson(this);
}