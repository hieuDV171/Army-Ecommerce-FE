import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatelessWidget {
  final String username;
  final String token;

  const HomeScreen({super.key, required this.username, required this.token});

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLogoutSuccess) {
            // Khi logout xong thì đẩy về màn hình Login
            Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
            );
          }
        },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quân Nhu Tiền Tuyến'),
          backgroundColor: const Color(0xFF003366), // Màu Navy quân đội
          actions: [
            IconButton(
                onPressed: () {
                  // Hiển thị hộp thoại xác nhận
                  _showLogoutDialog(context);
                },
                icon: const Icon(Icons.logout),
                tooltip: 'Đăng xuất',
            ),
          ],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.military_tech, size: 100, color: Colors.lightGreen),
              const SizedBox(height: 20),
              Text('Chào đồng chí: $username',
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)
              ),
              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text('Hệ thống sẵn sàng tiếp nhận yêu cầu quân nhu.',
                    textAlign: TextAlign.center
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Đồng chí muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(innerContext), child: const Text('HỦY')),
          TextButton(
              onPressed: () {
                Navigator.pop(innerContext);
                // Bắn sự kiện Logout
                context.read<AuthBloc>().add(LogoutButtonPressed(token: token));
              },
              child: const Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}