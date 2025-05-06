// lib/core/utils/result.dart
sealed class Result<T> {
  const Result();

  // Add the when method for handling both success and failure cases
  R when<R>({
    required R Function(T data) success,
    required R Function(String message) failure,
  }) {
    final result = this;
    if (result is Success<T>) {
      return success(result.data);
    } else if (result is Failure<T>) {
      return failure(result.message);
    }
    throw Exception('Unknown result type');
  }
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
}

class Failure<T> extends Result<T> {
  final String message;
  const Failure(this.message);
}