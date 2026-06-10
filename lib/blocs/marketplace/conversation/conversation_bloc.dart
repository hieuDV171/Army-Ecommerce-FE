import 'package:army_ecommerce/blocs/marketplace/conversation/conversation_event.dart';
import 'package:army_ecommerce/blocs/marketplace/conversation/conversation_state.dart';
import 'package:army_ecommerce/models/conversation_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';

class ConversationListBloc extends Bloc<ConversationEvent, ConversationState> {
  final MarketplaceRepository marketplaceRepository;

  ConversationListBloc({required this.marketplaceRepository})
      : super(const ConversationState()) {
    on<ConversationsRequested>(_onRequested);
    on<ConversationsRefreshed>(_onRefreshed);
    on<ConversationsLoadMoreRequested>(_onLoadMoreRequested);
  }

  Future<void> _onRequested(
    ConversationsRequested event,
    Emitter<ConversationState> emit,
  ) async {
    emit(state.copyWith(isInitialLoading: true, index: 1, clearError: true));
    await _loadPage(emit, index: 1, replace: true);
  }

  Future<void> _onRefreshed(
    ConversationsRefreshed event,
    Emitter<ConversationState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, index: 1, clearError: true));
    await _loadPage(emit, index: 1, replace: true);
  }

  Future<void> _onLoadMoreRequested(
    ConversationsLoadMoreRequested event,
    Emitter<ConversationState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading) return;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    await _loadPage(emit, index: state.index, replace: false);
  }

  Future<void> _loadPage(
    Emitter<ConversationState> emit, {
    required int index,
    required bool replace,
  }) async {
    try {
      final response = await marketplaceRepository.getConversations(
        index: index,
        count: state.count,
      );
      final conversations = response.data ?? [];
      final merged = replace ? conversations : _deduplicateConversations(
        [...state.conversations, ...conversations],
      );
      emit(
        state.copyWith(
          conversations: merged,
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          hasReachedEnd: conversations.length < state.count,
          index: index + 1,
          clearError: true,
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

  List<ConversationModel> _deduplicateConversations(
    List<ConversationModel> conversations,
  ) {
    final map = <int, ConversationModel>{};
    for (final conversation in conversations) {
      map[conversation.id] = conversation;
    }
    return map.values.toList();
  }
}
