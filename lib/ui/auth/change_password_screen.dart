import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _oldPassController = TextEditingController();
  final _newPassController = TextEditingController();
  final _confirmPassController = TextEditingController();

  bool _isStep2 = false; // Chuyển đổi giữa 2 giao diện

  String? _oldPassError;
  String? _newPassError;
  String? _confirmPassError;

  @override
  void initState() {
    super.initState();
    _oldPassController.addListener(() {
      if (_oldPassError != null) {
        setState(() {
          _oldPassError = null;
        });
      }
    });
    _newPassController.addListener(() {
      if (_newPassError != null) {
        setState(() {
          _newPassError = null;
        });
      }
    });
    _confirmPassController.addListener(() {
      if (_confirmPassError != null) {
        setState(() {
          _confirmPassError = null;
        });
      }
    });
  }

  @override
  void dispose() {
    _oldPassController.dispose();
    _newPassController.dispose();
    _confirmPassController.dispose();
    super.dispose();
  }

  void _onVerifyOldPass() {
    final oldP = _oldPassController.text.trim();
    setState(() {
      _oldPassError = oldP.isEmpty ? 'Mật khẩu hiện tại không được để trống' : null;
    });

    if (_oldPassError != null) return;

    // Bắn event xác minh mật khẩu cũ qua API Login
    context.read<AuthBloc>().add(VerifyOldPasswordRequested(oldPassword: oldP));
  }

  void _onSubmitChange() {
    final oldP = _oldPassController.text.trim();
    final newP = _newPassController.text.trim();
    final confP = _confirmPassController.text.trim();

    setState(() {
      if (newP.isEmpty) {
        _newPassError = 'Mật khẩu mới không được để trống';
      } else if (newP.length < 6 || newP.length > 10) {
        _newPassError = 'Mật khẩu phải từ 6 đến 10 ký tự';
      } else if (newP == oldP) {
        _newPassError = 'Mật khẩu mới không được trùng với mật khẩu cũ';
      } else {
        _newPassError = null;
      }

      if (confP.isEmpty) {
        _confirmPassError = 'Xác nhận mật khẩu mới không được để trống';
      } else if (newP != confP) {
        _confirmPassError = 'Mật khẩu xác nhận không khớp';
      } else {
        _confirmPassError = null;
      }
    });

    if (_newPassError != null || _confirmPassError != null) {
      return;
    }

    context.read<AuthBloc>().add(
      ChangePasswordRequested(oldPassword: oldP, newPassword: newP),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is OldPasswordVerifySuccess) {
          setState(() => _isStep2 = true); // NHẢY SANG BƯỚC 2
          AppSnackBar.showSuccess(
            context,
            message: 'Xác minh thành công! Hãy nhập mật khẩu mới',
          );
        } else if (state is ChangePasswordSuccess) {
          AppSnackBar.showSuccess(context, message: 'Đổi mật khẩu thành công!');
          Navigator.pop(context); // Quay lại trang cá nhân
        } else if (state is AuthFailure) {
          AppSnackBar.showError(context, message: state.error);
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Đổi mật khẩu')),
        body: Padding(
          padding: const EdgeInsets.all(20.0),
          child: _isStep2 ? _buildStep2() : _buildStep1(),
        ),
      ),
    );
  }

  // Giao diện nhập mật khẩu cũ để xác minh
  Widget _buildStep1() {
    return Column(
      children: [
        const Text('Nhập mật khẩu hiện tại để xác minh danh tính'),
        const SizedBox(height: 20),
        TextField(
          controller: _oldPassController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Mật khẩu hiện tại',
            border: const OutlineInputBorder(),
            errorText: _oldPassError,
          ),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _onVerifyOldPass,
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
          child: const Text('XÁC NHẬN'),
        ),
      ],
    );
  }

  // Giao diện nhập mật khẩu mới
  Widget _buildStep2() {
    return Column(
      children: [
        TextField(
          controller: _newPassController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Mật khẩu mới',
            border: const OutlineInputBorder(),
            errorText: _newPassError,
          ),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _confirmPassController,
          obscureText: true,
          decoration: InputDecoration(
            labelText: 'Xác nhận mật khẩu mới',
            border: const OutlineInputBorder(),
            errorText: _confirmPassError,
          ),
        ),
        const SizedBox(height: 30),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return ElevatedButton(
              onPressed: state is AuthLoading ? null : _onSubmitChange,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: context.specialTheme.primaryColor,
              ),
              child: state is AuthLoading
                  ? const CircularProgressIndicator()
                  : const Text('THAY ĐỔI'),
            );
          },
        ),
      ],
    );
  }
}
