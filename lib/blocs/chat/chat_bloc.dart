import 'dart:async';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/blocs/chat/chat_state.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const int _pageSize = 20;

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final MarketplaceRepository marketplaceRepository;

  int _conversationsIndex = 0;
  int _messagesIndex = 0;
  int numNewMessage = 0;

  StreamSubscription<MessageModel>? _messageSubscription;
  String? _activePartnerId;

  ChatBloc({required this.marketplaceRepository}) : super(ChatInitial()) {
    on<SendMessageRequested>(_onSendMessageRequested);
    on<LoadConversationsRequested>(_onLoadConversationsRequested);
    on<LoadMoreConversationsRequested>(_onLoadMoreConversationsRequested);
    on<LoadMessagesRequested>(_onLoadMessagesRequested);
    on<LoadMoreMessagesRequested>(_onLoadMoreMessagesRequested);
    on<MarkMessageReadRequested>(_onMarkMessageReadRequested);
    on<NewMessageReceived>(_onNewMessageReceived);

    // Subscribe to new messages from Socket.IO stream
    _messageSubscription = marketplaceRepository.newMessagesStream.listen((message) {
      logger.d('ChatBloc WebSocket Stream: Received message: "${message.message}" from senderId=${message.sender.id} (activePartnerId=$_activePartnerId)');
      if (_activePartnerId != null && message.sender.id.toString() == _activePartnerId) {
        logger.d('ChatBloc: Sender matches active chat. Appending message to list.');
        add(NewMessageReceived(message: message));
        add(MarkMessageReadRequested(partnerId: _activePartnerId!));
      } else if (_activePartnerId == null) {
        logger.d('ChatBloc: No active chat partner. Refreshing conversation list.');
        add(LoadConversationsRequested(isSilent: true));
      } else {
        logger.d('ChatBloc: Ignored message because sender ID does not match active partner.');
      }
    });
  }

  // Xử lý sự kiện gửi tin nhắn
  Future<void> _onSendMessageRequested(
    SendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    List<MessageModel> originalMessages = [];
    bool hasMore = false;
    bool canSendMessage = true;
    MessageModel? optimisticMessage;

    if (currentState is MessagesLoaded) {
      originalMessages = currentState.messages;
      hasMore = currentState.hasMore;
      canSendMessage = currentState.canSendMessage;

      if (event.senderId != null) {
        optimisticMessage = MessageModel(
          message: event.message,
          unread: false,
          type: event.typeMessage,
          created: DateTime.now(),
          sender: MessageSender(
            id: int.tryParse(event.senderId!) ?? 0,
            username: '',
          ),
        );

        emit(MessagesLoaded(
          messages: [optimisticMessage, ...originalMessages],
          hasMore: hasMore,
          canSendMessage: canSendMessage,
        ));
      }
    }

    try {
      final response = await marketplaceRepository.sendMessage(
        toId: event.toId,
        message: event.message,
        typeMessage: event.typeMessage,
        productId: event.productId,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok && response.data != null) {
        emit(MessageSent(
          conversationId: response.data!.conversationId,
          messageId: response.data!.messageId,
        ));

        // Re-emit MessagesLoaded to maintain chat list state
        final sentMessage = optimisticMessage ?? MessageModel(
          message: event.message,
          unread: false,
          type: event.typeMessage,
          created: DateTime.now(),
          sender: MessageSender(
            id: int.tryParse(event.senderId ?? '0') ?? 0,
            username: '',
          ),
        );

        final finalMessages = optimisticMessage != null
            ? [sentMessage, ...originalMessages]
            : [sentMessage, ...originalMessages];

        emit(MessagesLoaded(
          messages: finalMessages,
          hasMore: hasMore,
          canSendMessage: canSendMessage,
        ));
      } else {
        logger.w('ChatBloc: sendMessage failed code=${response.code}');
        emit(ChatFailure(error: response.message, code: response.code));
        
        // Restore original message list (remove optimistic message)
        emit(MessagesLoaded(
          messages: originalMessages,
          hasMore: hasMore,
          canSendMessage: canSendMessage,
        ));
      }
    } catch (e) {
      emit(ChatFailure(error: e.toString(), code: ResponseCode.exception.code));
      
      // Restore original message list (remove optimistic message)
      emit(MessagesLoaded(
        messages: originalMessages,
        hasMore: hasMore,
        canSendMessage: canSendMessage,
      ));
    }
  }

  // Xử lý tải trang đầu danh sách hội thoại
  Future<void> _onLoadConversationsRequested(
    LoadConversationsRequested event,
    Emitter<ChatState> emit,
  ) async {
    _activePartnerId = null;
    if (!event.isSilent) {
      emit(ChatLoading());
    }
    _conversationsIndex = 0;

    try {
      final response = await marketplaceRepository.getConversations(
        index: _conversationsIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final list = response.data ?? [];
        _conversationsIndex += 1;

        // Sắp xếp danh sách hội thoại theo tin nhắn mới nhất lên đầu làm phương án phòng thủ
        list.sort((a, b) {
          final aTime = a.lastMessage?.created;
          final bTime = b.lastMessage?.created;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        numNewMessage = response.numNewMessage;
        emit(ConversationsLoaded(
          conversations: list,
          hasMore: list.length == _pageSize,
          numNewMessage: response.numNewMessage,
        ));
      } else {
        logger.w('ChatBloc: getConversations failed code=${response.code}');
        emit(ChatFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(ChatFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  // Xử lý tải thêm hội thoại (infinite scroll)
  Future<void> _onLoadMoreConversationsRequested(
    LoadMoreConversationsRequested event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! ConversationsLoaded || !currentState.hasMore) return;

    emit(ChatLoadingMore(currentList: currentState.conversations));

    try {
      final response = await marketplaceRepository.getConversations(
        index: _conversationsIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final newItems = response.data ?? [];
        _conversationsIndex += 1;
        final updatedList = [...currentState.conversations, ...newItems];

        // Sắp xếp danh sách hội thoại theo tin nhắn mới nhất lên đầu làm phương án phòng thủ
        updatedList.sort((a, b) {
          final aTime = a.lastMessage?.created;
          final bTime = b.lastMessage?.created;
          if (aTime == null && bTime == null) return 0;
          if (aTime == null) return 1;
          if (bTime == null) return -1;
          return bTime.compareTo(aTime);
        });

        numNewMessage = response.numNewMessage;
        emit(ConversationsLoaded(
          conversations: updatedList,
          hasMore: newItems.length == _pageSize,
          numNewMessage: response.numNewMessage,
        ));
      } else {
        if (responseCode == ResponseCode.noData) {
          emit(ConversationsLoaded(
            conversations: currentState.conversations,
            hasMore: false,
            numNewMessage: currentState.numNewMessage,
          ));
          return;
        }
        logger.w('ChatBloc: loadMore conversations failed code=${response.code}');
        emit(ChatFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(ChatFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  // Xử lý tải trang đầu tin nhắn trong một conversation
  Future<void> _onLoadMessagesRequested(
    LoadMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    _activePartnerId = event.partnerId;
    emit(ChatLoading());
    _messagesIndex = 0;

    try {
      final response = await marketplaceRepository.getConversation(
        partnerId: event.partnerId ?? '',
        conversationId: event.conversationId ?? '',
        index: _messagesIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok && response.data != null) {
        final conversationData = response.data!;
        final list = conversationData.messages;
        _messagesIndex += 1;
        emit(MessagesLoaded(
          messages: list,
          hasMore: list.length == _pageSize,
          canSendMessage: conversationData.canSendMessage,
        ));
      } else {
        logger.w('ChatBloc: getConversation failed code=${response.code}');
        emit(ChatFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(ChatFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  // Xử lý tải thêm tin nhắn cũ hơn (infinite scroll ngược)
  Future<void> _onLoadMoreMessagesRequested(
    LoadMoreMessagesRequested event,
    Emitter<ChatState> emit,
  ) async {
    final currentState = state;
    if (currentState is! MessagesLoaded || !currentState.hasMore) return;

    emit(ChatLoadingMore(currentList: currentState.messages));

    try {
      final response = await marketplaceRepository.getConversation(
        partnerId: event.partnerId ?? '',
        conversationId: event.conversationId ?? '',
        index: _messagesIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok && response.data != null) {
        final newItems = response.data!.messages;
        _messagesIndex += 1;
        // Backend trả về mới nhất trước → tin cũ hơn (newItems) nối vào CUỐI list
        // ListView(reverse: true): index 0 = đáy (mới nhất), index cuối = đỉnh (cũ nhất)
        final updatedList = [...currentState.messages, ...newItems];
        emit(MessagesLoaded(
          messages: updatedList,
          hasMore: newItems.length == _pageSize,
          canSendMessage: response.data!.canSendMessage,
        ));
      } else {
        if (responseCode == ResponseCode.noData) {
          emit(MessagesLoaded(
            messages: currentState.messages,
            hasMore: false,
            canSendMessage: currentState.canSendMessage,
          ));
          return;
        }
        logger.w('ChatBloc: loadMore messages failed code=${response.code}');
        emit(ChatFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(ChatFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  // Xử lý đánh dấu đã đọc tin nhắn (gọi ngầm, không emit state mới)
  Future<void> _onMarkMessageReadRequested(
    MarkMessageReadRequested event,
    Emitter<ChatState> emit,
  ) async {
    try {
      await marketplaceRepository.markConversationRead(
        event.partnerId,
      );
      // Không emit state mới - mobile không hiển thị trạng thái "Đã xem"
    } catch (e) {
      logger.w('ChatBloc: markConversationRead failed: $e');
      // Lỗi đọc tin nhắn không ảnh hưởng đến trải nghiệm người dùng
    }
  }

  // Xử lý chèn tin nhắn mới nhận từ socket
  void _onNewMessageReceived(
    NewMessageReceived event,
    Emitter<ChatState> emit,
  ) {
    final currentState = state;
    if (currentState is MessagesLoaded) {
      // Tránh trùng lặp tin nhắn (phòng trường hợp API HTTP và Socket cùng về một lúc)
      final isDuplicate = currentState.messages.any((m) =>
          m.message == event.message.message &&
          m.created.millisecondsSinceEpoch == event.message.created.millisecondsSinceEpoch &&
          m.sender.id == event.message.sender.id);

      if (!isDuplicate) {
        final updatedList = [event.message, ...currentState.messages];
        emit(MessagesLoaded(
          messages: updatedList,
          hasMore: currentState.hasMore,
          canSendMessage: currentState.canSendMessage,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _messageSubscription?.cancel();
    return super.close();
  }
}
