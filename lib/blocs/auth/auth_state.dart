import 'package:army_ecommerce/models/user_model.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Trạng thái khi người dùng chưa đăng nhập
class AuthInitial extends AuthState {}

// Trạng thái khi người dùng đang đăng nhập (hiển thị vòng xoay loading)
class AuthLoading extends AuthState {}

// Trạng thái khi người dùng đã đăng nhập thành công
class AuthSuccess extends AuthState {
  final UserModel user;

  AuthSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

// Trạng thái khi đăng nhập thất bại (hiển thị popup/toast lỗi)
class AuthFailure extends AuthState {
  final String error;
  final String code; // Thêm mã lỗi để hiển thị chính xác theo requirement

  AuthFailure({required this.error, required this.code});

  @override
  List<Object?> get props => [error, code];
}

class AuthSignupSuccess extends AuthState {
  final String phoneNumber; // Truyền SĐT sang màn hình OTP để người dùng biết

  AuthSignupSuccess({required this.phoneNumber});

  @override
  List<Object?> get props => [phoneNumber];
}

// Trạng thái báo hiệu đã đăng xuất thành công khỏi thiết bị
class AuthLogoutSuccess extends AuthState {}

// Trạng thái xác định người dùng chưa đăng nhập hoặc token hết hạn
class Unauthenticated extends AuthState {}

// Trạng thái báo hiệu mã OTP đã được gửi thành công
class ForgotPasswordCodeSent extends AuthState {
  final String phoneNumber;
  final String otp; // Biến tạm để giữ mã OTP từ BE trả về
  ForgotPasswordCodeSent({required this.phoneNumber, required this.otp});

  @override
  List<Object?> get props => [phoneNumber, otp];
}

class VerifyResetCodeSuccess extends AuthState {
  final String phoneNumber;
  final String resetCode; // Giữ lại mã code để gửi kèm ở bước Reset mật khẩu cuối cùng

  VerifyResetCodeSuccess({required this.phoneNumber, required this.resetCode});

  @override
  List<Object?> get props => [phoneNumber, resetCode];
}

// Trạng thái báo hiệu đã đặt lại mật khẩu thành công
class ResetPasswordSuccess extends AuthState {
  final UserModel user;

  ResetPasswordSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class ChangePasswordSuccess extends AuthState {}

class OldPasswordVerifySuccess extends AuthState {} // Cho phép sang bước 2

class ChangeInfoSuccess extends AuthState {
  final UserModel updatedUser; // Chứa thông tin và link avatar mới

  ChangeInfoSuccess({required this.updatedUser});

  @override
  List<Object?> get props => [updatedUser];
}