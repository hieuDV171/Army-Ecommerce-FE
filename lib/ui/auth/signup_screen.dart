import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/ui/auth/verify_otp_screen.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter/material.dart';

import '../util/widgets/app_button.dart';
import '../util/widgets/app_text_field.dart';
import '../util/theme/special_app_theme.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  String? _phoneError;
  String? _passwordError;
  String? _confirmPasswordError;

  @override
  void initState() {
    super.initState();
    _phoneController.addListener(() {
      if (_phoneError != null) {
        setState(() {
          _phoneError = null;
        });
      }
    });
    _passwordController.addListener(() {
      if (_passwordError != null) {
        setState(() {
          _passwordError = null;
        });
      }
    });
    _confirmPasswordController.addListener(() {
      if (_confirmPasswordError != null) {
        setState(() {
          _confirmPasswordError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _onSignupPressed() {
    final phone = _phoneController.text.trim();
    final pass = _passwordController.text.trim();
    final confirmPass = _confirmPasswordController.text.trim();

    setState(() {
      // 1. Kiểm tra Số điện thoại
      if (phone.isEmpty) {
        _phoneError = "Số điện thoại không được để trống";
      } else if (!RegExp(r'^(?:\+84|84|0)[0-9]{9}$').hasMatch(phone)) {
        _phoneError = "Số điện thoại không đúng định dạng";
      } else {
        _phoneError = null;
      }

      // 2. Kiểm tra Mật khẩu
      if (pass.isEmpty) {
        _passwordError = "Mật khẩu không được để trống";
      } else if (pass.length < 6 || pass.length > 10) {
        _passwordError = "Mật khẩu phải từ 6 đến 10 ký tự";
      } else if (pass == phone) {
        _passwordError = "Mật khẩu không được trùng với số điện thoại";
      } else {
        _passwordError = null;
      }

      // 3. Kiểm tra Xác nhận mật khẩu
      if (confirmPass.isEmpty) {
        _confirmPasswordError = "Xác nhận mật khẩu không được để trống";
      } else if (pass != confirmPass) {
        _confirmPasswordError = "Mật khẩu xác nhận không khớp";
      } else {
        _confirmPasswordError = null;
      }
    });

    if (_phoneError != null || _passwordError != null || _confirmPasswordError != null) {
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
    final specialTheme = context.specialTheme;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: specialTheme.useGradient ? Colors.transparent : specialTheme.primaryDarkColor,
        flexibleSpace: specialTheme.useGradient
            ? Container(
                decoration: BoxDecoration(
                  gradient: specialTheme.primaryGradient,
                ),
              )
            : null,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Đăng ký', style: TextStyle(color: Colors.white, fontSize: 16)),
      ),
      body: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthSignupSuccess) {
              // Đăng ký thành công -> Chuyển sang màn hình xác thực OTP
              AppSnackBar.showSuccess(context, message: 'Đăng ký thành công, vui lòng xác thực OTP');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => VerifyOtpScreen(
                    phoneNumber: state.phoneNumber,
                    isForgotPassword: false,
                    password: state.password,
                  ),
                ),
              );
            } else if (state is AuthSuccess) {
              // Không điều hướng trực tiếp — main.dart sẽ tự xử lý khi nhận AuthSuccess
              AppSnackBar.showSuccess(context, message: 'Xác thực thành công!');
            } else if (state is AuthFailure) {
              AppSnackBar.showError(context, message: "Lỗi: ${state.error}");
            }
          },
          builder: (context, state) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  AppTextField(
                    controller: _phoneController,
                    label: "Số điện thoại",
                    keyboardType: TextInputType.phone,
                    errorText: _phoneError,
                  ),
                  const SizedBox(height: 20,),
                  AppTextField(
                    controller: _passwordController,
                    label: 'Mật khẩu (6-10 ký tự)',
                    obscureText: true,
                    errorText: _passwordError,
                  ),
                  const SizedBox(height: 20,),
                  AppTextField(
                    controller: _confirmPasswordController,
                    label: 'Xác nhận mật khẩu',
                    obscureText: true,
                    errorText: _confirmPasswordError,
                  ),
                  const SizedBox(height: 30,),
                  AppButton(
                    label: 'TIẾP THEO',
                    isLoading: state is AuthLoading,
                    onPressed: _onSignupPressed,
                  ),
                ],
              ),
            );
          },
      ),
    );
  }
}
