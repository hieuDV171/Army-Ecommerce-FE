import 'package:army_ecommerce/models/product_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';

import 'home_event.dart';
import 'home_state.dart';

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final MarketplaceRepository marketplaceRepository;

  HomeBloc({required this.marketplaceRepository}) : super(const HomeState()) {
    on<HomeRequested>(_onRequested);
    on<HomeRefreshed>(_onRefreshed);
    on<HomeLoadMoreRequested>(_onLoadMoreRequested);
  }

  Future<void> _onRequested(HomeRequested event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isInitialLoading: true, clearError: true, index: 0));
    try {
      final categories = await marketplaceRepository.getCategories(parentId: 0);
      final result = await marketplaceRepository.getListProducts(index: 0, count: state.count);
      emit(
        state.copyWith(
          categories: categories,
          products: _deduplicateProducts(result.products),
          isInitialLoading: false,
          hasReachedEnd: result.products.length < state.count,
          lastId: result.lastId,
          index: result.products.length,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isInitialLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onRefreshed(HomeRefreshed event, Emitter<HomeState> emit) async {
    emit(state.copyWith(isRefreshing: true, clearError: true, index: 0));
    try {
      final categories = await marketplaceRepository.getCategories(parentId: 0);
      final result = await marketplaceRepository.getListProducts(index: 0, count: state.count);
      emit(
        state.copyWith(
          categories: categories,
          products: _deduplicateProducts(result.products),
          isRefreshing: false,
          hasReachedEnd: result.products.length < state.count,
          lastId: result.lastId,
          index: result.products.length,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isRefreshing: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    HomeLoadMoreRequested event,
    Emitter<HomeState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading) return;

    emit(state.copyWith(isLoadingMore: true, clearError: true));
    try {
      final result = await marketplaceRepository.getListProducts(
        index: state.index,
        count: state.count,
        lastId: state.lastId,
      );
      final products = result.products;
      final merged = _deduplicateProducts([...state.products, ...products]);
      emit(
        state.copyWith(
          products: merged,
          isLoadingMore: false,
          hasReachedEnd: products.length < state.count,
          lastId: result.lastId,
          index: merged.length,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: error.toString()));
    }
  }

  List<ProductModel> _deduplicateProducts(List<ProductModel> products) {
    final map = <String, ProductModel>{};
    for (final product in products) {
      map[product.id] = product;
    }
    return map.values.toList();
  }
}
