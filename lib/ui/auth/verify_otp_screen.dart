
import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/ui/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class VerifyOtpScreen extends StatefulWidget{
  final String phoneNumber;

  const VerifyOtpScreen({super.key, required this.phoneNumber});

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();

  void _onVerifyPressed() {
    final otpCode = _otpController.text.trim();

    // Mã OTP gồm 6 ký tự (số kèm chữ)
    if (otpCode.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mã xác thực phải gồm đúng 6 ký tự')),
      );
      return;
    }

    // Bắn sự kiện xác thực vào BLoC
    context.read<AuthBloc>().add(
      VerifyOtpPressed(phoneNumber: widget.phoneNumber, code: otpCode),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            // XÁC THỰC THÀNH CÔNG -> Vào trang Home
            Navigator.pushAndRemoveUntil(
                context,
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