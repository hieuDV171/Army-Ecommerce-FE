import 'package:army_ecommerce/blocs/notification/notification_event.dart';
import 'package:army_ecommerce/blocs/notification/notification_state.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/models/notification_model.dart';
import 'package:army_ecommerce/repositories/notification_repository.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const int _pageSize = 20;

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final NotificationRepository notificationRepository;

  int _index = 0;

  NotificationBloc({required this.notificationRepository}) : super(NotificationInitial()) {
    on<LoadNotificationsRequested>(_onLoadNotificationsRequested);
    on<LoadMoreNotificationsRequested>(_onLoadMoreNotificationsRequested);
    on<MarkNotificationReadRequested>(_onMarkNotificationReadRequested);
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
    emit(NotificationLoading());
    _index = 1;

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

  // Xử lý đánh dấu một thông báo đã đọc
  Future<void> _onMarkNotificationReadRequested(
    MarkNotificationReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    try {
      final response = await notificationRepository.setReadNotification(
        notificationId: event.notificationId,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        emit(NotificationMarkedRead(notificationId: event.notificationId));
      } else {
        logger.w('NotificationBloc: setReadNotification failed code=${response.code}');
        emit(NotificationFailure(error: response.message, code: response.code));
      }
    } catch (e) {
      emit(NotificationFailure(error: e.toString(), code: ResponseCode.exception.code));
    }
  }
}
