import 'package:army_ecommerce/core/config/app_config.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/network/api_exception.dart';
import 'package:army_ecommerce/core/network/api_response_parser.dart';
import 'package:dio/dio.dart';

import '../services/session_manager.dart';
import '../utils/logger.dart';

class DioClient {
  static DioClient? _instance;
  late final Dio _dio;
  late String _baseUrl;

  DioClient() {
    _baseUrl = AppConfig.baseUrl;
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );
    _instance = this;

    _dio.interceptors.add(
      InterceptorsWrapper(
        // 1. KHI GỬI REQUEST — gắn token vào header nếu có
        onRequest: (options, handler) async {
          final token = await SessionManager.getToken();
          final isSameBackend =
              options.path.startsWith(baseUrl) || !options.path.startsWith('http');
          final isPublicApi =
              options.path.endsWith('/auth/login') || options.path.endsWith('/auth/signup');

          if (token != null && token.isNotEmpty && isSameBackend && !isPublicApi) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          final hasAuth = options.headers.containsKey('Authorization');
          logger.d('📡 GỬI: [${options.method}] ${options.path} | auth=$hasAuth | body=${options.data}');
          return handler.next(options);
        },
        // 2. KHI NHẬN PHẢN HỒI — kiểm tra token có còn hợp lệ không
        onResponse: (response, handler) async {
          logger.i('✅ NHẬN VỀ: [${response.statusCode}] ${response.requestOptions.path}');

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

          final data = response.data;
          if (data is Map<String, dynamic>) {
            final code = data['code']?.toString();
            if (code != null && code.isNotEmpty) {
              if (code != '1000' && code != '1010' && code != '9994') {
                final apiException = ApiResponseParser.exceptionFromData(
                  data,
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
            }
          }

          return handler.next(response);
        },
        // 3. KHI CÓ LỖI — xử lý token hết hạn và bọc lỗi thành ApiException
        onError: (DioException error, handler) async {
          logger.e('❌ LỖI API: [${error.response?.statusCode}] ${error.requestOptions.path} | msg=${error.message}');

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

  static DioClient? get instance => _instance;

  String get baseUrl => _baseUrl;

  void updateBaseUrl(String newUrl) {
    _baseUrl = AppConfig.baseUrl;
    _dio.options.baseUrl = _baseUrl;
  }

  Dio get dio => _dio;
}
