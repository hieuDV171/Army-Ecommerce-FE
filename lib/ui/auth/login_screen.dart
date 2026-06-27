import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/ui/auth/forgot_password_screen.dart';
import 'package:army_ecommerce/ui/auth/signup_screen.dart';
import 'package:army_ecommerce/ui/util/widgets/app_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/core/config/app_config.dart';
import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../util/constants/app_colors.dart';
import '../util/constants/app_spacing.dart';
import '../util/widgets/app_button.dart';
import '../util/widgets/app_text_field.dart';

import '../util/theme/special_app_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isObscure = true;
  int _logoTapCount = 0;
  DateTime? _lastLogoTapTime;

  String? _phoneError;
  String? _passwordError;

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
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onLoginPressed() {
    final phone = _phoneController.text.trim();
    final password = _passwordController.text.trim();

    setState(() {
      if (phone.isEmpty) {
        _phoneError = 'Số điện thoại không được để trống';
      } else if (!RegExp(r'^(?:\+84|84|0)[0-9]{9}$').hasMatch(phone)) {
        _phoneError = 'Số điện thoại không đúng định dạng';
      } else {
        _phoneError = null;
      }

      if (password.isEmpty) {
        _passwordError = 'Mật khẩu không được để trống';
      } else if (password.length < 6) {
        _passwordError = 'Mật khẩu phải có ít nhất 6 ký tự';
      } else if (password.length > 10) {
        _passwordError = 'Mật khẩu không được lớn hơn 10 ký tự';
      } else {
        _passwordError = null;
      }
    });

    if (_phoneError != null || _passwordError != null) {
      return;
    }

    context.read<AuthBloc>().add(
      LoginButtonPressed(phoneNumber: phone, password: password),
    );
  }

  void _showDevSettingsDialog() {
    final controller = TextEditingController(text: AppConfig.baseUrl);
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.developer_mode, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Developer Settings'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Nhập địa chỉ BASE_URL mới của Backend bên dưới:',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Backend BASE_URL',
                  hintText: 'http://localhost:8000/',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Lưu ý: Thay đổi này có tác dụng ngay lập tức cho các kết nối tiếp theo mà không cần build lại.',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newUrl = controller.text.trim();
                if (newUrl.isNotEmpty) {
                  try {
                    // 1. Lưu SharedPreferences
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('custom_base_url', newUrl);

                    // 2. Cấu hình lại AppConfig
                    AppConfig.baseUrl = newUrl;

                    // 3. Cấu hình lại DioClient singleton
                    DioClient.instance?.updateBaseUrl(newUrl);

                    if (context.mounted) {
                      Navigator.pop(context);
                      AppDialog.showSuccess(
                        context,
                        message: 'Đã cập nhật BASE_URL thành công:\n$newUrl',
                        autoCloseDuration: const Duration(seconds: 2),
                        confirmLabel: null,
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      AppDialog.showError(
                        context,
                        message: 'Lỗi khi lưu cấu hình: $e',
                        autoCloseDuration: const Duration(seconds: 2),
                        confirmLabel: null,
                      );
                    }
                  }
                }
              },
              child: const Text('Lưu'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthSuccess) {
            AppDialog.showSuccess(
              context,
              message: 'Đăng nhập thành công',
              autoCloseDuration: const Duration(seconds: 2),
              confirmLabel: null,
            );
            // Không thực hiện Navigator.push/pushReplacement nữa.
            // main.dart lắng nghe AuthSuccess ở root và tự động điều hướng.
          } else if (state is AuthFailure) {
            final isUserNotValidated =
                state.code == '9995' ||
                state.error.contains('9995') ||
                state.error.toLowerCase().contains('user is not validated') ||
                state.error.contains('Tài khoản chưa đăng ký');
            if (isUserNotValidated) {
              setState(() {
                _phoneError = '';
                _passwordError = 'Thông tin đăng nhập hoặc mật khẩu không đúng';
              });
            } else {
              AppDialog.showError(
                context,
                message: state.error,
                autoCloseDuration: const Duration(seconds: 2),
                confirmLabel: null,
              );
            }
          }
        },
        builder: (context, state) {
          return SafeArea(
            child: Stack(
              children: [
                SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const SizedBox(height: 48),
                      GestureDetector(
                        onTap: () {
                          final now = DateTime.now();
                          if (_lastLogoTapTime == null ||
                              now.difference(_lastLogoTapTime!) >
                                  const Duration(seconds: 2)) {
                            _logoTapCount = 1;
                          } else {
                            _logoTapCount++;
                          }
                          _lastLogoTapTime = now;

                          if (_logoTapCount >= 5) {
                            _logoTapCount = 0;
                            _showDevSettingsDialog();
                          }
                        },
                        child: (() {
                          final specialTheme = context.specialTheme;
                          final iconWidget = Icon(
                            Icons.military_tech,
                            size: 76,
                            color: specialTheme.useGradient
                                ? Colors.white
                                : specialTheme.primaryColor,
                          );
                          if (specialTheme.useGradient) {
                            return ShaderMask(
                              shaderCallback: (bounds) => specialTheme
                                  .primaryGradient!
                                  .createShader(bounds),
                              child: iconWidget,
                            );
                          }
                          return iconWidget;
                        }()),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text(
                        'Army E-commerce',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        'Đăng nhập để tiếp tục mua bán quân nhu',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 36),
                      AppTextField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        label: 'Số điện thoại',
                        errorText: _phoneError,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      AppTextField(
                        controller: _passwordController,
                        obscureText: _isObscure,
                        label: 'Mật khẩu',
                        errorText: _passwordError,
                        suffixIcon: IconButton(
                          tooltip: _isObscure ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
                          icon: Icon(
                            _isObscure
                                ? Icons.visibility_off
                                : Icons.visibility,
                          ),
                          onPressed: () {
                            setState(() {
                              _isObscure = !_isObscure;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      AppButton(
                        label: 'Đăng nhập',
                        isLoading: state is AuthLoading,
                        onPressed: _onLoginPressed,
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text('Quên mật khẩu'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignupScreen(),
                                ),
                              );
                            },
                            child: const Text('Đăng ký'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    tooltip: 'Đóng',
                    icon: const Icon(
                      Icons.close,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
