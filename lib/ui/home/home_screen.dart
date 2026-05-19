import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/blocs/block/block_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/blocs/chat/chat_state.dart';
import 'package:army_ecommerce/blocs/follow/follow_bloc.dart';
import 'package:army_ecommerce/blocs/notification/notification_bloc.dart';
import 'package:army_ecommerce/blocs/notification/notification_event.dart';
import 'package:army_ecommerce/blocs/notification/notification_state.dart';
import 'package:army_ecommerce/repositories/block_repository.dart';
import 'package:army_ecommerce/repositories/chat_repository.dart';
import 'package:army_ecommerce/repositories/follow_repository.dart';
import 'package:army_ecommerce/repositories/notification_repository.dart';
import 'package:army_ecommerce/ui/auth/change_password_screen.dart';
import 'package:army_ecommerce/ui/auth/login_screen.dart';
import 'package:army_ecommerce/ui/block/blocked_users_screen.dart';
import 'package:army_ecommerce/ui/chat/conversation_list_screen.dart';
import 'package:army_ecommerce/ui/follow/followers_screen.dart';
import 'package:army_ecommerce/ui/follow/following_screen.dart';
import 'package:army_ecommerce/ui/notification/notification_screen.dart';
import 'package:army_ecommerce/ui/profile/update_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/services/session_manager.dart';

const Color _shopeeOrange = Color(0xFFEE4D2D);
const Color _navyBlue = Color(0xFF003366);

class HomeScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String token;
  final String? phoneNumber;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.token,
    this.phoneNumber,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _avatarUrl;
  late String _currentUsername;
  // Cache số tin nhắn mới để badge không nhấp nháy trong lúc ChatBloc đang tải
  int _chatUnreadCount = 0;

  // BLoC được tạo trong initState và dispose đúng lifecycle
  late final FollowBloc _followBloc;
  late final BlockBloc _blockBloc;
  late final ChatBloc _chatBloc;
  late final NotificationBloc _notificationBloc;

  // GlobalKey để truy cập ScaffoldState nhằm đóng Drawer đúng cách
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _currentUsername = widget.username;

    // Khởi tạo 4 BLoC mới dùng repository từ MultiRepositoryProvider ở main.dart
    _followBloc = FollowBloc(followRepository: context.read<FollowRepository>());
    _blockBloc = BlockBloc(blockRepository: context.read<BlockRepository>());
    _chatBloc = ChatBloc(chatRepository: context.read<ChatRepository>());
    _notificationBloc = NotificationBloc(
      notificationRepository: context.read<NotificationRepository>(),
    );

    // Tải sẵn thông báo và hội thoại ngay khi vào Home để hiển thị badge
    _notificationBloc.add(LoadNotificationsRequested());
    _chatBloc.add(LoadConversationsRequested());

    // Tải avatar từ bộ nhớ cục bộ
    SessionManager.getAvatar().then((avatar) {
      if (mounted) setState(() => _avatarUrl = avatar);
    });
  }

  @override
  void dispose() {
    _followBloc.close();
    _blockBloc.close();
    _chatBloc.close();
    _notificationBloc.close();
    super.dispose();
  }

  // Mở màn hình thông báo và truyền BLoC hiện tại
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _notificationBloc,
          child: const NotificationScreen(),
        ),
      ),
    );
  }

  // Mở màn hình danh sách hội thoại
  void _openConversations() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _chatBloc,
          child: ConversationListScreen(currentUserId: widget.userId),
        ),
      ),
    ).then((_) {
      // Làm mới badge chat khi quay lại
      if (mounted) _chatBloc.add(LoadConversationsRequested());
    });
  }

  // Mở màn hình danh sách người theo dõi (followers)
  void _openFollowers() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _followBloc,
          child: FollowersScreen(userId: widget.userId),
        ),
      ),
    );
  }

  // Mở màn hình danh sách đang theo dõi (following)
  void _openFollowing() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _followBloc,
          child: FollowingScreen(userId: widget.userId),
        ),
      ),
    );
  }

  // Mở màn hình danh sách người đã chặn
  void _openBlockedUsers() {
    _closeDrawer(); // Đóng Drawer an toàn trước khi navigate
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _blockBloc,
          child: const BlockedUsersScreen(),
        ),
      ),
    );
  }

  // Đóng Drawer an toàn (no-op nếu Drawer không mở)
  void _closeDrawer() {
    _scaffoldKey.currentState?.closeDrawer();
  }

  // Mở màn hình cập nhật hồ sơ
  void _openUpdateProfile() {
    _closeDrawer();
    final authBloc = context.read<AuthBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: authBloc,
          child: UpdateProfileScreen(currentUsername: _currentUsername),
        ),
      ),
    ).then((updatedUser) {
      if (!mounted || updatedUser == null) return;
      setState(() {
        _currentUsername = updatedUser.username;
        _avatarUrl = updatedUser.avatar;
      });
    });
  }

  // Mở màn hình đổi mật khẩu
  void _openChangePassword() {
    _closeDrawer();
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
  }


  @override
  Widget build(BuildContext context) {
    // Cung cấp 4 BLoC cho toàn bộ cây widget trong HomeScreen
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _followBloc),
        BlocProvider.value(value: _blockBloc),
        BlocProvider.value(value: _chatBloc),
        BlocProvider.value(value: _notificationBloc),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthLogoutSuccess) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const LoginScreen()),
              (route) => false,
            );
          } else if (state is ChangeInfoSuccess) {
            if (mounted) {
              setState(() {
                _currentUsername = state.updatedUser.username;
                _avatarUrl = state.updatedUser.avatar;
              });
            }
          }
        },
        child: Scaffold(
          key: _scaffoldKey,
          backgroundColor: const Color(0xFFF5F5F5),
          appBar: _buildAppBar(),
          drawer: _buildDrawer(),
          body: IndexedStack(
            index: _selectedIndex,
            children: [
              _HomeTabBody(username: _currentUsername),
              const _CategoryTabBody(),
              const _CartTabBody(),
              _ProfileTabBody(
                userId: widget.userId,
                username: _currentUsername,
                avatarUrl: _avatarUrl,
                onFollowers: _openFollowers,
                onFollowing: _openFollowing,
                onEditProfile: _openUpdateProfile,
                onChangePassword: _openChangePassword,
                onBlockedUsers: _openBlockedUsers,
                onLogout: () => _showLogoutDialog(context),
              ),
            ],
          ),
          bottomNavigationBar: _buildBottomNavBar(),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _navyBlue,
      title: Text(
        _selectedIndex == 0
            ? 'Quân Nhu Tiền Tuyến'
            : _selectedIndex == 1
                ? 'Danh mục'
                : _selectedIndex == 2
                    ? 'Giỏ hàng'
                    : 'Trang cá nhân',
        style: const TextStyle(color: Colors.white, fontSize: 16),
      ),
      actions: [
        // Nút chat với badge số tin nhắn mới — chỉ rebuild khi ConversationsLoaded
        // để badge không nhấp nháy về 0 trong lúc tải
        BlocBuilder<ChatBloc, ChatState>(
          buildWhen: (_, current) => current is ConversationsLoaded,
          builder: (context, state) {
            if (state is ConversationsLoaded) {
              _chatUnreadCount = state.numNewMessage;
            }
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: _openConversations,
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Colors.white),
                    if (_chatUnreadCount > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: _Badge(count: _chatUnreadCount),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomNavBar() {
    return BlocBuilder<NotificationBloc, NotificationState>(
      builder: (context, notifState) {
        final notifUnread = notifState is NotificationsLoaded
            ? notifState.unreadCount
            : 0;

        return BottomNavigationBar(
          currentIndex: _selectedIndex,
          selectedItemColor: _shopeeOrange,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (index) {
            if (index == _selectedIndex) return;
            // Tab Thông báo → push sang NotificationScreen riêng
            if (index == 4) {
              _openNotifications();
              return;
            }
            setState(() => _selectedIndex = index);
          },
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Trang chủ',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.grid_view_outlined),
              activeIcon: Icon(Icons.grid_view),
              label: 'Danh mục',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.shopping_cart_outlined),
              activeIcon: Icon(Icons.shopping_cart),
              label: 'Giỏ hàng',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tôi',
            ),
            // Thông báo với badge
            BottomNavigationBarItem(
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications_outlined),
                  if (notifUnread > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: _Badge(count: notifUnread),
                    ),
                ],
              ),
              activeIcon: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(Icons.notifications),
                  if (notifUnread > 0)
                    Positioned(
                      right: -6,
                      top: -4,
                      child: _Badge(count: notifUnread),
                    ),
                ],
              ),
              label: 'Thông báo',
            ),
          ],
        );
      },
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: const BoxDecoration(color: _navyBlue),
            accountName: Text('Đồng chí: $_currentUsername'),
            accountEmail: const Text('Quân binh chủng: Bộ binh'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: _avatarUrl != null && _avatarUrl!.isNotEmpty
                  ? NetworkImage(_avatarUrl!)
                  : null,
              child: _avatarUrl == null || _avatarUrl!.isEmpty
                  ? const Icon(Icons.person, size: 50, color: _navyBlue)
                  : null,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.person_outline, color: Colors.blue),
            title: const Text('Cập nhật hồ sơ'),
            onTap: _openUpdateProfile,
          ),
          ListTile(
            leading: const Icon(Icons.lock_reset, color: Colors.orange),
            title: const Text('Đổi mật khẩu'),
            onTap: _openChangePassword,
          ),
          ListTile(
            leading: const Icon(Icons.block, color: Colors.grey),
            title: const Text('Người dùng đã chặn'),
            onTap: _openBlockedUsers,
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Đăng xuất'),
            onTap: () {
              Navigator.pop(context);
              _showLogoutDialog(context);
            },
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Đồng chí muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('HỦY'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              ctx.read<AuthBloc>().add(LogoutButtonPressed(token: widget.token));
            },
            child: const Text('ĐĂNG XUẤT', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Badge số đếm nhỏ gọn
class _Badge extends StatelessWidget {
  final int count;
  const _Badge({required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
      decoration: const BoxDecoration(
        color: _shopeeOrange,
        borderRadius: BorderRadius.all(Radius.circular(8)),
      ),
      constraints: const BoxConstraints(minWidth: 16),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
        textAlign: TextAlign.center,
      ),
    );
  }
}

// ── Tab bodies ─────────────────────────────────────────────────────────────

// Tab 0: Trang chủ
class _HomeTabBody extends StatelessWidget {
  final String username;
  const _HomeTabBody({required this.username});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.military_tech, size: 100, color: Colors.lightGreen),
          const SizedBox(height: 20),
          Text(
            'Chào đồng chí: $username',
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const Padding(
            padding: EdgeInsets.all(20),
            child: Text(
              'Hệ thống sẵn sàng tiếp nhận yêu cầu quân nhu.',
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// Tab 1: Danh mục (placeholder)
class _CategoryTabBody extends StatelessWidget {
  const _CategoryTabBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.grid_view, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Danh mục sản phẩm', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Tab 2: Giỏ hàng (placeholder)
class _CartTabBody extends StatelessWidget {
  const _CartTabBody();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
          SizedBox(height: 12),
          Text('Giỏ hàng trống', style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}

// Tab 3: Trang cá nhân với links tới followers/following/settings
class _ProfileTabBody extends StatelessWidget {
  final String userId;
  final String username;
  final String? avatarUrl;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onBlockedUsers;
  final VoidCallback onLogout;

  const _ProfileTabBody({
    required this.userId,
    required this.username,
    this.avatarUrl,
    required this.onFollowers,
    required this.onFollowing,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onBlockedUsers,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Vùng thông tin cá nhân
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Column(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 44,
                  backgroundColor: Colors.grey[200],
                  backgroundImage: (avatarUrl != null && avatarUrl!.isNotEmpty)
                      ? NetworkImage(avatarUrl!)
                      : null,
                  child: (avatarUrl == null || avatarUrl!.isEmpty)
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                const SizedBox(height: 10),
                Text(
                  username,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),

                // Nút followers / following
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _StatButton(
                      label: 'Người theo dõi',
                      onTap: onFollowers,
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    _StatButton(
                      label: 'Đang theo dõi',
                      onTap: onFollowing,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Phần cài đặt
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.person_outline,
                  iconColor: Colors.blue,
                  title: 'Cập nhật hồ sơ',
                  onTap: onEditProfile,
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.lock_reset,
                  iconColor: Colors.orange,
                  title: 'Đổi mật khẩu',
                  onTap: onChangePassword,
                ),
                const _Divider(),
                _SettingsTile(
                  icon: Icons.block,
                  iconColor: Colors.grey,
                  title: 'Người dùng đã chặn',
                  onTap: onBlockedUsers,
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Nút đăng xuất
          Container(
            color: Colors.white,
            child: _SettingsTile(
              icon: Icons.logout,
              iconColor: Colors.red,
              title: 'Đăng xuất',
              titleColor: Colors.red,
              onTap: onLogout,
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

// Nút thống kê (followers / following)
class _StatButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _StatButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          const Icon(Icons.people_outline, size: 22, color: _shopeeOrange),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}

// Tile mục cài đặt tái sử dụng
class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final Color? titleColor;
  final VoidCallback onTap;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.titleColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor, size: 22),
      title: Text(
        title,
        style: TextStyle(fontSize: 14, color: titleColor ?? Colors.black87),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: onTap,
      dense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
    );
  }
}

// Đường kẻ ngăn cách mảnh trong settings
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 52, color: Color(0xFFF0F0F0));
  }
}
