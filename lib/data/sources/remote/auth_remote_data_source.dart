// =============================================================================
// [GIẢI PHÁP TẠM THỜI: XỬ LÝ OTP]
// MÔ TẢ: Do Backend chưa cài đặt SMS Gateway nên OTP được trả về trực tiếp
// trong response của API 'create_code_reset_password'.
//
// TODO: KHI BACKEND HOÀN THIỆN SMS:
// 1. Xóa biến 'tempOtp' trong VerifyOtpScreen.
// 2. Sửa lại AuthRepository để trả về AuthResponse chuẩn thay vị Map.
// 3. Xóa logic tự động điền (auto-fill) trong initState của VerifyOtpScreen.
// =============================================================================


import 'package:army_ecommerce/core/network/api_exception.dart';
import 'dart:io';

import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/models/api_response.dart';
import 'package:army_ecommerce/models/user_model.dart';
import 'package:dio/dio.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/constants/api_paths.dart';

class AuthRemoteDataSource {
  final DioClient _dioClient;

  AuthRemoteDataSource({required DioClient dioClient}) : _dioClient = dioClient;

  Future<ApiResponse<UserModel>> login(String phoneNumber, String password) async {
    try {
      // Gửi request POST với SĐT và mật khẩu
      final response = await _dioClient.dio.post(
        ApiPaths.login,
        data: {
          'phone_number': phoneNumber,
          'password': password,
        },
      );

      return ApiResponse<UserModel>.fromJson(
        response.data,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

    } on DioException catch (e) {
      throw ApiException.fromResponse(
        data: e.response?.data,
        statusCode: e.response?.statusCode,
        fallbackMessage: e.message,
      );
    } catch (e) {
      throw Exception('Lỗi đăng nhâp: $e');
    }
  }

  Future<ApiResponse<UserModel>> signup(String phoneNumber, String password, String uuid) async {
    try {
      // Gửi request POST đăng ký
      final response = await _dioClient.dio.post(
        ApiPaths.signup,
        data: {
          'phone_number': phoneNumber,
          'password': password,
          'uuid': uuid, // Device ID
        },
      );

      return ApiResponse<UserModel>.fromJson(
        response.data,
        (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    } catch (e) {
      throw Exception('Lỗi đăng ký: $e');
    }
  }

  Future<void> logout(String token) async {
    try {
      // Gửi request POST kèm tham số token theo yêu cầu
      await _dioClient.dio.post(
        ApiPaths.logout,
        data: {
          'token': token,
        },
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
          },
        ),
      );
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    } catch (e) {
      throw Exception('Lỗi đăng xuất: $e');
    }
  }

  Future<ApiResponse<UserModel>> checkSignupCode(String phoneNumber, String code) async {
    // --- ĐOẠN MÃ GIẢ LẬP (PLACEHOLDER) ---
    // Giả lập thời gian chờ phản hồi từ server là 1 giây
    await Future.delayed(const Duration(seconds: 1));

    // Giả lập logic kiểm tra: Nếu mã là '123456' thì coi như thành công
    if (code == '123456') {
      return ApiResponse(
          code: '1000',
          message: 'Xác thực thành công',
          // Trả về data ảo để app không bị crash khi parse
          data: UserModel(id: 'temp', username: phoneNumber, token: 'temp_token', active: -1)
      );
    } else {
      return ApiResponse(
          code: ResponseCode.codeVerifyIncorrect.code,
          message: ResponseCode.codeVerifyIncorrect.message
      );
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
    //   return ApiResponse<UserModel>.fromJson(
    //      response.data,
    //      (json) => UserModel.fromJson(json as Map<String, dynamic>)
    //   );
    // } on DioException catch (e) {
    //   throw Exception(ApiException.getMessage(e));
    // } catch (e) {
    //   throw Exception('Lỗi kiểm tra OTP đăng ký: $e');
    // }
  }

  // Future<ApiResponse<String?>> createCodeResetPassword(String phoneNumber) async {
  //   // Gọi API tạo mã OTP quên mật khẩu
  //   try {
  //     final response = await _dioClient.dio.post(
  //       '/auth/create_code_reset_password',
  //       data: {
  //         'phone_number': phoneNumber
  //       }
  //     );
  //
  //     return ApiResponse<String?>.fromJson(
  //         response.data,
  //         (json) => json?.toString(),
  //     );
  //
  //   } on DioException catch (e) {
  //     throw Exception(ApiException.getMessage(e));
  //   } catch (e) {
  //     throw Exception('Lỗi tạo OTP: $e');
  //   }
  // }

  // [!!!] QUAN TRỌNG: ĐOẠN CODE TẠM THỜI ĐỂ LẤY OTP TRỰC TIẾP TỪ BE [!!!]
  // Sau này BE cài SMS xong, chỉ cần comment đoạn code dưới đây và mở đoạn code bên trên
  Future<Map<String, dynamic>> createCodeResetPassword(String phoneNumber) async {
    try {
      final response = await _dioClient.dio.post(
          ApiPaths.createCodeResetPassword,
          data: {
            'phone_number': phoneNumber
          }
      );

      return response.data;
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    }
  }
  // [!!!] HẾT ĐOẠN TẠM THỜI [!!!]

  Future<ApiResponse<String?>> checkCodeResetPassword(String phoneNumber, String resetCode) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.checkCodeResetPassword,
        data: {
          'phone_number': phoneNumber,
          'reset_code': resetCode,
        },
      );
      return ApiResponse<String?>.fromJson(
          response.data,
              (json) => json?.toString()
      );
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    } catch (e) {
      throw Exception('Lỗi kiểm tra OTP: $e');
    }
  }

  Future<ApiResponse<UserModel>> getUserInfo({
    required String token,
    Object? userId,
  }) async {
    try {
      final data = <String, dynamic>{
        'token': token,
        'user_id': userId ?? 0,
      };

      final response = await _dioClient.dio.post(
        ApiPaths.getUserInfo,
        data: data,
      );
      return ApiResponse<UserModel>.fromJson(
          response.data,
              (json) => UserModel.fromJson(json as Map<String, dynamic>)
      );
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    } catch (e) {
      throw Exception('Lỗi lấy thông tin người dùng: $e');
    }
  }

  Future<ApiResponse<UserModel>> resetPassword(String phoneNumber, String newPassword) async {
    try {
      final response = await _dioClient.dio.post(
          ApiPaths.resetPassword,
          data: {
            'phone_number': phoneNumber,
            'password': newPassword,
          }
      );

      return ApiResponse<UserModel>.fromJson(
          response.data,
              (json) => UserModel.fromJson(json as Map<String, dynamic>)
      );
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    } catch (e) {
      throw Exception('Lỗi đặt lại mật khẩu: $e');
    }
  }

  Future<ApiResponse<String>> changePassword({
    required String oldPassword,
    required String newPassword
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
          ApiPaths.changePassword,
          data: {
            'token': token,
            'password': oldPassword,
            'new_password': newPassword,
          }
      );

      return ApiResponse<String>.fromJson(
          response.data,
              (json) => json.toString()
      );
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    } catch (e) {
      throw Exception('Lỗi thay đổi mật khẩu: $e');
    }
  }

  /// Gửi device token (FCM / APNs) lên server để đăng ký thiết bị cho push notification
  /// devtype: '0' = iOS, '1' = Android
  Future<ApiResponse<String>> setDevToken({
    required String devToken,
    required String devType,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        ApiPaths.setDevToken,
        data: {
          'token': token,
          'devtype': devType,
          'devtoken': devToken,
        },
      );

      return ApiResponse<String>.fromJson(
          response.data,
              (json) => json.toString()
      );
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    } catch (e) {
      throw Exception('Lỗi thiết lập token thiết bị: $e');
    }
  }

  Future<ApiResponse<UserModel>> changeInfoAfterSignup({
    required String username,
    File? avatarFile,
  }) async {
    // Lấy token
    final token = await SessionManager.getToken();

    try {
      String? avatarUrl;

      // Nếu avatar được cung cấp, gửi nó cho BE '/upload/file'
      if (avatarFile != null) {
        final fileName = avatarFile.path.split(Platform.pathSeparator).last;
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            avatarFile.path,
            filename: fileName,
          ),
        });

        final uploadResponse = await _dioClient.dio.post(
          ApiPaths.uploadFile,
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
          ),
        );

        avatarUrl = uploadResponse.data?['data']?['url'] as String?;
      }

      final response = await _dioClient.dio.post(
        ApiPaths.changeInfoAfterSignup,
        data: {
          'token': token,
          'username': username,
          'avatar': avatarUrl,
        },
      );

      return ApiResponse<UserModel>.fromJson(
          response.data,
              (json) => UserModel.fromJson(json as Map<String, dynamic>)
      );
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    } catch (e) {
      throw Exception('Lỗi thay đổi thông tin: $e');
    }
  }

  Future<String?> _uploadFile(File? file) async {
    if (file == null) return null;

    final fileName = file.path.split(Platform.pathSeparator).last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(
        file.path,
        filename: fileName,
      ),
    });

    final uploadResponse = await _dioClient.dio.post(
      ApiPaths.uploadFile,
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
    );

    return uploadResponse.data?['data']?['url'] as String?;
  }

  Future<ApiResponse<UserModel>> setUserInfo({
    required UserModel currentUser,
    String? email,
    String? username,
    String? status,
    File? avatarFile,
    String? firstName,
    String? lastName,
    String? address,
    String? password,
    File? coverImageFile,
    File? coverImageWebFile,
    bool removeAvatar = false,
    bool removeCoverImage = false,
    bool removeCoverImageWeb = false,
  }) async {
    final token = await SessionManager.getToken();

    try {
      final avatarUrl = await _uploadFile(avatarFile);
      final coverImageUrl = await _uploadFile(coverImageFile);
      final coverImageWebUrl = await _uploadFile(coverImageWebFile);

      final payload = <String, dynamic>{
        'token': token,
      };

      if (email != null && email.trim().isNotEmpty) payload['email'] = email.trim();
      if (username != null && username.trim().isNotEmpty) payload['username'] = username.trim();
      if (status != null && status.trim().isNotEmpty) payload['status'] = status.trim();
      
      if (removeAvatar) {
        payload['avatar'] = "";
      } else if (avatarUrl != null) {
        payload['avatar'] = avatarUrl;
      }

      if (firstName != null && firstName.trim().isNotEmpty) payload['firstname'] = firstName.trim();
      if (lastName != null && lastName.trim().isNotEmpty) payload['lastname'] = lastName.trim();
      if (address != null && address.trim().isNotEmpty) payload['address'] = address.trim();
      if (password != null && password.trim().isNotEmpty) payload['password'] = password;
      
      if (removeCoverImage) {
        payload['cover_image'] = "";
      } else if (coverImageUrl != null) {
        payload['cover_image'] = coverImageUrl;
      }

      if (removeCoverImageWeb) {
        payload['cover_image_web'] = "";
      } else if (coverImageWebUrl != null) {
        payload['cover_image_web'] = coverImageWebUrl;
      }

      final response = await _dioClient.dio.post(
        ApiPaths.setUserInfo,
        data: payload,
      );

      final parsedResponse = ApiResponse<UserModel>.fromJson(
        response.data,
            (json) => UserModel.fromJson(json as Map<String, dynamic>),
      );

      final responseCode = ResponseCode.fromCode(parsedResponse.code);

      if (responseCode == ResponseCode.ok && parsedResponse.data == null) {
        final fallbackUser = currentUser.copyWith(
          token: token ?? currentUser.token,
          username: username ?? currentUser.username,
          avatar: removeAvatar ? "" : (avatarUrl ?? currentUser.avatar),
          email: email ?? currentUser.email,
          status: status ?? currentUser.status,
          firstName: firstName ?? currentUser.firstName,
          lastName: lastName ?? currentUser.lastName,
          address: address ?? currentUser.address,
          coverImage: removeCoverImage ? "" : (coverImageUrl ?? currentUser.coverImage),
          coverImageWeb: removeCoverImageWeb ? "" : (coverImageWebUrl ?? currentUser.coverImageWeb),
        );

        return ApiResponse<UserModel>(
          code: parsedResponse.code,
          message: parsedResponse.message,
          data: fallbackUser,
        );
      }

      if (responseCode == ResponseCode.ok && parsedResponse.data != null) {
        final mergedUser = parsedResponse.data!.copyWith(
          token: token ?? parsedResponse.data!.token,
          username: username?.trim().isNotEmpty == true ? username!.trim() : (parsedResponse.data!.username.isNotEmpty ? parsedResponse.data!.username : currentUser.username),
          avatar: removeAvatar ? "" : (avatarUrl ?? (parsedResponse.data!.avatar ?? currentUser.avatar)),
          email: email?.trim().isNotEmpty == true ? email!.trim() : (parsedResponse.data!.email ?? currentUser.email),
          status: status?.trim().isNotEmpty == true ? status!.trim() : (parsedResponse.data!.status ?? currentUser.status),
          firstName: firstName?.trim().isNotEmpty == true ? firstName!.trim() : (parsedResponse.data!.firstName ?? currentUser.firstName),
          lastName: lastName?.trim().isNotEmpty == true ? lastName!.trim() : (parsedResponse.data!.lastName ?? currentUser.lastName),
          address: address?.trim().isNotEmpty == true ? address!.trim() : (parsedResponse.data!.address ?? currentUser.address),
          coverImage: removeCoverImage ? "" : (coverImageUrl ?? (parsedResponse.data!.coverImage ?? currentUser.coverImage)),
          coverImageWeb: removeCoverImageWeb ? "" : (coverImageWebUrl ?? (parsedResponse.data!.coverImageWeb ?? currentUser.coverImageWeb)),
        );

        return ApiResponse<UserModel>(
          code: parsedResponse.code,
          message: parsedResponse.message,
          data: mergedUser,
        );
      }

      return parsedResponse;
    } on DioException catch (e) {
      throw Exception(ApiException.getMessage(e));
    } catch (e) {
      throw Exception('Lỗi cập nhật thông tin người dùng: $e');
    }
  }
}
