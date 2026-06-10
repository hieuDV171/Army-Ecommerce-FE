import 'package:army_ecommerce/models/marketplace_chat_model.dart';
import 'package:equatable/equatable.dart';

class NotificationState extends Equatable {
  final List<NotificationModel> notifications;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isSubmitting;
  final bool hasReachedEnd;
  final String? errorMessage;
  final String? successMessage;
  final int index;
  final int count;

  const NotificationState({
    this.notifications = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.isSubmitting = false,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.successMessage,
    this.index = 0,
    this.count = 20,
  });

  NotificationState copyWith({
    List<NotificationModel>? notifications,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? isSubmitting,
    bool? hasReachedEnd,
    String? errorMessage,
    String? successMessage,
    int? index,
    int? count,
    bool clearMessages = false,
  }) {
    return NotificationState(
      notifications: notifications ?? this.notifications,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
      index: index ?? this.index,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
    notifications,
    isInitialLoading,
    isRefreshing,
    isLoadingMore,
    isSubmitting,
    hasReachedEnd,
    errorMessage,
    successMessage,
    index,
    count,
  ];
}
