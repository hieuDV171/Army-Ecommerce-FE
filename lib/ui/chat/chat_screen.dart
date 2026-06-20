import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/blocs/chat/chat_state.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:army_ecommerce/ui/marketplace/product/seller_listings_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../util/constants/app_colors.dart';
import '../util/theme/special_app_theme.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

class ChatScreen extends StatefulWidget {
  final String partnerId;
  final String partnerUsername;
  final String? partnerAvatar;
  final String currentUserId;
  // Truyền conversationId nếu đã có, hoặc partnerId + productId nếu mở từ sản phẩm
  final String? conversationId;
  final String? productId;
  // Thông tin sản phẩm để hiển thị trên banner (tùy chọn)
  final String? productTitle;
  final num? productPrice;
  final String? productImageUrl;

  const ChatScreen({
    super.key,
    required this.partnerId,
    required this.partnerUsername,
    this.partnerAvatar,
    required this.currentUserId,
    this.conversationId,
    this.productId,
    this.productTitle,
    this.productPrice,
    this.productImageUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  // Lưu conversationId khi đã có (có thể từ props hoặc từ API trả về khi gửi tin đầu tiên)
  String? _resolvedConversationId;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    _resolvedConversationId = widget.conversationId;

    // Tải tin nhắn khi mở màn hình
    context.read<ChatBloc>().add(LoadMessagesRequested(
          partnerId: widget.partnerId,
          conversationId: widget.conversationId,
        ));

    // Đánh dấu đã đọc tất cả tin nhắn (gọi ngầm, không ảnh hưởng UI)
    context.read<ChatBloc>().add(MarkMessageReadRequested(
          partnerId: widget.partnerId,
        ));

    // Lắng nghe cuộn đến đầu danh sách để tải thêm tin cũ
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // reverse: true → cuộn đến "đầu" ListView = kéo lên đỉnh màn hình = tin nhắn cũ nhất
  void _onScroll() {
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 100) {
      context.read<ChatBloc>().add(LoadMoreMessagesRequested(
            partnerId: widget.partnerId,
            conversationId: _resolvedConversationId,
          ));
    }
  }

  // Gửi tin nhắn
  void _sendMessage() {
    final text = _inputController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _inputController.clear();

    context.read<ChatBloc>().add(SendMessageRequested(
          toId: widget.partnerId,
          message: text,
          productId: widget.productId ?? '0',
        ));
  }

  // Cuộn về cuối danh sách (tin mới nhất)
  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.greyBackground,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Banner sản phẩm đang trao đổi (nếu có)
          if (widget.productId != null) _buildProductBanner(),

          // Vùng hiển thị tin nhắn
          Expanded(
            child: BlocConsumer<ChatBloc, ChatState>(
              listener: (context, state) {
                if (state is MessageSent) {
                  // Lưu conversationId mới (trường hợp conversation vừa được tạo)
                  _resolvedConversationId = state.conversationId;
                  setState(() => _isSending = false);
                  // Tải lại tin nhắn để hiển thị tin vừa gửi
                  context.read<ChatBloc>().add(LoadMessagesRequested(
                        partnerId: widget.partnerId,
                        conversationId: _resolvedConversationId,
                      ));
                  _scrollToBottom();
                } else if (state is ChatFailure) {
                  setState(() => _isSending = false);
                  AppSnackBar.showError(context, message: 'Gửi thất bại: ${state.error}');
                }
              },
              builder: (context, state) {
                if (state is ChatLoading) {
                  return _buildSkeleton();
                }

                List<MessageModel> messages = [];
                bool isLoadingMore = false;

                if (state is MessagesLoaded) {
                  messages = state.messages;
                } else if (state is ChatLoadingMore) {
                  messages = state.currentList.whereType<MessageModel>().toList();
                  isLoadingMore = true;
                }

                if (messages.isEmpty && state is! ChatLoading) {
                  return _buildEmptyChat();
                }

                // reverse: true — index 0 = tin mới nhất (hiển thị ở dưới cùng)
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  itemCount: messages.length + (isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Indicator tải thêm ở đầu danh sách (tin cũ nhất = index cao nhất)
                    if (index == messages.length) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: context.specialTheme.primaryColor,
                            strokeWidth: 2,
                          ),
                        ),
                      );
                    }

                    final message = messages[index];
                    final isMine = message.sender.id.toString() == widget.currentUserId;

                    // Hiển thị ngăn cách ngày nếu tin nhắn trước đó là ngày khác
                    final bool showDateSeparator = _shouldShowDate(messages, index);

                    return Column(
                      children: [
                        if (showDateSeparator)
                          _DateSeparator(date: message.created),
                        _MessageBubble(message: message, isMine: isMine),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Vùng nhập tin nhắn — ẩn khi không được phép gửi (can_send_message = false)
          BlocBuilder<ChatBloc, ChatState>(
            builder: (context, state) {
              final canSend = state is MessagesLoaded ? state.canSendMessage : true;
              return canSend ? _buildInputArea() : _buildBlockedBanner();
            },
          ),
        ],
      ),
    );
  }

  // Kiểm tra có cần hiển thị ngăn cách ngày không
  // Vì ListView reverse: true, index 0 = mới nhất → index+1 = tin ngay trước đó (cũ hơn)
  bool _shouldShowDate(List<MessageModel> messages, int index) {
    if (index == messages.length - 1) return true; // Tin cũ nhất luôn có date
    final current = messages[index];
    final older = messages[index + 1];
    return !_isSameDay(current.created, older.created);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  PreferredSizeWidget _buildAppBar() {
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
      elevation: 0.5,
      iconTheme: const IconThemeData(color: Colors.white),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      titleSpacing: 0,
      title: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SellerInfoPage(
                userId: widget.partnerId,
                sellerName: widget.partnerUsername,
                avatarUrl: widget.partnerAvatar,
              ),
            ),
          );
        },
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Colors.grey[200],
              backgroundImage: (widget.partnerAvatar != null &&
                      widget.partnerAvatar!.isNotEmpty)
                  ? NetworkImage(widget.partnerAvatar!)
                  : null,
              child: (widget.partnerAvatar == null || widget.partnerAvatar!.isEmpty)
                  ? Icon(Icons.person, size: 20, color: Colors.grey[500])
                  : null,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                widget.partnerUsername,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Banner hiển thị thông tin sản phẩm đang trao đổi
  Widget _buildProductBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.unreadBackground,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Thumbnail sản phẩm
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: widget.productImageUrl != null && widget.productImageUrl!.isNotEmpty
                ? Image.network(
                    widget.productImageUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => _buildProductIconBox(),
                  )
                : _buildProductIconBox(),
          ),
          const SizedBox(width: 10),
          // Tên và giá sản phẩm
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  widget.productTitle ?? 'Đang trao đổi về sản phẩm',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.productPrice != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      _formatPrice(widget.productPrice!),
                      style: TextStyle(
                        fontSize: 13,
                        color: context.specialTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Hộp icon dự phòng khi không có ảnh sản phẩm
  Widget _buildProductIconBox() {
    return Container(
      width: 48,
      height: 48,
      color: AppColors.primaryUltraLight,
      child: Icon(Icons.inventory_2_outlined, size: 22, color: context.specialTheme.primaryColor),
    );
  }

  // Định dạng giá tiền theo kiểu Việt Nam (₫1.500.000)
  String _formatPrice(num price) {
    final formatted = price.toInt().toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
    return '₫$formatted';
  }

  // Vùng nhập và gửi tin nhắn
  Widget _buildInputArea() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 12,
        right: 8,
        top: 8,
        bottom: MediaQuery.of(context).padding.bottom + 8,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // TextField
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxHeight: 100),
              decoration: BoxDecoration(
                color: AppColors.greyBackground,
                borderRadius: BorderRadius.circular(20),
              ),
              child: TextField(
                controller: _inputController,
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(fontSize: 14),
                decoration: const InputDecoration(
                  hintText: 'Nhập tin nhắn...',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 6),

          // Nút gửi
          GestureDetector(
            onTap: _isSending ? null : _sendMessage,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _isSending
                    ? Colors.grey[300]
                    : (context.specialTheme.useGradient ? null : context.specialTheme.primaryColor),
                gradient: _isSending
                    ? null
                    : (context.specialTheme.useGradient ? context.specialTheme.primaryGradient : null),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                      padding: EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // Skeleton loading khi tải lần đầu
  Widget _buildSkeleton() {
    return ListView.builder(
      reverse: true,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: 10,
      itemBuilder: (context, index) => _SkeletonBubble(isMine: index.isEven),
    );
  }

  // Banner hiển thị khi không được phép gửi tin nhắn (bị chặn hoặc chưa xác thực)
  Widget _buildBlockedBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.greyBackground,
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 12,
        bottom: MediaQuery.of(context).padding.bottom + 12,
      ),
      child: const Text(
        'Bạn không thể gửi tin nhắn trong cuộc trò chuyện này',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 13, color: Colors.grey),
      ),
    );
  }

  // Màn hình trống khi chưa có tin nhắn
  Widget _buildEmptyChat() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 56, color: Colors.grey[300]),
          const SizedBox(height: 10),
          Text(
            'Bắt đầu cuộc trò chuyện',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }
}

// Bubble tin nhắn
class _MessageBubble extends StatelessWidget {
  final MessageModel message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine) const SizedBox(width: 4),
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.72,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isMine
                    ? (context.specialTheme.useGradient ? null : context.specialTheme.primaryColor)
                    : Colors.white,
                gradient: isMine && context.specialTheme.useGradient ? context.specialTheme.primaryGradient : null,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isMine ? 16 : 4),
                  bottomRight: Radius.circular(isMine ? 4 : 16),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 3,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: isMine
                    ? CrossAxisAlignment.end
                    : CrossAxisAlignment.start,
                children: [
                  _buildMessageText(message.message, isMine, context),
                  const SizedBox(height: 3),
                  Text(
                    _formatTime(message.created),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMine
                          ? Colors.white.withValues(alpha: 0.75)
                          : Colors.grey[400],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMine) const SizedBox(width: 4),
        ],
      ),
    );
  }

  // Định dạng giờ:phút
  // Định dạng giờ:phút
  String _formatTime(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  Widget _buildMessageText(String text, bool isMine, BuildContext context) {
    final List<InlineSpan> spans = [];
    final regExp = RegExp(r'(https?:\/\/[^\s]+)', caseSensitive: false);
    final matches = regExp.allMatches(text);

    int lastMatchEnd = 0;
    for (final match in matches) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: text.substring(lastMatchEnd, match.start),
          style: TextStyle(
            fontSize: 14,
            color: isMine ? Colors.white : Colors.black87,
            height: 1.4,
          ),
        ));
      }

      final url = match.group(0)!;
      spans.add(TextSpan(
        text: url,
        style: TextStyle(
          fontSize: 14,
          color: isMine ? Colors.white : Colors.blue,
          decoration: TextDecoration.underline,
          decorationColor: isMine ? Colors.white : Colors.blue,
          height: 1.4,
        ),
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            final uri = Uri.tryParse(url);
            if (uri != null) {
              try {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } catch (e) {
                debugPrint('Error launching url: $e');
              }
            }
          },
      ));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < text.length) {
      spans.add(TextSpan(
        text: text.substring(lastMatchEnd),
        style: TextStyle(
          fontSize: 14,
          color: isMine ? Colors.white : Colors.black87,
          height: 1.4,
        ),
      ));
    }

    if (spans.isEmpty) {
      return Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isMine ? Colors.white : Colors.black87,
          height: 1.4,
        ),
      );
    }

    return RichText(
      text: TextSpan(children: spans),
    );
  }
}

// Ngăn cách ngày giữa các nhóm tin nhắn
class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          const Expanded(child: Divider(color: AppColors.greyDivider)),
          const SizedBox(width: 10),
          Text(
            _formatDate(date),
            style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
          ),
          const SizedBox(width: 10),
          const Expanded(child: Divider(color: AppColors.greyDivider)),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(date.year, date.month, date.day);

    if (d == today) return 'Hôm nay';
    if (d == yesterday) return 'Hôm qua';
    return '${date.day}/${date.month}/${date.year}';
  }
}

// Skeleton bubble khi đang tải
class _SkeletonBubble extends StatelessWidget {
  final bool isMine;

  const _SkeletonBubble({required this.isMine});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            height: 36,
            width: isMine ? 180 : 140,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ],
      ),
    );
  }
}
