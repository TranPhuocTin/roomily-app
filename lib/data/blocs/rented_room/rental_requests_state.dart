import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/rental_request.dart';

abstract class RentalRequestsState extends Equatable {
  const RentalRequestsState();
  
  @override
  List<Object?> get props => [];
}

class RentalRequestsInitial extends RentalRequestsState {}

class RentalRequestsLoading extends RentalRequestsState {}

class RentalRequestsLoaded extends RentalRequestsState {
  final List<RentalRequest> rentalRequests;
  
  const RentalRequestsLoaded(this.rentalRequests);
  
  @override
  List<Object?> get props => [rentalRequests];
}

class RentalRequestsError extends RentalRequestsState {
  final String error;
  
  const RentalRequestsError(this.error);
  
  @override
  List<Object?> get props => [error];
} 