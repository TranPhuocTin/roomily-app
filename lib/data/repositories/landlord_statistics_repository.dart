import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/landlord_statistics.dart';

abstract class LandlordStatisticsRepository {
  Future<Result<LandlordStatistics>> getLandlordStatistics(String userId);
} 