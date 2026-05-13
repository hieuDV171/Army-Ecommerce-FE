import 'package:army_ecommerce/blocs/block/block_bloc.dart';
import 'package:army_ecommerce/blocs/block/block_event.dart';
import 'package:army_ecommerce/blocs/block/block_state.dart';
import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Color _shopeeOrange = Color(0xFFEE4D2D);
const Color _greyBackground = Color(0xFFF5F5F5);

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

  // Hiển thị dialog xác nhận trước khi bỏ chặn
  void _showUnblockConfirmDialog(BuildContext context, UserFollowModel user) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Bỏ chặn người dùng'),
        content: Text('Bỏ chặn "${user.username}"? Người này sẽ có thể xem trang cá nhân và liên hệ với bạn.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('HỦY', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<BlockBloc>().add(
                    BlockUserRequested(userId: user.id, action: 'unblock'),
                  );
            },
            child: const Text('BỎ CHẶN', style: TextStyle(color: _shopeeOrange)),
          ),
        ],
      ),
    );
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
        listener: (context, state) {
          if (state is BlockActionSuccess && !state.isBlocked) {
            // Bỏ chặn thành công → làm mới danh sách
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Đã bỏ chặn người dùng'),
                duration: Duration(seconds: 2),
              ),
            );
            context.read<BlockBloc>().add(LoadBlockedUsersRequested());
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
            color: _shopeeOrange,
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
                        return const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: CircularProgressIndicator(color: _shopeeOrange),
                          ),
                        );
                      }
                      return _BlockedUserItem(
                        user: blockedUsers[index],
                        onUnblock: () =>
                            _showUnblockConfirmDialog(context, blockedUsers[index]),
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

// Widget một dòng user đã chặn
class _BlockedUserItem extends StatelessWidget {
  final UserFollowModel user;
  final VoidCallback onUnblock;

  const _BlockedUserItem({required this.user, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar tròn với hiệu ứng mờ báo hiệu bị chặn
          Stack(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey[200],
                backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                    ? NetworkImage(user.avatar!)
                    : null,
                child: (user.avatar == null || user.avatar!.isEmpty)
                    ? Icon(Icons.person, size: 28, color: Colors.grey[400])
                    : null,
              ),
              // Overlay mờ biểu thị trạng thái bị chặn
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

          // Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.username,
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
                  'Đã chặn',
                  style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Nút bỏ chặn — màu xám để phân biệt với nút follow
          GestureDetector(
            onTap: onUnblock,
            child: Container(
              height: 32,
              constraints: const BoxConstraints(minWidth: 88),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: Colors.grey[400]!, width: 1),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'Bỏ chặn',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
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
