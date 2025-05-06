import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../constants/api_constants.dart';
import '../exceptions/api_exceptions.dart';
import '../interceptors/auth_token_interceptor.dart';

class DioConfig {
  static Dio createDio() {
    if (kDebugMode) {
      print('🔄 [DioConfig] Creating new Dio instance');
    }

    Dio dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: const Duration(milliseconds: 30000),
        receiveTimeout: const Duration(milliseconds: 30000),
        sendTimeout: const Duration(milliseconds: 30000),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        validateStatus: (status) {
          return status != null && status < 500;
        },
      ),
    );

    // Clear any existing interceptors
    dio.interceptors.clear();

    // Add new interceptors
    dio.interceptors.addAll([
      _LoggerInterceptor(),
      AuthTokenInterceptor(),
      _ErrorInterceptor(),
    ]);

    if (kDebugMode) {
      print('✅ [DioConfig] Dio instance created with fresh interceptors');
    }

    return dio;
  }
}

// Logger Interceptor
class _LoggerInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (kDebugMode) {
      print('REQUEST[${options.method}] => PATH: ${options.path}');
      print('Headers:');
      options.headers.forEach((key, value) {
        print('$key: $value');
      });
      if (options.data != null) {
        print('Request Data:');
        print(options.data);
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (kDebugMode) {
      print('RESPONSE[${response.statusCode}] => PATH: ${response.requestOptions.path}');
      print('Response Data:');
      print(response.data);
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('ERROR[${err.response?.statusCode}] => PATH: ${err.requestOptions.path}');
      print('Error Message: ${err.message}');
    }
    handler.next(err);
  }
}

// Error Interceptor
class _ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (kDebugMode) {
      print('Error Interceptor - Type: ${err.type}');
      print('Error Interceptor - Message: ${err.message}');
      print('Error Interceptor - Error: ${err.error}');
    }

    DioException dioError;
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        dioError = err.copyWith(
          error: ApiTimeoutException(err.requestOptions),
          message: 'Connection timed out. Please check your internet connection.'
        );
        break;
      case DioExceptionType.badResponse:
        String message;
        switch (err.response?.statusCode) {
          case 400:
            message = err.response?.data?['message'] ?? 'Bad request';
            dioError = err.copyWith(
              error: BadRequestException(err.requestOptions),
              message: message
            );
            break;
          case 401:
            message = 'Unauthorized. Please login again.';
            dioError = err.copyWith(
              error: UnauthorizedException(err.requestOptions),
              message: message
            );
            break;
          case 403:
            message = 'Access denied.';
            dioError = err.copyWith(
              error: ForbiddenException(err.requestOptions),
              message: message
            );
            break;
          case 404:
            message = 'Resource not found.';
            dioError = err.copyWith(
              error: NotFoundException(err.requestOptions),
              message: message
            );
            break;
          case 500:
            message = 'Server error. Please try again later.';
            dioError = err.copyWith(
              error: ServerException(err.requestOptions),
              message: message
            );
            break;
          default:
            message = err.response?.data?['message'] ?? 'Server error occurred.';
            dioError = err.copyWith(
              error: ServerException(err.requestOptions),
              message: message
            );
        }
        break;
      case DioExceptionType.cancel:
        dioError = err.copyWith(message: 'Request cancelled');
        break;
      case DioExceptionType.unknown:
        if (err.error != null && err.error.toString().contains('SocketException')) {
          dioError = err.copyWith(
            error: NoInternetConnectionException(err.requestOptions),
            message: 'No internet connection. Please check your network connection.'
          );
        } else if (err.error != null && err.error.toString().contains('FormatException')) {
          // Look for authentication issues in the logs
          print('Error Interceptor - FormatException: ${err.error}');
          if (err.requestOptions.uri.toString().contains('mrthinkj.site')) {
            // Check if the error message or stack trace contains indicators of a 401
            final errorString = err.toString().toLowerCase();
            if (errorString.contains('401') || 
                errorString.contains('unauthorized') || 
                errorString.contains('authentication')) {
              dioError = err.copyWith(
                error: UnauthorizedException(err.requestOptions),
                message: 'Unauthorized access. Please login again to continue.'
              );
            }
            else {
              // Default format exception but possibly successful operation
              dioError = err.copyWith(
                error: ServerException(err.requestOptions),
                message: 'The operation may have been successful, but the response format was unexpected.'
              );
            }
          } else {
            // Handle FormatException specifically
            dioError = err.copyWith(
              error: ServerException(err.requestOptions),
              message: 'The operation was successful, but the response format was unexpected.'
            );
          }
        } else {
          dioError = err.copyWith(
            error: ServerException(err.requestOptions),
            message: 'Connection error. Please check your internet connection and try again.'
          );
        }
        break;
      default:
        dioError = err.copyWith(
          error: ServerException(err.requestOptions),
          message: 'An unexpected error occurred. Please try again.'
        );
    }
    
    if (kDebugMode) {
      print('Error Interceptor - Final Error: ${dioError.message}');
    }
    
    handler.next(dioError);
  }
}