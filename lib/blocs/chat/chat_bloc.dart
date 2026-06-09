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
  int numNewMessage = 0;

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
        typeMessage: event.typeMessage,
        productId: int.tryParse(event.productId) ?? 0,
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
    _conversationsIndex = 1;

    try {
      final response = await chatRepository.getListConversation(
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
    emit(ChatLoading());
    _messagesIndex = 1;

    try {
      final response = await chatRepository.getConversation(
        partnerId: int.tryParse(event.partnerId ?? '') ?? 0,
        conversationId: int.tryParse(event.conversationId ?? '') ?? 0,
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
      final response = await chatRepository.getConversation(
        partnerId: int.tryParse(event.partnerId ?? '') ?? 0,
        conversationId: int.tryParse(event.conversationId ?? '') ?? 0,
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
      await chatRepository.setReadMessage(
        partnerId: int.tryParse(event.partnerId) ?? 0,
      );
      // Không emit state mới - mobile không hiển thị trạng thái "Đã xem"
    } catch (e) {
      logger.w('ChatBloc: setReadMessage failed: $e');
      // Lỗi đọc tin nhắn không ảnh hưởng đến trải nghiệm người dùng
    }
  }
}
