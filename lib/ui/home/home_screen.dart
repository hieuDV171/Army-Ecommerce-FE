import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/blocs/block/block_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/blocs/follow/follow_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/home/home_bloc.dart';
import 'package:army_ecommerce/blocs/marketplace/home/home_event.dart';
import 'package:army_ecommerce/blocs/marketplace/home/home_state.dart';
import 'package:army_ecommerce/blocs/notification/notification_bloc.dart';
import 'package:army_ecommerce/blocs/notification/notification_event.dart';
import 'package:army_ecommerce/blocs/notification/notification_state.dart';
import 'package:army_ecommerce/repositories/block_repository.dart';
import 'package:army_ecommerce/repositories/follow_repository.dart';
import 'package:army_ecommerce/repositories/notification_repository.dart';
import 'package:army_ecommerce/ui/auth/login_screen.dart';
import 'package:army_ecommerce/ui/block/blocked_users_screen.dart';
import 'package:army_ecommerce/ui/follow/followers_screen.dart';
import 'package:army_ecommerce/ui/follow/following_screen.dart';
import 'package:army_ecommerce/ui/notification/notification_screen.dart';
import 'package:army_ecommerce/ui/util/widgets/login_prompt.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/core/services/firebase_notification_service.dart';

import '../../blocs/settings/push_setting_bloc.dart';
import '../../core/services/session_manager.dart';
import '../../core/services/cart_manager.dart';
import '../../repositories/marketplace_repository.dart';
import '../auth/change_password_screen.dart';
import '../marketplace/marketplace_home_page.dart';
import '../marketplace/list/news_page.dart';
import '../marketplace/list/wallet_page.dart';
import '../marketplace/order/buyer_orders_page.dart';
import '../marketplace/order/seller_orders_page.dart';
import '../marketplace/address/address_list_page.dart';
import '../marketplace/checkout/checkout_page.dart';
import '../marketplace/product/product_search_page.dart';
import '../marketplace/product/seller_listings_page.dart';
import '../marketplace/reward_screen.dart';
import '../util/widgets/app_button.dart';
import '../util/widgets/price_text.dart';
import '../profile/user_profile_screen.dart';
import '../settings/push_settings_screen.dart';
import '../settings/theme_selection_screen.dart';
import '../util/constants/app_colors.dart';
import '../util/theme/special_app_theme.dart';


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

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  String? _avatarUrl;
  String? _coverImageUrl;
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
    WidgetsBinding.instance.addObserver(this);
    _currentUsername = widget.username;

    // Khởi tạo 4 BLoC từ Repository do thành viên đảm nhận
    _followBloc = FollowBloc(followRepository: context.read<FollowRepository>());
    _blockBloc = BlockBloc(blockRepository: context.read<BlockRepository>());
    _chatBloc = ChatBloc(marketplaceRepository: context.read<MarketplaceRepository>());
    _notificationBloc = NotificationBloc(
      notificationRepository: context.read<NotificationRepository>(),
    );

    // Đăng ký lắng nghe foreground message để cập nhật badge số chưa đọc ngay lập tức
    FirebaseNotificationService.addMessageReceivedListener(_onForegroundMessageReceived);

    // Tải avatar và cover image từ bộ nhớ cục bộ
    if (widget.token.isNotEmpty) {
      SessionManager.getAvatar().then((avatar) {
        if (mounted) setState(() => _avatarUrl = avatar);
      });
      SessionManager.getCoverImage().then((cover) {
        if (mounted) setState(() => _coverImageUrl = cover);
      });
    }

    // Tải sẵn dữ liệu sau khi frame đầu tiên được vẽ để tránh xung đột vòng đời
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onForegroundMessageReceived();
      if (mounted && widget.token.isNotEmpty) {
        context.read<AuthBloc>().add(GetUserInfoRequested(userId: null));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    FirebaseNotificationService.removeMessageReceivedListener(_onForegroundMessageReceived);
    _followBloc.close();
    _blockBloc.close();
    _chatBloc.close();
    _notificationBloc.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onForegroundMessageReceived();
    }
  }

  void _onForegroundMessageReceived() {
    if (mounted && widget.token.isNotEmpty) {
      _notificationBloc.add(LoadNotificationsRequested());
      _chatBloc.add(LoadConversationsRequested());
    }
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
            if (state is ChangeInfoSuccess && mounted) {
              setState(() {
                _currentUsername = state.updatedUser.username;
                _avatarUrl = state.updatedUser.avatar;
                _coverImageUrl = state.updatedUser.coverImage;
              });
            } else if (state is SetUserInfoSuccess && mounted) {
              setState(() {
                _currentUsername = state.user.username;
                _avatarUrl = state.user.avatar;
                _coverImageUrl = state.user.coverImage;
              });
            } else if (state is GetUserInfoSuccess && mounted) {
              setState(() {
                _currentUsername = state.user.username;
                _avatarUrl = state.user.avatar;
                _coverImageUrl = state.user.coverImage;
              });
            } else if (state is AuthSuccess && mounted) {
              setState(() {
                _currentUsername = state.user.username;
                _avatarUrl = state.user.avatar;
                _coverImageUrl = state.user.coverImage;
              });
            }
          },
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: AppColors.greyBackground,
            appBar: _selectedIndex == 3 ? null : _buildAppBar(),
            drawer: _HomeDrawer(
              displayName: _currentUsername,
              avatarUrl: _avatarUrl,
              token: widget.token,
            ),
            body: IndexedStack(
              index: _selectedIndex,
              children: [
                // Tab 0: Trang chủ marketplace (giao diện mới của team)
                MarketplaceHomeBody(
                  username: _currentUsername,
                  avatarUrl: _avatarUrl,
                  userId: widget.userId,
                  token: widget.token,
                ),
                // Tab 1: Danh mục (placeholder)
                const _CategoryTabBody(),
                // Tab 2: Giỏ hàng (placeholder)
                _CartTabBody(token: widget.token),
                // Tab 3: Thông báo
                BlocProvider.value(
                  value: _notificationBloc,
                  child: NotificationScreen(isTab: true, token: widget.token),
                ),
                // Tab 4: Trang cá nhân với links followers/following/blocked
                _ProfileTabBody(
                  userId: widget.userId,
                  username: _currentUsername,
                  avatarUrl: _avatarUrl,
                  coverImageUrl: _coverImageUrl,
                  onFollowers: _openFollowers,
                  onFollowing: _openFollowing,
                  onEditProfile: _openUpdateProfile,
                  onChangePassword: _openChangePassword,
                  onNotificationSettings: () {
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
    final specialTheme = context.specialTheme;
    return AppBar(
      backgroundColor: specialTheme.useGradient ? Colors.transparent : specialTheme.primaryDarkColor,
      flexibleSpace: specialTheme.useGradient
          ? Container(
              decoration: BoxDecoration(
                gradient: specialTheme.primaryGradient,
              ),
            )
          : null,
      iconTheme: const IconThemeData(color: Colors.white),
      title: Text(
        _selectedIndex == 0
            ? 'Quân Nhu Tiền Tuyến'
            : _selectedIndex == 1
                ? 'Danh mục'
                : _selectedIndex == 2
                    ? 'Giỏ hàng'
                    : _selectedIndex == 3
                        ? 'Thông báo'
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
          selectedItemColor: context.specialTheme.primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          onTap: (index) {
            if (index == _selectedIndex) return;
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
            // Thông báo với badge số chưa đọc (index 3)
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
            // Tôi (index 4)
            const BottomNavigationBarItem(
              icon: Icon(Icons.person_outline),
              activeIcon: Icon(Icons.person),
              label: 'Tôi',
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

  const _HomeDrawer({
    required this.displayName,
    required this.avatarUrl,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    final bool isGuest = token.isEmpty;
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            decoration: BoxDecoration(
              color: context.specialTheme.useGradient ? null : context.specialTheme.primaryDarkColor,
              gradient: context.specialTheme.useGradient ? context.specialTheme.primaryGradient : null,
            ),
            accountName: Text(isGuest ? 'Đồng chí: Khách' : 'Đồng chí: $displayName'),
            accountEmail: const Text('Chợ quân nhu nội bộ'),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: !isGuest && avatarUrl != null && avatarUrl!.isNotEmpty
                  ? SessionManager.getImageProvider(avatarUrl!)
                  : null,
              child: isGuest || avatarUrl == null || avatarUrl!.isEmpty
                  ? Icon(Icons.person, size: 42, color: context.specialTheme.primaryDarkColor)
                  : null,
            ),
          ),
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
            onTap: () {
              if (checkLogin(context, token: token)) {
                _push(context, const BuyerOrdersPage());
              }
            },
          ),
          _DrawerTile(
            icon: Icons.storefront_outlined,
            color: Colors.blueAccent,
            title: 'Quản lý bán hàng',
            onTap: () {
              if (checkLogin(context, token: token)) {
                _push(context, const SellerOrdersPage());
              }
            },
          ),
          _DrawerTile(
            icon: Icons.location_on_outlined,
            color: Colors.green,
            title: 'Địa chỉ giao hàng',
            onTap: () {
              if (checkLogin(context, token: token)) {
                _push(context, const AddressListPage());
              }
            },
          ),
          _DrawerTile(
            icon: Icons.account_balance_wallet_outlined,
            color: Colors.brown,
            title: 'Ví quân nhu',
            onTap: () {
              if (checkLogin(context, token: token)) {
                _push(context, const WalletPage());
              }
            },
          ),
          _DrawerTile(
            icon: Icons.stars_outlined,
            color: Colors.amber,
            title: 'Điểm thưởng',
            onTap: () {
              if (checkLogin(context, token: token)) {
                _push(context, const RewardScreen());
              }
            },
          ),

          _DrawerTile(
            icon: Icons.article_outlined,
            color: Colors.cyan,
            title: 'Tin tức',
            onTap: () => _push(context, const NewsPage()),
          ),
          _DrawerTile(
            icon: Icons.palette_outlined,
            color: Colors.purple,
            title: 'Chọn giao diện',
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ThemeSelectionScreen()),
              );
            },
          ),
          const Divider(),
          if (isGuest)
            _DrawerTile(
              icon: Icons.login,
              color: Colors.green,
              title: 'Đăng nhập',
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            )
          else
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

  // Removed _showThemeSelectorDialog as it is replaced by ThemeSelectionScreen.

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
      decoration: BoxDecoration(
        color: context.specialTheme.useGradient ? null : context.specialTheme.primaryDarkColor,
        gradient: context.specialTheme.useGradient ? context.specialTheme.primaryGradient : null,
        borderRadius: const BorderRadius.all(Radius.circular(8)),
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

// Tab 1: Danh mục
class _CategoryTabBody extends StatelessWidget {
  const _CategoryTabBody();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeBloc, HomeState>(
      builder: (context, state) {
        if (state.isInitialLoading) {
          return Center(
            child: CircularProgressIndicator(color: context.specialTheme.primaryColor),
          );
        }
        final categories = state.categories;
        if (categories.isEmpty) {
          return const Center(
            child: Text(
              'Không có danh mục nào',
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 16,
            childAspectRatio: 0.85,
          ),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final category = categories[index];
            return InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SearchPage(categoryId: category.id),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: context.specialTheme.primaryColor.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.category_outlined,
                        color: context.specialTheme.primaryColor,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        category.name,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// Tab 2: Giỏ hàng (interactive Cart Screen)
class _CartTabBody extends StatelessWidget {
  final String token;
  const _CartTabBody({required this.token});

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
                        if (checkLogin(context, token: token)) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CheckoutPage(items: items),
                            ),
                          );
                        }
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
  final String? coverImageUrl;
  final VoidCallback onFollowers;
  final VoidCallback onFollowing;
  final VoidCallback onEditProfile;
  final VoidCallback onChangePassword;
  final VoidCallback onNotificationSettings;
  final VoidCallback onBlockedUsers;
  final VoidCallback onLogout;

  const _ProfileTabBody({
    required this.userId,
    required this.username,
    this.avatarUrl,
    this.coverImageUrl,
    required this.onFollowers,
    required this.onFollowing,
    required this.onEditProfile,
    required this.onChangePassword,
    required this.onNotificationSettings,
    required this.onBlockedUsers,
    required this.onLogout,
  });

  void _showZoomedAvatar(BuildContext context, String imageUrl, String name) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.black,
          insetPadding: EdgeInsets.zero,
          child: Stack(
            alignment: Alignment.center,
            children: [
              InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image(
                  image: SessionManager.getImageProvider(imageUrl),
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.white, size: 80),
                ),
              ),
              Positioned(
                top: MediaQuery.of(context).padding.top + 16,
                left: 16,
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isGuest = userId.isEmpty;
    return SingleChildScrollView(
      child: Column(
        children: [
          // Vùng thông tin cá nhân đồng bộ Side bar header (Ảnh bìa / Nền xám)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 4),
              color: (isGuest || coverImageUrl == null || coverImageUrl!.isEmpty)
                  ? (context.specialTheme.useGradient ? null : const Color.fromARGB(255, 251, 209, 209))
                  : null,
              gradient: (isGuest || coverImageUrl == null || coverImageUrl!.isEmpty) && context.specialTheme.useGradient
                  ? context.specialTheme.primaryGradient
                  : null,
              image: (!isGuest && coverImageUrl != null && coverImageUrl!.isNotEmpty)
                  ? DecorationImage(
                      image: SessionManager.getImageProvider(coverImageUrl!),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withValues(alpha: 0.3),
                        BlendMode.srcOver,
                      ),
                    )
                  : null,
            ),
            child: Column(
              children: [
                // Avatar
                GestureDetector(
                  onTap: () {
                    if (!isGuest && avatarUrl != null && avatarUrl!.isNotEmpty) {
                      _showZoomedAvatar(context, avatarUrl!, username);
                    }
                  },
                  child: CircleAvatar(
                    radius: 46,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 44,
                      backgroundColor: Colors.white,
                      backgroundImage: (!isGuest && avatarUrl != null && avatarUrl!.isNotEmpty)
                          ? SessionManager.getImageProvider(avatarUrl!)
                          : null,
                      child: (isGuest || avatarUrl == null || avatarUrl!.isEmpty)
                          ? Icon(Icons.person, size: 50, color: context.specialTheme.primaryDarkColor)
                          : null,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                if (isGuest) ...[
                  const Text(
                    'Chào mừng bạn đến với Army E-commerce!',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: context.specialTheme.primaryDarkColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LoginScreen()),
                      );
                    },
                    child: const Text('Đăng nhập / Đăng ký', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ] else ...[
                  Text(
                    username,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Nút followers / following
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _StatButton(
                          label: 'Người theo dõi',
                          onTap: onFollowers,
                          textColor: Colors.white,
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Colors.white30,
                          margin: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                        _StatButton(
                          label: 'Đang theo dõi',
                          onTap: onFollowing,
                          textColor: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 8),

          // Phần cài đặt
          if (!isGuest) ...[
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
                    icon: Icons.inventory_2_outlined,
                    iconColor: Colors.teal,
                    title: 'Sản phẩm của tôi',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SellerListingsPage(userId: userId),
                        ),
                      );
                    },
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
                    icon: Icons.notifications_active,
                    iconColor: Colors.purple,
                    title: 'Cài đặt thông báo',
                    onTap: onNotificationSettings,
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
          ] else ...[
            Container(
              padding: const EdgeInsets.all(24),
              color: Colors.white,
              child: const Center(
                child: Text(
                  'Vui lòng đăng nhập để xem thông tin cá nhân và thiết lập tài khoản.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 13),
                ),
              ),
            ),
          ],
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
  final Color textColor;

  const _StatButton({
    required this.label,
    required this.onTap,
    this.textColor = Colors.black87,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(Icons.people_outline, size: 20, color: textColor),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
              fontWeight: FontWeight.w500,
            ),
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

// Đường kẻ ngăn cách mỏng trong settings
class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(height: 1, indent: 52, color: AppColors.greyLightest);
  }
}
