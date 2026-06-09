import 'package:army_ecommerce/blocs/block/block_bloc.dart';
import 'package:army_ecommerce/blocs/block/block_event.dart';
import 'package:army_ecommerce/blocs/block/block_state.dart';
import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../util/constants/app_colors.dart';
import 'package:army_ecommerce/ui/util/theme/special_app_theme.dart';

Color _shopeeOrange(BuildContext context) => context.specialTheme.primaryDarkColor;
const Color _greyBackground = AppColors.greyBackground;

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tải danh sách user đã chặn khi màn hình được mở
    context.read<BlockBloc>().add(LoadBlockedUsersRequested());
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // Kích hoạt tải thêm khi cuộn gần đến cuối
  void _onScroll() {
    final maxScroll = _scrollController.position.maxScrollExtent;
    if (_scrollController.offset >= maxScroll - 200) {
      context.read<BlockBloc>().add(LoadMoreBlockedUsersRequested());
    }
  }

  // Kéo để làm mới danh sách
  Future<void> _onRefresh() async {
    context.read<BlockBloc>().add(LoadBlockedUsersRequested());
    await Future.delayed(const Duration(milliseconds: 800));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _greyBackground,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Người dùng đã chặn',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<BlockBloc, BlockState>(
        // Không rebuild khi BlockActionSuccess — item tự quản lý trạng thái nút
        buildWhen: (_, current) => current is! BlockActionSuccess,
        listenWhen: (_, current) =>
            current is BlockActionSuccess || current is BlockFailure,
        listener: (context, state) {
          if (state is BlockActionSuccess) {
            final message = state.isBlocked
                ? 'Đã chặn ${state.username}'
                : 'Đã bỏ chặn ${state.username}';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 2),
                backgroundColor: state.isBlocked ? Colors.black87 : _shopeeOrange(context),
              ),
            );
          } else if (state is BlockFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.error}')),
            );
          }
        },
        builder: (context, state) {
          if (state is BlockLoading) {
            return _buildSkeleton();
          }

          List<UserFollowModel> blockedUsers = [];
          bool isLoadingMore = false;

          if (state is BlockedUsersLoaded) {
            blockedUsers = state.blockedUsers;
          } else if (state is BlockLoadingMore) {
            blockedUsers = state.currentList;
            isLoadingMore = true;
          }

          if (blockedUsers.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: _shopeeOrange(context),
            onRefresh: _onRefresh,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Mô tả chức năng
                Container(
                  width: double.infinity,
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Text(
                    'Người bị chặn không thể xem trang cá nhân hay liên hệ với bạn.',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    itemCount: blockedUsers.length + (isLoadingMore ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == blockedUsers.length) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(color: _shopeeOrange(context)),
                          ),
                        );
                      }
                      return _BlockedUserItem(
                        key: ValueKey(blockedUsers[index].id),
                        user: blockedUsers[index],
                        onBlockToggle: (u, action) {
                          context.read<BlockBloc>().add(
                                BlockUserRequested(
                                  userId: u.id,
                                  username: u.username,
                                  action: action,
                                ),
                              );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // Skeleton loading — 8 placeholder items
  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Container(height: 12, width: 240, color: Colors.grey[200]),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (context, i) => const _SkeletonItem(),
          ),
        ),
      ],
    );
  }

  // Màn hình trống khi chưa chặn ai
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.block, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Chưa chặn người dùng nào',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            'Người bị chặn sẽ xuất hiện ở đây',
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// Widget một dòng user đã chặn — StatefulWidget để tự quản lý trạng thái nút
class _BlockedUserItem extends StatefulWidget {
  final UserFollowModel user;
  final void Function(UserFollowModel user, String action) onBlockToggle;

  const _BlockedUserItem({
    required this.user,
    required this.onBlockToggle,
    super.key,
  });

  @override
  State<_BlockedUserItem> createState() => _BlockedUserItemState();
}

class _BlockedUserItemState extends State<_BlockedUserItem> {
  // Tất cả item trong danh sách này mặc định đang bị chặn
  late bool _isBlocked;

  @override
  void initState() {
    super.initState();
    _isBlocked = true;
  }

  // Hiện dialog xác nhận trước khi bỏ chặn
  Future<void> _showUnblockDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        title: const Text(
          'Bỏ chặn người dùng',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Bỏ chặn "${widget.user.username}"? Người này sẽ có thể xem trang cá nhân và liên hệ với bạn.',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        actions: [
          // Nút hủy — đóng dialog, không làm gì
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogCtx, false),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: Colors.grey),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Hủy', style: TextStyle(color: Colors.black54)),
          ),
          // Nút xác nhận — gọi API unblock (type=1)
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogCtx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _shopeeOrange(context),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            ),
            child: const Text('Xác nhận', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // Cập nhật nút ngay lập tức trước khi API trả về
      setState(() => _isBlocked = false);
      widget.onBlockToggle(widget.user, 'unblock');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar tròn với overlay mờ khi đang bị chặn
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: (widget.user.avatar != null && widget.user.avatar!.isNotEmpty)
                    ? NetworkImage(widget.user.avatar!)
                    : null,
                child: (widget.user.avatar == null || widget.user.avatar!.isEmpty)
                    ? Icon(Icons.person, size: 28, color: Colors.grey[400])
                    : null,
              ),
              if (_isBlocked)
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.15),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Tên người dùng và trạng thái
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.user.username,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  _isBlocked ? 'Đã chặn' : 'Chưa chặn',
                  style: TextStyle(
                    fontSize: 11,
                    color: _isBlocked ? Colors.grey[500] : Colors.green[600],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Nút bỏ chặn / chặn
          GestureDetector(
            onTap: () {
              if (_isBlocked) {
                // Đang chặn → hiện dialog xác nhận trước khi bỏ chặn (type=1)
                _showUnblockDialog();
              } else {
                // Chưa chặn → chặn lại ngay, không cần xác nhận (type=0)
                setState(() => _isBlocked = true);
                widget.onBlockToggle(widget.user, 'block');
              }
            },
            child: Container(
              height: 32,
              constraints: const BoxConstraints(minWidth: 88),
              decoration: BoxDecoration(
                color: _isBlocked ? Colors.white : Colors.black87,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: _isBlocked ? Colors.grey[400]! : Colors.black87,
                  width: 1,
                ),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _isBlocked ? 'Bỏ chặn' : 'Chặn',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isBlocked ? Colors.grey[700] : Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Skeleton placeholder item
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
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 13, width: 110, color: Colors.grey[200]),
                const SizedBox(height: 6),
                Container(height: 11, width: 55, color: Colors.grey[100]),
              ],
            ),
          ),
          Container(
            width: 88,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(2),
              border: Border.all(color: Colors.grey[200]!),
            ),
          ),
        ],
      ),
    );
  }
}
