import 'package:army_ecommerce/models/marketplace_chat_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import 'notification_event.dart';
import 'notification_state.dart';

class NotificationBloc extends Bloc<NotificationEvent, NotificationState> {
  final MarketplaceRepository marketplaceRepository;

  NotificationBloc({required this.marketplaceRepository})
      : super(const NotificationState()) {
    on<NotificationsRequested>(_onRequested);
    on<NotificationsRefreshed>(_onRefreshed);
    on<NotificationsLoadMoreRequested>(_onLoadMoreRequested);
    on<NotificationReadRequested>(_onReadRequested);
  }

  Future<void> _onRequested(
    NotificationsRequested event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isInitialLoading: true, index: 0, clearMessages: true));
    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onRefreshed(
    NotificationsRefreshed event,
    Emitter<NotificationState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, index: 0, clearMessages: true));
    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onLoadMoreRequested(
    NotificationsLoadMoreRequested event,
    Emitter<NotificationState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading) return;
    emit(state.copyWith(isLoadingMore: true, clearMessages: true));
    await _loadPage(emit, index: state.index, replace: false);
  }

  Future<void> _onReadRequested(
    NotificationReadRequested event,
    Emitter<NotificationState> emit,
  ) async {
    final current = state.notifications;
    emit(
      state.copyWith(
        isSubmitting: true,
        notifications: current
            .map((item) => item.id == event.notificationId ? item.copyWith(read: true) : item)
            .toList(),
        clearMessages: true,
      ),
    );

    try {
      await marketplaceRepository.markNotificationRead(event.notificationId);
      emit(state.copyWith(isSubmitting: false, successMessage: 'Da danh dau da doc'));
    } catch (error) {
      emit(
        state.copyWith(
          isSubmitting: false,
          notifications: current,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _loadPage(
    Emitter<NotificationState> emit, {
    required int index,
    required bool replace,
  }) async {
    try {
      final notifications = await marketplaceRepository.getNotifications(
        index: index,
        count: state.count,
      );
      final merged = replace
          ? notifications
          : _deduplicate([...state.notifications, ...notifications]);
      emit(
        state.copyWith(
          notifications: merged,
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasReachedEnd: notifications.length < state.count,
          index: merged.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  List<NotificationModel> _deduplicate(List<NotificationModel> notifications) {
    final map = <String, NotificationModel>{};
    for (final notification in notifications) {
      map[notification.id] = notification;
    }
    return map.values.toList();
  }
}
