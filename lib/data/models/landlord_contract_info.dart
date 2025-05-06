import 'package:json_annotation/json_annotation.dart';

part 'landlord_contract_info.g.dart';

@JsonSerializable()
class LandlordContractInfo {
  final String landlordFullName;
  final String landlordDateOfBirth;
  final String landlordPermanentResidence;
  final String landlordIdentityNumber;
  final String landlordIdentityProvidedDate;
  final String landlordIdentityProvidedPlace;
  final String landlordPhoneNumber;

  LandlordContractInfo({
    required this.landlordFullName,
    required this.landlordDateOfBirth,
    required this.landlordPermanentResidence,
    required this.landlordIdentityNumber,
    required this.landlordIdentityProvidedDate,
    required this.landlordIdentityProvidedPlace,
    required this.landlordPhoneNumber,
  });

  factory LandlordContractInfo.fromJson(Map<String, dynamic> json) => 
      _$LandlordContractInfoFromJson(json);
  
  Map<String, dynamic> toJson() => _$LandlordContractInfoToJson(this);

  LandlordContractInfo copyWith({
    String? landlordFullName,
    String? landlordDateOfBirth,
    String? landlordPermanentResidence,
    String? landlordIdentityNumber,
    String? landlordIdentityProvidedDate,
    String? landlordIdentityProvidedPlace,
    String? landlordPhoneNumber,
  }) {
    return LandlordContractInfo(
      landlordFullName: landlordFullName ?? this.landlordFullName,
      landlordDateOfBirth: landlordDateOfBirth ?? this.landlordDateOfBirth,
      landlordPermanentResidence: landlordPermanentResidence ?? this.landlordPermanentResidence,
      landlordIdentityNumber: landlordIdentityNumber ?? this.landlordIdentityNumber,
      landlordIdentityProvidedDate: landlordIdentityProvidedDate ?? this.landlordIdentityProvidedDate,
      landlordIdentityProvidedPlace: landlordIdentityProvidedPlace ?? this.landlordIdentityProvidedPlace,
      landlordPhoneNumber: landlordPhoneNumber ?? this.landlordPhoneNumber,
    );
  }
} 