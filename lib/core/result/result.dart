/// A simple class to handle operation results
class Result<T> {
  final T? _data;
  final Exception? _error;
  final bool _isSuccess;

  Result._({
    T? data,
    Exception? error,
    required bool isSuccess,
  })  : _data = data,
        _error = error,
        _isSuccess = isSuccess;

  factory Result.success(T data) {
    return Result._(
      data: data,
      isSuccess: true,
    );
  }

  factory Result.failure(Exception error) {
    return Result._(
      error: error,
      isSuccess: false,
    );
  }

  bool get isSuccess => _isSuccess;
  bool get isFailure => !_isSuccess;
  T get data => _data as T;
  Exception get error => _error!;

  R when<R>({
    required R Function(T data) success,
    required R Function(Exception error) failure,
  }) {
    if (_isSuccess) {
      return success(_data as T);
    } else {
      return failure(_error!);
    }
  }
} 