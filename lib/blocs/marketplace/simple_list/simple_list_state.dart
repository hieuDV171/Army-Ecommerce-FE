import 'package:army_ecommerce/models/model_helpers.dart';
import 'package:equatable/equatable.dart';

class SimpleListState extends Equatable {
  final List<MarketplaceItem> items;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool isSubmitting;
  final bool hasReachedEnd;
  final String? errorMessage;
  final String? successMessage;
  final int index;
  final int count;

  const SimpleListState({
    this.items = const [],
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

  SimpleListState copyWith({
    List<MarketplaceItem>? items,
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
    return SimpleListState(
      items: items ?? this.items,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage,
      index: index ?? this.index,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
    items,
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
