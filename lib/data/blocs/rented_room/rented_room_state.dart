  import 'package:equatable/equatable.dart';
  import 'package:roomily/data/models/models.dart';
  import 'package:roomily/data/models/room.dart';

  abstract class RentedRoomState extends Equatable {
    const RentedRoomState();

    @override
    List<Object?> get props => [];
  }

  class RentedRoomInitial extends RentedRoomState {}

  class RentedRoomLoading extends RentedRoomState {}

  class RentedRoomSuccess extends RentedRoomState {
    final List<RentedRoom>? rentedRooms;

    const RentedRoomSuccess(this.rentedRooms);

    @override
    List<Object?> get props => [rentedRooms];
  }

  class RentedRoomFailure extends RentedRoomState {
    final String error;

    const RentedRoomFailure(this.error);

    @override
    List<Object?> get props => [error];
  }
  
  // Bill log states
  class BillLogLoading extends RentedRoomState {}
  
  class BillLogSuccess extends RentedRoomState {
    final BillLog billLog;
    final String? message;
    
    const BillLogSuccess(this.billLog, {this.message});
    
    @override
    List<Object?> get props => [billLog, message];
  }
  
  class BillLogConfirmSuccess extends RentedRoomState {
    final String message;
    
    const BillLogConfirmSuccess({this.message = 'Xác nhận chỉ số thành công'});
    
    @override
    List<Object?> get props => [message];
  }
  
  class BillLogFailure extends RentedRoomState {
    final String error;
    
    const BillLogFailure(this.error);
    
    @override
    List<Object?> get props => [error];
  }
  
  // Bill log history states
  class BillLogHistoryLoading extends RentedRoomState {}
  
  class BillLogHistorySuccess extends RentedRoomState {
    final List<BillLog> billLogs;
    final String? rentedRoomId;
    
    const BillLogHistorySuccess(this.billLogs, {this.rentedRoomId});
    
    @override
    List<Object?> get props => [billLogs, rentedRoomId];
  }
  
  class BillLogHistoryFailure extends RentedRoomState {
    final String error;
    
    const BillLogHistoryFailure(this.error);
    
    @override
    List<Object?> get props => [error];
  }
  
  // Room detail states
  class RoomDetailLoading extends RentedRoomState {}
  
  class RoomDetailSuccess extends RentedRoomState {
    final Room room;
    
    const RoomDetailSuccess(this.room);
    
    @override
    List<Object?> get props => [room];
  }
  
  class RoomDetailFailure extends RentedRoomState {
    final String error;
    
    const RoomDetailFailure(this.error);
    
    @override
    List<Object?> get props => [error];
  }
  
  // Combined room data states
  class RentedRoomEnrichingDetails extends RentedRoomState {}
  
  class RentedRoomWithDetailsSuccess extends RentedRoomState {
    final List<RentedRoom> rentedRooms;
    final Map<String, Room> roomDetails;
    
    const RentedRoomWithDetailsSuccess(this.rentedRooms, this.roomDetails);
    
    @override
    List<Object?> get props => [rentedRooms, roomDetails];
  }

  // Landlord rented rooms states
  class LandlordRentedRoomsLoading extends RentedRoomState {}

  class LandlordRentedRoomsSuccess extends RentedRoomState {
    final List<RentedRoom> rentedRooms;
    
    const LandlordRentedRoomsSuccess(this.rentedRooms);
    
    @override
    List<Object?> get props => [rentedRooms];
  }

  class LandlordRentedRoomsFailure extends RentedRoomState {
    final String error;
    
    const LandlordRentedRoomsFailure(this.error);
    
    @override
    List<Object?> get props => [error];
  }

  // Upcoming Payments states
  class UpcomingPaymentsLoading extends RentedRoomState {}
  
  class UpcomingPaymentsSuccess extends RentedRoomState {
    final List<BillLog> upcomingBills;
    final Map<String, Room> roomDetails;
    
    const UpcomingPaymentsSuccess(this.upcomingBills, this.roomDetails);
    
    @override
    List<Object?> get props => [upcomingBills, roomDetails];
  }
  
  class UpcomingPaymentsFailure extends RentedRoomState {
    final String error;
    
    const UpcomingPaymentsFailure(this.error);
    
    @override
    List<Object?> get props => [error];
  }
