import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/follow/follow_bloc.dart';
import 'package:army_ecommerce/blocs/follow/follow_event.dart';
import 'package:army_ecommerce/blocs/follow/follow_state.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:army_ecommerce/ui/marketplace/product/seller_listings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../util/constants/app_colors.dart';
import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

Color _themePrimaryColor(BuildContext context) => context.specialTheme.primaryDarkColor;
const Color _greyBackground = AppColors.greyBackground;

class FollowersScreen extends StatefulWidget {
  // userId của người cần xem danh sách người theo dõi
  final String userId;
  final String title;

  const FollowersScreen({
    super.key,
    required this.userId,
    this.title = 'Người theo dõi',
  });

  @override
  State<FollowersScreen> createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tải danh sách người theo dõi khi màn hình được mở
    context.read<FollowBloc>().add(LoadFollowersRequested(userId: widget.userId));
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Kiểm tra nếu đã cuộn đến gần cuối danh sách
  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    if (currentScroll >= maxScroll - 200) {
      context.read<FollowBloc>().add(LoadMoreFollowersRequested(userId: widget.userId));
    }
  }

  // Xử lý kéo để làm mới danh sách
  Future<void> _onRefresh() async {
    context.read<FollowBloc>().add(LoadFollowersRequested(userId: widget.userId));
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greyBackground,
      appBar: AppBar(
        backgroundColor: context.specialTheme.useGradient
            ? Colors.transparent
            : context.specialTheme.primaryDarkColor,
        flexibleSpace: context.specialTheme.useGradient
            ? Container(
                decoration: BoxDecoration(
                  gradient: context.specialTheme.primaryGradient,
                ),
              )
            : null,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<FollowBloc, FollowState>(
        // Không rebuild khi FollowActionSuccess vì ngay sau đó sẽ có FollowersLoaded
        buildWhen: (_, current) => current is! FollowActionSuccess,
        listenWhen: (_, current) =>
            current is FollowActionSuccess || current is FollowFailure,
        listener: (context, state) {
          if (state is FollowActionSuccess) {
            final message = state.isFollowed
                ? 'Theo dõi ${state.username} thành công'
                : 'Đã hủy theo dõi ${state.username}';
            AppSnackBar.show(context, message: message, backgroundColor: _themePrimaryColor(context), duration: Duration(seconds: 2));
          } else if (state is FollowFailure) {
            if (state.code == ResponseCode.notAccess.code ||
                state.error == ResponseCode.notAccess.message ||
                state.error.contains('Not access')) {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Thông báo'),
                  content: const Text('Bạn không có quyền truy cập vào đây'),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
                      child: const Text('Đóng'),
                    ),
                  ],
                ),
              );
            } else {
              AppSnackBar.showError(context, message: 'Lỗi: ${state.error}');
            }
          }
        },
        builder: (context, state) {
          if (state is FollowLoading) {
            return _buildSkeleton();
          }

          List<UserFollowModel> followers = [];
          bool isLoadingMore = false;

          if (state is FollowersLoaded) {
            followers = state.followers;
          } else if (state is FollowLoadingMore) {
            followers = state.currentList.whereType<UserFollowModel>().toList();
            isLoadingMore = true;
          }

          if (followers.isEmpty && state is! FollowLoading) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: _themePrimaryColor(context),
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: followers.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == followers.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: _themePrimaryColor(context)),
                    ),
                  );
                }
                return _UserFollowItem(
                  key: ValueKey(followers[index].id),
                  user: followers[index],
                  onFollowToggle: (u, action) {
                    context.read<FollowBloc>().add(
                          FollowUserRequested(
                            followeeId: u.id,
                            username: u.username,
                            action: action,
                          ),
                        );
                  },
                  onRefresh: () {
                    context.read<FollowBloc>().add(
                          LoadFollowersRequested(userId: widget.userId),
                        );
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }

  // Skeleton loading — hiển thị khi đang tải lần đầu
  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (context, i) => const _SkeletonItem(),
    );
  }

  // Màn hình trống khi không có người theo dõi
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Chưa có người theo dõi',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Widget hiển thị một user trong danh sách — StatefulWidget để tự quản lý trạng thái nút
class _UserFollowItem extends StatefulWidget {
  final UserFollowModel user;
  final void Function(UserFollowModel user, String action) onFollowToggle;
  final VoidCallback onRefresh;

  const _UserFollowItem({
    required this.user,
    required this.onFollowToggle,
    required this.onRefresh,
    super.key,
  });

  @override
  State<_UserFollowItem> createState() => _UserFollowItemState();
}

class _UserFollowItemState extends State<_UserFollowItem> {
  // Trạng thái nút cục bộ — dựa vào trường 'followed' từ API (0=chưa follow, 1=đã follow)
  late bool _isFollowed;

  @override
  void initState() {
    super.initState();
    _isFollowed = widget.user.isFollowed ?? false;
  }

  @override
  void didUpdateWidget(_UserFollowItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Đồng bộ nếu parent truyền user mới với isFollowed thay đổi
    if (oldWidget.user.isFollowed != widget.user.isFollowed) {
      _isFollowed = widget.user.isFollowed ?? false;
    }
  }

  // Hiện dialog xác nhận hủy theo dõi
  Future<void> _showUnfollowDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text(
          'Hủy theo dõi',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bạn có muốn bỏ theo dõi "${widget.user.username}"?',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          // Nút hủy — đóng dialog, không làm gì
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Hủy', style: TextStyle(color: Colors.black54)),
          ),
          // Nút xác nhận — cập nhật state cục bộ rồi gọi API unfollow
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _themePrimaryColor(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Cập nhật nút ngay lập tức trước khi API trả về
      setState(() => _isFollowed = false);
      widget.onFollowToggle(widget.user, 'unfollow');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthBloc>().state;
    final currentUserId = authState.currentUser?.id.toString() ?? '';
    final isMe = widget.user.id.toString() == currentUserId;

    final onTapAction = isMe
        ? null
        : () {
            if (_isFollowed) {
              _showUnfollowDialog();
            } else {
              setState(() => _isFollowed = true);
              widget.onFollowToggle(widget.user, 'follow');
            }
          };

    final decoration = isMe
        ? BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey[300]!),
          )
        : BoxDecoration(
            gradient: (_isFollowed && context.specialTheme.useGradient)
                ? context.specialTheme.primaryGradient
                : null,
            color: _isFollowed
                ? (context.specialTheme.useGradient ? null : context.specialTheme.primaryDarkColor)
                : Colors.white,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: context.specialTheme.primaryDarkColor,
              width: 1,
            ),
          );

    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      color: isMe
          ? Colors.grey[500]
          : (_isFollowed ? Colors.white : context.specialTheme.primaryDarkColor),
    );

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar tròn & Username clickable area
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SellerInfoPage(
                      userId: widget.user.id.toString(),
                      sellerName: widget.user.username,
                      avatarUrl: widget.user.avatar,
                    ),
                  ),
                ).then((_) {
                  if (context.mounted) {
                    widget.onRefresh();
                  }
                });
              },
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (widget.user.avatar != null && widget.user.avatar!.isNotEmpty)
                        ? NetworkImage(widget.user.avatar!)
                        : null,
                    child: (widget.user.avatar == null || widget.user.avatar!.isEmpty)
                        ? Icon(Icons.person, size: 28, color: Colors.grey[500])
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.user.username,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // Nút theo dõi / đang theo dõi
          GestureDetector(
            onTap: onTapAction,
            child: Container(
              height: 32,
              constraints: const BoxConstraints(minWidth: 96),
              decoration: decoration,
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                isMe ? 'Theo dõi' : (_isFollowed ? 'Đang theo dõi' : 'Theo dõi'),
                style: textStyle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Skeleton item — placeholder khi đang tải dữ liệu
class _SkeletonItem extends StatelessWidget {
  const _SkeletonItem();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Skeleton avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          // Skeleton username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: 120, color: Colors.grey[200]),
                const SizedBox(height: 6),
                Container(height: 11, width: 80, color: Colors.grey[100]),
              ],
            ),
          ),
          // Skeleton button
          Container(
            width: 96,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}
