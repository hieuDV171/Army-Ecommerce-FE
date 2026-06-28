import 'package:army_ecommerce/models/message_model.dart';
import 'package:army_ecommerce/models/notification_model.dart';

abstract class NotificationRepository {
  Future<NotificationListResponse> getNotification({
    required int index,
    required int count,
    required int group,
  });

  Future<SimpleResponse> setReadNotification({required String notificationId});
}
