import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/ui/auth/forgot_password_screen.dart';
import 'package:army_ecommerce/ui/auth/signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../home/home_screen.dart';
import '../profile/change_info_after_signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controller để lấy dữ liệu người dùng nhập vào ô text
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Biến để quản lý trạng thái ẩn/hiện mật khẩu
  bool _isObscure = true;

  @override
  void dispose() {
    // Luôn nhớ giải phóng controller khi đóng màn hình để tránh rò rỉ bộ nhớ
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Hàm gọi sự kiện đăng nhập
  void _onLoginPressed() {
    // Loại bỏ khoảng trắng ở 2 đầu
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    if (phone.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin'),)
      );
      return;
    }

    // Bắn sự kiện LoginButtonPressed vào AuthBloc
    context.read<AuthBloc>().add(
      LoginButtonPressed(phoneNumber: phone, password: password)
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Đăng nhập', style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      // BlocConsumer vừa lắng nghe trạng thái (listener), vừa vẽ lại UI (builder)
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          final navigator = Navigator.of(context);
          // Xử lý các logic điều hướng hoặc hiển thị thông báo ở đây
          if (state is AuthSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Đăng nhập thành công!'),)
            );

            // Nếu backend trả về active == -1 -> yêu cầu user hoàn tất thông tin
            if (state.user.active == -1) {
              final authBloc = context.read<AuthBloc>();

              // Chuyển sang màn hình cập nhật thông tin (đã được cài đặt).
              // Sau khi màn cập nhật đóng lại, chuyển tiếp đến Home.
              navigator.push(
                MaterialPageRoute(
                  builder: (context) => BlocProvider.value(
                    value: authBloc,
                    child: ChangeInfoAfterSignupScreen(currentUsername: state.user.username),
                  ),
                ),
              ).then((updatedUser) {
                // Chỉ cho vào Home khi đã cập nhật xong và màn này trả về user hợp lệ
                if (updatedUser == null) return;
                navigator.pushReplacement(
                  MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      username: updatedUser != null ? updatedUser.username : state.user.username,
                      token: state.user.token,
                    ),
                  ),
                );
              });

              return; // tránh chạy phần điều hướng Home mặc định phía dưới
            }

            // Chuyển sang màn hình Home
            navigator.pushReplacement(
                MaterialPageRoute(
                    builder: (_) => HomeScreen(
                      username: state.user.username,
                      token: state.user.token,
                    )
                )
            );
          } else if (state is AuthFailure) {
            // Hiển thị lỗi từ API trả về
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.error}'),)
            );
          }
        },
        builder: (context, state) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),
                // Ô nhập Số điện thoại
                TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Số điện thoại',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),
                // Ô nhập Mật khẩu
                TextField(
                  controller: _passwordController,
                  obscureText: _isObscure, // Ẩn/hiện mật khẩu
                  decoration: InputDecoration(
                    labelText: 'Mật khẩu',
                    border: const OutlineInputBorder(),
                    // Icon để toggle ẩn/hiện mật khẩu
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isObscure ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () {
                        setState(() {
                          _isObscure = !_isObscure;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 30),

                // Nút Đăng nhập
                SizedBox(
                  height: 50,
                  // Nếu đang loading thì vô hiệu hóa nút (null), ngược lại thì gọi _onLoginPressed
                  child: ElevatedButton(
                      onPressed: state is AuthLoading ? null : _onLoginPressed,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.deepOrangeAccent,
                      ),
                      child: state is AuthLoading
                          ? const CircularProgressIndicator(
                              color: Colors.white,
                            )
                          : const Text(
                            'Đăng nhập',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
                // Nút Quên mật khẩu & Đăng ký
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const ForgotPasswordScreen()));
                        },
                        child: const Text('Quên mật khẩu'),
                    ),
                    TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const SignupScreen()),
                          );
                        },
                        child: const Text('Đăng ký'),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      )
    );
  }
}