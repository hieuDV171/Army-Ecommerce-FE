import 'package:army_ecommerce/models/model_helpers.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';

import 'simple_list_event.dart';
import 'simple_list_state.dart';

typedef SimpleListLoader = Future<List<MarketplaceItem>> Function(int index, int count);

class SimpleListBloc extends Bloc<SimpleListEvent, SimpleListState> {
  final SimpleListLoader loader;
  final MarketplaceRepository marketplaceRepository;

  SimpleListBloc({
    required this.loader,
    required this.marketplaceRepository,
  }) : super(const SimpleListState()) {
    on<SimpleListRequested>(_onRequested);
    on<SimpleListRefreshed>(_onRefreshed);
    on<SimpleListLoadMoreRequested>(_onLoadMoreRequested);
    on<SimpleActionRequested>(_onActionRequested);
  }

  Future<void> _onRequested(
    SimpleListRequested event,
    Emitter<SimpleListState> emit,
  ) async {
    emit(state.copyWith(isInitialLoading: true, index: 0, clearMessages: true));
    try {
      final items = await loader(0, state.count);
      emit(
        state.copyWith(
          items: _deduplicateItems(items),
          isInitialLoading: false,
          hasReachedEnd: items.length < state.count,
          index: items.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isInitialLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onRefreshed(
    SimpleListRefreshed event,
    Emitter<SimpleListState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, index: 0, clearMessages: true));
    try {
      final items = await loader(0, state.count);
      emit(
        state.copyWith(
          items: _deduplicateItems(items),
          isRefreshing: false,
          hasReachedEnd: items.length < state.count,
          index: items.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isRefreshing: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    SimpleListLoadMoreRequested event,
    Emitter<SimpleListState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading) return;

    emit(state.copyWith(isLoadingMore: true, clearMessages: true));
    try {
      final items = await loader(state.index, state.count);
      final merged = _deduplicateItems([...state.items, ...items]);
      emit(
        state.copyWith(
          items: merged,
          isLoadingMore: false,
          hasReachedEnd: items.length < state.count,
          index: merged.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onActionRequested(
    SimpleActionRequested event,
    Emitter<SimpleListState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      await marketplaceRepository.postAction(event.path, event.data);
      emit(state.copyWith(isSubmitting: false, successMessage: 'Thao tác thành công'));
      add(SimpleListRefreshed());
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }

  List<MarketplaceItem> _deduplicateItems(List<MarketplaceItem> items) {
    final map = <String, MarketplaceItem>{};
    for (final item in items) {
      map[item.id] = item;
    }
    return map.values.toList();
  }
}
