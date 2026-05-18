import 'dart:io';


import '../models/api_response.dart';
import '../models/user_model.dart';

abstract class AuthRepository {
  Future<ApiResponse<UserModel>> login(String phoneNumber, String password);
  Future<ApiResponse<UserModel>> signup(String phoneNumber, String password, String uuid);
  Future<void> logout(String token);
  Future<ApiResponse<UserModel>> checkSignupCode(String phoneNumber, String code);
  Future<Map<String, dynamic>> createCodeResetPassword(String phoneNumber);
  Future<ApiResponse<String?>> checkCodeResetPassword(String phoneNumber, String resetCode);
  Future<ApiResponse<UserModel>> getUserInfo({required String token, Object? userId});
  Future<ApiResponse<UserModel>> resetPassword(String phoneNumber, String newPassword);
  Future<ApiResponse<String>> changePassword({required String oldPassword, required String newPassword});
  Future<ApiResponse<String>> setDevToken({required String devToken, required String devType});
  Future<ApiResponse<UserModel>> changeInfoAfterSignup({required String username, File? avatarFile});
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
  });
}