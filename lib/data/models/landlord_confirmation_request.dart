import 'package:json_annotation/json_annotation.dart';

part 'landlord_confirmation_request.g.dart';

@JsonSerializable()
class LandlordConfirmationRequest {
  final bool isElectricityChecked;
  final bool isWaterChecked;
  final String? landlordComment;

  LandlordConfirmationRequest({
    required this.isElectricityChecked,
    required this.isWaterChecked,
    this.landlordComment,
  });

  factory LandlordConfirmationRequest.fromJson(Map<String, dynamic> json) => 
      _$LandlordConfirmationRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$LandlordConfirmationRequestToJson(this);
} 