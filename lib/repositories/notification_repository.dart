import 'package:army_ecommerce/core/api/dio_client.dart';
import 'package:army_ecommerce/core/constants/api_paths.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:army_ecommerce/models/notification_model.dart';
import 'package:dio/dio.dart';

class NotificationRepository {
  final DioClient _dioClient;

  NotificationRepository({required DioClient dioClient}) : _dioClient = dioClient;

  // Lấy danh sách thông báo hệ thống của người dùng hiện tại
  // group: nhóm thông báo cần lấy (bắt buộc theo spec)
  Future<NotificationListResponse> getNotification({
    required int index,
    required int count,
    required int group,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        ApiPaths.getNotification,
        data: {
          'index': index,
          'count': count,
          'group': group,
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
      final response = await _dioClient.dio.post(
        ApiPaths.setReadNotification,
        data: {
          'notification_id': int.tryParse(notificationId) ?? 0,
        },
      );

      return SimpleResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception(e.response?.data['message'] ?? 'Lỗi kết nối mạng');
    }
  }
}
