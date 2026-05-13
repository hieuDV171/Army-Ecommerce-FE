import 'package:army_ecommerce/models/notification_model.dart';
import 'package:equatable/equatable.dart';

abstract class NotificationState extends Equatable {
  @override
  List<Object?> get props => [];
}

// Trạng thái khởi đầu
class NotificationInitial extends NotificationState {}

// Trạng thái đang tải lần đầu (hiển thị skeleton)
class NotificationLoading extends NotificationState {}

// Trạng thái đang tải thêm (đã có list, đang append)
class NotificationLoadingMore extends NotificationState {
  final List<NotificationModel> currentList;

  NotificationLoadingMore({required this.currentList});

  @override
  List<Object?> get props => [currentList];
}

// Trạng thái sau khi tải thông báo thành công
class NotificationsLoaded extends NotificationState {
  final List<NotificationModel> notifications;
  final bool hasMore;
  // Số thông báo chưa đọc (dùng để hiển thị badge trên tab bar)
  final int unreadCount;

  NotificationsLoaded({
    required this.notifications,
    required this.hasMore,
    required this.unreadCount,
  });

  @override
  List<Object?> get props => [notifications, hasMore, unreadCount];
}

// Trạng thái sau khi đánh dấu đọc thông báo thành công
class NotificationMarkedRead extends NotificationState {
  final String notificationId;

  NotificationMarkedRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

// Trạng thái khi có lỗi xảy ra
class NotificationFailure extends NotificationState {
  final String error;
  final String code;

  NotificationFailure({required this.error, required this.code});

  @override
  List<Object?> get props => [error, code];
}
