import '../constants/response_code.dart';
import 'api_exception.dart';

class ApiResponseParser {
  static bool isTokenInvalid(Object? data) {
    if (data is! Map<String, dynamic>) return false;
    return data['code']?.toString() == ResponseCode.tokenInvalid.code;
  }

  static ApiException exceptionFromData(
    Object? data, {
    int? statusCode,
    String? fallbackMessage,
  }) {
    return ApiException.fromResponse(
      data: data,
      statusCode: statusCode,
      fallbackMessage: fallbackMessage,
    );
  }
}
