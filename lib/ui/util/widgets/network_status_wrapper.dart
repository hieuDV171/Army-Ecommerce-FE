import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';

class NetworkStatusWrapper extends StatefulWidget {
  final Widget child;
  const NetworkStatusWrapper({super.key, required this.child});

  @override
  State<NetworkStatusWrapper> createState() => _NetworkStatusWrapperState();
}

class _NetworkStatusWrapperState extends State<NetworkStatusWrapper> {
  bool _isOnline = true;
  bool _showOnlineSuccess = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startConnectionCheck();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startConnectionCheck() {
    _checkStatus();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    try {
      final result = await InternetAddress.lookup('google.com').timeout(const Duration(seconds: 3));
      final online = result.isNotEmpty && result[0].rawAddress.isNotEmpty;
      if (online != _isOnline) {
        setState(() {
          _isOnline = online;
          if (online) {
            _showOnlineSuccess = true;
            Future.delayed(const Duration(seconds: 3), () {
              if (mounted) {
                setState(() => _showOnlineSuccess = false);
              }
            });
          }
        });
      }
    } catch (_) {
      if (_isOnline) {
        setState(() {
          _isOnline = false;
          _showOnlineSuccess = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final double topPadding = MediaQuery.of(context).padding.top;
    final double visibleTop = topPadding + 8;
    final double hiddenTop = -150.0;

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
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: !_isOnline ? const Color(0xFFE83A14) : const Color(0xFF2E7D32),
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
