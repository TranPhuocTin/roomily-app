import 'package:roomily/data/models/budget_plan_preference.dart';
import 'package:roomily/data/models/budget_plan_room.dart';
import 'package:roomily/data/models/budget_plan_room_detail.dart';

abstract class BudgetPlanRepository {
  /// Saves user budget plan preferences
  /// 
  /// Returns true if the operation was successful
  Future<bool> saveBudgetPlanPreference(BudgetPlanPreference preference);
  
  /// Get rooms that match the user's budget plan criteria
  /// 
  /// Returns a list of matching rooms
  Future<List<BudgetPlanRoom>> getSearchedRooms();

  /// Get detailed budget plan information for a specific room
  /// [roomId] is the ID of the room
  /// [scope] is an integer (1=ward, 2=district, 3=city) that determines the geographic scope for comparisons
  /// 
  /// Returns detailed budget plan information for the room
  Future<BudgetPlanRoomDetail> getRoomBudgetPlanDetail(String roomId, int scope);
  
  /// Check if the current user has saved budget plan preferences
  /// 
  /// Returns true if preferences exist, false otherwise
  Future<bool> isUserPreferenceExists();

  /// Extract user prompt from natural language input
  /// [userPrompt] is the natural language input from the user
  /// 
  /// Returns a BudgetPlanPreference object populated with extracted information
  Future<BudgetPlanPreference> extractUserPrompt(String userPrompt);
} 