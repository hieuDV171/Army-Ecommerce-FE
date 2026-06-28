import 'dart:io';

import 'package:army_ecommerce/models/api_response.dart';
import 'package:army_ecommerce/models/user_model.dart';

import '../../data/sources/remote/auth_remote_data_source.dart';
import '../../repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ApiResponse<UserModel>> login(String phoneNumber, String password) {
    return remoteDataSource.login(phoneNumber, password);
  }

  @override
  Future<ApiResponse<UserModel>> signup(
    String phoneNumber,
    String password,
    String uuid,
  ) {
    return remoteDataSource.signup(phoneNumber, password, uuid);
  }

  @override
  Future<void> logout(String token) {
    return remoteDataSource.logout(token);
  }

  @override
  Future<ApiResponse<UserModel>> checkSignupCode(
    String phoneNumber,
    String code,
  ) {
    return remoteDataSource.checkSignupCode(phoneNumber, code);
  }

  @override
  Future<Map<String, dynamic>> createCodeResetPassword(String phoneNumber) {
    return remoteDataSource.createCodeResetPassword(phoneNumber);
  }

  @override
  Future<ApiResponse<String?>> checkCodeResetPassword(
    String phoneNumber,
    String resetCode,
  ) {
    return remoteDataSource.checkCodeResetPassword(phoneNumber, resetCode);
  }

  @override
  Future<ApiResponse<UserModel>> getUserInfo({
    required String token,
    Object? userId,
  }) {
    return remoteDataSource.getUserInfo(token: token, userId: userId);
  }

  @override
  Future<ApiResponse<UserModel>> resetPassword(
    String phoneNumber,
    String newPassword,
  ) {
    return remoteDataSource.resetPassword(phoneNumber, newPassword);
  }

  @override
  Future<ApiResponse<String>> changePassword({
    required String oldPassword,
    required String newPassword,
  }) {
    return remoteDataSource.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
  }

  @override
  Future<ApiResponse<String>> setDevToken({
    required String devToken,
    required String devType,
  }) {
    return remoteDataSource.setDevToken(devToken: devToken, devType: devType);
  }

  @override
  Future<ApiResponse<UserModel>> changeInfoAfterSignup({
    required String username,
    File? avatarFile,
  }) {
    return remoteDataSource.changeInfoAfterSignup(
      username: username,
      avatarFile: avatarFile,
    );
  }

  @override
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
  }) {
    return remoteDataSource.setUserInfo(
      currentUser: currentUser,
      email: email,
      username: username,
      status: status,
      avatarFile: avatarFile,
      firstName: firstName,
      lastName: lastName,
      address: address,
      password: password,
      coverImageFile: coverImageFile,
      coverImageWebFile: coverImageWebFile,
      removeAvatar: removeAvatar,
      removeCoverImage: removeCoverImage,
      removeCoverImageWeb: removeCoverImageWeb,
    );
  }
}
