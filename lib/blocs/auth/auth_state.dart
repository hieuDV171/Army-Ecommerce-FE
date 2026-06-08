import 'package:army_ecommerce/models/user_model.dart';
import 'package:equatable/equatable.dart';

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];

  // Thêm helper getters để lấy thông tin user hiện tại và kiểm tra đăng nhập
  UserModel? get currentUser {
    final state = this;
    if (state is AuthSuccess) return state.user;
    if (state is GetUserInfoSuccess) return state.user;
    if (state is SetUserInfoSuccess) return state.user;
    if (state is ChangeInfoSuccess) return state.updatedUser;
    if (state is ResetPasswordSuccess) return state.user;
    return null;
  }

  bool get isAuthenticated => currentUser != null && currentUser!.token.isNotEmpty;
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
  final String phoneNumber;
  final String password; // Mật khẩu đăng ký dùng để tự động đăng nhập sau OTP

  AuthSignupSuccess({required this.phoneNumber, required this.password});

  @override
  List<Object?> get props => [phoneNumber, password];
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

class GetUserInfoLoading extends AuthState {}

class GetUserInfoSuccess extends AuthState {
  final UserModel user;

  GetUserInfoSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class GetUserInfoFailure extends AuthState {
  final String error;
  final String code;

  GetUserInfoFailure({required this.error, required this.code});

  @override
  List<Object?> get props => [error, code];
}

class SetUserInfoLoading extends AuthState {}

class SetUserInfoSuccess extends AuthState {
  final UserModel user;

  SetUserInfoSuccess({required this.user});

  @override
  List<Object?> get props => [user];
}

class SetUserInfoFailure extends AuthState {
  final String error;
  final String code;

  SetUserInfoFailure({required this.error, required this.code});

  @override
  List<Object?> get props => [error, code];
}

