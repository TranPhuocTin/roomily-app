import 'package:dio/dio.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/landlord_statistics.dart';
import 'package:roomily/data/repositories/landlord_statistics_repository.dart';

class LandlordStatisticsRepositoryImpl implements LandlordStatisticsRepository {
  final Dio _dio;

  LandlordStatisticsRepositoryImpl({required Dio dio}) : _dio = dio;

  @override
  Future<Result<LandlordStatistics>> getLandlordStatistics(String userId) async {
    try {
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.landlordStatistics(userId)}',
      );
      
      return Success(LandlordStatistics.fromJson(response.data));
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to fetch landlord statistics');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }
} 