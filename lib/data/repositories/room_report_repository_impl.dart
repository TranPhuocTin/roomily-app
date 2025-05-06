import 'package:dio/dio.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/room_report.dart';
import 'package:roomily/data/repositories/room_report_repository.dart';

class RoomReportRepositoryImpl implements RoomReportRepository {
  final Dio _dio;

  RoomReportRepositoryImpl({Dio? dio}) : _dio = dio ?? DioConfig.createDio();

  @override
  Future<Result<void>> reportRoom(RoomReport report) async {
    try {
      await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.roomReport()}',
        data: report.toJson(),
      );
      return const Success(null);
    } on DioException catch (e) {
      return Failure(e.message ?? 'Failed to report room');
    } catch (e) {
      return Failure('An unexpected error occurred: $e');
    }
  }
} 