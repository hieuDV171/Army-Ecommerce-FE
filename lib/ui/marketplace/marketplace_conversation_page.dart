
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/marketplace/marketplace_bloc.dart';
import '../../blocs/marketplace/marketplace_event.dart';
import '../../blocs/marketplace/marketplace_state.dart';
import '../../models/marketplace_models.dart';
import '../../repositories/marketplace_repository.dart';
import '../util/constants/app_colors.dart';
import '../util/constants/app_radius.dart';
import '../util/constants/app_spacing.dart';
import '../util/widgets/app_text_field.dart';
import '../util/widgets/empty_state.dart';
import '../util/widgets/error_state.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ConversationListBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
      )..add(ConversationsRequested()),
      child: const _ConversationListView(),
    );
  }
}

class _ConversationListView extends StatefulWidget {
  const _ConversationListView();

  @override
  State<_ConversationListView> createState() => _ConversationListViewState();
}

class _ConversationListViewState extends State<_ConversationListView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final threshold = _scrollController.position.maxScrollExtent - 240;
    if (_scrollController.position.pixels >= threshold) {
      context.read<ConversationListBloc>().add(ConversationsLoadMoreRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationListBloc, ConversationState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Tin nhắn')),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ConversationState state) {
    if (state.isInitialLoading) return const Center(child: CircularProgressIndicator());
    if (state.errorMessage != null && state.conversations.isEmpty) {
      return ErrorState(
        message: state.errorMessage!,
        onRetry: () => context.read<ConversationListBloc>().add(ConversationsRequested()),
      );
    }
    if (state.conversations.isEmpty) {
      return const EmptyState(title: 'Chưa có cuộc trò chuyện');
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ConversationListBloc>().add(ConversationsRefreshed());
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: state.conversations.length + (state.isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          if (index >= state.conversations.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversation = state.conversations[index];
          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Icon(conversation.unread ? Icons.mark_chat_unread : Icons.chat_outlined),
            ),
            title: Text(conversation.partnerName),
            subtitle: Text(conversation.lastMessage, maxLines: 1, overflow: TextOverflow.ellipsis),
            trailing: conversation.unread
                ? const Icon(Icons.circle, size: 10, color: AppColors.primary)
                : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(conversation: conversation),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final ConversationModel conversation;

  const ChatDetailPage({super.key, required this.conversation});

  @override
  State<ChatDetailPage> createState() => _ChatDetailPageState();
}

class _ChatDetailPageState extends State<ChatDetailPage> {
  final TextEditingController _messageController = TextEditingController();

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => ChatBloc(
        marketplaceRepository: context.read<MarketplaceRepository>(),
        conversation: widget.conversation,
      )..add(ChatRequested()),
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state.errorMessage != null) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.errorMessage!)),
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.conversation.partnerName)),
            body: Column(
              children: [
                if (widget.conversation.productId != null)
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('Sản phẩm liên quan'),
                    subtitle: Text('Mã sản phẩm: ${widget.conversation.productId}'),
                  ),
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ListView.builder(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isMine = message.senderId == 'me';
                      return Align(
                        alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                          padding: const EdgeInsets.all(AppSpacing.md),
                          decoration: BoxDecoration(
                            color: isMine ? AppColors.primary : AppColors.surface,
                            borderRadius: BorderRadius.circular(AppRadius.md),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                message.content,
                                style: TextStyle(
                                  color: isMine ? Colors.white : AppColors.textPrimary,
                                ),
                              ),
                              if (message.isLocalPending || message.isFailed)
                                Text(
                                  message.isFailed ? 'Gửi lỗi' : 'Đang gửi',
                                  style: TextStyle(
                                    color: isMine ? Colors.white70 : AppColors.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppTextField(
                            controller: _messageController,
                            label: 'Tin nhắn',
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        IconButton.filled(
                          tooltip: 'Gửi',
                          onPressed: state.isSending
                              ? null
                              : () {
                            context
                                .read<ChatBloc>()
                                .add(ChatMessageSubmitted(_messageController.text));
                            _messageController.clear();
                          },
                          icon: const Icon(Icons.send),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
