import 'package:dio/dio.dart';

import '../telemetry/telemetry.dart';

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
    _reportFailure(error);
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
            // ponytail: the underlying error is the only thing that tells a
            // Windows TLS failure apart from a DNS/proxy one, and it is what
            // the user reads off the error screen. Keep it verbatim.
            : 'Unexpected error occurred: ${error.error ?? error.message}',
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
    // olevod answers a bare `用户签名非法` string, not JSON — keeping it beats
    // flattening every 4xx to "Unauthorized".
    final apiMessage = switch (data) {
      Map<String, dynamic>() => data['message'] as String?,
      String s when s.trim().isNotEmpty && s.length < 200 => s.trim(),
      _ => null,
    };
    return ApiException(
      message:
          apiMessage ??
          _statusMessages[statusCode] ??
          'Received invalid status code: $statusCode',
      statusCode: statusCode,
    );
  }

  /// Failure signatures already reported this run: `type/status`.
  static final _reportedFailures = <String>{};

  /// A request that ends as an error screen. Every data source funnels through
  /// [fromDioException] to build that screen, so this is the one place that
  /// sees them all.
  ///
  /// Type and status, nothing else — dio's own message carries the URL that
  /// failed, and the URL carries what the user was watching. Reported once per
  /// signature per run: an offline machine is worth one event, not one per
  /// retry the user taps. Cancellations are the user's own doing and are not
  /// reported at all.
  static void _reportFailure(DioException error) {
    if (error.type == DioExceptionType.cancel) return;
    final status = error.response?.statusCode;
    if (!_reportedFailures.add('${error.type.name}/$status')) return;
    Telemetry.report(
      'network.request_failed',
      data: {'type': error.type.name, 'status': status},
    );
  }

  @override
  String toString() => message;
}
