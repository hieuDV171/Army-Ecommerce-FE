import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';

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

  void _onVerifyOldPass() {
    final oldP = _oldPassController.text.trim();
    if (oldP.isEmpty) return;

    // Bắn event xác minh mật khẩu cũ qua API Login
    context.read<AuthBloc>().add(VerifyOldPasswordRequested(oldPassword: oldP));
  }

  void _onSubmitChange() {
    final oldP = _oldPassController.text.trim();
    final newP = _newPassController.text.trim();
    final confP = _confirmPassController.text.trim();

    if (newP != confP) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Xác nhận mật khẩu không khớp')));
      return;
    }

    context.read<AuthBloc>().add(
        ChangePasswordRequested(oldPassword: oldP, newPassword: newP)
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is OldPasswordVerifySuccess) {
          setState(() => _isStep2 = true); // NHẢY SANG BƯỚC 2
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Xác minh thành công! Hãy nhập mật khẩu mới')),
          );
        } else if (state is ChangePasswordSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Đổi mật khẩu thành công!')));
          Navigator.pop(context); // Quay lại trang cá nhân
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.error)));
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
          decoration: const InputDecoration(labelText: 'Mật khẩu hiện tại', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 30),
        ElevatedButton(
          onPressed: _onVerifyOldPass,
          style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50)),
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
          decoration: const InputDecoration(labelText: 'Mật khẩu mới', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 20),
        TextField(
          controller: _confirmPassController,
          obscureText: true,
          decoration: const InputDecoration(labelText: 'Xác nhận mật khẩu mới', border: OutlineInputBorder()),
        ),
        const SizedBox(height: 30),
        BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            return ElevatedButton(
              onPressed: state is AuthLoading ? null : _onSubmitChange,
              style: ElevatedButton.styleFrom(minimumSize: const Size(double.infinity, 50), backgroundColor: Colors.orange),
              child: state is AuthLoading ? const CircularProgressIndicator() : const Text('THAY ĐỔI'),
            );
          },
        ),
      ],
    );
  }
}