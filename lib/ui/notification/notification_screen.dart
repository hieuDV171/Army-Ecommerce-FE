import 'package:army_ecommerce/blocs/notification/notification_bloc.dart';
import 'package:army_ecommerce/blocs/notification/notification_event.dart';
import 'package:army_ecommerce/blocs/notification/notification_state.dart';
import 'package:army_ecommerce/models/notification_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/ui/auth/login_screen.dart';

const Color _shopeeOrange = Color(0xFFE83A14);
const Color _greyBackground = Color(0xFFF5F5F5);

class NotificationScreen extends StatefulWidget {
  final bool isTab;
  final String token;
  const NotificationScreen({super.key, this.isTab = false, this.token = ""});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final ScrollController _scrollController = ScrollController();
  // Lưu id các thông báo đã đọc trong phiên này để cập nhật UI ngay lập tức
  final Set<String> _locallyReadIds = {};

  @override
  void initState() {
    super.initState();
    if (widget.token.isNotEmpty) {
      context.read<NotificationBloc>().add(LoadNotificationsRequested());
    }
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= maxScroll - 200) {
      context.read<NotificationBloc>().add(LoadMoreNotificationsRequested());
    }
  }

  Future<void> _onRefresh() async {
    _locallyReadIds.clear();
    context.read<NotificationBloc>().add(LoadNotificationsRequested());
    await Future.delayed(const Duration(milliseconds: 800));
  }

  // Đánh dấu đã đọc và cập nhật UI ngay lập tức (optimistic)
  void _onNotificationTap(NotificationModel notification) {
    if (!notification.isRead && !_locallyReadIds.contains(notification.notificationId)) {
      setState(() => _locallyReadIds.add(notification.notificationId));
      context.read<NotificationBloc>().add(
            MarkNotificationReadRequested(notificationId: notification.notificationId),
          );
    }
    // TODO: Điều hướng tới màn hình liên quan dựa trên notification.type và notification.objectId
  }

  @override
  Widget build(BuildContext context) {
    if (widget.token.isEmpty) {
      return Scaffold(
        backgroundColor: _greyBackground,
        appBar: AppBar(
          backgroundColor: widget.isTab ? _shopeeOrange : Colors.white,
          elevation: widget.isTab ? 0.0 : 0.5,
          iconTheme: IconThemeData(color: widget.isTab ? Colors.white : Colors.black87),
          leading: widget.isTab
              ? IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: () {
                    Scaffold.of(context).openDrawer();
                  },
                )
              : null,
          title: Text(
            'Thông báo',
            style: TextStyle(
              color: widget.isTab ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          centerTitle: true,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.notifications_none_outlined, size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              const Text(
                'Vui lòng đăng nhập để xem thông báo',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.grey),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _shopeeOrange,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                  );
                },
                child: const Text('Đăng nhập ngay', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _greyBackground,
      appBar: AppBar(
        backgroundColor: widget.isTab ? _shopeeOrange : Colors.white,
        elevation: widget.isTab ? 0.0 : 0.5,
        iconTheme: IconThemeData(color: widget.isTab ? Colors.white : Colors.black87),
        leading: widget.isTab
            ? IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              )
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
        automaticallyImplyLeading: !widget.isTab,
        title: Text(
          'Thông báo',
          style: TextStyle(
            color: widget.isTab ? Colors.white : Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<NotificationBloc, NotificationState>(
        listener: (context, state) {
          if (state is NotificationFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.error}')),
            );
          }
        },
        builder: (context, state) {
          if (state is NotificationLoading) {
            return _buildSkeleton();
          }

          List<NotificationModel> notifications = [];
          bool isLoadingMore = false;

          if (state is NotificationsLoaded) {
            notifications = state.notifications;
          } else if (state is NotificationLoadingMore) {
            notifications = state.currentList;
            isLoadingMore = true;
          }

          if (notifications.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: _shopeeOrange,
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              itemCount: notifications.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == notifications.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: _shopeeOrange),
                    ),
                  );
                }
                final notification = notifications[index];
                final isRead = notification.isRead ||
                    _locallyReadIds.contains(notification.notificationId);
                return _NotificationItem(
                  notification: notification,
                  isRead: isRead,
                  onTap: () => _onNotificationTap(notification),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 8,
      itemBuilder: (context, i) => const _SkeletonItem(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.notifications_none_outlined, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Chưa có thông báo nào',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            'Các thông báo về đơn hàng, lượt thích và\nnhững hoạt động khác sẽ xuất hiện ở đây',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// Widget một dòng thông báo
class _NotificationItem extends StatelessWidget {
  final NotificationModel notification;
  final bool isRead;
  final VoidCallback onTap;

  const _NotificationItem({
    required this.notification,
    required this.isRead,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: isRead ? Colors.white : const Color(0xFFFFF3F0),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon loại thông báo trong vòng tròn màu
            _NotificationIcon(type: notification.type),
            const SizedBox(width: 12),

            // Nội dung thông báo + thời gian
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.content,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black87,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.w500,
                      height: 1.4,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(notification.createdAt),
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),

            // Chấm đỏ nếu chưa đọc
            if (!isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: _shopeeOrange,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Định dạng thời gian kiểu "vừa xong", "5 phút trước", "2 giờ trước", ...
  String _formatTime(DateTime createdAt) {
    final now = DateTime.now();
    final diff = now.difference(createdAt);

    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
    if (diff.inHours < 24) return '${diff.inHours} giờ trước';
    if (diff.inDays < 7) return '${diff.inDays} ngày trước';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()} tuần trước';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()} tháng trước';
    return '${(diff.inDays / 365).floor()} năm trước';
  }
}

// Icon hiển thị theo loại thông báo
class _NotificationIcon extends StatelessWidget {
  final String type;

  const _NotificationIcon({required this.type});

  @override
  Widget build(BuildContext context) {
    final config = _iconConfig(type);
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: config.$2.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(config.$1, color: config.$2, size: 22),
    );
  }

  // Trả về (icon, màu) theo loại thông báo
  (IconData, Color) _iconConfig(String type) {
    switch (type) {
      case 'order':
        return (Icons.local_shipping_outlined, const Color(0xFF1E88E5));
      case 'like':
        return (Icons.favorite_outline, _shopeeOrange);
      case 'follow':
        return (Icons.person_add_outlined, const Color(0xFF43A047));
      case 'comment':
        return (Icons.chat_bubble_outline, const Color(0xFF8E24AA));
      case 'promotion':
        return (Icons.local_offer_outlined, _shopeeOrange);
      case 'system':
        return (Icons.notifications_outlined, const Color(0xFF757575));
      default:
        return (Icons.notifications_outlined, const Color(0xFF757575));
    }
  }
}

// Skeleton placeholder item
class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Skeleton icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Skeleton text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, color: Colors.grey[200]),
                const SizedBox(height: 6),
                Container(height: 13, width: 260, color: Colors.grey[200]),
                const SizedBox(height: 6),
                Container(height: 11, width: 80, color: Colors.grey[100]),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
