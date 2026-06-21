import 'package:army_ecommerce/models/message_model.dart';
import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class NewMessageReceived extends ChatEvent {
  final MessageModel message;

  NewMessageReceived({required this.message});

  @override
  List<Object?> get props => [message];
}

// Sự kiện gửi tin nhắn tới một user
class SendMessageRequested extends ChatEvent {
  final String toId;
  final String message;
  // type_message bắt buộc theo spec: 'text' | 'image' | 'video' | 'file'
  final String typeMessage;
  // product_id bắt buộc theo spec, truyền '0' nếu không chat từ trang sản phẩm
  final String productId;
  final String? senderId;

  SendMessageRequested({
    required this.toId,
    required this.message,
    this.typeMessage = 'text',
    this.productId = '0',
    this.senderId,
  });

  @override
  List<Object?> get props => [toId, message, typeMessage, productId, senderId];
}

// Sự kiện tải danh sách hội thoại (trang đầu)
class LoadConversationsRequested extends ChatEvent {
  final bool isSilent;
  LoadConversationsRequested({this.isSilent = false});

  @override
  List<Object?> get props => [isSilent];
}

// Sự kiện tải thêm danh sách hội thoại (infinite scroll)
class LoadMoreConversationsRequested extends ChatEvent {}

// Sự kiện tải tin nhắn trong một conversation (trang đầu)
// partnerId và conversationId là String, BLoC sẽ parse sang int khi gọi repository
class LoadMessagesRequested extends ChatEvent {
  final String? partnerId;
  final String? conversationId;

  LoadMessagesRequested({this.partnerId, this.conversationId});

  @override
  List<Object?> get props => [partnerId, conversationId];
}

// Sự kiện tải thêm tin nhắn cũ hơn (infinite scroll ngược)
class LoadMoreMessagesRequested extends ChatEvent {
  final String? partnerId;
  final String? conversationId;

  LoadMoreMessagesRequested({this.partnerId, this.conversationId});

  @override
  List<Object?> get props => [partnerId, conversationId];
}

// Sự kiện đánh dấu đã đọc tin nhắn (gọi ngầm khi mở màn hình chat)
class MarkMessageReadRequested extends ChatEvent {
  final String partnerId;

  MarkMessageReadRequested({required this.partnerId});

  @override
  List<Object?> get props => [partnerId];
}
