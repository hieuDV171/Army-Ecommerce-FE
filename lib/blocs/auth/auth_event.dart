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
