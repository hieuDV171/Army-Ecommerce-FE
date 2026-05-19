import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/blocs/chat/chat_state.dart';
import 'package:army_ecommerce/models/conversation_model.dart';
import 'package:army_ecommerce/ui/chat/chat_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const Color _shopeeOrange = Color(0xFFEE4D2D);
const Color _greyBackground = Color(0xFFF5F5F5);

class ConversationListScreen extends StatefulWidget {
  // userId của người dùng hiện tại — dùng để xác định bubble tin nhắn trong ChatScreen
  final String currentUserId;

  const ConversationListScreen({super.key, required this.currentUserId});

  @override
  State<ConversationListScreen> createState() => _ConversationListScreenState();
}

class _ConversationListScreenState extends State<ConversationListScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    context.read<ChatBloc>().add(LoadConversationsRequested());
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
      context.read<ChatBloc>().add(LoadMoreConversationsRequested());
    }
  }

  Future<void> _onRefresh() async {
    context.read<ChatBloc>().add(LoadConversationsRequested());
    await Future.delayed(const Duration(milliseconds: 800));
  }

  // Mở màn hình chat với người dùng được chọn
  void _openChat(ConversationModel conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ChatBloc>(),
          child: ChatScreen(
            partnerId: conversation.partner.id.toString(),
            partnerUsername: conversation.partner.username,
            partnerAvatar: conversation.partner.avatar,
            currentUserId: widget.currentUserId,
            conversationId: conversation.id.toString(),
          ),
        ),
      ),
    ).then((_) {
      // Làm mới danh sách khi quay lại để cập nhật tin nhắn cuối và unread count
      if (!mounted) return;
      context.read<ChatBloc>().add(LoadConversationsRequested());
    });
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
          'Tin nhắn',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Lỗi: ${state.error}')),
            );
          }
        },
        builder: (context, state) {
          if (state is ChatLoading) {
            return _buildSkeleton();
          }

          List<ConversationModel> conversations = [];
          bool isLoadingMore = false;

          if (state is ConversationsLoaded) {
            conversations = state.conversations;
          } else if (state is ChatLoadingMore) {
            conversations = state.currentList.whereType<ConversationModel>().toList();
            isLoadingMore = true;
          }

          if (conversations.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            color: _shopeeOrange,
            onRefresh: _onRefresh,
            child: ListView.separated(
              controller: _scrollController,
              itemCount: conversations.length + (isLoadingMore ? 1 : 0),
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 76,
                color: Color(0xFFEEEEEE),
              ),
              itemBuilder: (context, index) {
                if (index == conversations.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(
                      child: CircularProgressIndicator(color: _shopeeOrange),
                    ),
                  );
                }
                return _ConversationItem(
                  conversation: conversations[index],
                  onTap: () => _openChat(conversations[index]),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      itemCount: 8,
      separatorBuilder: (context, index) => const Divider(
        height: 1,
        indent: 76,
        color: Color(0xFFEEEEEE),
      ),
      itemBuilder: (context, i) => const _SkeletonItem(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 12),
          Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          const SizedBox(height: 6),
          Text(
            'Nhắn tin với người bán để trao đổi\nthông tin về sản phẩm',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }
}

// Widget một dòng hội thoại
class _ConversationItem extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationItem({required this.conversation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final bool hasUnread = conversation.lastMessage?.unread == true;
    final String? avatarUrl = conversation.partner.avatar;

    return InkWell(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Avatar đối phương
            CircleAvatar(
              radius: 26,
              backgroundColor: Colors.grey[200],
              backgroundImage: (avatarUrl != null && avatarUrl.isNotEmpty)
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl == null || avatarUrl.isEmpty)
                  ? Icon(Icons.person, size: 30, color: Colors.grey[500])
                  : null,
            ),
            const SizedBox(width: 12),

            // Tên + tin nhắn cuối
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    conversation.partner.username,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: hasUnread ? FontWeight.w600 : FontWeight.w500,
                      color: Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    conversation.lastMessage?.message ?? 'Bắt đầu cuộc trò chuyện',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasUnread ? Colors.black87 : Colors.grey[500],
                      fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Thời gian + badge unread
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(conversation.lastMessage?.created),
                  style: TextStyle(
                    fontSize: 11,
                    color: hasUnread ? _shopeeOrange : Colors.grey[400],
                  ),
                ),
                const SizedBox(height: 4),
                if (hasUnread)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: const BoxDecoration(
                      color: _shopeeOrange,
                      borderRadius: BorderRadius.all(Radius.circular(10)),
                    ),
                    constraints: const BoxConstraints(minWidth: 18),
                    child: const Text(
                      '1',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                else
                  // Placeholder để giữ chiều cao nhất quán
                  const SizedBox(height: 18),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Định dạng thời gian tin nhắn cuối
  String _formatTime(DateTime? time) {
    if (time == null) return '';
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes} phút';

    // Cùng ngày → hiển thị giờ:phút
    if (diff.inDays < 1 &&
        now.day == time.day) {
      final h = time.hour.toString().padLeft(2, '0');
      final m = time.minute.toString().padLeft(2, '0');
      return '$h:$m';
    }

    // Hôm qua
    if (diff.inDays == 1 ||
        (diff.inDays < 2 && now.day != time.day)) {
      return 'Hôm qua';
    }

    // Trong tuần → hiển thị thứ
    if (diff.inDays < 7) {
      const days = ['CN', 'T2', 'T3', 'T4', 'T5', 'T6', 'T7'];
      return days[time.weekday % 7];
    }

    // Lâu hơn → ngày/tháng
    return '${time.day}/${time.month}';
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
        children: [
          Container(
            width: 52,
            height: 52,
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
                Container(height: 14, width: 130, color: Colors.grey[200]),
                const SizedBox(height: 7),
                Container(height: 12, color: Colors.grey[100]),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(height: 11, width: 35, color: Colors.grey[100]),
              const SizedBox(height: 4),
              const SizedBox(height: 18),
            ],
          ),
        ],
      ),
    );
  }
}
