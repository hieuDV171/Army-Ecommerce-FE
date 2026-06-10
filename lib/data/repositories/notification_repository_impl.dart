import 'package:army_ecommerce/data/sources/remote/notification_remote_data_source.dart';
import 'package:army_ecommerce/models/message_model.dart';
import 'package:army_ecommerce/models/notification_model.dart';
import 'package:army_ecommerce/repositories/notification_repository.dart';

class NotificationRepositoryImpl implements NotificationRepository {
  final NotificationRemoteDataSource remoteDataSource;

  NotificationRepositoryImpl({required this.remoteDataSource});

  @override
  Future<NotificationListResponse> getNotification({
    required int index,
    required int count,
    required int group,
  }) async {
    final response = await remoteDataSource.getNotification(
      index: index,
      count: count,
      group: group,
    );
    return NotificationListResponse.fromJson(response.rawJson);
  }

  @override
  Future<SimpleResponse> setReadNotification({
    required String notificationId,
  }) async {
    final response = await remoteDataSource.setReadNotification(
      notificationId: notificationId,
    );
    return SimpleResponse.fromJson(response.rawJson);
  }
}
