import 'package:army_ecommerce/ui/auth/change_password_screen.dart';
import 'package:army_ecommerce/ui/profile/update_profile_screen.dart';
import 'package:army_ecommerce/ui/settings/push_settings_screen.dart';
import 'package:flutter/material.dart';
import '../../core/services/session_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/settings/push_setting_bloc.dart';
import '../auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String token;
  final String? phoneNumber;

  const HomeScreen({super.key, required this.username, required this.token, this.phoneNumber});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _phoneFromPrefs;
  String? _avatarUrl;
  late String _currentUsername;

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.username;
    // Nếu màn gọi không truyền phoneNumber, thử load từ SessionManager
    if (widget.phoneNumber == null) {
      SessionManager.getPhoneNumber().then((p) {
        if (mounted) {
          setState(() => _phoneFromPrefs = p);
        }
      });
    }
    // Load avatar từ SessionManager
    SessionManager.getAvatar().then((avatar) {
      if (mounted) {
        setState(() => _avatarUrl = avatar);
      }
    });
  }

  String get _displayName {
    if (_currentUsername.isNotEmpty) return _currentUsername;
    return widget.phoneNumber ?? _phoneFromPrefs ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthLogoutSuccess) {
          // Khi logout xong thì đẩy về màn hình Login
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
          );
        } else if (state is ChangeInfoSuccess) {
          // Cập nhật avatar và username khi thay đổi thông tin
          if (mounted) {
            setState(() {
              _currentUsername = state.updatedUser.username;
              _avatarUrl = state.updatedUser.avatar;
            });
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Quân Nhu Tiền Tuyến'),
          backgroundColor: const Color(0xFF003366), // Màu Navy quân đội
        ),
        drawer: Drawer(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              // Phần đầu Menu hiển thị thông tin quân nhân
              UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: Color(0xFF003366)),
                accountName: Text('Đồng chí: $_displayName'),
                accountEmail: const Text('Quân binh chủng: Bộ binh'),
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                      ? NetworkImage(_avatarUrl!)
                      : null,
                  child: _avatarUrl == null || _avatarUrl!.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Color(0xFF003366))
                      : null,
                ),
              ),

               // MỤC CẬP NHẬT HỒ SƠ
               ListTile(
                 leading: const Icon(Icons.person_outline, color: Colors.blue,),
                 title: const Text('Cập nhật hồ sơ'),
                 onTap: () {
                   // 1. Đóng menu trượt trước
                   Navigator.pop(context);

                   // 2. Chuyển sang màn hình cập nhật hồ sơ
                   final authBloc = context.read<AuthBloc>();
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => BlocProvider.value(
                         value: authBloc,
                         child: UpdateProfileScreen(currentUsername: _displayName),
                       ),
                     ),
                   ).then((updatedUser) {
                     if (updatedUser != null) {
                       setState(() {
                           _currentUsername = updatedUser.username;
                           _avatarUrl = updatedUser.avatar;
                       });
                     }
                   });
                 },
               ),

               // MỤC ĐỔI MẬT KHẨU
               ListTile(
                 leading: const Icon(Icons.lock_reset, color: Colors.orange,),
                 title: Text('Đổi mật khẩu'),
                 onTap: () {
                   // 1. Đóng menu trượt trước
                   Navigator.pop(context);

                   // 2. Chuyển sang màn hình đổi mật khẩu
                   // Lưu ý: "Truyền tay" AuthBloc hiện tại sang để dùng tiếp
                   final authBloc = context.read<AuthBloc>();
                   Navigator.push(
                     context,
                     MaterialPageRoute(
                       builder: (context) => BlocProvider.value(
                         value: authBloc,
                         child: const ChangePasswordScreen(),
                       ),
                     ),
                   );
                 },
               ),

                // MỤC CÀI ĐẶT THÔNG BÁO
                ListTile(
                  leading: const Icon(Icons.notifications_active, color: Colors.purple,),
                  title: const Text('Cài đặt thông báo'),
                  onTap: () {
                    // 1. Đóng menu trượt trước
                    Navigator.pop(context);

                    // 2. Chuyển sang màn hình cài đặt thông báo
                    // Lưu ý: "Truyền tay" PushSettingBloc hiện tại sang để dùng tiếp
                    final pushSettingBloc = context.read<PushSettingBloc>();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => BlocProvider.value(
                          value: pushSettingBloc,
                          child: const PushSettingsScreen(),
                        ),
                      ),
                    );
                  },
                ),

              const Divider(), // Đường kẻ ngăn cách
              // MỤC ĐĂNG XUẤT
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red,),
                title: const Text('Đăng xuất'),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context);
                },
              )
              //----------------------------------
            ],
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.military_tech, size: 100, color: Colors.lightGreen),
              const SizedBox(height: 20),
              Text('Chào đồng chí: $_displayName',
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
                context.read<AuthBloc>().add(LogoutButtonPressed(token: widget.token));
              },
              child: const Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }
}