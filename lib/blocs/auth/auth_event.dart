
import 'dart:io';

import 'package:army_ecommerce/models/user_model.dart';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Sự kiện khi người dùng bấm nút "Đăng nhập"
class LoginButtonPressed extends AuthEvent {
  final String phoneNumber;
  final String password;

  LoginButtonPressed({required this.phoneNumber, required this.password});

  @override
  List<Object?> get props => [phoneNumber, password];
}

class SignupButtonPressed extends AuthEvent {
  final String phoneNumber;
  final String password;
  final String uuid;

  SignupButtonPressed({
    required this.phoneNumber,
    required this.password,
    required this.uuid
  });

  @override
  List<Object?> get props => [phoneNumber, password, uuid];
}

class LogoutButtonPressed extends AuthEvent {
  final String token;

  LogoutButtonPressed({required this.token});

  @override
  List<Object?> get props => [token];
}

// Sự kiện kiểm tra trạng thái khi vừa mở App
class AppStarted extends AuthEvent {}

class VerifyOtpPressed extends AuthEvent {
  final String phoneNumber;
  final String password;
  final String code;

  VerifyOtpPressed({required this.phoneNumber, required this.password, required this.code});

  @override
  List<Object?> get props => [phoneNumber, password, code];
}

// Sự kiện yêu cầu gửi mã OTP quên mật khẩu
class ForgotPasswordRequested extends AuthEvent {
  final String phoneNumber;
  ForgotPasswordRequested({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

// Sự kiện xác thực mã OTP quên mật khẩu
class VerifyResetCodeRequested extends AuthEvent {
  final String phoneNumber;
  final String resetCode;

  VerifyResetCodeRequested({required this.phoneNumber, required this.resetCode});

  @override
  List<Object?> get props => [phoneNumber, resetCode];
}

class ResetPasswordRequested extends AuthEvent {
  final String phoneNumber;
  final String newPassword;

  ResetPasswordRequested({required this.phoneNumber, required this.newPassword});

  @override
  List<Object?> get props => [phoneNumber, newPassword];
}

class ChangePasswordRequested extends AuthEvent {
  final String oldPassword;
  final String newPassword;

  ChangePasswordRequested({required this.oldPassword, required this.newPassword});

  @override
  List<Object?> get props => [oldPassword, newPassword];
}

class VerifyOldPasswordRequested extends AuthEvent {
  final String oldPassword;
  VerifyOldPasswordRequested({required this.oldPassword});
}

class ChangeInfoRequested extends AuthEvent {
  final String username;
  final File? avatarFile;

  ChangeInfoRequested({required this.username, this.avatarFile});

  @override
  List<Object?> get props => [username, avatarFile];
}

class GetUserInfoRequested extends AuthEvent {
  final int? userId;

  GetUserInfoRequested({this.userId});

  @override
  List<Object?> get props => [userId];
}

class SetUserInfoRequested extends AuthEvent {
  final UserModel currentUser;
  final String? email;
  final String? username;
  final String? status;
  final File? avatarFile;
  final String? firstName;
  final String? lastName;
  final String? address;
  final String? password;
  final File? coverImageFile;
  final File? coverImageWebFile;

  SetUserInfoRequested({
    required this.currentUser,
    this.email,
    this.username,
    this.status,
    this.avatarFile,
    this.firstName,
    this.lastName,
    this.address,
    this.password,
    this.coverImageFile,
    this.coverImageWebFile,
  });

  @override
  List<Object?> get props => [
        currentUser,
        email,
        username,
        status,
        avatarFile,
        firstName,
        lastName,
        address,
        password,
        coverImageFile,
        coverImageWebFile,
      ];
}

