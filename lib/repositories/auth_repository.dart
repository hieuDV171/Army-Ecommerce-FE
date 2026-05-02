import 'package:army_ecommerce/models/user_model.dart';
import 'package:dio/dio.dart';

import '../core/api/dio_client.dart';

class AuthRepository {
  final DioClient _dioClient;

  AuthRepository({required DioClient dioClient}) : _dioClient = dioClient;

  Future<AuthResponse> login(String phoneNumber, String password) async {
    try {
      // Gửi request POST với SĐT và mật khẩu
      final response = await _dioClient.dio.post(
        '/auth/login',
        data: {
          'phone_number': phoneNumber,
          'password': password,
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      // Bắt các lỗi kết nối hoặc server
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
    }
  }

  Future<AuthResponse> signup(String phoneNumber, String password, String uuid) async {
    try {
      // Gửi request POST đăng ký
      final response = await _dioClient.dio.post(
        '/auth/signup',
        data: {
          'phone_number': phoneNumber,
          'password': password,
          'uuid': uuid, // Device ID
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi đăng ký');
    }
  }

  Future<void> logout(String token) async {
    try {
      // Gửi request POST kèm tham số token theo yêu cầu
      await _dioClient.dio.post(
        '/auth/logout',
        data: {
          'token': token,
        },
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối");
    }
  }

  Future<AuthResponse> checkVerifyCode(String phoneNumber, String resetCode) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/check_code_reset_password',
        data: {
          'phone_number': phoneNumber,
          'reset_code': resetCode,
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Mã xác thực không đúng");
    }
  }

  Future<AuthResponse> getUserInfo(String token) async {
    try {
      final response = await _dioClient.dio.post(
        '/users/get_user_info',
        data: {
          'token': token
          // Không truyền user_id để lấy thông tin của chính mình
        },
      );
      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi xác thực token");
    }
  }

}