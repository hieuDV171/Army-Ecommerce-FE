import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/blocs/block/block_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/blocs/follow/follow_bloc.dart';
import 'package:army_ecommerce/blocs/notification/notification_bloc.dart';
import 'package:army_ecommerce/blocs/notification/notification_event.dart';
import 'package:army_ecommerce/blocs/notification/notification_state.dart';
import 'package:army_ecommerce/repositories/block_repository.dart';
import 'package:army_ecommerce/repositories/chat_repository.dart';
import 'package:army_ecommerce/repositories/follow_repository.dart';
import 'package:army_ecommerce/repositories/notification_repository.dart';
import 'package:army_ecommerce/ui/block/blocked_users_screen.dart';
import 'package:army_ecommerce/ui/follow/followers_screen.dart';
import 'package:army_ecommerce/ui/follow/following_screen.dart';
import 'package:army_ecommerce/ui/notification/notification_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/core/utils/logger.dart';

import '../../blocs/marketplace/marketplace_bloc.dart' show HomeBloc;
import '../../blocs/marketplace/marketplace_event.dart' show HomeRequested;
import '../../blocs/settings/push_setting_bloc.dart';
import '../../core/services/session_manager.dart';
import '../../core/services/cart_manager.dart';
import '../../repositories/marketplace_repository.dart';
import '../auth/change_password_screen.dart';
import '../marketplace/marketplace_chat_pages.dart';
import '../marketplace/marketplace_home_page.dart';
import '../marketplace/marketplace_list_pages.dart';
import '../marketplace/marketplace_order_pages.dart';
import '../marketplace/marketplace_product_pages.dart';
import '../widgets/app_button.dart';
import '../widgets/price_text.dart';
import '../profile/user_profile_screen.dart';
import '../settings/push_settings_screen.dart';

const Color _shopeeOrange = Color(0xFFEE4D2D);
const Color _navyBlue = Color(0xFF003366);

class HomeScreen extends StatefulWidget {
  final String userId;
  final String username;
  final String token;

  const HomeScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.token,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  String? _avatarUrl;
  late String _currentUsername;
  // BLoC phụ trách API follow/block/chat/notification — tạo và dispose trong lifecycle
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

    // Khởi tạo 4 BLoC từ Repository do thành viên đảm nhận
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

  // Mở màn hình thông báo
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: _notificationBloc,
          child: const NotificationScreen(),
        ),
      ),
    ).then((_) {
      // Làm mới badge sau khi đọc thông báo
      if (mounted) _notificationBloc.add(LoadNotificationsRequested());
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
    _scaffoldKey.currentState?.closeDrawer();
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

  // Mở màn hình hồ sơ cá nhân (dùng UserProfileScreen mới của team)
  void _openUpdateProfile() {
    _scaffoldKey.currentState?.closeDrawer();
    final authBloc = context.read<AuthBloc>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: authBloc,
          child: const UserProfileScreen(),
        ),
      ),
    );
  }

  // Mở màn hình đổi mật khẩu
  void _openChangePassword() {
    _scaffoldKey.currentState?.closeDrawer();
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
    // Cung cấp 4 BLoC phụ trách API cho toàn bộ cây widget trong HomeScreen
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _followBloc),
        BlocProvider.value(value: _blockBloc),
        BlocProvider.value(value: _chatBloc),
        BlocProvider.value(value: _notificationBloc),
      ],
      child: BlocProvider<HomeBloc>(
        // HomeBloc phục vụ MarketplaceHomeBody (giao diện mới của team)
        create: (ctx) => HomeBloc(
          marketplaceRepository: ctx.read<MarketplaceRepository>(),
        )..add(HomeRequested()),
        child: BlocListener<AuthBloc, AuthState>(
          listener: (context, state) {
            // Cập nhật username và avatar khi đổi thông tin thành công
            if (state is ChangeInfoSuccess && mounted) {
              setState(() {
                _currentUsername = state.updatedUser.username;
                _avatarUrl = state.updatedUser.avatar;
              });
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: const Color(0xFFF5F5F5),
            appBar: _buildAppBar(),
            drawer: _HomeDrawer(
              displayName: _currentUsername,
              avatarUrl: _avatarUrl,
              token: widget.token,
              onBlockedUsers: _openBlockedUsers,
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                // Tab 0: Trang chủ marketplace (giao diện mới của team)
                MarketplaceHomeBody(
                  username: _currentUsername,
                  avatarUrl: _avatarUrl,
                  userId: widget.userId,
                ),
                // Tab 1: Danh mục (placeholder)
                const _CategoryTabBody(),
                // Tab 2: Giỏ hàng (placeholder)
                const _CartTabBody(),
                // Tab 3: Trang cá nhân với links followers/following/blocked
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
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: _navyBlue,
      iconTheme: const IconThemeData(color: Colors.white),
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
            // Tab Thông báo (index 4) → push sang màn hình riêng
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
            BottomNavigationBarItem(
              icon: ListenableBuilder(
                listenable: CartManager(),
                builder: (context, child) {
                  final cartCount = CartManager().totalCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart_outlined),
                      if (cartCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: _Badge(count: cartCount),
                        ),
                    ],
                  );
                },
              ),
              activeIcon: ListenableBuilder(
                listenable: CartManager(),
                builder: (context, child) {
                  final cartCount = CartManager().totalCount;
                  return Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const Icon(Icons.shopping_cart),
                      if (cartCount > 0)
                        Positioned(
                          right: -6,
                          top: -4,
                          child: _Badge(count: cartCount),
                        ),
                    ],
                  );
                },
              ),
              label: 'Giỏ hàng',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tôi',
            ),
            // Thông báo với badge số chưa đọc
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

  void _showLogoutDialog(BuildContext ctx) {
    final authBloc = ctx.read<AuthBloc>();
    showDialog<void>(
      context: ctx,
      builder: (innerCtx) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Đồng chí muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(innerCtx),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              logger.i('HOME: Dispatching LogoutButtonPressed');
              Navigator.pop(innerCtx);
              authBloc.add(LogoutButtonPressed(token: widget.token));
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ── Drawer (giao diện mới của team) ────────────────────────────────────────

class _HomeDrawer extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final String token;
  final VoidCallback onBlockedUsers;

  const _HomeDrawer({
    required this.displayName,
    required this.avatarUrl,
    required this.token,
    required this.onBlockedUsers,
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
          _DrawerTile(
            icon: Icons.block,
            color: Colors.grey,
            title: 'Người dùng đã chặn',
            onTap: onBlockedUsers,
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
            onTap: () => _push(context, const BuyerOrdersPage()),
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
    logger.i('HOME DRAWER: _showLogoutDialog called');
    final authBloc = context.read<AuthBloc>();

    showDialog<void>(
      context: context,
      builder: (innerContext) => AlertDialog(
        title: const Text('Xác nhận'),
        content: const Text('Đồng chí muốn đăng xuất khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(innerContext);
              Navigator.pop(context);
            },
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              logger.i('HOME DRAWER: Dispatching LogoutButtonPressed');
              Navigator.pop(innerContext);
              Navigator.pop(context);
              authBloc.add(LogoutButtonPressed(token: token));
            },
            child: const Text('Đăng xuất', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// Tile menu drawer tái sử dụng
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

// Tab 2: Giỏ hàng (interactive Cart Screen)
class _CartTabBody extends StatelessWidget {
  const _CartTabBody();

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: CartManager(),
      builder: (context, child) {
        final items = CartManager().items;
        if (items.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey),
                SizedBox(height: 16),
                Text(
                  'Giỏ hàng trống',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                ),
                SizedBox(height: 8),
                Text(
                  'Hãy khám phá thêm nhiều sản phẩm quân nhu nhé!',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final totalPrice = items.fold<num>(0, (sum, item) => sum + item.price * item.quantity);

        return Column(
          children: [
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    elevation: 1,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          // Product Image
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                                ? Image.network(
                                    item.imageUrl!,
                                    width: 70,
                                    height: 70,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      width: 70,
                                      height: 70,
                                      color: Colors.grey[200],
                                      child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                                    ),
                                  )
                                : Container(
                                    width: 70,
                                    height: 70,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.inventory_2_outlined, color: Colors.grey),
                                  ),
                          ),
                          const SizedBox(width: 12),
                          // Title & Price
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.title,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                PriceText(price: item.price),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Quantity controls & Delete
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                                onPressed: () {
                                  CartManager().updateQuantity(item.productId, 0);
                                },
                              ),
                              Row(
                                children: [
                                  GestureDetector(
                                    onTap: () {
                                      CartManager().updateQuantity(item.productId, item.quantity - 1);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.remove, size: 14),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 10),
                                    child: Text(
                                      '${item.quantity}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  GestureDetector(
                                    onTap: () {
                                      CartManager().updateQuantity(item.productId, item.quantity + 1);
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Icon(Icons.add, size: 14),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            // Bottom Panel
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    offset: const Offset(0, -2),
                    blurRadius: 10,
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Tổng tiền hàng:',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                        ),
                        PriceText(price: totalPrice),
                      ],
                    ),
                    const SizedBox(height: 16),
                    AppButton(
                      label: 'Mua hàng',
                      icon: Icons.shopping_bag_outlined,
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CheckoutPage(items: items),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Tab 3: Trang cá nhân với links tới followers/following/blocked/settings
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
                    _StatButton(label: 'Người theo dõi', onTap: onFollowers),
                    Container(
                      width: 1,
                      height: 32,
                      color: Colors.grey[300],
                      margin: const EdgeInsets.symmetric(horizontal: 24),
                    ),
                    _StatButton(label: 'Đang theo dõi', onTap: onFollowing),
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
                  title: 'Hồ sơ của tôi',
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
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.black87)),
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

// Đường kẻ ngăn cách mỏng trong settings
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 52, color: Color(0xFFF0F0F0));
  }
}
