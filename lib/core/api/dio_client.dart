import 'package:army_ecommerce/core/config/app_config.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/network/api_exception.dart';
import 'package:army_ecommerce/core/network/api_response_parser.dart';
import 'package:dio/dio.dart';

import '../services/session_manager.dart';
import '../utils/logger.dart';

class DioClient {
  late final Dio _dio;
  final String baseUrl = AppConfig.baseUrl;

  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SessionManager.getToken();
          final isSameBackend =
              options.path.startsWith(baseUrl) || !options.path.startsWith('http');
          final isPublicApi =
              options.path.endsWith('/auth/login') || options.path.endsWith('/auth/signup');

          if (token != null && token.isNotEmpty && isSameBackend && !isPublicApi) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          logger.d('API gửi đi: [${options.method}] ${options.path}');
          return handler.next(options);
        },
        onResponse: (response, handler) async {
          logger.i(
            'API nhận về: [${response.statusCode}] ${response.requestOptions.path}',
          );

          if (ApiResponseParser.isTokenInvalid(response.data)) {
            await SessionManager.clearSession();
            final apiException = ApiResponseParser.exceptionFromData(
              response.data,
              statusCode: response.statusCode,
            );

            return handler.reject(
              DioException(
                requestOptions: response.requestOptions,
                response: response,
                type: DioExceptionType.badResponse,
                error: apiException,
              ),
            );
          }

          return handler.next(response);
        },
        onError: (DioException error, handler) async {
          logger.e('Lỗi API: [${error.response?.statusCode}] ${error.message}');

          final responseData = error.response?.data;
          final code = responseData is Map<String, dynamic>
              ? responseData['code']?.toString() ?? ''
              : '';

          if (code == ResponseCode.tokenInvalid.code) {
            await SessionManager.clearSession();
            logger.w('Phiên đăng nhập đã hết hạn');
          }

          if (error.error is ApiException) {
            return handler.next(error);
          }

          final apiException = ApiResponseParser.exceptionFromData(
            responseData,
            statusCode: error.response?.statusCode,
            fallbackMessage: error.message,
          );

          return handler.next(error.copyWith(error: apiException));
        },
      ),
    );
  }

  Dio get dio => _dio;
}
