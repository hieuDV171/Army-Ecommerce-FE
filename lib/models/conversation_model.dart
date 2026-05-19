// Model đại diện cho thông tin đối tác trong hội thoại
class ConversationPartner {
  final int id;
  final String username;
  final String? avatar;

  ConversationPartner({
    required this.id,
    required this.username,
    this.avatar,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory ConversationPartner.fromJson(Map<String, dynamic> json) {
    return ConversationPartner(
      id: (json['id'] as num?)?.toInt() ?? 0,
      username: json['username']?.toString() ?? '',
      avatar: json['avatar']?.toString(),
    );
  }
}

// Model đại diện cho tin nhắn cuối trong hội thoại
class ConversationLastMessage {
  final String message;
  final String type;
  final DateTime created;
  final bool unread;

  ConversationLastMessage({
    required this.message,
    required this.type,
    required this.created,
    required this.unread,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  // created là Unix timestamp (giây)
  factory ConversationLastMessage.fromJson(Map<String, dynamic> json) {
    final createdTs = (json['created'] as num?)?.toInt() ?? 0;
    return ConversationLastMessage(
      message: json['message']?.toString() ?? '',
      type: json['type']?.toString() ?? 'text',
      created: DateTime.fromMillisecondsSinceEpoch(createdTs * 1000),
      unread: json['unread'] == true,
    );
  }
}

// Model đại diện cho một hội thoại trong danh sách conversation
class ConversationModel {
  final int id;
  final ConversationPartner partner;
  final ConversationLastMessage? lastMessage;

  ConversationModel({
    required this.id,
    required this.partner,
    this.lastMessage,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: (json['id'] as num?)?.toInt() ?? 0,
      partner: ConversationPartner.fromJson(
        json['partner'] as Map<String, dynamic>? ?? {},
      ),
      lastMessage: (json['last_message'] != null && json['last_message'] is Map)
          ? ConversationLastMessage.fromJson(
              json['last_message'] as Map<String, dynamic>,
            )
          : null,
    );
  }
}

// Kết quả trả về sau khi gửi tin nhắn thành công
class SendMessageResult {
  final String conversationId;
  final String messageId;
  final DateTime? createdAt;

  SendMessageResult({
    required this.conversationId,
    required this.messageId,
    this.createdAt,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory SendMessageResult.fromJson(Map<String, dynamic> json) {
    return SendMessageResult(
      conversationId: json['conversation_id']?.toString() ?? '',
      messageId: json['message_id']?.toString() ?? '',
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
    );
  }
}

// Wrapper phản hồi API cho danh sách conversation
class ConversationListResponse {
  final String code;
  final String message;
  final List<ConversationModel>? data;
  final int numNewMessage;

  ConversationListResponse({
    required this.code,
    required this.message,
    this.data,
    this.numNewMessage = 0,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory ConversationListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<ConversationModel>? dataList;
    if (rawData is List) {
      dataList = rawData
          .whereType<Map<String, dynamic>>()
          .map((item) => ConversationModel.fromJson(item))
          .toList();
    }
    return ConversationListResponse(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: dataList,
      numNewMessage: (json['num_new_message'] as num?)?.toInt() ?? 0,
    );
  }
}

// Wrapper phản hồi API cho thao tác gửi tin nhắn
class SendMessageResponse {
  final String code;
  final String message;
  final SendMessageResult? data;

  SendMessageResponse({
    required this.code,
    required this.message,
    this.data,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory SendMessageResponse.fromJson(Map<String, dynamic> json) {
    return SendMessageResponse(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: (json['data'] != null && json['data'] is Map<String, dynamic>)
          ? SendMessageResult.fromJson(json['data'])
          : null,
    );
  }
}
