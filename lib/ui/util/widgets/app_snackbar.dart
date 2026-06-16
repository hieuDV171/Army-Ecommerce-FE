import 'package:flutter/material.dart';

class AppSnackBar {
  /// Hiển thị SnackBar và ngay lập tức đóng SnackBar trước đó nếu có.
  static void show(BuildContext context, {required String message, Color? backgroundColor, Duration duration = const Duration(seconds: 2)}) {
    final messenger = ScaffoldMessenger.of(context);
    
    // Xóa SnackBar hiện tại ngay lập tức để SnackBar mới được hiện lên luôn
    messenger.removeCurrentSnackBar();
    
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating, // UX hiện đại
      ),
    );
  }

  /// Hiển thị SnackBar thông báo lỗi (màu đỏ)
  static void showError(BuildContext context, {required String message}) {
    String cleanMessage = message.trim();
    
    // 1. Loại bỏ các tiền tố thô của Exception
    if (cleanMessage.startsWith('Lỗi: Exception: ')) {
      cleanMessage = cleanMessage.substring('Lỗi: Exception: '.length);
    }
    if (cleanMessage.startsWith('Exception: ')) {
      cleanMessage = cleanMessage.substring('Exception: '.length);
    }
    if (cleanMessage.contains('Exception: ')) {
      cleanMessage = cleanMessage.replaceAll('Exception: ', '');
    }
    if (cleanMessage.startsWith('Lỗi: Lỗi: ')) {
      cleanMessage = cleanMessage.substring('Lỗi: '.length);
    }
    if (cleanMessage.startsWith('Lỗi: ')) {
      cleanMessage = cleanMessage.substring('Lỗi: '.length);
    }

    // 2. Chuyển đổi dự phòng (fallback) các lỗi mạng thô còn sót lại
    final msgLower = cleanMessage.toLowerCase();
    if (msgLower.contains('502') || msgLower.contains('503') || msgLower.contains('504')) {
      cleanMessage = 'Hệ thống đang bảo trì hoặc gặp sự cố. Vui lòng thử lại sau ít phút.';
    } else if (msgLower.contains('timeout') || msgLower.contains('deadline')) {
      cleanMessage = 'Kết nối mạng quá hạn. Vui lòng kiểm tra kết nối internet và thử lại.';
    } else if (msgLower.contains('socketexception') || 
               msgLower.contains('connection error') ||
               msgLower.contains('connection refused') || 
               msgLower.contains('failed host lookup') ||
               msgLower.contains('network is unreachable')) {
      cleanMessage = 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc thử lại sau.';
    } else if (msgLower.contains('500') || msgLower.contains('internal server error')) {
      cleanMessage = 'Máy chủ gặp sự cố hệ thống (500). Vui lòng thử lại sau.';
    }

    show(
      context,
      message: cleanMessage,
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

/// Extension để gọi AppSnackBar.show dễ dàng hơn từ BuildContext
extension AppSnackBarExtension on BuildContext {
  void showSnackBar(String message, {Color? backgroundColor}) {
    AppSnackBar.show(this, message: message, backgroundColor: backgroundColor);
  }

  void showSuccessSnackBar(String message) {
    AppSnackBar.showSuccess(this, message: message);
  }

  void showErrorSnackBar(String message) {
    AppSnackBar.showError(this, message: message);
  }
}
