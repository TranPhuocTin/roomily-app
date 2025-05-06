import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/data/repositories/landlord_statistics_repository.dart';
import 'package:roomily/core/utils/result.dart';

import 'landlord_statistics_state.dart';

class LandlordStatisticsCubit extends Cubit<LandlordStatisticsState> {
  final LandlordStatisticsRepository _repository;

  LandlordStatisticsCubit(this._repository) : super(LandlordStatisticsInitial());

  Future<void> fetchLandlordStatistics(String landlordId) async {
    emit(LandlordStatisticsLoading());

    final result = await _repository.getLandlordStatistics(landlordId);

    result.when(
      success: (statistics) => emit(LandlordStatisticsLoaded(statistics)),
      failure: (message) => emit(LandlordStatisticsError(message)),
    );
  }
} 