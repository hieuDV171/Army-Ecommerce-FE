import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'create_new_password_screen.dart';
import '../util/widgets/app_button.dart';
import '../util/theme/special_app_theme.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

class VerifyOtpScreen extends StatefulWidget{
  final String phoneNumber;
  final bool isForgotPassword;
  final String? tempOtp; // Mã OTP tạm thời từ BE
  final String? password; // Mật khẩu dùng để login ngầm

  const VerifyOtpScreen({
    super.key,
    required this.phoneNumber,
    this.isForgotPassword = false,
    this.tempOtp,
    this.password,
  });

  @override
  State<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  String? _otpError;

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
        AppSnackBar.show(context, message: 'Mã xác thực tạm thời: ${widget.tempOtp}');
      });
    }

    _otpController.addListener(() {
      if (_otpError != null) {
        setState(() {
          _otpError = null;
        });
      }
    });
  }
  // [!!!] ----------------------------------------------------------[!!!]

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  void _onVerifyPressed() {
    final otpCode = _otpController.text.trim();

    setState(() {
      if (otpCode.isEmpty) {
        _otpError = 'Mã xác thực không được để trống';
      } else if (otpCode.length != 6) {
        _otpError = 'Mã xác thực phải gồm đúng 6 ký tự';
      } else {
        _otpError = null;
      }
    });

    if (_otpError != null) {
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
        VerifyOtpPressed(
          phoneNumber: widget.phoneNumber,
          password: widget.password ?? '',
          code: otpCode,
        ),
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
            AppSnackBar.showSuccess(context, message: 'Xác thực OTP thành công!');
            // Không thực hiện Navigator.push hay Navigator.pushAndRemoveUntil nữa.
            // main.dart đang lắng nghe AuthSuccess ở root và sẽ tự động điều hướng.
          } else if (state is AuthFailure) {
            // XÁC THỰC THẤT BẠI -> Hiển thị thông báo lỗi
            AppSnackBar.showError(context, message: 'Lỗi: ${state.error}');
          }
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: context.specialTheme.useGradient ? Colors.transparent : context.specialTheme.primaryDarkColor,
            flexibleSpace: context.specialTheme.useGradient
                ? Container(
                    decoration: BoxDecoration(
                      gradient: context.specialTheme.primaryGradient,
                    ),
                  )
                : null,
            iconTheme: const IconThemeData(color: Colors.white),
            title: const Text('Xác thực OTP', style: TextStyle(color: Colors.white, fontSize: 16)),
          ),
          body: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  (() {
                    final specialTheme = context.specialTheme;
                    final iconWidget = Icon(
                      Icons.verified_user,
                      size: 80,
                      color: specialTheme.useGradient ? Colors.white : specialTheme.primaryColor,
                    );
                    if (specialTheme.useGradient) {
                      return ShaderMask(
                        shaderCallback: (bounds) => specialTheme.primaryGradient!.createShader(bounds),
                        child: iconWidget,
                      );
                    }
                    return iconWidget;
                  }()),
                  const SizedBox(height: 20,),
                  Text('Nhập mã 6 ký tự được gửi đến:\n${widget.phoneNumber}',
                    textAlign: TextAlign.center, style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 30,),
                  TextField(
                    controller: _otpController,
                    decoration: InputDecoration(
                      labelText: 'Mã xác thực',
                      border: const OutlineInputBorder(),
                      counterText: "", // Ẩn dòng đếm ký tự mặc định
                      errorText: _otpError,
                    ),
                    maxLength: 6,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 24, letterSpacing: 8, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Sử dụng BlocBuilder để đổi trạng thái nút bấm (Loading)
                  BlocBuilder<AuthBloc, AuthState>(
                      builder: (context, state) {
                        return AppButton(
                          label: 'XÁC NHẬN',
                          isLoading: state is AuthLoading,
                          onPressed: _onVerifyPressed,
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
