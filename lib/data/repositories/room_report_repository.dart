import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/room_report.dart';

abstract class RoomReportRepository {
  Future<Result<void>> reportRoom(RoomReport report);
} 