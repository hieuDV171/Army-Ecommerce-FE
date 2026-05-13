import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:army_ecommerce/models/notification_model.dart';
import 'package:dio/dio.dart';

class NotificationRepository {
  final DioClient _dioClient;

  NotificationRepository({required DioClient dioClient}) : _dioClient = dioClient;

  // Lấy danh sách thông báo hệ thống của người dùng hiện tại
  Future<NotificationListResponse> getNotification({
    required int index,
    required int count,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        '/notifications/get_notification',
        data: {
          'token': token,
          'index': index,
          'count': count,
        },
      );

      return NotificationListResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }

  // Đánh dấu một thông báo đã được đọc
  Future<SimpleResponse> setReadNotification({
    required String notificationId,
  }) async {
    try {
      final token = await SessionManager.getToken();

      final response = await _dioClient.dio.post(
        '/notifications/set_read_notification',
        data: {
          'token': token,
          'notification_id': notificationId,
        },
      );

      return SimpleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }
}
