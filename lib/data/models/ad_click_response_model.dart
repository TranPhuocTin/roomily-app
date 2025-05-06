import 'package:json_annotation/json_annotation.dart';

part 'ad_click_response_model.g.dart';

@JsonSerializable()
class AdClickResponseModel {
  final String adClickId;
  final String status;

  AdClickResponseModel({
    required this.adClickId,
    required this.status,
  });

  factory AdClickResponseModel.fromJson(Map<String, dynamic> json) => 
      _$AdClickResponseModelFromJson(json);

  Map<String, dynamic> toJson() => _$AdClickResponseModelToJson(this);
} 