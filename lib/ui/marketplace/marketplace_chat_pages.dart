import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/blocs/chat/chat_state.dart';
import 'package:army_ecommerce/models/conversation_model.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../repositories/marketplace_repository.dart';
import '../util/constants/app_colors.dart';
import '../util/constants/app_radius.dart';
import '../util/constants/app_spacing.dart';
import '../util/widgets/app_text_field.dart';
import '../util/widgets/empty_state.dart';
import '../util/widgets/error_state.dart';
import 'package:army_ecommerce/ui/util/widgets/app_snackbar.dart';

class ConversationPage extends StatelessWidget {
  const ConversationPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          ChatBloc(marketplaceRepository: context.read<MarketplaceRepository>())
            ..add(LoadConversationsRequested()),
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
      context.read<ChatBloc>().add(LoadMoreConversationsRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ChatBloc, ChatState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(title: const Text('Tin nhắn')),
          body: _buildBody(context, state),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, ChatState state) {
    if (state is ChatInitial || state is ChatLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    List<ConversationModel> conversations = [];
    bool isLoadingMore = false;
    String? errorMessage;

    if (state is ConversationsLoaded) {
      conversations = state.conversations;
    } else if (state is ChatLoadingMore) {
      conversations = state.currentList.whereType<ConversationModel>().toList();
      isLoadingMore = true;
    } else if (state is ChatFailure) {
      errorMessage = state.error;
    }

    if (errorMessage != null && conversations.isEmpty) {
      return ErrorState(
        message: errorMessage,
        onRetry: () =>
            context.read<ChatBloc>().add(LoadConversationsRequested()),
      );
    }

    if (conversations.isEmpty && state is! ChatLoadingMore) {
      return const EmptyState(title: 'Chưa có cuộc trò chuyện');
    }

    return RefreshIndicator(
      onRefresh: () async {
        context.read<ChatBloc>().add(LoadConversationsRequested());
      },
      child: ListView.separated(
        controller: _scrollController,
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: conversations.length + (isLoadingMore ? 1 : 0),
        separatorBuilder: (_, _) => const Divider(height: AppSpacing.lg),
        itemBuilder: (context, index) {
          if (index >= conversations.length) {
            return const Center(child: CircularProgressIndicator());
          }
          final conversation = conversations[index];
          final unread =
              (conversation.lastMessage?.unread ?? false) ||
              conversation.numNewMessage > 0;

          return ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              child: Icon(
                unread ? Icons.mark_chat_unread : Icons.chat_outlined,
              ),
            ),
            title: Text(conversation.partner.username),
            subtitle: Text(
              conversation.lastMessage?.message ?? '',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            trailing: unread
                ? const Icon(Icons.circle, size: 10, color: AppColors.primary)
                : null,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ChatDetailPage(
                  partnerId: conversation.partner.id.toString(),
                  conversationId: conversation.id.toString(),
                  partnerName: conversation.partner.username,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ChatDetailPage extends StatefulWidget {
  final String partnerId;
  final String conversationId;
  final String partnerName;
  final String? productId;

  const ChatDetailPage({
    super.key,
    required this.partnerId,
    required this.conversationId,
    required this.partnerName,
    this.productId,
  });

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
      create: (context) =>
          ChatBloc(marketplaceRepository: context.read<MarketplaceRepository>())
            ..add(
              LoadMessagesRequested(
                partnerId: widget.partnerId,
                conversationId: widget.conversationId,
              ),
            )
            ..add(MarkMessageReadRequested(partnerId: widget.partnerId)),
      child: BlocConsumer<ChatBloc, ChatState>(
        listener: (context, state) {
          if (state is ChatFailure) {
            AppSnackBar.showError(context, message: state.error);
          }
        },
        builder: (context, state) {
          return Scaffold(
            appBar: AppBar(title: Text(widget.partnerName)),
            body: Column(
              children: [
                if (widget.productId != null && widget.productId != '0')
                  ListTile(
                    leading: const Icon(Icons.inventory_2_outlined),
                    title: const Text('Sản phẩm liên quan'),
                    subtitle: Text('Mã sản phẩm: ${widget.productId}'),
                  ),
                Expanded(child: _buildMessageList(context, state)),
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
                          onPressed: () {
                            final text = _messageController.text.trim();
                            if (text.isNotEmpty) {
                              context.read<ChatBloc>().add(
                                SendMessageRequested(
                                  toId: widget.partnerId,
                                  message: text,
                                  productId: widget.productId ?? '0',
                                ),
                              );
                              _messageController.clear();
                            }
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

  Widget _buildMessageList(BuildContext context, ChatState state) {
    if (state is ChatLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    List<MessageModel> messages = [];
    if (state is MessagesLoaded) {
      messages = state.messages;
    } else if (state is ChatLoadingMore) {
      messages = state.currentList.whereType<MessageModel>().toList();
    }

    if (messages.isEmpty && state is! ChatLoadingMore) {
      return const Center(child: Text('Chưa có tin nhắn nào'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: messages.length,
      itemBuilder: (context, index) {
        final message = messages[index];

        final isMine = message.sender.id.toString() != widget.partnerId;

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
                  message.message,
                  style: TextStyle(
                    color: isMine ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
