import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/core/utils/room_report_type.dart';
import 'package:roomily/data/blocs/room_report/room_report_state.dart';
import 'package:roomily/data/models/room_report.dart';
import 'package:roomily/data/repositories/room_report_repository.dart';

class RoomReportCubit extends Cubit<RoomReportState> {
  final RoomReportRepository repository;

  RoomReportCubit({required this.repository}) : super(RoomReportInitial());

  Future<void> reportRoom({
    required String reporterId,
    required String roomId,
    required String reason,
    required RoomReportType type,
  }) async {
    emit(RoomReportLoading());

    final report = RoomReport(
      reporterId: reporterId,
      roomId: roomId,
      reason: reason,
      type: type,
    );

    final result = await repository.reportRoom(report);

    switch (result) {
      case Success():
        emit(RoomReportSuccess());
      case Failure(message: final message):
        emit(RoomReportError(message: message));
    }
  }
} 