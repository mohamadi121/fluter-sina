sealed class Result<T> {
  const Result();

  R when<R>({
    required R Function(T data) success,
    required R Function(ResultError error) failure,
  }) {
    return switch (this) {
      Success<T>(:final data) => success(data),
      Failure<T>(:final error) => failure(error),
    };
  }

  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;

  T? get dataOrNull => switch (this) {
    Success<T>(:final data) => data,
    Failure<T>() => null,
  };

  ResultError? get errorOrNull => switch (this) {
    Success<T>() => null,
    Failure<T>(:final error) => error,
  };
}

final class Success<T> extends Result<T> {
  const Success(this.data);
  final T data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Success<T> && other.data == data);

  @override
  int get hashCode => data.hashCode;

  @override
  String toString() => 'Success(data: $data)';
}

final class Failure<T> extends Result<T> {
  const Failure(this.error);
  final ResultError error;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Failure<T> && other.error == error);

  @override
  int get hashCode => error.hashCode;

  @override
  String toString() => 'Failure(error: $error)';
}

sealed class ResultError {
  const ResultError(this.message);
  final String message;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ResultError && other.message == message);

  @override
  int get hashCode => message.hashCode;

  @override
  String toString() => '$runtimeType: $message';
}

final class NetworkError extends ResultError {
  const NetworkError(super.message, {this.statusCode, this.data});
  final int? statusCode;
  final dynamic data;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NetworkError &&
          other.message == message &&
          other.statusCode == statusCode);

  @override
  int get hashCode => Object.hash(message, statusCode);

  @override
  String toString() => 'NetworkError($statusCode): $message';
}

final class TimeoutError extends ResultError {
  const TimeoutError(super.message);
}

final class CacheError extends ResultError {
  const CacheError(super.message);
}

final class ValidationError extends ResultError {
  const ValidationError(super.message, {this.field});
  final String? field;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ValidationError &&
          other.message == message &&
          other.field == field);

  @override
  int get hashCode => Object.hash(message, field);

  @override
  String toString() => 'ValidationError${field != null ? '($field)' : ''}: $message';
}

final class UnknownError extends ResultError {
  const UnknownError(super.message, {this.originalError, this.stackTrace});
  final Object? originalError;
  final StackTrace? stackTrace;

  @override
  String toString() => 'UnknownError: $message${originalError != null ? ' ($originalError)' : ''}';
}