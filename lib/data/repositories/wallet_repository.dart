import 'package:dio/dio.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/data/models/withdraw_info.dart';

import '../../core/config/dio_config.dart';
import '../models/withdraw_info_create.dart';

abstract class WalletRepository {
  Future<WithdrawInfo> getWithdrawInfo();
  Future<bool> createWithdrawInfo(WithdrawInfoCreate withdrawInfoCreate);
  Future<bool> withdrawMoney(double money);
}

class WalletRepositoryImpl extends WalletRepository {
  final Dio _dio;

  WalletRepositoryImpl({Dio? dio})
      : _dio = dio ?? DioConfig.createDio();


  @override
  Future<bool> createWithdrawInfo(WithdrawInfoCreate withdrawInfoCreate) async {
    try {
      final response = await _dio.post(
        ApiConstants.createWithdrawRequest(),
        data: withdrawInfoCreate.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Handle error
        throw Exception('Failed to create withdraw info');
      }

    } on DioException catch (e) {
      print('Error creating withdraw info: $e');
      rethrow;
    } catch (e) {
      print('Unexpected error creating withdraw info: $e');
      rethrow;
    }
  }

  @override
  Future<WithdrawInfo> getWithdrawInfo() async {
    try {
      final response = await _dio.get(ApiConstants.getWithdrawInfo());
      if (response.statusCode == 200) {
        return WithdrawInfo.fromJson(response.data);
      } else {
        // Handle error
        throw Exception('Failed to fetch withdraw info');
      }
    } on DioException catch (e) {
      print('Error fetching withdraw info: $e');
      rethrow;
    } catch (e) {
      print('Unexpected error fetching withdraw info: $e');
      rethrow;
    }
  }

  @override
  Future<bool> withdrawMoney(double money) async {
    try {
      final response = await _dio.post(
        ApiConstants.withDrawMoney(money),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true;
      } else {
        // Handle error
        throw Exception('Failed to withdraw money');
      }
    } on DioException catch (e) {
      print('Error withdrawing money: $e');
      rethrow;
    } catch (e) {
      print('Unexpected error withdrawing money: $e');
      rethrow;
    }
  }

}