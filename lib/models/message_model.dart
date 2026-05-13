// Model đại diện cho một tin nhắn trong hội thoại
class MessageModel {
  final String messageId;
  // Id của người gửi tin nhắn
  final String senderId;
  final String content;
  final DateTime createdAt;
  final bool isRead;

  MessageModel({
    required this.messageId,
    required this.senderId,
    required this.content,
    required this.createdAt,
    required this.isRead,
  });

  // Tạo bản sao với trạng thái đã đọc được cập nhật
  MessageModel copyWith({bool? isRead}) {
    return MessageModel(
      messageId: messageId,
      senderId: senderId,
      content: content,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
    );
  }

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      messageId: json['message_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
      isRead: json['is_read'] == true || json['is_read'] == 1,
    );
  }
}

// Wrapper phản hồi API cho danh sách tin nhắn trong một conversation
class MessageListResponse {
  final String code;
  final String message;
  final List<MessageModel>? data;

  MessageListResponse({
    required this.code,
    required this.message,
    this.data,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory MessageListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<MessageModel>? dataList;
    if (rawData is List) {
      dataList = rawData
          .whereType<Map<String, dynamic>>()
          .map((item) => MessageModel.fromJson(item))
          .toList();
    }
    return MessageListResponse(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: dataList,
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
