import 'package:bloc/bloc.dart';
import 'package:flutter/cupertino.dart';
import 'package:roomily/core/services/auth_service.dart';
import 'package:roomily/data/blocs/auth/auth_cubit.dart';
import 'package:roomily/data/blocs/rented_room/rented_room_state.dart';
import 'package:roomily/data/repositories/rented_room_repository.dart';
import 'package:roomily/data/models/utility_reading_request.dart';
import 'package:roomily/data/models/landlord_confirmation_request.dart';
import 'package:roomily/data/models/bill_log.dart';
import 'package:roomily/core/utils/bill_status.dart';
import 'package:roomily/core/utils/result.dart';
import 'dart:io';
import 'package:roomily/data/models/room.dart';
import 'package:roomily/data/repositories/room_repository.dart';
import 'package:roomily/data/models/rented_room.dart';
import 'package:roomily/main.dart';

class RentedRoomCubit extends Cubit<RentedRoomState> {
  final RentedRoomRepository _rentedRoomRepository;
  final RoomRepository? _roomRepository;

  RentedRoomCubit({
    required RentedRoomRepository rentedRoomRepository,
    RoomRepository? roomRepository,
  })  : _rentedRoomRepository = rentedRoomRepository,
        _roomRepository = roomRepository,
        super(RentedRoomInitial());

  Future<void> getRentedRooms() async {
    emit(RentedRoomLoading());
    AuthService _authService = getIt<AuthService>();
    print('AuthCubit in rented room: ${_authService.userId}');

    final result = await _rentedRoomRepository.getRentedRooms();
    result.when(success: (rentedRooms) {
      debugPrint('Load rented rooms successful');
      emit(RentedRoomSuccess(rentedRooms));
    },failure: (error) => emit(RentedRoomFailure(error)));
  }
  
  Future<void> getActiveBillLog(String rentedRoomId, {bool forceRefresh = false}) async {
    emit(BillLogLoading());
    
    final result = await _rentedRoomRepository.getActiveBillLogByRentedRoomId(rentedRoomId);
    result.when(
      success: (billLog) {
        debugPrint('Load active bill log successful, billStatus: ${billLog.billStatus}');
        debugPrint('Emitting BillLogSuccess with bill status: ${billLog.billStatus}, id: ${billLog.id}');
        
        emit(BillLogSuccess(billLog));
      },
      failure: (error) {
        if (error == "NO_ACTIVE_BILL_FOUND") {
          // If there's no active bill, create an empty one to display
          debugPrint('No active bill found, creating empty bill log');
          final emptyBill = BillLog.empty();
          emit(BillLogSuccess(emptyBill, message: 'Không có hóa đơn hiện tại'));
        } else {
          emit(BillLogFailure(error));
        }
      },
    );
  }

  Future<void> getActiveBillLogByRoomId(String roomId, {bool forceRefresh = false}) async {
    emit(BillLogLoading());

    final result = await _rentedRoomRepository.getActiveBillLogByRoomId(roomId);
    result.when(
      success: (billLog) {
        debugPrint('Load active bill log by room id successful');
        
        emit(BillLogSuccess(billLog));
      },
      failure: (error) {
        if (error == "NO_ACTIVE_BILL_FOUND") {
          // If there's no active bill, create an empty one to display
          debugPrint('No active bill found, creating empty bill log');
          final emptyBill = BillLog.empty();
          emit(BillLogSuccess(emptyBill, message: 'Không có hóa đơn hiện tại'));
        } else {
          emit(BillLogFailure(error));
        }
      },
    );
  }
  
  Future<void> updateUtilityReadings(
    String billLogId, 
    int electricity, 
    int water,
    String rentedRoomId,
    {File? electricityImage, File? waterImage}
  ) async {
    debugPrint('Starting updateUtilityReadings with values: E:$electricity, W:$water');
    
    // Emit loading state
    emit(BillLogLoading());
    
    try {
      // Create the request object
      final request = UtilityReadingRequest(
        electricity: electricity,
        water: water,
        electricityImage: electricityImage,
        waterImage: waterImage,
      );
      
      // Make API call
      debugPrint('Making updateUtilityReadings API call to server');
      final result = await _rentedRoomRepository.updateUtilityReadings(billLogId, request);
      
      // Handle result
      result.when(
        success: (billLog) {
          debugPrint('Utility readings update successful, emitting success state');
          
          // First emit success message - this is important to trigger UI update
          emit(BillLogConfirmSuccess(message: 'Cập nhật chỉ số điện nước thành công'));
          
          // Then directly fetch the latest data
          debugPrint('Immediately fetching latest bill log data after success');
          getActiveBillLog(rentedRoomId, forceRefresh: true);
        },
        failure: (error) {
          if (error == "SUCCESS_BUT_NO_DATA") {
            debugPrint('Got SUCCESS_BUT_NO_DATA, showing confirmation message');
            
            // First emit confirmation success - this is important to trigger UI update
            emit(BillLogConfirmSuccess(message: 'Đã gửi chỉ số thành công'));
            
            // Then immediately get active bill log
            debugPrint('Immediately fetching latest bill log data after SUCCESS_BUT_NO_DATA');
            getActiveBillLog(rentedRoomId, forceRefresh: true);
          } else {
            // For real errors, show error first
            debugPrint('Error in updateUtilityReadings: $error, showing error');
            emit(BillLogFailure(error));
            
            // But still try to refresh with latest data
            debugPrint('Trying to fetch latest data despite error: $error');
            getActiveBillLog(rentedRoomId, forceRefresh: true);
          }
        },
      );
    } catch (e) {
      debugPrint('Unexpected exception in updateUtilityReadings: $e');
      
      // Show error
      emit(BillLogFailure(e.toString()));
      
      // But still try to refresh with latest data
      debugPrint('Trying to fetch latest data despite exception');
      getActiveBillLog(rentedRoomId, forceRefresh: true);
    }
  }

  Future<void> getBillLogHistory(String roomId) async {
    emit(BillLogHistoryLoading());
    
    final result = await _rentedRoomRepository.getBillLogHistory(roomId);
    result.when(
      success: (billLogs) {
        debugPrint('Get bill log history successful');
        emit(BillLogHistorySuccess(billLogs));
      },
      failure: (error) => emit(BillLogHistoryFailure(error)),
    );
  }

  Future<void> getBillLogHistoryByRentedRoomId(String rentedRoomId) async {
    emit(BillLogHistoryLoading());

    final result = await _rentedRoomRepository.getBillLogHistoryByRentedRoomId(rentedRoomId);
    result.when(
      success: (billLogs) {
        debugPrint('Get bill log history by rented room id successful');
        emit(BillLogHistorySuccess(billLogs));
      },
      failure: (error) => emit(BillLogHistoryFailure(error)),
    );
  }

  Future<void> confirmUtilityReadings(
    String billLogId,
    {required bool isElectricityChecked,
    required bool isWaterChecked,
    String? landlordComment,
    String? roomId}
  ) async {
    emit(BillLogLoading());

    final request = LandlordConfirmationRequest(
      isElectricityChecked: isElectricityChecked,
      isWaterChecked: isWaterChecked,
      landlordComment: landlordComment,
    );

    final result = await _rentedRoomRepository.confirmUtilityReadings(billLogId, request);
    result.when(
      success: (updatedBillLog) {
        debugPrint('Confirm utility readings successful');
        if (updatedBillLog == null) {
          emit(BillLogConfirmSuccess());
          // Use the provided roomId parameter if available, otherwise try to extract from billLogId
          final targetRoomId = roomId ?? billLogId.split('-')[0];
          debugPrint('Getting active bill log for roomId: $targetRoomId');
          getActiveBillLogByRoomId(targetRoomId, forceRefresh: true);
        } else {
          emit(BillLogSuccess(updatedBillLog));
        }
      },
      failure: (error) => emit(BillLogFailure(error)),
    );
  }

  Future<void> getRoomDetails(String roomId) async {
    debugPrint('Fetching room details for roomId: $roomId');

    // Check if we have the room repository
    if (_roomRepository == null) {
      debugPrint('RoomRepository is not available, cannot fetch room details');
      emit(RoomDetailFailure('Room repository not available'));
      return;
    }

    emit(RoomDetailLoading());

    final result = await _roomRepository.getRoom(roomId);

    result.when(
      success: (room) {
        debugPrint('Fetched room details successfully for $roomId');
        emit(RoomDetailSuccess(room));
      },
      failure: (error) {
        debugPrint('Failed to fetch room details: $error');
        emit(RoomDetailFailure(error));
      }
    );
  }

  // Get rented rooms by landlord ID
  Future<void> getRentedRoomsByLandlordId(String landlordId) async {
    debugPrint('Fetching rented rooms for landlord ID: $landlordId');

    emit(LandlordRentedRoomsLoading());

    final result = await _rentedRoomRepository.getRentedRoomsByLandlordId(landlordId);

    result.when(
      success: (rentedRooms) {
        debugPrint('Successfully fetched ${rentedRooms.length} rented rooms for landlord');
        emit(LandlordRentedRoomsSuccess(rentedRooms));

        // If room repository exists, we can also enrich the data with room details
        if (_roomRepository != null) {
          enrichRentedRoomsWithDetails(rentedRooms);
        }
      },
      failure: (error) {
        debugPrint('Failed to fetch rented rooms for landlord: $error');
        emit(LandlordRentedRoomsFailure(error));
      }
    );
  }

  // For each rented room, fetch corresponding room details
  Future<void> enrichRentedRoomsWithDetails(List<RentedRoom> rentedRooms) async {
    if (_roomRepository == null) {
      debugPrint('RoomRepository is not available, cannot enrich rooms');
      return;
    }

    emit(RentedRoomEnrichingDetails());

    final roomDetails = <String, Room>{};

    // Fetch all room details
    for (final rentedRoom in rentedRooms) {
      final roomId = rentedRoom.roomId;

      final result = await _roomRepository.getRoom(roomId);

      result.when(
        success: (room) {
          roomDetails[roomId] = room;
        },
        failure: (error) {
          debugPrint('Failed to fetch details for room $roomId: $error');
        }
      );
    }

    // Now emit the enhanced data
    emit(RentedRoomWithDetailsSuccess(rentedRooms, roomDetails));
  }

  void reset() {
    print('Resetting RentedRoomCubit state');
    emit(RentedRoomInitial());
  }

  // Phương thức đồng bộ để lấy hóa đơn theo roomId
  Future<Result<BillLog>> getActiveBillLogByRoomIdSync(String roomId) async {
    try {
      final result = await _rentedRoomRepository.getActiveBillLogByRoomId(roomId);
      return result;
    } catch (e) {
      debugPrint('Exception in getActiveBillLogByRoomIdSync: $e');
      return Failure(e.toString());
    }
  }

  // Phương thức đồng bộ để lấy thông tin chi tiết phòng
  Future<Result<Room>> getRoomDetailsSync(String roomId) async {
    try {
      if (_roomRepository == null) {
        return Failure('Room repository not available');
      }

      final result = await _roomRepository.getRoom(roomId);
      return result;
    } catch (e) {
      debugPrint('Exception in getRoomDetailsSync: $e');
      return Failure(e.toString());
    }
  }

  // Lấy các thanh toán sắp tới của chủ trọ
  Future<void> getLandlordUpcomingPayments(String landlordId) async {
    debugPrint('📊 Fetching upcoming payments for landlord ID: $landlordId');

    // Đặt trạng thái loading
    emit(UpcomingPaymentsLoading());

    try {
      // Bước 1: Lấy danh sách phòng đang được thuê của chủ trọ
      final rentedRoomsResult = await _rentedRoomRepository.getRentedRoomsByLandlordId(landlordId);

      rentedRoomsResult.when(
        success: (rentedRooms) async {
          debugPrint('✅ Found ${rentedRooms.length} rented rooms for landlord');

          if (rentedRooms.isEmpty) {
            emit(UpcomingPaymentsSuccess([], {}));
            return;
          }

          // Bước 2: Tạo danh sách để lưu trữ bills và thông tin phòng
          final List<BillLog> upcomingBills = [];
          final Map<String, Room> roomDetails = {};

          // Bước 3: Lấy thông tin hóa đơn và chi tiết phòng cho mỗi phòng đang thuê
          for (final rentedRoom in rentedRooms) {
            // 3.1: Lấy thông tin hóa đơn hiện tại
            try {
              final billResult = await _rentedRoomRepository.getActiveBillLogByRoomId(rentedRoom.roomId);
              billResult.when(
                success: (billLog) {
                  // Kiểm tra nếu là bill hợp lệ (có ID và không phải empty bill)
                  if (billLog.id.isNotEmpty && !billLog.id.startsWith('empty-')) {
                    upcomingBills.add(billLog);
                  }
                },
                failure: (error) {
                  debugPrint('⚠️ Failed to get bill for room ${rentedRoom.roomId}: $error');
                }
              );
            } catch (e) {
              debugPrint('❌ Error getting bill for room ${rentedRoom.roomId}: $e');
            }

            // 3.2: Lấy thông tin chi tiết phòng
            if (_roomRepository != null) {
              try {
                final roomResult = await _roomRepository.getRoom(rentedRoom.roomId);
                roomResult.when(
                  success: (room) {
                    roomDetails[rentedRoom.roomId] = room;
                  },
                  failure: (error) {
                    debugPrint('⚠️ Failed to get details for room ${rentedRoom.roomId}: $error');
                  }
                );
              } catch (e) {
                debugPrint('❌ Error getting details for room ${rentedRoom.roomId}: $e');
              }
            }
          }

          // Bước 4: Sắp xếp hóa đơn theo trạng thái và ngày hết hạn
          upcomingBills.sort((a, b) {
            // Đưa các bill chưa thanh toán lên đầu
            if (a.billStatus == BillStatus.PENDING && b.billStatus != BillStatus.PENDING) {
              return -1;
            }
            if (a.billStatus != BillStatus.PENDING && b.billStatus == BillStatus.PENDING) {
              return 1;
            }

            // Nếu cùng trạng thái, sắp xếp theo ngày
            try {
              final dateA = DateTime.parse(a.toDate);
              final dateB = DateTime.parse(b.toDate);
              return dateA.compareTo(dateB);
            } catch (_) {
              return 0;
            }
          });

          // Bước 5: Emit state thành công với dữ liệu đã xử lý
          emit(UpcomingPaymentsSuccess(upcomingBills, roomDetails));
        },
        failure: (error) {
          debugPrint('❌ Failed to get rented rooms: $error');
          emit(UpcomingPaymentsFailure(error));
        }
      );
    } catch (e) {
      debugPrint('❌ Exception in getLandlordUpcomingPayments: $e');
      emit(UpcomingPaymentsFailure(e.toString()));
    }
  }
}