import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class NetworkStatusWrapper extends StatefulWidget {
  final Widget child;
  const NetworkStatusWrapper({super.key, required this.child});

  @override
  State<NetworkStatusWrapper> createState() => _NetworkStatusWrapperState();
}

/// FIX 1: Bỏ auto-logout khi mất mạng — chỉ hiển thị banner cảnh báo.
/// FIX 2: Thêm WidgetsBindingObserver để tạm dừng kiểm tra mạng khi app
///         vào background, tránh false-positive khi resume.
class _NetworkStatusWrapperState extends State<NetworkStatusWrapper>
    with WidgetsBindingObserver {
  bool _isOnline = true;
  bool _showOnlineSuccess = false;

  /// Timer định kỳ kiểm tra mạng (chỉ chạy khi app ở foreground).
  Timer? _periodicTimer;

  /// Timer delay sau khi resume từ background trước khi bắt đầu check lại.
  Timer? _resumeDelayTimer;

  /// Trạng thái lifecycle của app.
  AppLifecycleState _lifecycleState = AppLifecycleState.resumed;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startPeriodicCheck();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _periodicTimer?.cancel();
    _resumeDelayTimer?.cancel();
    super.dispose();
  }

  // ─── Lifecycle Observer ─────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _lifecycleState = state;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      // App vào background: dừng timer định kỳ để tiết kiệm tài nguyên
      // và tránh DNS timeout gây false-positive khi resume.
      _stopPeriodicCheck();
    } else if (state == AppLifecycleState.resumed) {
      // App quay lại foreground: chờ 2 giây cho hệ điều hành khôi phục
      // kết nối mạng trước khi bắt đầu check lại.
      _resumeDelayTimer?.cancel();
      _resumeDelayTimer = Timer(const Duration(seconds: 2), () {
        if (mounted && _lifecycleState == AppLifecycleState.resumed) {
          _checkStatus();
          _startPeriodicCheck();
        }
      });
    }
  }

  // ─── Network Check ──────────────────────────────────────────────────────────

  void _startPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer =
        Timer.periodic(const Duration(seconds: 5), (_) => _checkStatus());
  }

  void _stopPeriodicCheck() {
    _periodicTimer?.cancel();
    _periodicTimer = null;
  }

  Future<void> _checkStatus() async {
    // Không check khi app đang ở background
    if (_lifecycleState != AppLifecycleState.resumed) return;

    bool online;
    try {
      final result = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 3));
      online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (_) {
      online = false;
    }

    if (!mounted) return;

    if (online == _isOnline) return; // Không thay đổi, không cần rebuild

    setState(() {
      _isOnline = online;
      if (online) {
        // Vừa khôi phục kết nối: hiện banner xanh 3 giây
        _showOnlineSuccess = true;
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _showOnlineSuccess = false);
        });
      }
      // FIX 1: Không còn gọi _handleAutoLogout() nữa.
      // Chỉ hiển thị banner đỏ, người dùng KHÔNG bị đăng xuất.
    });
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double visibleTop = topPadding + 8;
    const double hiddenTop = -150.0;

    return Stack(
      children: [
        widget.child,
        AnimatedPositioned(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          top: (!_isOnline || _showOnlineSuccess) ? visibleTop : hiddenTop,
          left: 0,
          right: 0,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding:
                  const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color:
                    !_isOnline ? AppColors.primaryDark : AppColors.successDark,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    !_isOnline ? Icons.cloud_off : Icons.cloud_done,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      !_isOnline
                          ? 'Bạn đang ngoại tuyến. Vui lòng kiểm tra kết nối mạng.'
                          : 'Đã khôi phục kết nối mạng.',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
