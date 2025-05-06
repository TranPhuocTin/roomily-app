import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/data/models/landlord_contract_info.dart';
import 'package:roomily/data/repositories/contract_repository.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/data/models/contract_responsibilities.dart';
import 'package:roomily/data/models/contract_modify_request.dart';
import 'package:roomily/data/models/tenant_contract_info.dart';

/// Implementation of [ContractRepository]
class ContractRepositoryImpl implements ContractRepository {
  final Dio dio;

  /// Constructor for [ContractRepositoryImpl]
  ContractRepositoryImpl({Dio? dio})
      : dio = dio ?? DioConfig.createDio();

  @override
  Future<String> getDefaultContract(String roomId) async {
    try {
      final response = await dio.get(
        ApiConstants.getDefaultContract(roomId),
        options: Options(
          headers: {
            'Accept': 'text/html',
          },
          responseType: ResponseType.plain,
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as String;
      } else {
        throw Exception('Failed to fetch contract: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching contract: $e');
      throw Exception('Failed to fetch contract: $e');
    }
  }
  
  @override
  Future<String> getContractByRentedRoom(String rentedRoomId) async {
    try {
      final response = await dio.get(
        ApiConstants.getContractByRentedRoom(rentedRoomId),
        options: Options(
          headers: {
            'Accept': 'text/html',
          },
          responseType: ResponseType.plain,
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as String;
      } else {
        throw Exception('Failed to fetch rented room contract: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching rented room contract: $e');
      throw Exception('Failed to fetch rented room contract: $e');
    }
  }
  
  @override
  Future<Uint8List> downloadContractPdf(String roomId) async {
    try {
      final response = await dio.get(
        ApiConstants.downloadContractPdf(roomId),
        options: Options(
          headers: {
            'Accept': 'application/pdf',
          },
          responseType: ResponseType.bytes,
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Uint8List;
      } else {
        throw Exception('Failed to download PDF: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading PDF contract: $e');
      throw Exception('Failed to download PDF contract: $e');
    }
  }
  
  @override
  Future<Uint8List> downloadRentedRoomContractPdf(String rentedRoomId) async {
    try {
      final response = await dio.get(
        ApiConstants.downloadRentedRoomContractPdf(rentedRoomId),
        options: Options(
          headers: {
            'Accept': 'application/pdf',
          },
          responseType: ResponseType.bytes,
        ),
      );
      
      if (response.statusCode == 200) {
        return response.data as Uint8List;
      } else {
        throw Exception('Failed to download rented room PDF: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error downloading rented room PDF contract: $e');
      throw Exception('Failed to download rented room PDF contract: $e');
    }
  }
  
  @override
  Future<ContractResponsibilities> getContractResponsibilities(String roomId) async {
    try {
      final response = await dio.get(
        ApiConstants.getContractResponsibilities(roomId),
      );
      
      if (response.statusCode == 200) {
        return ContractResponsibilities.fromJson(response.data);
      } else {
        throw Exception('Failed to fetch contract responsibilities: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error fetching contract responsibilities: $e');
      throw Exception('Failed to fetch contract responsibilities: $e');
    }
  }
  
  @override
  Future<bool> modifyContract(ContractModifyRequest request) async {
    try {
      final response = await dio.put(
        ApiConstants.modifyContract(),
        data: request.toJson(),
      );
      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        throw Exception('Failed to modify contract: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error modifying contract: $e');
      throw Exception('Failed to modify contract: $e');
    }
  }

  @override
    Future<LandlordContractInfo> getLandLordInfo() async {
    try {
      final response = await dio.get(
        ApiConstants.getLandlordInfo(),
      );
      debugPrint('Landlord info: ${response.data}');
      return LandlordContractInfo.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching landlord info: $e');
      throw Exception('Failed to fetch landlord info: $e');
    }
  }

  @override
  Future<bool> updateLandlordInfo(LandlordContractInfo info) async {
    try {
      final response = await dio.put(
        ApiConstants.updateLandlordInfo(),
        data: info.toJson(),
      );
      debugPrint('Landlord info updated: ${response.data}');
      debugPrint('Landlord updated status code: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    }catch(e) {
      debugPrint('Error updating landlord info: $e');
      throw Exception('Failed to update landlord info: $e');
    }
  }

  @override
  Future<TenantContractInfo?> getTenantInfo(String roomId) async {
    try {
      final response = await dio.get(
        ApiConstants.getTenantInfo(roomId),
      );
      debugPrint('Tenant info: ${response.data}');
      return TenantContractInfo.fromJson(response.data);
    } catch (e) {
      debugPrint('Error fetching tenant info: $e');
      // Return null instead of throwing to handle case where tenant info doesn't exist yet
      return null;
    }
  }

  @override
  Future<bool> updateTenantInfo(TenantContractInfo info) async {
    try {
      final response = await dio.put(
        ApiConstants.updateTenantInfo(),
        data: info.toJson(),
      );
      debugPrint('Tenant info updated: ${response.data}');
      debugPrint('Tenant updated status code: ${response.statusCode}');
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
      debugPrint('Error updating tenant info: $e');
      throw Exception('Failed to update tenant info: $e');
    }
  }
} 