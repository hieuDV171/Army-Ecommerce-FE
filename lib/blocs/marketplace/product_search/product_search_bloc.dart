import 'package:army_ecommerce/models/product_model.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import 'product_search_event.dart';
import 'product_search_state.dart';

class ProductSearchBloc extends Bloc<ProductSearchEvent, ProductSearchState> {
  final MarketplaceRepository marketplaceRepository;

  ProductSearchBloc({required this.marketplaceRepository})
      : super(const ProductSearchState()) {
    on<ProductSearchRequested>(_onRequested);
    on<ProductSearchFiltered>(_onFiltered);
    on<ProductSearchRefreshed>(_onRefreshed);
    on<ProductSearchLoadMoreRequested>(_onLoadMoreRequested);
    on<ProductSearchBrandsRequested>(_onBrandsRequested);
  }

  Future<void> _onRequested(
    ProductSearchRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    final hasCondition = event.keyword.trim().isNotEmpty ||
        (event.categoryId != null && event.categoryId!.isNotEmpty && event.categoryId != '0') ||
        (event.brandId != null && event.brandId!.isNotEmpty) ||
        event.priceMin != null ||
        event.priceMax != null;

    emit(
      state.copyWith(
        keyword: event.keyword,
        categoryId: () => event.categoryId,
        brandId: () => event.brandId,
        priceMin: () => event.priceMin,
        priceMax: () => event.priceMax,
        useListProductsApi: !hasCondition,
        lastId: () => null,
        products: const [],
        index: 0,
        isInitialLoading: true,
        hasReachedEnd: false,
        clearError: true,
      ),
    );

    // Tải danh sách thương hiệu nếu có categoryId
    if (event.categoryId != null && event.categoryId!.isNotEmpty && event.categoryId != '0') {
      add(ProductSearchBrandsRequested(categoryId: event.categoryId));
    } else {
      emit(state.copyWith(brands: const [], brandId: () => null));
    }

    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onFiltered(
    ProductSearchFiltered event,
    Emitter<ProductSearchState> emit,
  ) async {
    final hasCondition = event.keyword.trim().isNotEmpty ||
        (event.categoryId != null && event.categoryId!.isNotEmpty && event.categoryId != '0') ||
        (event.brandId != null && event.brandId!.isNotEmpty) ||
        event.priceMin != null ||
        event.priceMax != null;

    emit(
      state.copyWith(
        keyword: event.keyword,
        categoryId: () => event.categoryId,
        brandId: () => event.brandId,
        priceMin: () => event.priceMin,
        priceMax: () => event.priceMax,
        useListProductsApi: !hasCondition,
        lastId: () => null,
        products: const [],
        index: 0,
        isInitialLoading: true,
        hasReachedEnd: false,
        clearError: true,
      ),
    );

    // Tải danh sách thương hiệu nếu có categoryId
    if (event.categoryId != null && event.categoryId!.isNotEmpty && event.categoryId != '0') {
      add(ProductSearchBrandsRequested(categoryId: event.categoryId));
    } else {
      emit(state.copyWith(brands: const [], brandId: () => null));
    }

    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onRefreshed(
    ProductSearchRefreshed event,
    Emitter<ProductSearchState> emit,
  ) async {
    emit(state.copyWith(isRefreshing: true, index: 0, lastId: () => null, clearError: true));
    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onLoadMoreRequested(
    ProductSearchLoadMoreRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading) return;
    emit(state.copyWith(isLoadingMore: true, clearError: true));
    await _loadPage(emit, index: state.index, replace: false);
  }

  Future<void> _onBrandsRequested(
    ProductSearchBrandsRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    emit(state.copyWith(isBrandsLoading: true));
    try {
      final brands = await marketplaceRepository.getBrands(
        categoryId: event.categoryId,
      );
      emit(state.copyWith(brands: brands, isBrandsLoading: false));
    } catch (error) {
      // Lỗi tải thương hiệu không ảnh hưởng đến tải sản phẩm
      emit(state.copyWith(isBrandsLoading: false));
    }
  }

  Future<void> _loadPage(
    Emitter<ProductSearchState> emit, {
    required int index,
    required bool replace,
  }) async {
    try {
      List<ProductModel> products;
      int? lastId;
      if (state.useListProductsApi) {
        final result = await marketplaceRepository.getListProducts(
          keyword: state.keyword,
          categoryId: state.categoryId,
          brandId: state.brandId,
          priceMin: state.priceMin,
          priceMax: state.priceMax,
          index: index,
          count: state.count,
          lastId: state.lastId,
        );
        products = result.products;
        lastId = result.lastId;
      } else {
        products = await marketplaceRepository.searchProducts(
          keyword: state.keyword,
          categoryId: state.categoryId,
          brandId: state.brandId,
          priceMin: state.priceMin,
          priceMax: state.priceMax,
          index: index,
          count: state.count,
        );
      }
      final merged = replace ? products : _deduplicate([...state.products, ...products]);
      emit(
        state.copyWith(
          products: merged,
          isInitialLoading: false,
          isRefreshing: false,
          isLoadingMore: false,
          lastId: () => lastId ?? state.lastId,
          hasReachedEnd: products.length < state.count,
          index: merged.length,
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

  List<ProductModel> _deduplicate(List<ProductModel> products) {
    final map = <String, ProductModel>{};
    for (final product in products) {
      map[product.id] = product;
    }
    return map.values.toList();
  }
}
