import 'package:json_annotation/json_annotation.dart';

part 'contract_responsibilities.g.dart';

@JsonSerializable()
class ContractResponsibilities {
  final List<String> responsibilitiesA;
  final List<String> responsibilitiesB;
  final List<String> commonResponsibilities;

  ContractResponsibilities({
    required this.responsibilitiesA,
    required this.responsibilitiesB,
    required this.commonResponsibilities,
  });

  factory ContractResponsibilities.fromJson(Map<String, dynamic> json) => 
      _$ContractResponsibilitiesFromJson(json);
  
  Map<String, dynamic> toJson() => _$ContractResponsibilitiesToJson(this);

  ContractResponsibilities copyWith({
    List<String>? responsibilitiesA,
    List<String>? responsibilitiesB,
    List<String>? commonResponsibilities,
  }) {
    return ContractResponsibilities(
      responsibilitiesA: responsibilitiesA ?? this.responsibilitiesA,
      responsibilitiesB: responsibilitiesB ?? this.responsibilitiesB,
      commonResponsibilities: commonResponsibilities ?? this.commonResponsibilities,
    );
  }
} 