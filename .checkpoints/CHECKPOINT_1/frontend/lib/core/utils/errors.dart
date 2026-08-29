import 'package:equatable/equatable.dart';

// Base Failure class for domain/presentation layer
abstract class Failure extends Equatable {
  final String message;
  final int? statusCode;

  const Failure({required this.message, this.statusCode});

  @override
  List<Object?> get props => [message, statusCode];
}

class NetworkFailure extends Failure {
  const NetworkFailure({required super.message, super.statusCode});
}

class ServerFailure extends Failure {
  const ServerFailure({required super.message, super.statusCode});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.message, super.statusCode});
}

class ValidationFailure extends Failure {
  const ValidationFailure({required super.message, super.statusCode});
}

class UnknownFailure extends Failure {
  const UnknownFailure({required super.message, super.statusCode});
}

// Base AppException class for data layer
abstract class AppException implements Exception {
  final String message;
  final int? statusCode;

  const AppException({required this.message, this.statusCode});

  @override
  String toString() => 'AppException(message: $message, statusCode: $statusCode)';
}

class NetworkException extends AppException {
  const NetworkException({required super.message, super.statusCode});
}

class ServerException extends AppException {
  const ServerException({required super.message, super.statusCode});
}

class CacheException extends AppException {
  const CacheException({required super.message, super.statusCode});
}

class ValidationException extends AppException {
  const ValidationException({required super.message, super.statusCode});
}

class AuthException extends AppException {
  const AuthException({required super.message, super.statusCode});
}

// Mapper converting Exceptions to Failures
class ErrorMapper {
  static Failure mapExceptionToFailure(Object exception) {
    if (exception is NetworkException) {
      return NetworkFailure(message: exception.message, statusCode: exception.statusCode);
    } else if (exception is ServerException) {
      return ServerFailure(message: exception.message, statusCode: exception.statusCode);
    } else if (exception is CacheException) {
      return CacheFailure(message: exception.message, statusCode: exception.statusCode);
    } else if (exception is ValidationException) {
      return ValidationFailure(message: exception.message, statusCode: exception.statusCode);
    }
    return UnknownFailure(message: exception.toString());
  }
}
