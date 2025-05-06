import 'package:json_annotation/json_annotation.dart';

part 'tenant_contract_info.g.dart';

@JsonSerializable()
class TenantContractInfo {
  final String rentedRoomId;
  final String tenantFullName;
  final String tenantDateOfBirth;
  final String tenantPermanentResidence;
  final String tenantIdentityNumber;
  final String tenantIdentityProvidedDate;
  final String tenantIdentityProvidedPlace;
  final String tenantPhoneNumber;

  TenantContractInfo({
    required this.rentedRoomId,
    required this.tenantFullName,
    required this.tenantDateOfBirth,
    required this.tenantPermanentResidence,
    required this.tenantIdentityNumber,
    required this.tenantIdentityProvidedDate,
    required this.tenantIdentityProvidedPlace,
    required this.tenantPhoneNumber,
  });

  factory TenantContractInfo.fromJson(Map<String, dynamic> json) => 
      _$TenantContractInfoFromJson(json);
  
  Map<String, dynamic> toJson() => _$TenantContractInfoToJson(this);

  TenantContractInfo copyWith({
    String? rentedRoomId,
    String? tenantFullName,
    String? tenantDateOfBirth,
    String? tenantPermanentResidence,
    String? tenantIdentityNumber,
    String? tenantIdentityProvidedDate,
    String? tenantIdentityProvidedPlace,
    String? tenantPhoneNumber,
  }) {
    return TenantContractInfo(
      rentedRoomId: rentedRoomId ?? this.rentedRoomId,
      tenantFullName: tenantFullName ?? this.tenantFullName,
      tenantDateOfBirth: tenantDateOfBirth ?? this.tenantDateOfBirth,
      tenantPermanentResidence: tenantPermanentResidence ?? this.tenantPermanentResidence,
      tenantIdentityNumber: tenantIdentityNumber ?? this.tenantIdentityNumber,
      tenantIdentityProvidedDate: tenantIdentityProvidedDate ?? this.tenantIdentityProvidedDate,
      tenantIdentityProvidedPlace: tenantIdentityProvidedPlace ?? this.tenantIdentityProvidedPlace,
      tenantPhoneNumber: tenantPhoneNumber ?? this.tenantPhoneNumber,
    );
  }
} 