import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import 'package:roomily/data/repositories/contract_repository.dart';
import 'package:roomily/data/models/contract_responsibilities.dart';
import 'package:roomily/data/models/contract_modify_request.dart';
import 'package:roomily/data/models/landlord_contract_info.dart';
import 'package:roomily/data/models/tenant_contract_info.dart';

import 'contract_state.dart';

/// Cubit for managing contract-related state
class ContractCubit extends Cubit<ContractState> {
  final ContractRepository repository;

  /// Constructor for [ContractCubit]
  ContractCubit({required this.repository}) : super(const ContractInitial());

  /// Fetches the default contract HTML content for a specific room
  Future<void> getDefaultContract(String roomId) async {
    try {
      emit(const ContractLoading());
      
      final htmlContent = await repository.getDefaultContract(roomId);
      
      emit(ContractLoaded(htmlContent));
    } catch (e) {
      debugPrint('Error in ContractCubit.getDefaultContract: $e');
      emit(ContractError(e.toString()));
    }
  }
  
  /// Fetches the contract HTML content for a specific rented room
  Future<void> getContractByRentedRoom(String rentedRoomId) async {
    try {
      emit(const ContractLoading());
      
      final htmlContent = await repository.getContractByRentedRoom(rentedRoomId);
      
      emit(ContractLoaded(htmlContent));
    } catch (e) {
      debugPrint('Error in ContractCubit.getContractByRentedRoom: $e');
      emit(ContractError(e.toString()));
    }
  }
  
  /// Download contract as PDF for a specific room
  Future<Uint8List?> downloadContractPdf(String roomId) async {
    try {
      emit(const ContractLoading());
      
      final pdfBytes = await repository.downloadContractPdf(roomId);
      
      emit(const ContractInitial());
      return pdfBytes;
    } catch (e) {
      debugPrint('Error in ContractCubit.downloadContractPdf: $e');
      emit(ContractError(e.toString()));
      return null;
    }
  }
  
  /// Download contract as PDF for a specific rented room
  Future<Uint8List?> downloadRentedRoomContractPdf(String rentedRoomId) async {
    try {
      emit(const ContractLoading());
      
      final pdfBytes = await repository.downloadRentedRoomContractPdf(rentedRoomId);
      
      emit(const ContractInitial());
      return pdfBytes;
    } catch (e) {
      debugPrint('Error in ContractCubit.downloadRentedRoomContractPdf: $e');
      emit(ContractError(e.toString()));
      return null;
    }
  }
  
  /// Get contract responsibilities for a specific room
  Future<ContractResponsibilities?> getContractResponsibilities(String roomId) async {
    try {
      emit(const ContractLoading());
      
      final responsibilities = await repository.getContractResponsibilities(roomId);
      
      emit(const ContractInitial());
      return responsibilities;
    } catch (e) {
      debugPrint('Error in ContractCubit.getContractResponsibilities: $e');
      emit(ContractError(e.toString()));
      return null;
    }
  }
  
  /// Modify contract responsibilities
  Future<bool> modifyContract(ContractModifyRequest request) async {
    try {
      emit(const ContractLoading());
      
      final success = await repository.modifyContract(request);
      
      emit(const ContractInitial());
      return success;
    } catch (e) {
      debugPrint('Error in ContractCubit.modifyContract: $e');
      emit(ContractError(e.toString()));
      return false;
    }
  }
  
  /// Get landlord information for contract
  Future<LandlordContractInfo?> getLandlordInfo() async {
    try {
      emit(const ContractLoading());

      final landlordInfo = await repository.getLandLordInfo();

      emit(const ContractInitial());
      return landlordInfo;
    } catch (e) {
      debugPrint('Error in ContractCubit.getLandlordInfo: $e');
      emit(ContractError(e.toString()));
      return null;
    }
  }

  /// Update landlord information for contract
  Future<bool> updateLandlordInfo(LandlordContractInfo info) async {
    try {
      emit(const ContractLoading());

      final success = await repository.updateLandlordInfo(info);

      emit(const ContractInitial());
      return success;
    } catch (e) {
      debugPrint('Error in ContractCubit.updateLandlordInfo: $e');
      emit(ContractError(e.toString()));
      return false;
    }
  }

  /// Get tenant information for contract
  Future<TenantContractInfo?> getTenantInfo(String roomId) async {
    try {
      emit(const ContractLoading());

      final tenantInfo = await repository.getTenantInfo(roomId);

      emit(const ContractInitial());
      return tenantInfo;
    } catch (e) {
      debugPrint('Error in ContractCubit.getTenantInfo: $e');
      emit(ContractError(e.toString()));
      return null;
    }
  }

  /// Update tenant information for contract
  Future<bool> updateTenantInfo(TenantContractInfo info) async {
    try {
      emit(const ContractLoading());

      final success = await repository.updateTenantInfo(info);

      emit(const ContractInitial());
      return success;
    } catch (e) {
      debugPrint('Error in ContractCubit.updateTenantInfo: $e');
      emit(ContractError(e.toString()));
      return false;
    }
  }
} 