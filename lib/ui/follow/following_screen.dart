import 'package:army_ecommerce/blocs/follow/follow_bloc.dart';
import 'package:army_ecommerce/blocs/follow/follow_event.dart';
import 'package:army_ecommerce/blocs/follow/follow_state.dart';
import 'package:army_ecommerce/models/user_follow_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Color _shopeeOrange = Color(0xFFE83A14);
const Color _greyBackground = Color(0xFFF5F5F5);

class FollowingScreen extends StatefulWidget {
  // userId của người cần xem danh sách đang theo dõi
  final String userId;

  const FollowingScreen({super.key, required this.userId});

  @override
  State<FollowingScreen> createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Tải danh sách đang theo dõi khi màn hình được mở
    context.read<FollowBloc>().add(LoadFollowingRequested(userId: widget.userId));
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
      context.read<FollowBloc>().add(LoadMoreFollowingRequested(userId: widget.userId));
    }
  }

  // Xử lý kéo để làm mới danh sách
  Future<void> _onRefresh() async {
    context.read<FollowBloc>().add(LoadFollowingRequested(userId: widget.userId));
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
          'Đang theo dõi',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<FollowBloc, FollowState>(
        // Không rebuild khi FollowActionSuccess vì ngay sau đó sẽ có FollowingLoaded
        buildWhen: (_, current) => current is! FollowActionSuccess,
        listenWhen: (_, current) =>
            current is FollowActionSuccess || current is FollowFailure,
        listener: (context, state) {
          if (state is FollowActionSuccess) {
            final message = state.isFollowed
                ? 'Theo dõi ${state.username} thành công'
                : 'Đã hủy theo dõi ${state.username}';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                duration: const Duration(seconds: 2),
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

          List<UserFollowModel> following = [];
          bool isLoadingMore = false;

          if (state is FollowingLoaded) {
            following = state.following;
          } else if (state is FollowLoadingMore) {
            following = state.currentList.whereType<UserFollowModel>().toList();
            isLoadingMore = true;
          }

          if (following.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: _shopeeOrange,
            onRefresh: _onRefresh,
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: following.length + (isLoadingMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == following.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: _shopeeOrange),
                    ),
                  );
                }
                return _UserListItem(
                  key: ValueKey(following[index].id),
                  user: following[index],
                  onFollowToggle: (user, action) {
                    context.read<FollowBloc>().add(
                          FollowUserRequested(
                            followeeId: user.id,
                            username: user.username,
                            action: action,
                          ),
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

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 8,
      itemBuilder: (context, i) => const _SkeletonItem(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 12),
          Text(
            'Chưa theo dõi ai',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

// Widget một dòng user trong danh sách — StatefulWidget để tự quản lý trạng thái nút
class _UserListItem extends StatefulWidget {
  final UserFollowModel user;
  final void Function(UserFollowModel user, String action) onFollowToggle;

  const _UserListItem({
    required this.user,
    required this.onFollowToggle,
    super.key,
  });

  @override
  State<_UserListItem> createState() => _UserListItemState();
}

class _UserListItemState extends State<_UserListItem> {
  // Trạng thái nút cục bộ — không phụ thuộc vào BLoC state để tránh lệch timing
  late bool _isFollowed;

  @override
  void initState() {
    super.initState();
    // Trong danh sách đang theo dõi, mặc định là đang theo dõi nếu API không trả về
    _isFollowed = widget.user.isFollowed ?? true;
  }

  @override
  void didUpdateWidget(_UserListItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Đồng bộ nếu parent truyền user mới với isFollowed thay đổi
    if (oldWidget.user.isFollowed != widget.user.isFollowed) {
      _isFollowed = widget.user.isFollowed ?? true;
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
              backgroundColor: _shopeeOrange,
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
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 1),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () {
              if (_isFollowed) {
                // Đang theo dõi → hiện dialog xác nhận trước khi hủy
                _showUnfollowDialog();
              } else {
                // Chưa theo dõi → cập nhật nút ngay rồi gọi API follow
                setState(() => _isFollowed = true);
                widget.onFollowToggle(widget.user, 'follow');
              }
            },
            child: Container(
              height: 32,
              constraints: const BoxConstraints(minWidth: 96),
              decoration: BoxDecoration(
                color: _isFollowed ? _shopeeOrange : Colors.white,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: _shopeeOrange, width: 1),
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _isFollowed ? 'Đang theo dõi' : 'Theo dõi',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _isFollowed ? Colors.white : _shopeeOrange,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Skeleton placeholder khi đang tải
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
                Container(height: 13, width: 120, color: Colors.grey[200]),
                const SizedBox(height: 6),
                Container(height: 11, width: 80, color: Colors.grey[100]),
              ],
            ),
          ),
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
