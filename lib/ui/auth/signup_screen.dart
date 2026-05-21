import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/ui/home/home_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Hàm kiểm tra định dạng dữ liệu trước khi gửi lên server[cite: 1]
  String? _validateData(String phone, String pass) {
    // 1. Kiểm tra trống[cite: 1]
    if (phone.isEmpty || pass.isEmpty) return "Các ô không được để trống";

    // 2. Kiểm tra định dạng SĐT (VD: phải có số 0 ở đầu, đủ 10 số)[cite: 1]
    if (!RegExp(r'^0[0-9]{9}$').hasMatch(phone)) {
      return "Số điện thoại không đúng định dạng";
    }

    // 3. Kiểm tra độ dài mật khẩu (6-10 ký tự)[cite: 1]
    if (pass.length < 6 || pass.length > 10) {
      return "Mật khẩu phải từ 6 đến 10 ký tự";
    }

    // 4. Mật khẩu không được trùng số điện thoại
    if (pass == phone) {
      return "Mật khẩu không được trùng với số điện thoại";
    }

    return null; // Dữ liệu hợp lệ
  }

  void _onSignupPressed() {
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text.trim();

    // Chạy bộ kiểm tra tại app trước
    final error = _validateData(phone, pass);
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar((SnackBar(content: Text(error),)));
      return;
    }

    // Tạo UUID ngẫu nhiên cho thiết bị
    var uuid = const Uuid().v4();
    
    context.read<AuthBloc>().add(
      SignupButtonPressed(phoneNumber: phone, password: pass, uuid: uuid),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Đăng ký'),),
      body: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSignupSuccess) {
              // Đăng ký thành công -> Chuyển sang màn hình xác thực OTP
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đăng ký thành công, vui lòng đăng nhập')),
              );
              Navigator.pop(context);
            } else if (state is AuthSuccess) {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => HomeScreen(
                    username: state.user.username,
                    token: state.user.token,
                  ),
                ),
                (route) => false,
              );
            } else if (state is AuthFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Lỗi: ${state.error}"))
              );
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              children: [
                TextField(
                  controller: _phoneController,
                  decoration: const InputDecoration(labelText: "Số điện thoại"),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 20,),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(labelText: 'Mật khẩu (6-10 ký tự)'),
                  obscureText: true,
                ),
                const SizedBox(height: 30,),
                ElevatedButton(
                    onPressed: _onSignupPressed,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                      backgroundColor: Colors.deepOrangeAccent
                    ),
                    child: const Text('TIẾP THEO'),
                ),
              ],
            ),
          ),
      )
    );
  }
}
