import 'package:army_ecommerce/models/conversation_model.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:equatable/equatable.dart';

abstract class ChatState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Trạng thái khởi đầu
class ChatInitial extends ChatState {}

// Trạng thái đang tải dữ liệu lần đầu (hiển thị skeleton)
class ChatLoading extends ChatState {}

// Trạng thái đang tải thêm tin nhắn hoặc hội thoại
class ChatLoadingMore extends ChatState {
  final List<dynamic> currentList;

  ChatLoadingMore({required this.currentList});

  @override
  List<Object?> get props => [currentList];
}

// Trạng thái sau khi gửi tin nhắn thành công
class MessageSent extends ChatState {
  final String conversationId;
  final String messageId;

  MessageSent({required this.conversationId, required this.messageId});

  @override
  List<Object?> get props => [conversationId, messageId];
}

// Trạng thái sau khi tải danh sách hội thoại thành công
class ConversationsLoaded extends ChatState {
  final List<ConversationModel> conversations;
  final bool hasMore;

  ConversationsLoaded({required this.conversations, required this.hasMore});

  @override
  List<Object?> get props => [conversations, hasMore];
}

// Trạng thái sau khi tải tin nhắn trong một conversation thành công
class MessagesLoaded extends ChatState {
  final List<MessageModel> messages;
  final bool hasMore;

  MessagesLoaded({required this.messages, required this.hasMore});

  @override
  List<Object?> get props => [messages, hasMore];
}

// Trạng thái khi có lỗi xảy ra
class ChatFailure extends ChatState {
  final String error;
  final String code;

  ChatFailure({required this.error, required this.code});

  @override
  List<Object?> get props => [error, code];
}
