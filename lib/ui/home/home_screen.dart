import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/core/utils/logger.dart';

import '../../blocs/auth/auth_bloc.dart';
import '../../blocs/auth/auth_event.dart';
import '../../blocs/auth/auth_state.dart';
import '../../blocs/marketplace/marketplace_bloc.dart';
import '../../blocs/settings/push_setting_bloc.dart';
import '../../core/services/session_manager.dart';
import '../../repositories/marketplace_repository.dart';
import '../auth/change_password_screen.dart';
import '../marketplace/marketplace_pages.dart';
import '../profile/user_profile_screen.dart';
import '../settings/push_settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final String username;
  final String token;
  final String? phoneNumber;

  const HomeScreen({
    super.key,
    required this.username,
    required this.token,
    this.phoneNumber,
  });

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
    if (widget.phoneNumber == null) {
      SessionManager.getPhoneNumber().then((phone) {
        if (mounted) setState(() => _phoneFromPrefs = phone);
      });
    }
    SessionManager.getAvatar().then((avatar) {
      if (mounted) setState(() => _avatarUrl = avatar);
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
        if (state is ChangeInfoSuccess && mounted) {
          setState(() {
            _currentUsername = state.updatedUser.username;
            _avatarUrl = state.updatedUser.avatar;
          });
        }
      },
      child: BlocProvider(
        create: (context) => HomeBloc(
          marketplaceRepository: context.read<MarketplaceRepository>(),
        )..add(HomeRequested()),
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Quân Nhu Tiền Tuyến'),
          ),
          drawer: _HomeDrawer(
            displayName: _displayName,
            avatarUrl: _avatarUrl,
            token: widget.token,
          ),
          body: MarketplaceHomeBody(
            username: _displayName.isEmpty ? 'Đồng chí' : _displayName,
            avatarUrl: _avatarUrl,
          ),
        ),
      ),
    );
  }
}

class _HomeDrawer extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String token;

  const _HomeDrawer({
    required this.displayName,
    required this.avatarUrl,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: Color(0xFFE83A14)),
            accountName: Text('Đồng chí: $displayName'),
            accountEmail: const Text('Chợ quân nhu nội bộ'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: avatarUrl != null && avatarUrl!.isNotEmpty
                  ? NetworkImage(avatarUrl!)
                  : null,
              child: avatarUrl == null || avatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 42, color: Color(0xFFE83A14))
                  : null,
            ),
          ),
          _DrawerTile(
            icon: Icons.person_outline,
            color: Colors.blue,
            title: 'Hồ sơ của tôi',
            onTap: () => _push(context, const UserProfileScreen()),
          ),
          _DrawerTile(
            icon: Icons.lock_reset,
            color: Colors.orange,
            title: 'Đổi mật khẩu',
            onTap: () {
              Navigator.pop(context);
              final authBloc = context.read<AuthBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: authBloc,
                    child: const ChangePasswordScreen(),
                  ),
                ),
              );
            },
          ),
          _DrawerTile(
            icon: Icons.notifications_active,
            color: Colors.purple,
            title: 'Cài đặt thông báo',
            onTap: () {
              Navigator.pop(context);
              final pushSettingBloc = context.read<PushSettingBloc>();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: pushSettingBloc,
                    child: const PushSettingsScreen(),
                  ),
                ),
              );
            },
          ),
          const Divider(),
          _DrawerTile(
            icon: Icons.search,
            color: Colors.deepOrange,
            title: 'Tìm kiếm sản phẩm',
            onTap: () => _push(context, const SearchPage()),
          ),
          _DrawerTile(
            icon: Icons.receipt_long_outlined,
            color: Colors.teal,
            title: 'Đơn hàng',
            onTap: () => _push(context, const OrderListPage()),
          ),
          _DrawerTile(
            icon: Icons.location_on_outlined,
            color: Colors.green,
            title: 'Địa chỉ giao hàng',
            onTap: () => _push(context, const AddressListPage()),
          ),
          _DrawerTile(
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.brown,
            title: 'Ví quân nhu',
            onTap: () => _push(context, const WalletPage()),
          ),
          _DrawerTile(
            icon: Icons.chat_bubble_outline,
            color: Colors.indigo,
            title: 'Tin nhắn',
            onTap: () => _push(context, const ConversationPage()),
          ),
          _DrawerTile(
            icon: Icons.article_outlined,
            color: Colors.cyan,
            title: 'Tin tức',
            onTap: () => _push(context, const NewsPage()),
          ),
          const Divider(),
          _DrawerTile(
            icon: Icons.logout,
            color: Colors.red,
            title: 'Đăng xuất',
            onTap: () => _showLogoutDialog(context),
          ),
        ],
      ),
    );
  }

  void _push(BuildContext context, Widget page) {
    Navigator.pop(context);
    Navigator.push(context, MaterialPageRoute(builder: (_) => page));
  }

  void _showLogoutDialog(BuildContext context) {
    logger.i('DEBUG LOGOUT UI: _showLogoutDialog called');
    // Lấy AuthBloc ngay lập tức khi context của drawer còn đang active và chắc chắn hợp lệ
    final authBloc = context.read<AuthBloc>();

    showDialog<void>(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Đồng chí muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () {
              logger.i('DEBUG LOGOUT UI: Clicked Cancel');
              Navigator.pop(innerContext); // Đóng dialog
              Navigator.pop(context); // Đóng drawer
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              logger.i('DEBUG LOGOUT UI: Clicked Confirm Đăng xuất. Token was: "$token"');
              Navigator.pop(innerContext); // Đóng dialog
              Navigator.pop(context); // Đóng drawer
              logger.i('DEBUG LOGOUT UI: Dispatching LogoutButtonPressed event');
              authBloc.add(LogoutButtonPressed(token: token));
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(title),
      onTap: onTap,
    );
  }
}
