class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  @override
  String toString() => 'ApiException: $message (StatusCode: $statusCode)';
}

class NetworkException extends ApiException {
  const NetworkException({super.message = 'No internet connection or server unreachable.', super.data});
}

class UnauthorizedException extends ApiException {
  const UnauthorizedException({super.message = 'Session expired. Please log in again.', super.statusCode = 401, super.data});
}

class ForbiddenException extends ApiException {
  const ForbiddenException({super.message = 'You do not have permission to perform this action.', super.statusCode = 403, super.data});
}

class NotFoundApiException extends ApiException {
  const NotFoundApiException({super.message = 'Requested resource not found.', super.statusCode = 404, super.data});
}

class ServerException extends ApiException {
  const ServerException({super.message = 'Internal server error occurred.', super.statusCode = 500, super.data});
}
