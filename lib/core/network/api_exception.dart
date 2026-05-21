import '../constants/response_code.dart';

class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
  });

  factory ApiException.fromResponse({
    required Object? data,
    int? statusCode,
    String? fallbackMessage,
  }) {
    if (data is Map<String, dynamic>) {
      final code = data['code']?.toString() ?? ResponseCode.exception.code;
      final responseCode = ResponseCode.fromCode(code);
      final message = data['message']?.toString();

      return ApiException(
        code: code,
        message: message?.isNotEmpty == true
            ? message!
            : _messageFor(responseCode, fallbackMessage),
        statusCode: statusCode,
      );
    }

    return ApiException(
      code: ResponseCode.exception.code,
      message: fallbackMessage ?? ResponseCode.exception.message,
      statusCode: statusCode,
    );
  }

  static String _messageFor(ResponseCode responseCode, String? fallbackMessage) {
    if (responseCode != ResponseCode.unhandled) return responseCode.message;
    return fallbackMessage ?? ResponseCode.exception.message;
  }

  @override
  String toString() => message;
}
