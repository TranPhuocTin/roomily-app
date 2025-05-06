import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/blocs/budget_plan/budget_plan_state.dart';
import 'package:roomily/data/models/budget_plan_preference.dart';
import 'package:roomily/data/models/budget_plan_room.dart';
import 'package:roomily/data/models/budget_plan_room_detail.dart';
import 'package:roomily/data/repositories/budget_plan_repository.dart';

class BudgetPlanCubit extends Cubit<BudgetPlanState> {
  final BudgetPlanRepository _budgetPlanRepository;

  BudgetPlanCubit({
    required BudgetPlanRepository budgetPlanRepository,
  }) : _budgetPlanRepository = budgetPlanRepository,
       super(const BudgetPlanState());

  /// Saves the user's budget plan preferences
  Future<void> saveBudgetPlanPreference(BudgetPlanPreference preference) async {
    try {
      emit(state.copyWith(status: BudgetPlanStatus.loading));
      
      final success = await _budgetPlanRepository.saveBudgetPlanPreference(preference);
      
      if (success) {
        emit(state.copyWith(
          status: BudgetPlanStatus.success,
          preference: preference,
        ));
      } else {
        emit(state.copyWith(
          status: BudgetPlanStatus.failure,
          errorMessage: 'Failed to save budget plan preferences',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        status: BudgetPlanStatus.failure,
        errorMessage: 'An unexpected error occurred: $e',
      ));
    }
  }
  
  /// Fetches rooms that match the user's budget criteria
  Future<void> fetchSearchedRooms() async {
    try {
      emit(state.copyWith(isLoadingRooms: true));

      debugPrint('Fetching rooms...');
      
      final rooms = await _budgetPlanRepository.getSearchedRooms();
      debugPrint('Fetched rooms: ${rooms.length}');
      
      emit(state.copyWith(
        searchedRooms: rooms,
        isLoadingRooms: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingRooms: false,
        errorMessage: 'Failed to fetch rooms: $e',
      ));
    }
  }

  /// Fetches detailed budget plan information for a specific room
  Future<void> fetchRoomBudgetPlanDetail(String roomId, int? scope) async {
    try {
      emit(state.copyWith(isLoadingRoomDetail: true));
      
      final roomDetail = await _budgetPlanRepository.getRoomBudgetPlanDetail(roomId, scope ?? 1);
      
      emit(state.copyWith(
        roomBudgetPlanDetail: roomDetail,
        isLoadingRoomDetail: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        isLoadingRoomDetail: false,
        errorMessage: 'Failed to fetch room budget plan details: $e',
      ));
    }
  }
  
  /// Extracts budget plan preferences from a natural language prompt
  Future<void> extractUserPrompt(String prompt) async {
    try {
      emit(state.copyWith(
        status: BudgetPlanStatus.loading,
        errorMessage: null,
      ));
      
      final preference = await _budgetPlanRepository.extractUserPrompt(prompt);
      
      emit(state.copyWith(
        status: BudgetPlanStatus.success,
        preference: preference,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: BudgetPlanStatus.failure,
        errorMessage: 'Failed to extract preferences: $e',
      ));
    }
  }
} 