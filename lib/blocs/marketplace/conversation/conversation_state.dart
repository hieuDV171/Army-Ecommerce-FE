import 'package:army_ecommerce/models/conversation_model.dart';
import 'package:equatable/equatable.dart';

class ConversationState extends Equatable {
  final List<ConversationModel> conversations;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? errorMessage;
  final int index;
  final int count;

  const ConversationState({
    this.conversations = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.index = 0,
    this.count = 20,
  });

  ConversationState copyWith({
    List<ConversationModel>? conversations,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    String? errorMessage,
    int? index,
    int? count,
    bool clearError = false,
  }) {
    return ConversationState(
      conversations: conversations ?? this.conversations,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      index: index ?? this.index,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
    conversations,
    isInitialLoading,
    isRefreshing,
    isLoadingMore,
    hasReachedEnd,
    errorMessage,
    index,
    count,
  ];
}
