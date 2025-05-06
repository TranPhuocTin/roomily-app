import 'package:json_annotation/json_annotation.dart';

part 'contract_modify_request.g.dart';

@JsonSerializable()
class ContractModifyRequest {
  final String roomId;
  final String contractDate;
  final String contractAddress;
  final String rentalAddress;
  final int deposit;
  final List<String> responsibilitiesA;
  final List<String> responsibilitiesB;
  final List<String> commonResponsibilities;

  ContractModifyRequest({
    required this.roomId,
    required this.contractDate,
    required this.contractAddress,
    required this.rentalAddress,
    required this.deposit,
    required this.responsibilitiesA,
    required this.responsibilitiesB,
    required this.commonResponsibilities,
  });

  factory ContractModifyRequest.fromJson(Map<String, dynamic> json) => 
      _$ContractModifyRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$ContractModifyRequestToJson(this);
} 