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
