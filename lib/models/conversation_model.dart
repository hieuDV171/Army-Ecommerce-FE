// Model đại diện cho một hội thoại trong danh sách conversation
class ConversationModel {
  final String conversationId;
  final String partnerId;
  final String partnerUsername;
  final String? partnerAvatar;
  final String? lastMessage;
  final int unreadCount;
  final DateTime? lastMessageAt;

  ConversationModel({
    required this.conversationId,
    required this.partnerId,
    required this.partnerUsername,
    this.partnerAvatar,
    this.lastMessage,
    required this.unreadCount,
    this.lastMessageAt,
  });

  // Tạo bản sao với một số trường được thay đổi
  ConversationModel copyWith({String? lastMessage, int? unreadCount, DateTime? lastMessageAt}) {
    return ConversationModel(
      conversationId: conversationId,
      partnerId: partnerId,
      partnerUsername: partnerUsername,
      partnerAvatar: partnerAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
    );
  }

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      conversationId: json['conversation_id']?.toString() ?? '',
      partnerId: json['partner_id']?.toString() ?? '',
      partnerUsername: json['partner_username']?.toString() ?? '',
      partnerAvatar: json['partner_avatar']?.toString(),
      lastMessage: json['last_message']?.toString(),
      unreadCount: int.tryParse(json['unread_count']?.toString() ?? '0') ?? 0,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.tryParse(json['last_message_at'].toString())
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

  ConversationListResponse({
    required this.code,
    required this.message,
    this.data,
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
