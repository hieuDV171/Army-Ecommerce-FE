import 'dart:async';
import 'package:flutter/material.dart';
import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';
import '../constants/app_radius.dart';
import '../constants/app_spacing.dart';

class AppDialog extends StatefulWidget {
  final String message;
  final String? title;
  final String? confirmLabel;
  final String? cancelLabel;
  final VoidCallback? onConfirm;
  final VoidCallback? onCancel;
  final Duration? autoCloseDuration;
  final bool isError;
  final bool isSuccess;

  const AppDialog({
    super.key,
    required this.message,
    this.title,
    this.confirmLabel,
    this.cancelLabel,
    this.onConfirm,
    this.onCancel,
    this.autoCloseDuration,
    this.isError = false,
    this.isSuccess = false,
  });

  /// Hiển thị Dialog tùy biến
  static Future<T?> show<T>(
    BuildContext context, {
    required String message,
    String? title,
    String? confirmLabel,
    String? cancelLabel,
    VoidCallback? onConfirm,
    VoidCallback? onCancel,
    Duration? autoCloseDuration,
    bool barrierDismissible = true,
    bool isError = false,
    bool isSuccess = false,
  }) {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierColor: Colors.black54,
      builder: (context) => AppDialog(
        message: message,
        title: title,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onConfirm: onConfirm,
        onCancel: onCancel,
        autoCloseDuration: autoCloseDuration,
        isError: isError,
        isSuccess: isSuccess,
      ),
    );
  }

  /// Hiển thị Dialog lỗi (màu đỏ, tự đóng hoặc có nút đóng)
  static Future<T?> showError<T>(
    BuildContext context, {
    required String message,
    String? title = 'Thông báo lỗi',
    String? confirmLabel = 'Đã hiểu',
    Duration? autoCloseDuration,
    bool barrierDismissible = true,
  }) {
    return show<T>(
      context,
      message: message,
      title: title,
      confirmLabel: confirmLabel,
      isError: true,
      autoCloseDuration: autoCloseDuration,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Hiển thị Dialog thành công (màu xanh, tự đóng hoặc có nút đóng)
  static Future<T?> showSuccess<T>(
    BuildContext context, {
    required String message,
    String? title = 'Thành công',
    String? confirmLabel = 'Đồng ý',
    Duration? autoCloseDuration,
    bool barrierDismissible = true,
  }) {
    return show<T>(
      context,
      message: message,
      title: title,
      confirmLabel: confirmLabel,
      isSuccess: true,
      autoCloseDuration: autoCloseDuration,
      barrierDismissible: barrierDismissible,
    );
  }

  @override
  State<AppDialog> createState() => _AppDialogState();
}

class _AppDialogState extends State<AppDialog> with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );
    _animController.forward();

    if (widget.autoCloseDuration != null) {
      _timer = Timer(widget.autoCloseDuration!, () {
        if (mounted) {
          Navigator.of(context).pop();
        }
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final specialTheme = context.specialTheme;
    
    // Lấy màu sắc chủ đạo và icon của dạng dialog
    Color themeColor;
    IconData iconData;
    if (widget.isError) {
      themeColor = Colors.redAccent;
      iconData = Icons.error_outline_rounded;
    } else if (widget.isSuccess) {
      themeColor = Colors.green;
      iconData = Icons.check_circle_outline_rounded;
    } else {
      themeColor = specialTheme.primaryColor;
      iconData = Icons.info_outline_rounded;
    }

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 40),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 20,
                  offset: Offset(0, 10),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header chứa Icon có màu chủ đạo
                Container(
                  height: 80,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: themeColor.withValues(alpha: 0.1),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(AppRadius.lg),
                      topRight: Radius.circular(AppRadius.lg),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      iconData,
                      size: 44,
                      color: themeColor,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    children: [
                      if (widget.title != null) ...[
                        Text(
                          widget.title!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                      ],
                      Text(
                        widget.message,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      
                      // Khu vực nút bấm
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.cancelLabel != null) ...[
                            Expanded(
                              child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.black54,
                                  side: const BorderSide(color: Colors.black12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                ),
                                onPressed: () {
                                  widget.onCancel?.call();
                                  Navigator.of(context).pop(false);
                                },
                                child: Text(
                                  widget.cancelLabel!,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                          ],
                          if (widget.confirmLabel != null)
                            Expanded(
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: themeColor,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(AppRadius.md),
                                  ),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  elevation: 0,
                                ),
                                onPressed: () {
                                  widget.onConfirm?.call();
                                  Navigator.of(context).pop(true);
                                },
                                child: Text(
                                  widget.confirmLabel!,
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
