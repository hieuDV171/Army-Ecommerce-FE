import 'package:flutter/material.dart';
import 'package:army_ecommerce/ui/auth/login_screen.dart';

/// Hiển thị hộp thoại yêu cầu đăng nhập nếu người dùng đang ở chế độ khách.
/// Trả về `true` nếu người dùng đã đăng nhập, `false` nếu chưa đăng nhập và hiển thị dialog.
bool checkLogin(BuildContext context, {required String token}) {
  if (token.isNotEmpty) {
    return true;
  }
  showDialog<void>(
    context: context,
    builder: (innerCtx) => AlertDialog(
      title: const Text('Yêu cầu đăng nhập'),
      content: const Text('Đồng chí cần đăng nhập để thực hiện chức năng này.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(innerCtx),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            Navigator.pop(innerCtx); // Đóng dialog
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
            );
          },
          child: const Text('Đăng nhập', style: TextStyle(color: Colors.blue)),
        ),
      ],
    ),
  );
  return false;
}
