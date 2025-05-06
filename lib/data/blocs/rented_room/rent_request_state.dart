import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/rent_request.dart';
import 'package:roomily/data/models/rental_request.dart';

abstract class RentRequestState extends Equatable {
  const RentRequestState();
  
  @override
  List<Object?> get props => [];
}

class RentRequestInitial extends RentRequestState {}

class RentRequestLoading extends RentRequestState {}

class RentRequestSuccess extends RentRequestState {
  final String message;
  final RentalRequest? rentalRequest;
  
  const RentRequestSuccess(this.message, {this.rentalRequest});
  
  @override
  List<Object?> get props => [message, rentalRequest];
}

// New state for list of rental requests
class RentRequestListSuccess extends RentRequestState {
  final List<RentalRequest> rentalRequests;
  
  const RentRequestListSuccess(this.rentalRequests);
  
  @override
  List<Object?> get props => [rentalRequests];
}

class RentRequestFailure extends RentRequestState {
  final String error;
  
  const RentRequestFailure(this.error);
  
  @override
  List<Object?> get props => [error];
}