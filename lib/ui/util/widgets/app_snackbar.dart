import 'package:flutter/material.dart';

class AppSnackBar {
  /// Hiển thị SnackBar và ngay lập tức đóng SnackBar trước đó nếu có.
  static void show(BuildContext context, {required String message, Color? backgroundColor, Duration duration = const Duration(seconds: 3)}) {
    final messenger = ScaffoldMessenger.of(context);
    
    // Xóa SnackBar hiện tại ngay lập tức để SnackBar mới được hiện lên luôn
    messenger.removeCurrentSnackBar();
    
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating, // Khuyên dùng cho UX hiện đại
      ),
    );
  }

  /// Hiển thị SnackBar thông báo lỗi (màu đỏ)
  static void showError(BuildContext context, {required String message}) {
    show(
      context,
      message: message,
      backgroundColor: Colors.redAccent,
    );
  }

  /// Hiển thị SnackBar thông báo thành công (màu xanh)
  static void showSuccess(BuildContext context, {required String message}) {
    show(
      context,
      message: message,
      backgroundColor: Colors.green,
    );
  }
}
