import 'package:army_ecommerce/core/constants/response_code.dart';
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

  Future<AuthResponse> checkCodeResetPassword(String phoneNumber, String resetCode) async {
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

  Future<AuthResponse> checkSignupCode(String phoneNumber, String code) async {
    // --- ĐOẠN MÃ GIẢ LẬP (PLACEHOLDER) ---
    // Giả lập thời gian chờ phản hồi từ server là 1 giây
    await Future.delayed(const Duration(seconds: 1));

    // Giả lập logic kiểm tra: Nếu mã là '123456' thì coi như thành công
    if (code == '123456') {
      return AuthResponse(
          code: '1000',
          message: 'Xác thực thành công',
          // Trả về data ảo để app không bị crash khi parse
        data: UserModel(id: 'temp', username: phoneNumber, token: 'temp_token', active: 1)
      );
    } else {
      return AuthResponse(code: ResponseCode.codeVerifyIncorrect.code, message: ResponseCode.codeVerifyIncorrect.message);
    }

    // // --- SAU NÀY KHI BACKEND XONG, MỞ COMMENT ĐOẠN NÀY VÀ XÓA ĐOẠN GIẢ LẬP TRÊN ---
    // try {
    //   final response = await _dioClient.dio.post(
    //     '/auth/check_signup_code', // Thay bằng endpoint thật của backend
    //     data: {
    //       'phone_number': phoneNumber,
    //       'code': code,
    //     },
    //   );
    //   return AuthResponse.fromJson(response.data);
    // } on DioException catch (e) {
    //   throw Exception(e.response?.data['message'] ?? "Lỗi xác thực");
    // }
  }

}