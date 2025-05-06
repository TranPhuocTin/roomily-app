import 'package:dio/dio.dart';

abstract class ApiException implements Exception {
  final String message;
  final RequestOptions requestOptions;

  ApiException(this.message, this.requestOptions);
}

class ApiTimeoutException extends ApiException {
  ApiTimeoutException(RequestOptions requestOptions)
      : super('Connection timeout with API server', requestOptions);
}

class BadRequestException extends ApiException {
  BadRequestException(RequestOptions requestOptions)
      : super('Bad request', requestOptions);
}

class UnauthorizedException extends ApiException {
  UnauthorizedException(RequestOptions requestOptions)
      : super('Unauthorized', requestOptions);
}

class ForbiddenException extends ApiException {
  ForbiddenException(RequestOptions requestOptions)
      : super('Forbidden', requestOptions);
}

class NotFoundException extends ApiException {
  NotFoundException(RequestOptions requestOptions)
      : super('Not found', requestOptions);
}

class ServerException extends ApiException {
  ServerException(RequestOptions requestOptions)
      : super('Internal server error', requestOptions);
}

class NoInternetConnectionException extends ApiException {
  NoInternetConnectionException(RequestOptions requestOptions)
      : super('No internet connection', requestOptions);
}