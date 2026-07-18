import 'package:dio/dio.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException({required this.message, this.statusCode});

  static const _statusMessages = {
    400: 'Bad request',
    401: 'Unauthorized',
    403: 'Forbidden',
    404: 'Resource not found',
    500: 'Internal server error',
    502: 'Bad gateway',
    503: 'Service unavailable',
  };

  factory ApiException.fromDioException(DioException error) {
    final message = switch (error.type) {
      DioExceptionType.cancel => 'Request to server was cancelled',
      DioExceptionType.connectionTimeout => 'Connection timeout with server',
      DioExceptionType.receiveTimeout =>
        'Receive timeout in connection with server',
      DioExceptionType.sendTimeout => 'Send timeout in connection with server',
      DioExceptionType.connectionError => 'No internet connection',
      DioExceptionType.badCertificate => 'Bad certificate',
      DioExceptionType.badResponse => null, // handled below
      // unknown + any type future dio versions add
      _ =>
        (error.message?.contains('SocketException') ?? false)
            ? 'No internet connection'
            : 'Unexpected error occurred',
    };
    if (message != null) return ApiException(message: message);
    return ApiException.fromResponse(error.response);
  }

  factory ApiException.fromResponse(Response? response) {
    if (response == null) {
      return ApiException(message: 'No response from server');
    }
    final statusCode = response.statusCode;
    final data = response.data;
    final apiMessage = data is Map<String, dynamic>
        ? data['message'] as String?
        : null;
    return ApiException(
      message:
          apiMessage ??
          _statusMessages[statusCode] ??
          'Received invalid status code: $statusCode',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => message;
}
