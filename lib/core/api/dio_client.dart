import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/session_manager.dart';
import '../utils/logger.dart';

class DioClient {
  late Dio _dio;
  final baseUrl = dotenv.env['BASE_URL'] ?? '';
  DioClient() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        contentType: 'application/json',
      ),
    );

    // THÊM INTERCEPTOR Ở ĐÂY
    _dio.interceptors.add(
      InterceptorsWrapper(
        // 1. TRƯỚC KHI GỬI ĐI (onRequest)
        onRequest: (options, handler) async {
          // Lấy token từ bộ nhớ máy
          final token = await SessionManager.getToken();

          // ĐIỀU KIỆN 1: Chỉ gắn Token nếu gọi đến Server của mình
          bool isMyServer = options.path.startsWith(baseUrl) || !options.path.startsWith('http');

          // ĐIỀU KIỆN 2: Không gắn Token cho các API "Công cộng" (Login, Signup)
          // Chúng ta kiểm tra xem path có chứa từ khóa login/signup không
          bool isPublicApi = options.path.contains('/login') || options.path.contains('/signup');

          if (token != null && token.isNotEmpty && isMyServer && !isPublicApi) {
            // Tự động gắn vào Header cho MỌI API
            options.headers['Authorization'] = 'Bearer $token';

          }

          final hasAuth = options.headers.containsKey('Authorization');
          logger.d("📡 GỬI: [${options.method}] ${options.path} | auth=$hasAuth | body=${options.data}");
          return handler.next(options); // Tiếp tục gửi đi
        },

        // 2. KHI NHẬN PHẢN HỒI (onResponse)
        onResponse: (response, handler) {
          logger.i("✅ NHẬN VỀ: [${response.statusCode}] ${response.requestOptions.path} | data=${response.data}");
          return handler.next(response); // Tiếp tục trả về cho Repository
        },

        // 3. KHI CÓ LỖI (onError)
        onError: (DioException e, handler) {
          logger.e("❌ LỖI API: [${e.response?.statusCode}] ${e.requestOptions.path} | resp=${e.response?.data} | msg=${e.message}");

          String code = e.response?.data['code']?.toString() ?? '';
          // Xử lý thông minh: Nếu Server báo Token hết hạn (ví dụ mã 9998)
          if (code == ResponseCode.tokenInvalid.code) {
            // Có thể thực hiện logic Logout tự động ở đây nếu cần
            logger.w("Cảnh báo: Phiên đăng nhập hết hạn!");
          }

          return handler.next(e); // Trả lỗi về cho Repository xử lý
        },
      ),
    );
  }

  // Getter để lấy đối tượng Dio đã được cấu hình
  Dio get dio => _dio;
}