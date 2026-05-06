// =============================================================================
// [GIẢI PHÁP TẠM THỜI: XỬ LÝ OTP]
// MÔ TẢ: Do Backend chưa cài đặt SMS Gateway nên OTP được trả về trực tiếp
// trong response của API 'create_code_reset_password'.
//
// TODO: KHI BACKEND HOÀN THIỆN SMS:
// 1. Xóa biến 'tempOtp' trong VerifyOtpScreen.
// 2. Sửa lại AuthRepository để trả về AuthResponse chuẩn thay vì Map.
// 3. Xóa logic tự động điền (auto-fill) trong initState của VerifyOtpScreen.
// =============================================================================


import 'dart:io';

import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/models/user_model.dart';
import 'package:dio/dio.dart';

import '../core/api/dio_client.dart';
import '../core/services/cloudinary_service.dart';

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
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
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
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
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
    //   throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
    // }
  }

  // Future<AuthResponse> createCodeResetPassword(String phoneNumber) async {
  //   // Gọi API tạo mã OTP quên mật khẩu
  //   try {
  //     final response = await _dioClient.dio.post(
  //       '/auth/create_code_reset_password',
  //       data: {
  //         'phone_number': phoneNumber
  //       }
  //     );
  //
  //     return AuthResponse.fromJson(response.data);
  //   } on DioException catch (e) {
  //     throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
  //   }
  // }

  // [!!!] QUAN TRỌNG: ĐOẠN CODE TẠM THỜI ĐỂ LẤY OTP TRỰC TIẾP TỪ BE [!!!]
  // Sau này BE cài SMS xong, chỉ cần comment đoạn code dưới đây và mở đoạn code bên trên
  Future<Map<String, dynamic>> createCodeResetPassword(String phoneNumber) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/create_code_reset_password',
        data: {
          'phone_number': phoneNumber
        }
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
    }
  }
  // [!!!] HẾT ĐOẠN TẠM THỜI [!!!]

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
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
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
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
    }
  }

  Future<AuthResponse> resetPassword(String phoneNumber, String newPassword) async {
    try {
      final response = await _dioClient.dio.post(
        '/auth/reset_password',
        data: {
          'phone_number': phoneNumber,
          'password': newPassword,
        }
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
    }
  }

  Future<AuthResponse> changePassword({
    required String oldPassword,
    required String newPassword
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        '/auth/change_password',
        data: {
          'token': token,
          'password': oldPassword,
          'new_password': newPassword,
        }
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
    }
  }

  /// Gửi device token (FCM / APNs) lên server để đăng ký thiết bị cho push notification
  /// devtype: '0' = iOS, '1' = Android
  Future<AuthResponse> setDevToken({
    required String devToken,
    required String devType,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        '/dev_tokens/set_devtoken',
        data: {
          'token': token,
          'devtype': devType,
          'devtoken': devToken,
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
    }
  }

  Future<AuthResponse> changeInfoAfterSignup({
    required String username,
    File? avatarFile,
  }) async {
    // Lấy token
    final token = await SessionManager.getToken();

    try {
      String? avatarUrl;

      if (avatarFile != null) {
        final cloudinary = CloudinaryService();
        avatarUrl = await cloudinary.uploadImageFile(
          file: avatarFile,
          folder: 'users',
        );
      }
      
      final response = await _dioClient.dio.post(
        '/auth/change_info_after_signup',
        data: {
          'token': token,
          'username': username,
          'avatar': ?avatarUrl,
        },
      );

      return AuthResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? "Lỗi kết nối mạng");
    } catch (e) {
      throw Exception('Lỗi thay đổi thông tin: $e');
    }
  }

}