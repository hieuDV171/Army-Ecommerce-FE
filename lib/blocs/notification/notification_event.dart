import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

// Sự kiện tải danh sách thông báo (trang đầu)
class LoadNotificationsRequested extends NotificationEvent {}

// Sự kiện tải thêm thông báo (infinite scroll)
class LoadMoreNotificationsRequested extends NotificationEvent {}

// Sự kiện đánh dấu một thông báo đã đọc
class MarkNotificationReadRequested extends NotificationEvent {
  final String notificationId;

  MarkNotificationReadRequested({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}
