import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:roomily/core/config/dio_config.dart';
import 'package:roomily/core/constants/api_constants.dart';
import 'package:roomily/core/utils/result.dart';
import 'package:roomily/data/models/payment_request.dart';
import 'package:roomily/data/models/payment_response.dart';
import 'package:roomily/data/repositories/payment_repository.dart';

class PaymentRepositoryImpl implements PaymentRepository {
  final Dio _dio;

  PaymentRepositoryImpl({Dio? dio})
      : _dio = dio ?? DioConfig.createDio();

  @override
  Future<Result<PaymentResponse>> createPayment(PaymentRequest request) async {
    try {
      if (kDebugMode) {
        print('🔍 [REPOSITORY] Creating payment: ${request.toJson()}');
      }
      
      final response = await _dio.post(
        '${ApiConstants.baseUrl}${ApiConstants.createPayment()}',
        data: request.toJson(),
      );
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final paymentResponse = PaymentResponse.fromJson(response.data);
        
        if (kDebugMode) {
          print('✅ [REPOSITORY] Payment created: ${paymentResponse.description}');
        }
        
        return Success(paymentResponse);
      }

      if (kDebugMode) {
        print('❌ [REPOSITORY] Failed to create payment: ${response.statusCode}');
      }
      
      return Failure('Failed to create payment. Status code: ${response.statusCode}');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [REPOSITORY] DioException: ${e.message}');
        print('❌ [REPOSITORY] Response: ${e.response?.data}');
      }
      
      return Failure(e.message ?? 'Failed to create payment');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [REPOSITORY] Unexpected error: $e');
      }
      
      return Failure('An unexpected error occurred: $e');
    }
  }

  @override
  Future<Result<PaymentResponse>> getCheckout(String checkoutId) async {
    try {
      if (kDebugMode) {
        print('🔍 [REPOSITORY] Getting checkout info for ID: $checkoutId');
      }
      
      final response = await _dio.get(
        '${ApiConstants.baseUrl}${ApiConstants.getCheckout(checkoutId)}',
      );
      
      if (response.statusCode == 200) {
        final paymentResponse = PaymentResponse.fromJson(response.data);
        
        if (kDebugMode) {
          print('✅ [REPOSITORY] Got checkout info: ${paymentResponse.description}');
        }
        
        return Success(paymentResponse);
      }

      if (kDebugMode) {
        print('❌ [REPOSITORY] Failed to get checkout: ${response.statusCode}');
      }
      
      return Failure('Failed to get checkout info. Status code: ${response.statusCode}');
    } on DioException catch (e) {
      if (kDebugMode) {
        print('❌ [REPOSITORY] DioException: ${e.message}');
        print('❌ [REPOSITORY] Response: ${e.response?.data}');
      }
      
      return Failure(e.message ?? 'Failed to get checkout info');
    } catch (e) {
      if (kDebugMode) {
        print('❌ [REPOSITORY] Unexpected error: $e');
      }
      
      return Failure('An unexpected error occurred: $e');
    }
  }
} 