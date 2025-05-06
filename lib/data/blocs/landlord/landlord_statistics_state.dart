import 'package:equatable/equatable.dart';
import 'package:roomily/data/models/landlord_statistics.dart';

abstract class LandlordStatisticsState extends Equatable {
  const LandlordStatisticsState();

  @override
  List<Object?> get props => [];
}

class LandlordStatisticsInitial extends LandlordStatisticsState {}

class LandlordStatisticsLoading extends LandlordStatisticsState {}

class LandlordStatisticsLoaded extends LandlordStatisticsState {
  final LandlordStatistics statistics;

  const LandlordStatisticsLoaded(this.statistics);

  @override
  List<Object?> get props => [statistics];
}

class LandlordStatisticsError extends LandlordStatisticsState {
  final String message;

  const LandlordStatisticsError(this.message);

  @override
  List<Object?> get props => [message];
} 