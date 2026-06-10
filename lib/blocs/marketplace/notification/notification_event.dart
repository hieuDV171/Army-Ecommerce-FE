import 'package:equatable/equatable.dart';

abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsRequested extends NotificationEvent {}

class NotificationsRefreshed extends NotificationEvent {}

class NotificationsLoadMoreRequested extends NotificationEvent {}

class NotificationReadRequested extends NotificationEvent {
  final String notificationId;

  NotificationReadRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}
