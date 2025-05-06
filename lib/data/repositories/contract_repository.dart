import 'dart:typed_data';
import 'package:roomily/data/models/contract.dart';
import 'package:roomily/data/models/contract_responsibilities.dart';
import 'package:roomily/data/models/contract_modify_request.dart';
import 'dart:async';

import '../models/landlord_contract_info.dart';
import '../models/tenant_contract_info.dart';

/// Contract repository responsible for handling contract-related API calls
abstract class ContractRepository {
  /// Get default contract HTML content for a specific room
  /// Returns the HTML content of the contract as a string
  Future<String> getDefaultContract(String roomId);
  
  /// Get contract HTML content for a specific rented room
  /// Returns the HTML content of the contract as a string
  Future<String> getContractByRentedRoom(String rentedRoomId);
  
  /// Download contract as PDF for a specific room
  /// Returns the PDF as Uint8List (bytes)
  Future<Uint8List> downloadContractPdf(String roomId);
  
  /// Download contract as PDF for a specific rented room
  /// Returns the PDF as Uint8List (bytes)
  Future<Uint8List> downloadRentedRoomContractPdf(String rentedRoomId);
  
  /// Get contract responsibilities for a specific room
  Future<ContractResponsibilities> getContractResponsibilities(String roomId);
  
  /// Modify contract responsibilities
  Future<bool> modifyContract(ContractModifyRequest request);

  /// Get landlord information for contract
  Future<LandlordContractInfo> getLandLordInfo();

  /// Update landlord information for contract
  Future<bool> updateLandlordInfo(LandlordContractInfo info);
  
  /// Get tenant information for contract
  Future<TenantContractInfo?> getTenantInfo(String roomId);
  
  /// Update tenant information for contract
  Future<bool> updateTenantInfo(TenantContractInfo info);
} 