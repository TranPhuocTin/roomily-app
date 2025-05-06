import 'package:json_annotation/json_annotation.dart';
import 'dart:io';

part 'utility_reading_request.g.dart';

@JsonSerializable()
class UtilityReadingRequest {
  final int electricity;
  final int water;
  
  @JsonKey(ignore: true)
  final File? electricityImage;
  
  @JsonKey(ignore: true)
  final File? waterImage;
  
  final String? electricityImageUrl;
  final String? waterImageUrl;

  UtilityReadingRequest({
    required this.electricity,
    required this.water,
    this.electricityImage,
    this.waterImage,
    this.electricityImageUrl,
    this.waterImageUrl,
  });

  factory UtilityReadingRequest.fromJson(Map<String, dynamic> json) => 
      _$UtilityReadingRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$UtilityReadingRequestToJson(this);
}