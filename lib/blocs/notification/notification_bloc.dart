import 'dart:async';
import 'package:army_ecommerce/blocs/notification/notification_event.dart';
import 'package:army_ecommerce/blocs/notification/notification_state.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/network/socket_service.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/models/notification_model.dart';
import 'package:army_ecommerce/repositories/notification_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const int _pageSize = 20;

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;
  StreamSubscription? _notificationSubscription;

  int _index = 0;

  NotificationBloc({required this.notificationRepository}) : super(NotificationInitial()) {
    on<LoadNotificationsRequested>(_onLoadNotificationsRequested);
    on<LoadMoreNotificationsRequested>(_onLoadMoreNotificationsRequested);
    on<MarkNotificationReadRequested>(_onMarkNotificationReadRequested);
    on<RealTimeNotificationReceived>(_onRealTimeNotificationReceived);

    _notificationSubscription = SocketService().newNotificationsStream.listen((data) {
      try {
        final notification = NotificationModel.fromJson(data);
        add(RealTimeNotificationReceived(notification: notification));
      } catch (e) {
        logger.e('NotificationBloc: error parsing real-time notification: $e');
      }
    });
  }

  @override
  Future<void> close() {
    _notificationSubscription?.cancel();
    return super.close();
  }

  void _onRealTimeNotificationReceived(
    RealTimeNotificationReceived event,
    Emitter<NotificationState> emit,
  ) {
    final currentState = state;
    if (currentState is NotificationsLoaded) {
      if (currentState.notifications.any((n) => n.notificationId == event.notification.notificationId)) {
        return;
      }
      final updatedList = [event.notification, ...currentState.notifications];
      emit(NotificationsLoaded(
        notifications: updatedList,
        hasMore: currentState.hasMore,
        unreadCount: _countUnread(updatedList),
      ));
    } else if (currentState is NotificationLoadingMore) {
      if (currentState.currentList.any((n) => n.notificationId == event.notification.notificationId)) {
        return;
      }
      final updatedList = [event.notification, ...currentState.currentList];
      emit(NotificationLoadingMore(
        currentList: updatedList,
      ));
    }
  }

  // Tính số thông báo chưa đọc từ danh sách
  int _countUnread(List<NotificationModel> list) {
    return list.where((n) => !n.isRead).length;
  }

  // Xử lý tải trang đầu danh sách thông báo
  Future<void> _onLoadNotificationsRequested(
    LoadNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (state is! NotificationsLoaded && state is! NotificationLoadingMore) {
      emit(NotificationLoading());
    }
    _index = 0;

    try {
      final response = await notificationRepository.getNotification(
        index: _index,
        count: _pageSize,
        group: 0,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final list = response.data ?? [];
        _index += 1;
        emit(NotificationsLoaded(
          notifications: list,
          hasMore: list.length == _pageSize,
          unreadCount: _countUnread(list),
        ));
      } else {
        logger.w('NotificationBloc: getNotification failed code=${response.code}');
        emit(NotificationFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(NotificationFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  // Xử lý tải thêm thông báo (infinite scroll)
  Future<void> _onLoadMoreNotificationsRequested(
    LoadMoreNotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    if (currentState is! NotificationsLoaded || !currentState.hasMore) return;

    emit(NotificationLoadingMore(currentList: currentState.notifications));

    try {
      final response = await notificationRepository.getNotification(
        index: _index,
        count: _pageSize,
        group: 0,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        final newItems = response.data ?? [];
        _index += 1;
        final updatedList = [...currentState.notifications, ...newItems];
        emit(NotificationsLoaded(
          notifications: updatedList,
          hasMore: newItems.length == _pageSize,
          unreadCount: _countUnread(updatedList),
        ));
      } else {
        if (responseCode == ResponseCode.noData) {
          emit(NotificationsLoaded(
            notifications: currentState.notifications,
            hasMore: false,
            unreadCount: currentState.unreadCount,
          ));
          return;
        }
        logger.w('NotificationBloc: loadMore notifications failed code=${response.code}');
        emit(NotificationFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(NotificationFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }

  // Xử lý đánh dấu đã đọc một thông báo
  Future<void> _onMarkNotificationReadRequested(
    MarkNotificationReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final currentState = state;
    List<NotificationModel>? currentList;
    bool? hasMore;

    if (currentState is NotificationsLoaded) {
      currentList = currentState.notifications;
      hasMore = currentState.hasMore;
    }

    // Gọi API đánh dấu đã đọc (không await để UI không bị chặn)
    try {
      await notificationRepository.setReadNotification(
        notificationId: event.notificationId,
      );
    } catch (e) {
      logger.e('NotificationBloc: setReadNotification error: $e');
    }

    // Cập nhật state ngay lập tức (optimistic update)
    if (currentList != null) {
      final updatedList = currentList
          .map((n) => n.notificationId == event.notificationId ? n.copyWith(isRead: true) : n)
          .toList();
      emit(NotificationsLoaded(
        notifications: updatedList,
        hasMore: hasMore ?? false,
        unreadCount: _countUnread(updatedList),
      ));
    }
  }

}
