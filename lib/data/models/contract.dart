// import 'package:json_annotation/json_annotation.dart';

// part 'contract.g.dart';

// @JsonSerializable()
// class Contract {
//   final String? id;
//   final String? landlordName;
//   final String? landlordBirthDate;
//   final String? landlordAddress;
//   final String? landlordID;
//   final String? landlordIDDay;
//   final String? landlordIDMonth;
//   final String? landlordIDYear;
//   final String? landlordIDPlace;
//   final String? landlordPhone;
  
//   final String? tenantName;
//   final String? tenantBirthDate;
//   final String? tenantAddress;
//   final String? tenantID;
//   final String? tenantIDDay;
//   final String? tenantIDMonth;
//   final String? tenantIDYear;
//   final String? tenantIDPlace;
//   final String? tenantPhone;
  
//   final String? rentalAddress;
//   final String? rentalPrice;
//   final String? paymentMethod;
//   final String? electricityRate;
//   final String? waterRate;
//   final String? deposit;
  
//   final String? contractDay;
//   final String? contractMonth;
//   final String? contractYear;
//   final String? contractAddress;
  
//   final String? contractStartDay;
//   final String? contractStartMonth;
//   final String? contractStartYear;
//   final String? contractEndDay;
//   final String? contractEndMonth;
//   final String? contractEndYear;
  
//   final String? roomId;
//   final String? status;
//   final DateTime? createdAt;

//   Contract({
//     this.id,
//     this.landlordName,
//     this.landlordBirthDate,
//     this.landlordAddress,
//     this.landlordID,
//     this.landlordIDDay,
//     this.landlordIDMonth,
//     this.landlordIDYear,
//     this.landlordIDPlace,
//     this.landlordPhone,
//     this.tenantName,
//     this.tenantBirthDate,
//     this.tenantAddress,
//     this.tenantID,
//     this.tenantIDDay,
//     this.tenantIDMonth,
//     this.tenantIDYear,
//     this.tenantIDPlace,
//     this.tenantPhone,
//     this.rentalAddress,
//     this.rentalPrice,
//     this.paymentMethod,
//     this.electricityRate,
//     this.waterRate,
//     this.deposit,
//     this.contractDay,
//     this.contractMonth,
//     this.contractYear,
//     this.contractAddress,
//     this.contractStartDay,
//     this.contractStartMonth,
//     this.contractStartYear,
//     this.contractEndDay,
//     this.contractEndMonth,
//     this.contractEndYear,
//     this.roomId,
//     this.status,
//     this.createdAt,
//   });

//   factory Contract.fromJson(Map<String, dynamic> json) => _$ContractFromJson(json);
  
//   Map<String, dynamic> toJson() => _$ContractToJson(this);

//   Contract copyWith({
//     String? id,
//     String? landlordName,
//     String? landlordBirthDate,
//     String? landlordAddress,
//     String? landlordID,
//     String? landlordIDDay,
//     String? landlordIDMonth,
//     String? landlordIDYear,
//     String? landlordIDPlace,
//     String? landlordPhone,
//     String? tenantName,
//     String? tenantBirthDate,
//     String? tenantAddress,
//     String? tenantID,
//     String? tenantIDDay,
//     String? tenantIDMonth,
//     String? tenantIDYear,
//     String? tenantIDPlace,
//     String? tenantPhone,
//     String? rentalAddress,
//     String? rentalPrice,
//     String? paymentMethod,
//     String? electricityRate,
//     String? waterRate,
//     String? deposit,
//     String? contractDay,
//     String? contractMonth,
//     String? contractYear,
//     String? contractAddress,
//     String? contractStartDay,
//     String? contractStartMonth,
//     String? contractStartYear,
//     String? contractEndDay,
//     String? contractEndMonth,
//     String? contractEndYear,
//     String? roomId,
//     String? status,
//     DateTime? createdAt,
//   }) {
//     return Contract(
//       id: id ?? this.id,
//       landlordName: landlordName ?? this.landlordName,
//       landlordBirthDate: landlordBirthDate ?? this.landlordBirthDate,
//       landlordAddress: landlordAddress ?? this.landlordAddress,
//       landlordID: landlordID ?? this.landlordID,
//       landlordIDDay: landlordIDDay ?? this.landlordIDDay,
//       landlordIDMonth: landlordIDMonth ?? this.landlordIDMonth,
//       landlordIDYear: landlordIDYear ?? this.landlordIDYear,
//       landlordIDPlace: landlordIDPlace ?? this.landlordIDPlace,
//       landlordPhone: landlordPhone ?? this.landlordPhone,
//       tenantName: tenantName ?? this.tenantName,
//       tenantBirthDate: tenantBirthDate ?? this.tenantBirthDate,
//       tenantAddress: tenantAddress ?? this.tenantAddress,
//       tenantID: tenantID ?? this.tenantID,
//       tenantIDDay: tenantIDDay ?? this.tenantIDDay,
//       tenantIDMonth: tenantIDMonth ?? this.tenantIDMonth,
//       tenantIDYear: tenantIDYear ?? this.tenantIDYear,
//       tenantIDPlace: tenantIDPlace ?? this.tenantIDPlace,
//       tenantPhone: tenantPhone ?? this.tenantPhone,
//       rentalAddress: rentalAddress ?? this.rentalAddress,
//       rentalPrice: rentalPrice ?? this.rentalPrice,
//       paymentMethod: paymentMethod ?? this.paymentMethod,
//       electricityRate: electricityRate ?? this.electricityRate,
//       waterRate: waterRate ?? this.waterRate,
//       deposit: deposit ?? this.deposit,
//       contractDay: contractDay ?? this.contractDay,
//       contractMonth: contractMonth ?? this.contractMonth,
//       contractYear: contractYear ?? this.contractYear,
//       contractAddress: contractAddress ?? this.contractAddress,
//       contractStartDay: contractStartDay ?? this.contractStartDay,
//       contractStartMonth: contractStartMonth ?? this.contractStartMonth,
//       contractStartYear: contractStartYear ?? this.contractStartYear,
//       contractEndDay: contractEndDay ?? this.contractEndDay,
//       contractEndMonth: contractEndMonth ?? this.contractEndMonth,
//       contractEndYear: contractEndYear ?? this.contractEndYear,
//       roomId: roomId ?? this.roomId,
//       status: status ?? this.status,
//       createdAt: createdAt ?? this.createdAt,
//     );
//   }
  
//   // Convert the form data map from WebView to Contract object
//   factory Contract.fromFormData(Map<String, String> formData) {
//     return Contract(
//       landlordName: formData['landlordName'],
//       landlordBirthDate: formData['landlordBirthDate'],
//       landlordAddress: formData['landlordAddress'],
//       landlordID: formData['landlordID'],
//       landlordIDDay: formData['landlordIDDay'],
//       landlordIDMonth: formData['landlordIDMonth'],
//       landlordIDYear: formData['landlordIDYear'],
//       landlordIDPlace: formData['landlordIDPlace'],
//       landlordPhone: formData['landlordPhone'],
//       tenantName: formData['tenantName'],
//       tenantBirthDate: formData['tenantBirthDate'],
//       tenantAddress: formData['tenantAddress'],
//       tenantID: formData['tenantID'],
//       tenantIDDay: formData['tenantIDDay'],
//       tenantIDMonth: formData['tenantIDMonth'],
//       tenantIDYear: formData['tenantIDYear'],
//       tenantIDPlace: formData['tenantIDPlace'],
//       tenantPhone: formData['tenantPhone'],
//       rentalAddress: formData['rentalAddress'],
//       rentalPrice: formData['rentalPrice'],
//       paymentMethod: formData['paymentMethod'],
//       electricityRate: formData['electricityRate'],
//       waterRate: formData['waterRate'],
//       deposit: formData['deposit'],
//       contractDay: formData['contractDay'],
//       contractMonth: formData['contractMonth'],
//       contractYear: formData['contractYear'],
//       contractAddress: formData['contractAddress'],
//       contractStartDay: formData['contractStartDay'],
//       contractStartMonth: formData['contractStartMonth'],
//       contractStartYear: formData['contractStartYear'],
//       contractEndDay: formData['contractEndDay'],
//       contractEndMonth: formData['contractEndMonth'],
//       contractEndYear: formData['contractEndYear'],
//     );
//   }
  
//   // Convert Contract object to form data map for WebView
//   Map<String, String> toFormData() {
//     final Map<String, String> formData = {};
    
//     if (landlordName != null) formData['landlordName'] = landlordName!;
//     if (landlordBirthDate != null) formData['landlordBirthDate'] = landlordBirthDate!;
//     if (landlordAddress != null) formData['landlordAddress'] = landlordAddress!;
//     if (landlordID != null) formData['landlordID'] = landlordID!;
//     if (landlordIDDay != null) formData['landlordIDDay'] = landlordIDDay!;
//     if (landlordIDMonth != null) formData['landlordIDMonth'] = landlordIDMonth!;
//     if (landlordIDYear != null) formData['landlordIDYear'] = landlordIDYear!;
//     if (landlordIDPlace != null) formData['landlordIDPlace'] = landlordIDPlace!;
//     if (landlordPhone != null) formData['landlordPhone'] = landlordPhone!;
    
//     if (tenantName != null) formData['tenantName'] = tenantName!;
//     if (tenantBirthDate != null) formData['tenantBirthDate'] = tenantBirthDate!;
//     if (tenantAddress != null) formData['tenantAddress'] = tenantAddress!;
//     if (tenantID != null) formData['tenantID'] = tenantID!;
//     if (tenantIDDay != null) formData['tenantIDDay'] = tenantIDDay!;
//     if (tenantIDMonth != null) formData['tenantIDMonth'] = tenantIDMonth!;
//     if (tenantIDYear != null) formData['tenantIDYear'] = tenantIDYear!;
//     if (tenantIDPlace != null) formData['tenantIDPlace'] = tenantIDPlace!;
//     if (tenantPhone != null) formData['tenantPhone'] = tenantPhone!;
    
//     if (rentalAddress != null) formData['rentalAddress'] = rentalAddress!;
//     if (rentalPrice != null) formData['rentalPrice'] = rentalPrice!;
//     if (paymentMethod != null) formData['paymentMethod'] = paymentMethod!;
//     if (electricityRate != null) formData['electricityRate'] = electricityRate!;
//     if (waterRate != null) formData['waterRate'] = waterRate!;
//     if (deposit != null) formData['deposit'] = deposit!;
    
//     if (contractDay != null) formData['contractDay'] = contractDay!;
//     if (contractMonth != null) formData['contractMonth'] = contractMonth!;
//     if (contractYear != null) formData['contractYear'] = contractYear!;
//     if (contractAddress != null) formData['contractAddress'] = contractAddress!;
    
//     if (contractStartDay != null) formData['contractStartDay'] = contractStartDay!;
//     if (contractStartMonth != null) formData['contractStartMonth'] = contractStartMonth!;
//     if (contractStartYear != null) formData['contractStartYear'] = contractStartYear!;
//     if (contractEndDay != null) formData['contractEndDay'] = contractEndDay!;
//     if (contractEndMonth != null) formData['contractEndMonth'] = contractEndMonth!;
//     if (contractEndYear != null) formData['contractEndYear'] = contractEndYear!;
    
//     return formData;
//   }
// } 