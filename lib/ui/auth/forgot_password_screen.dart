import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/ui/auth/verify_otp_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _phoneController = TextEditingController();

  void _onSubmit() {
    final phone = _phoneController.text.trim();
    // Validate cơ bản tại client: bắt đầu bằng số 0 và đủ 10 số
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Số điện thoại không hợp lệ')),
      );
      return;
    }

    // Gửi sự kiện vào BLoC
    context.read<AuthBloc>().add(ForgotPasswordRequested(phoneNumber: phone));
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ForgotPasswordCodeSent) {
            // Gửi mã OK -> Chuyển sang màn hình nhập OTP
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => VerifyOtpScreen(
                    phoneNumber: state.phoneNumber,
                    isForgotPassword: true, // Đánh dấu đây là luồng quên mật khẩu
                  // ---------------------------------------------
                    tempOtp: state.otp, // OTP từ response BE
                  // ----------------------------------------------
                ),
              ),
            );
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.error}'))
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Đặt lại mật khẩu'),),
          body: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                    'Nhập số điện thoại đã đăng ký để nhận mã xác thực OTP.',
                  style: TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 30,),
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.phone),
                  ),
                ),
                const SizedBox(height: 30,),
                BlocBuilder<AuthBloc, AuthState>(
                  builder: (context, state) {
                    return ElevatedButton(
                        onPressed: state is AuthLoading ? null : _onSubmit,
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepOrangeAccent,
                            minimumSize: const Size(double.infinity, 50),
                        ),
                        child: state is AuthLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('TIẾP THEO')
                    );
                  },
                ),
              ],
            ),
          )
        ),
    );
  }
}