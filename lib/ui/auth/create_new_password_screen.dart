import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/models/user_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CreateNewPasswordScreen extends StatefulWidget {
  final String phoneNumber;
  final String resetCode; // Mã OTP từ bước trước

  const CreateNewPasswordScreen({super.key, required this.phoneNumber, required this.resetCode});

  @override
  State<CreateNewPasswordScreen> createState() => _CreateNewPasswordScreenState();
}

class _CreateNewPasswordScreenState extends State<CreateNewPasswordScreen> {
  final TextEditingController _passController = TextEditingController();
  bool _isObscure = true;

  // Hàm validate mật khẩu
  String? _validatePassword(String pass) {
    if (pass.length < 6 || pass.length > 10) return "Mật khẩu phải từ 6-10 ký tự";
    // if (!RegExp(r'[A-Z]').hasMatch(pass)) return "Cần ít nhất 1 ký tự viết HOA";
    // if (!RegExp(r'[a-z]').hasMatch(pass)) return "Cần ít nhất 1 ký tự viết thường";
    return null;
  }

  void _onConfirm() {
    final pass = _passController.text.trim();
    final error = _validatePassword(pass);

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      return;
    }

    context.read<AuthBloc>().add(
      ResetPasswordRequested(phoneNumber: widget.phoneNumber, newPassword: pass),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is ResetPasswordSuccess) {
            _showSuccessAndGoHome(context, state.user);
          } else if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Thiết lập mật khẩu'),),
          body: Padding(
              padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                const Text('Tạo mật khẩu mới cho tài khoản quân nhân', style: TextStyle(fontSize: 18)),
                const SizedBox(height: 30),
                TextField(
                  controller: _passController,
                  obscureText: _isObscure,
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu mới',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                        onPressed: () => setState(() => _isObscure = !_isObscure),
                        icon: Icon(_isObscure ? Icons.visibility_off : Icons.visibility)
                    ),
                  ),
                ),
                const SizedBox(height: 40,),
                ElevatedButton(
                    onPressed: _onConfirm,
                    style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
                    child: const Text('TIẾP THEO')
                ),
              ],
            ),
          ),
        ),
    );
  }
  void _showSuccessAndGoHome(BuildContext context, UserModel user) {
    final navigator = Navigator.of(context);
    final authBloc = context.read<AuthBloc>();

    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text(
                  'ĐẶT LẠI MẬT KHẨU THÀNH CÔNG',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.bold)
              ),
              const SizedBox(height: 10),
              Text('Chào đồng chí ${user.username}, hệ thống sẽ được kết nối sau 2 giây...'),
            ],
          ),
        )
    );

    // Chờ 2 giây để quân nhân kịp đọc thông báo rồi tự động vào Home
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;

      // Đóng dialog
      navigator.pop();

      // Quay về root screen (LoginScreen)
      navigator.popUntil((route) => route.isFirst);

      // Phát sự kiện AppStarted để tự động đăng nhập với token mới và chuyển tới HomeScreen
      authBloc.add(AppStarted());
    });
  }
}