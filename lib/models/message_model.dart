// Model đại diện cho người gửi tin nhắn
class MessageSender {
  final int id;
  final String username;

  MessageSender({required this.id, required this.username});

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory MessageSender.fromJson(Map<String, dynamic> json) {
    return MessageSender(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
    );
  }
}

// Model đại diện cho một tin nhắn trong hội thoại
class MessageModel {
  final String message;
  final bool unread;
  final String type;
  // created là Unix timestamp (giây) được chuyển thành DateTime
  final DateTime created;
  final MessageSender sender;

  MessageModel({
    required this.message,
    required this.unread,
    required this.type,
    required this.created,
    required this.sender,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    // created là Unix timestamp dạng số nguyên
    final createdRaw = json['created'];
    final createdTs = createdRaw is num ? createdRaw.toInt() : int.tryParse(createdRaw?.toString() ?? '') ?? 0;

    return MessageModel(
      message: json['message']?.toString() ?? '',
      unread: json['unread'] == true,
      type: json['type']?.toString() ?? 'text',
      created: createdTs > 0
          ? DateTime.fromMillisecondsSinceEpoch(createdTs * 1000)
          : DateTime.now(),
      sender: MessageSender.fromJson(
        json['sender'] as Map<String, dynamic>? ?? {},
      ),
    );
  }
}

// Dữ liệu bên trong data của get_conversation response
class ConversationData {
  final List<MessageModel> messages;
  final bool canSendMessage;

  ConversationData({required this.messages, required this.canSendMessage});

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory ConversationData.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final messages = rawMessages is List
        ? rawMessages
            .whereType<Map<String, dynamic>>()
            .map((item) => MessageModel.fromJson(item))
            .toList()
        : <MessageModel>[];
    return ConversationData(
      messages: messages,
      canSendMessage: json['can_send_message'] == true,
    );
  }
}

// Wrapper phản hồi API cho danh sách tin nhắn trong một conversation
class MessageListResponse {
  final String code;
  final String message;
  final ConversationData? data;

  MessageListResponse({
    required this.code,
    required this.message,
    this.data,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory MessageListResponse.fromJson(Map<String, dynamic> json) {
    return MessageListResponse(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: (json['data'] != null && json['data'] is Map<String, dynamic>)
          ? ConversationData.fromJson(json['data'] as Map<String, dynamic>)
          : null,
    );
  }
}

// Wrapper phản hồi API cho các thao tác không trả về data (set_read_message, set_blocks, ...)
class SimpleResponse {
  final String code;
  final String message;

  SimpleResponse({
    required this.code,
    required this.message,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory SimpleResponse.fromJson(Map<String, dynamic> json) {
    return SimpleResponse(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
    );
  }
}
