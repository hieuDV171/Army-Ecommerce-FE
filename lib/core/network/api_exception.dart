import 'package:dio/dio.dart';
import '../constants/response_code.dart';

class ApiException implements Exception {
  static String getMessage(
    Object? error, [
    String fallback = "Lỗi kết nối mạng",
  ]) {
    if (error is ApiException) {
      return error.message;
    }
    if (error is DioException) {
      if (error.error is ApiException) {
        return (error.error as ApiException).message;
      }
      final statusCode = error.response?.statusCode;
      if (statusCode != null) {
        if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
          return 'Hệ thống đang bảo trì hoặc gặp sự cố. Vui lòng thử lại sau ít phút.';
        }
        if (statusCode == 500) {
          return 'Máy chủ gặp sự cố hệ thống (500). Vui lòng thử lại sau.';
        }
      }
      final msgLower = error.message?.toLowerCase() ?? '';
      if (msgLower.contains('timeout') || msgLower.contains('deadline')) {
        return 'Kết nối mạng quá hạn. Vui lòng kiểm tra lại kết nối và thử lại.';
      }
      if (msgLower.contains('connection error') ||
          msgLower.contains('socketexception') ||
          msgLower.contains('connection refused') ||
          msgLower.contains('failed host lookup') ||
          msgLower.contains('network is unreachable')) {
        return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc thử lại sau.';
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
    if (statusCode != null) {
      if (statusCode == 502 || statusCode == 503 || statusCode == 504) {
        return ApiException(
          code: ResponseCode.exception.code,
          message:
              'Hệ thống đang bảo trì hoặc gặp sự cố. Vui lòng thử lại sau ít phút.',
          statusCode: statusCode,
        );
      }
      if (statusCode == 500) {
        return ApiException(
          code: ResponseCode.exception.code,
          message: 'Máy chủ gặp sự cố hệ thống. Vui lòng thử lại sau.',
          statusCode: statusCode,
        );
      }
    }

    if (fallbackMessage != null) {
      final msgLower = fallbackMessage.toLowerCase();
      if (msgLower.contains('timeout') || msgLower.contains('deadline')) {
        return ApiException(
          code: ResponseCode.exception.code,
          message:
              'Kết nối mạng quá hạn. Vui lòng kiểm tra lại kết nối và thử lại.',
          statusCode: statusCode,
        );
      }
      if (msgLower.contains('connection error') ||
          msgLower.contains('socketexception') ||
          msgLower.contains('connection refused') ||
          msgLower.contains('failed host lookup') ||
          msgLower.contains('network is unreachable')) {
        return ApiException(
          code: ResponseCode.exception.code,
          message:
              'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc thử lại sau.',
          statusCode: statusCode,
        );
      }
    }

    if (data is Map<String, dynamic>) {
      final code = data['code']?.toString() ?? ResponseCode.exception.code;
      final responseCode = ResponseCode.fromCode(code);
      final message = data['message']?.toString();

      return ApiException(
        code: code,
        message: responseCode != ResponseCode.unhandled
            ? responseCode.message
            : (message?.isNotEmpty == true
                  ? message!
                  : _messageFor(responseCode, fallbackMessage)),
        statusCode: statusCode,
      );
    }

    return ApiException(
      code: ResponseCode.exception.code,
      message: fallbackMessage ?? ResponseCode.exception.message,
      statusCode: statusCode,
    );
  }

  static String _messageFor(
    ResponseCode responseCode,
    String? fallbackMessage,
  ) {
    if (responseCode != ResponseCode.unhandled) return responseCode.message;
    return fallbackMessage ?? ResponseCode.exception.message;
  }

  @override
  String toString() => message;
}
