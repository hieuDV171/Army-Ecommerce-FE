import 'package:dio/dio.dart';
import '../constants/response_code.dart';

class ApiException implements Exception {
  static String getMessage(Object? error, [String fallback = "Lỗi kết nối mạng"]) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is DioException) {
      if (error.error is ApiException) {
        return (error.error as ApiException).message;
      }
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final msg = data['message']?.toString();
        if (msg != null && msg.isNotEmpty) {
          return msg;
        }
      }
      return error.message ?? fallback;
    }
    if (error is Exception) {
      final str = error.toString();
      if (str.startsWith('Exception: ')) {
        return str.substring('Exception: '.length);
      }
      return str;
    }
    return error?.toString() ?? fallback;
  }
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
