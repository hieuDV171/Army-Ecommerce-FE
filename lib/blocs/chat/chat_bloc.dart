import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/blocs/chat/chat_state.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/repositories/chat_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const int _pageSize = 20;

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository chatRepository;

  int _conversationsIndex = 0;
  int _messagesIndex = 0;

  ChatBloc({required this.chatRepository}) : super(ChatInitial()) {
    on<SendMessageRequested>(_onSendMessageRequested);
    on<LoadConversationsRequested>(_onLoadConversationsRequested);
    on<LoadMoreConversationsRequested>(_onLoadMoreConversationsRequested);
    on<LoadMessagesRequested>(_onLoadMessagesRequested);
    on<LoadMoreMessagesRequested>(_onLoadMoreMessagesRequested);
    on<MarkMessageReadRequested>(_onMarkMessageReadRequested);
  }

  // Xử lý sự kiện gửi tin nhắn
  Future<void> _onSendMessageRequested(
    SendMessageRequested event,
    Emitter<ChatState> emit,
  ) async {
    try {
      final response = await chatRepository.sendMessage(
        toId: event.toId,
        message: event.message,
        productId: event.productId,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok && response.data != null) {
        emit(MessageSent(
          conversationId: response.data!.conversationId,
          messageId: response.data!.messageId,
        ));
      } else {
        logger.w('ChatBloc: sendMessage failed code=${response.code}');
        emit(ChatFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(ChatFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  // Xử lý tải trang đầu danh sách hội thoại
  Future<void> _onLoadConversationsRequested(
    LoadConversationsRequested event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    _conversationsIndex = 0;

    try {
      final response = await chatRepository.getListConversation(
        index: _conversationsIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final list = response.data ?? [];
        _conversationsIndex = list.length;
        emit(ConversationsLoaded(conversations: list, hasMore: list.length == _pageSize));
      } else {
        logger.w('ChatBloc: getListConversation failed code=${response.code}');
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
      final response = await chatRepository.getListConversation(
        index: _conversationsIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final newItems = response.data ?? [];
        _conversationsIndex += newItems.length;
        final updatedList = [...currentState.conversations, ...newItems];
        emit(ConversationsLoaded(conversations: updatedList, hasMore: newItems.length == _pageSize));
      } else {
        if (responseCode == ResponseCode.noData) {
          emit(ConversationsLoaded(conversations: currentState.conversations, hasMore: false));
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
    emit(ChatLoading());
    _messagesIndex = 0;

    try {
      final response = await chatRepository.getConversation(
        partnerId: event.partnerId,
        productId: event.productId,
        conversationId: event.conversationId,
        index: _messagesIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final list = response.data ?? [];
        _messagesIndex = list.length;
        emit(MessagesLoaded(messages: list, hasMore: list.length == _pageSize));
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
      final response = await chatRepository.getConversation(
        partnerId: event.partnerId,
        productId: event.productId,
        conversationId: event.conversationId,
        index: _messagesIndex,
        count: _pageSize,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final newItems = response.data ?? [];
        _messagesIndex += newItems.length;
        // Tin nhắn cũ hơn được thêm vào đầu danh sách
        final updatedList = [...newItems, ...currentState.messages];
        emit(MessagesLoaded(messages: updatedList, hasMore: newItems.length == _pageSize));
      } else {
        if (responseCode == ResponseCode.noData) {
          emit(MessagesLoaded(messages: currentState.messages, hasMore: false));
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
      await chatRepository.setReadMessage(
        partnerId: event.partnerId,
        productId: event.productId,
      );
      // Không emit state mới - mobile không hiển thị trạng thái "Đã xem"
    } catch (e) {
      logger.w('ChatBloc: setReadMessage failed: $e');
      // Lỗi đọc tin nhắn không ảnh hưởng đến trải nghiệm người dùng
    }
  }
}
