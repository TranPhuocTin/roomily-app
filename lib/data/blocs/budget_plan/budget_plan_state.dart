import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/budget_plan_preference.dart';
import 'package:roomily/data/models/budget_plan_room.dart';
import 'package:roomily/data/models/budget_plan_room_detail.dart';

enum BudgetPlanStatus { initial, loading, success, failure }

class BudgetPlanState extends Equatable {
  final BudgetPlanStatus status;
  final String? errorMessage;
  final BudgetPlanPreference? preference;
  final List<BudgetPlanRoom> searchedRooms;
  final bool isLoadingRooms;
  final BudgetPlanRoomDetail? roomBudgetPlanDetail;
  final bool isLoadingRoomDetail;

  const BudgetPlanState({
    this.status = BudgetPlanStatus.initial,
    this.errorMessage,
    this.preference,
    this.searchedRooms = const [],
    this.isLoadingRooms = false,
    this.roomBudgetPlanDetail,
    this.isLoadingRoomDetail = false,
  });

  BudgetPlanState copyWith({
    BudgetPlanStatus? status,
    String? errorMessage,
    BudgetPlanPreference? preference,
    List<BudgetPlanRoom>? searchedRooms,
    bool? isLoadingRooms,
    BudgetPlanRoomDetail? roomBudgetPlanDetail,
    bool? isLoadingRoomDetail,
  }) {
    return BudgetPlanState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      preference: preference ?? this.preference,
      searchedRooms: searchedRooms ?? this.searchedRooms,
      isLoadingRooms: isLoadingRooms ?? this.isLoadingRooms,
      roomBudgetPlanDetail: roomBudgetPlanDetail ?? this.roomBudgetPlanDetail,
      isLoadingRoomDetail: isLoadingRoomDetail ?? this.isLoadingRoomDetail,
    );
  }

  @override
  List<Object?> get props => [
    status, 
    errorMessage, 
    preference, 
    searchedRooms, 
    isLoadingRooms,
    roomBudgetPlanDetail,
    isLoadingRoomDetail,
  ];
} 