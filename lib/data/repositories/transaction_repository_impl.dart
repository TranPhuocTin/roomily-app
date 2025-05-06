import 'package:dio/dio.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/data/models/transaction.dart';

import '../../core/utils/result.dart';

abstract class TransactionRepository {
 Future<Result<List<Transaction>>> getTransactionsByRentedRoomId(String rentedRoomId);
}

class TransactionRepositoryImpl extends TransactionRepository {
  final Dio _dio;
  TransactionRepositoryImpl({Dio? dio}) : _dio = dio ?? DioConfig.createDio();

  @override
  Future<Result<List<Transaction>>> getTransactionsByRentedRoomId(String rentedRoomId) async {
    try {
      final result = await _dio.get(ApiConstants.getTransactionHistoriesOfRentedRoom(rentedRoomId));
      if(result.statusCode == 200) {
        final transactionHistories = (result .data as List)
            .map((e) => Transaction.fromJson(e))
            .toList();
        return Success(transactionHistories);
      }
      return Failure('Lỗi không xác định');
    } catch (e) {
      return Failure('Lỗi không xác định: $e');
    }
  }
}