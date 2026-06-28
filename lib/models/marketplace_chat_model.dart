import 'model_helpers.dart';

class ConversationModel {
  final String id;
  final String partnerId;
  final String partnerName;
  final String lastMessage;
  final String? productId;
  final bool unread;

  const ConversationModel({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.lastMessage,
    this.productId,
    this.unread = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: readString(json, ['conversation_id', 'id']),
      partnerId: readString(json, ['partner_id', 'to_id', 'user_id']),
      partnerName: readString(json, [
        'partner_name',
        'username',
        'name',
      ], fallback: 'Người bán'),
      lastMessage: readString(json, ['last_message', 'message', 'content']),
      productId: readOptionalString(json, ['product_id']),
      unread: readBool(json, ['unread', 'is_unread']) ?? false,
    );
  }

  MarketplaceItem toItem() {
    return MarketplaceItem(
      id: id,
      title: partnerName,
      subtitle: lastMessage,
      trailing: unread ? 'Mới' : null,
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final String type;
  final String? createdAt;
  final bool isLocalPending;
  final bool isFailed;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.createdAt,
    this.isLocalPending = false,
    this.isFailed = false,
  });

  MessageModel copyWith({
    String? senderId,
    bool? isLocalPending,
    bool? isFailed,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId ?? this.senderId,
      content: content,
      type: type,
      createdAt: createdAt,
      isLocalPending: isLocalPending ?? this.isLocalPending,
      isFailed: isFailed ?? this.isFailed,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: readString(json, ['id', 'message_id']),
      senderId: readString(json, ['sender_id', 'from_id', 'user_id']),
      content: readString(json, ['message', 'content']),
      type: readString(json, ['type_message', 'type'], fallback: 'text'),
      createdAt: readOptionalString(json, ['created_at', 'createdAt']),
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String? createdAt;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.createdAt,
    this.read = false,
  });

  NotificationModel copyWith({bool? read}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: readString(json, ['id', 'notification_id']),
      title: readString(json, ['title', 'type'], fallback: 'Thông báo'),
      message: readString(json, ['message', 'content', 'description']),
      createdAt: readOptionalString(json, ['created_at', 'createdAt']),
      read: readBool(json, ['read', 'is_read']) ?? false,
    );
  }

  MarketplaceItem toItem() {
    return MarketplaceItem(
      id: id,
      title: title,
      subtitle: message,
      trailing: read ? null : 'Mới',
    );
  }
}
