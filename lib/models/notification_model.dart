// Model đại diện cho một thông báo hệ thống
class NotificationModel {
  final String notificationId;
  // Loại thông báo: 'order' | 'like' | 'follow' | 'comment' | ...
  final String type;
  final String content;
  final bool isRead;
  final DateTime createdAt;
  // Id của đối tượng liên quan (sản phẩm, bài đăng, ...)
  final String? objectId;

  NotificationModel({
    required this.notificationId,
    required this.type,
    required this.content,
    required this.isRead,
    required this.createdAt,
    this.objectId,
  });

  // Tạo bản sao với trạng thái đã đọc được cập nhật
  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      notificationId: notificationId,
      type: type,
      content: content,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt,
      objectId: objectId,
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is num) {
      if (value < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(value.toInt() * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    }
    final str = value.toString();
    final parsedNum = num.tryParse(str);
    if (parsedNum != null) {
      if (parsedNum < 10000000000) {
        return DateTime.fromMillisecondsSinceEpoch(parsedNum.toInt() * 1000);
      }
      return DateTime.fromMillisecondsSinceEpoch(parsedNum.toInt());
    }
    return DateTime.tryParse(str) ?? DateTime.now();
  }

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      notificationId:
          json['id']?.toString() ?? json['notification_id']?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      content:
          json['title']?.toString() ??
          json['content']?.toString() ??
          json['message']?.toString() ??
          '',
      isRead:
          json['read'] == true ||
          json['read'] == 1 ||
          json['is_read'] == true ||
          json['is_read'] == 1,
      createdAt: _parseDate(json['created_at']),
      objectId: json['object_id']?.toString(),
    );
  }
}

// Wrapper phản hồi API cho danh sách thông báo
class NotificationListResponse {
  final String code;
  final String message;
  final List<NotificationModel>? data;

  NotificationListResponse({
    required this.code,
    required this.message,
    this.data,
  });

  // Hàm chuyển đổi dữ liệu JSON từ API thành Object trong Flutter
  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final rawData = json['data'];
    List<NotificationModel>? dataList;
    if (rawData is List) {
      dataList = rawData
          .whereType<Map>()
          .map(
            (item) =>
                NotificationModel.fromJson(Map<String, dynamic>.from(item)),
          )
          .toList();
    }
    return NotificationListResponse(
      code: json['code']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      data: dataList,
    );
  }
}
