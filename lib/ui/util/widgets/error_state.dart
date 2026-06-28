import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_spacing.dart';

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorState({super.key, required this.message, this.onRetry});

  static bool isNetworkError(String? msg) {
    if (msg == null) return false;
    final m = msg.toLowerCase();
    return m.contains('502') ||
        m.contains('connection') ||
        m.contains('failed host') ||
        m.contains('socketexception') ||
        m.contains('lỗi kết nối') ||
        m.contains('timeout') ||
        m.contains('handshake') ||
        m.contains('network');
  }

  static String cleanMessage(String msg) {
    String clean = msg.trim();

    final RegExp prefixPattern = RegExp(
      r'^([a-zA-Z]*Exception|lỗi):\s*',
      caseSensitive: false,
    );

    bool cleaned = true;
    while (cleaned) {
      cleaned = false;
      final match = prefixPattern.firstMatch(clean);
      if (match != null) {
        clean = clean.substring(match.end).trim();
        cleaned = true;
      }
    }

    if (clean.isNotEmpty) {
      clean = clean[0].toUpperCase() + clean.substring(1);
    }

    final msgLower = clean.toLowerCase();
    if (msgLower.contains('502') ||
        msgLower.contains('503') ||
        msgLower.contains('504')) {
      return 'Hệ thống đang bảo trì hoặc gặp sự cố. Vui lòng thử lại sau ít phút.';
    } else if (msgLower.contains('timeout') || msgLower.contains('deadline')) {
      return 'Kết nối mạng quá hạn. Vui lòng kiểm tra kết nối internet và thử lại.';
    } else if (msgLower.contains('socketexception') ||
        msgLower.contains('connection error') ||
        msgLower.contains('connection refused') ||
        msgLower.contains('failed host lookup') ||
        msgLower.contains('network is unreachable')) {
      return 'Không thể kết nối đến máy chủ. Vui lòng kiểm tra mạng hoặc thử lại sau.';
    } else if (msgLower.contains('500') ||
        msgLower.contains('internal server error')) {
      return 'Máy chủ gặp sự cố hệ thống (500). Vui lòng thử lại sau.';
    }

    return clean;
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 56, color: AppColors.danger),
            const SizedBox(height: AppSpacing.md),
            Text(
              cleanMessage(message),
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Thử lại'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
