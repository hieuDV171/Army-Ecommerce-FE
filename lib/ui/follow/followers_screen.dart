import 'package:army_ecommerce/blocs/follow/follow_bloc.dart';
import 'package:army_ecommerce/blocs/follow/follow_event.dart';
import 'package:army_ecommerce/blocs/follow/follow_state.dart';
import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Color _shopeeOrange = Color(0xFFEE4D2D);
const Color _greyBackground = Color(0xFFF5F5F5);

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

    // Lắng nghe sự kiện cuộn để tải thêm (infinite scroll)
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
    // Chờ state mới trước khi kết thúc refresh indicator
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
        title: Text(
          widget.title,
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<FollowBloc, FollowState>(
        listener: (context, state) {
          // Xử lý follow/unfollow thành công — cập nhật item trong danh sách
          if (state is FollowActionSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.isFollowed ? 'Đã theo dõi' : 'Đã bỏ theo dõi'),
                duration: const Duration(seconds: 1),
                backgroundColor: _shopeeOrange,
              ),
            );
          } else if (state is FollowFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.error}')),
            );
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
            color: _shopeeOrange,
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              // +1 cho indicator tải thêm ở cuối
              itemCount: followers.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == followers.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: _shopeeOrange),
                    ),
                  );
                }
                return _UserFollowItem(
                  user: followers[index],
                  onFollowToggle: (u, action) {
                    context.read<FollowBloc>().add(
                          FollowUserRequested(followeeId: u.id, action: action),
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

// Widget hiển thị một user trong danh sách follow
class _UserFollowItem extends StatelessWidget {
  final UserFollowModel user;
  final void Function(UserFollowModel user, String action) onFollowToggle;

  const _UserFollowItem({required this.user, required this.onFollowToggle});

  @override
  Widget build(BuildContext context) {
    final bool isFollowed = user.isFollowed ?? false;

    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          // Avatar tròn
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[200],
            backgroundImage: (user.avatar != null && user.avatar!.isNotEmpty)
                ? NetworkImage(user.avatar!)
                : null,
            child: (user.avatar == null || user.avatar!.isEmpty)
                ? Icon(Icons.person, size: 28, color: Colors.grey[500])
                : null,
          ),
          const SizedBox(width: 12),

          // Username — chiếm phần còn lại
          Expanded(
            child: Text(
              user.username,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),

          // Nút theo dõi / đang theo dõi
          GestureDetector(
            onTap: () => onFollowToggle(user, isFollowed ? 'unfollow' : 'follow'),
            child: Container(
              height: 32,
              constraints: const BoxConstraints(minWidth: 96),
              decoration: BoxDecoration(
                color: isFollowed ? _shopeeOrange : Colors.white,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: _shopeeOrange, width: 1),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                isFollowed ? 'Đang theo dõi' : 'Theo dõi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isFollowed ? Colors.white : _shopeeOrange,
                ),
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
