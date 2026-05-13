import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Sự kiện gửi tin nhắn tới một user
class SendMessageRequested extends ChatEvent {
  final String toId;
  final String message;
  // product_id không bắt buộc, dùng khi chat từ trang sản phẩm
  final String? productId;

  SendMessageRequested({required this.toId, required this.message, this.productId});

  @override
  List<Object?> get props => [toId, message, productId];
}

// Sự kiện tải danh sách hội thoại (trang đầu)
class LoadConversationsRequested extends ChatEvent {}

// Sự kiện tải thêm danh sách hội thoại (infinite scroll)
class LoadMoreConversationsRequested extends ChatEvent {}

// Sự kiện tải tin nhắn trong một conversation (trang đầu)
class LoadMessagesRequested extends ChatEvent {
  final String? partnerId;
  final String? productId;
  final String? conversationId;

  LoadMessagesRequested({this.partnerId, this.productId, this.conversationId});

  @override
  List<Object?> get props => [partnerId, productId, conversationId];
}

// Sự kiện tải thêm tin nhắn cũ hơn (infinite scroll ngược)
class LoadMoreMessagesRequested extends ChatEvent {
  final String? partnerId;
  final String? productId;
  final String? conversationId;

  LoadMoreMessagesRequested({this.partnerId, this.productId, this.conversationId});

  @override
  List<Object?> get props => [partnerId, productId, conversationId];
}

// Sự kiện đánh dấu đã đọc tin nhắn (gọi ngầm khi mở màn hình chat)
class MarkMessageReadRequested extends ChatEvent {
  final String partnerId;
  final String? productId;

  MarkMessageReadRequested({required this.partnerId, this.productId});

  @override
  List<Object?> get props => [partnerId, productId];
}
