
import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/ui/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'create_new_password_screen.dart';
import '../profile/change_info_after_signup_screen.dart';

class VerifyOtpScreen extends StatefulWidget{
  final String phoneNumber;
  final bool isForgotPassword;
  final String? tempOtp; // Mã OTP tạm thời từ BE

  const VerifyOtpScreen({
    super.key,
    required this.phoneNumber,
    this.isForgotPassword = false,
    this.tempOtp
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  // ---------------------------------------------------------------------
  // [!!!] ĐOẠN CODE CÀI ĐẶT TẠM THỜI CHO BE TRẢ VỀ OTP TRONG RESPONSE
  @override
  void initState() {
    super.initState();

    // Nếu có mã tạm từ BE thì tự động điền vào controller
    if (widget.tempOtp != null) {
      _otpController.text = widget.tempOtp!;

      // Thông báo cho đồng chí biết mã đã được điền tự động
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Mã xác thực tạm thời: ${widget.tempOtp}'))
        );
      });
    }
  }
  // [!!!] ----------------------------------------------------------[!!!]

  void _onVerifyPressed() {
    final otpCode = _otpController.text.trim();

    // Mã OTP gồm 6 ký tự (số kèm chữ)
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã xác thực phải gồm đúng 6 ký tự')),
      );
      return;
    }

    if (widget.isForgotPassword) {
      // GỌI LOGIC QUÊN MẬT KHẨU
      context.read<AuthBloc>().add(
        VerifyResetCodeRequested(phoneNumber: widget.phoneNumber, resetCode: otpCode),
      );
    } else {
      // GỌI LOGIC ĐĂNG KÝ
      context.read<AuthBloc>().add(
        VerifyOtpPressed(phoneNumber: widget.phoneNumber, code: otpCode),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if(state is VerifyResetCodeSuccess) {
            // NẾU LÀ QUÊN MẬT KHẨU THÌ CHUYỂN SANG MÀN ĐẶT PASS MỚI
            Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreateNewPasswordScreen(
                      phoneNumber: state.phoneNumber,
                      resetCode: state.resetCode
                    )
                )
            );
          } else if (state is AuthSuccess && !widget.isForgotPassword) {
            final navigator = Navigator.of(context);
            // Nếu backend trả về active == -1 -> yêu cầu user hoàn tất thông tin
            if (state.user.active == -1 && RegExp(r'^0[0-9]{9}$').hasMatch(state.user.username)) {
              final authBloc = context.read<AuthBloc>();

              navigator.push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: authBloc,
                    child: ChangeInfoAfterSignupScreen(currentUsername: state.user.username),
                  ),
                ),
              ).then((updatedUser) {
                if (updatedUser == null) return;
                // Sau khi quay về từ màn cập nhật, đi tới Home và xoá lịch sử
                navigator.pushAndRemoveUntil(
                    MaterialPageRoute(
                        builder: (context) => HomeScreen(
                            username: updatedUser != null ? updatedUser.username : state.user.username,
                            token: state.user.token
                        ),
                    ),
                    (route) => false
                );
              });

              return;
            }

            // XÁC THỰC THÀNH CÔNG -> Vào trang Home
            navigator.pushAndRemoveUntil(
                MaterialPageRoute(
                    builder: (context) => HomeScreen(
                        username: state.user.username,
                        token: state.user.token
                    ),
                ),
                (route) => false // Xóa hết lịch sử các màn hình Login/Signup trước đó
            );
          } else if (state is AuthFailure) {
            // XÁC THỰC THẤT BẠI -> Hiển thị thông báo lỗi
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.error}')),
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Xác thực OTP'),),
          body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const Icon(Icons.verified_user, size: 80, color: Colors.blue,),
                  const SizedBox(height: 20,),
                  Text('Nhập mã 6 ký tự được gửi đến:\n${widget.phoneNumber}',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30,),
                  TextField(
                    controller: _otpController,
                    decoration: const InputDecoration(
                      labelText: 'Mã xác thực',
                      border: OutlineInputBorder(),
                      counterText: "", // Ẩn dòng đếm ký tự mặc định
                    ),
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Sử dụng BlocBuilder để đổi trạng thái nút bấm (Loading)
                  BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return ElevatedButton(
                            onPressed: state is AuthLoading ? null : _onVerifyPressed,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(double.infinity, 50),
                              backgroundColor: Colors.blue,
                            ),
                            child: state is AuthLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('XÁC NHẬN', style: TextStyle(fontWeight: FontWeight.bold)),
                        );
                      }
                  ),
                ],
              ),
          ),
        ),
    );
  }
}