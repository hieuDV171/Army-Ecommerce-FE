import 'package:army_ecommerce/models/product_model.dart';
import 'package:army_ecommerce/models/model_helpers.dart';
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
    on<ProductSearchProductLikeToggled>(_onProductLikeToggled);
    on<ProductSearchSavedSearchesRequested>(_onSavedSearchesRequested);
    on<ProductSearchDelSavedSearchRequested>(_onDelSavedSearchRequested);
    on<ProductSearchCategoriesRequested>(_onCategoriesRequested);
    on<ProductSearchCategoriesLoadMoreRequested>(
      _onCategoriesLoadMoreRequested,
    );
  }

  Future<void> _onRequested(
    ProductSearchRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    final hasCondition =
        event.keyword.trim().isNotEmpty ||
        (event.categoryId != null &&
            event.categoryId!.isNotEmpty &&
            event.categoryId != '0') ||
        (event.brandId != null && event.brandId!.isNotEmpty) ||
        event.priceMin != null ||
        event.priceMax != null;

    List<MarketplaceItem> savedSearches = state.savedSearches;
    if (event.keyword.trim().isNotEmpty) {
      try {
        await marketplaceRepository.saveSearch(event.keyword.trim());
        savedSearches = await marketplaceRepository.getSavedSearches();
      } catch (_) {}
    }

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
        savedSearches: savedSearches,
        index: 0,
        isInitialLoading: true,
        hasReachedEnd: false,
        clearError: true,
      ),
    );

    // Tải danh sách thương hiệu nếu có categoryId
    if (event.categoryId != null &&
        event.categoryId!.isNotEmpty &&
        event.categoryId != '0') {
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
    List<MarketplaceItem> savedSearches = state.savedSearches;
    if (event.keyword.trim().isNotEmpty) {
      try {
        await marketplaceRepository.saveSearch(event.keyword.trim());
        savedSearches = await marketplaceRepository.getSavedSearches();
      } catch (_) {}
    }

    final hasCondition =
        event.keyword.trim().isNotEmpty ||
        (event.categoryId != null &&
            event.categoryId!.isNotEmpty &&
            event.categoryId != '0') ||
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
        savedSearches: savedSearches,
        index: 0,
        isInitialLoading: true,
        hasReachedEnd: false,
        clearError: true,
      ),
    );

    // Tải danh sách thương hiệu nếu có categoryId
    if (event.categoryId != null &&
        event.categoryId!.isNotEmpty &&
        event.categoryId != '0') {
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
    emit(
      state.copyWith(
        isRefreshing: true,
        index: 0,
        lastId: () => null,
        clearError: true,
      ),
    );
    await _loadPage(emit, index: 0, replace: true);
  }

  Future<void> _onLoadMoreRequested(
    ProductSearchLoadMoreRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isInitialLoading)
      return;
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
      final merged = replace
          ? products
          : _deduplicate([...state.products, ...products]);
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

  Future<void> _onProductLikeToggled(
    ProductSearchProductLikeToggled event,
    Emitter<ProductSearchState> emit,
  ) async {
    final originalProducts = List<ProductModel>.from(state.products);
    final updatedProducts = state.products.map((product) {
      if (product.id == event.productId) {
        final newIsLiked = !product.isLiked;
        final newLikeCount = newIsLiked
            ? product.likeCount + 1
            : (product.likeCount - 1).clamp(0, 999999).toInt();
        return product.copyWith(isLiked: newIsLiked, likeCount: newLikeCount);
      }
      return product;
    }).toList();

    emit(state.copyWith(products: updatedProducts));

    try {
      await marketplaceRepository.likeProduct(event.productId);
    } catch (error) {
      emit(
        state.copyWith(
          products: originalProducts,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onSavedSearchesRequested(
    ProductSearchSavedSearchesRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    emit(state.copyWith(isSavedSearchesLoading: true));
    try {
      final saved = await marketplaceRepository.getSavedSearches();
      emit(state.copyWith(savedSearches: saved, isSavedSearchesLoading: false));
    } catch (error) {
      emit(
        state.copyWith(
          isSavedSearchesLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onDelSavedSearchRequested(
    ProductSearchDelSavedSearchRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    try {
      await marketplaceRepository.delSavedSearch(
        searchId: event.searchId,
        keyword: event.keyword,
      );
      final updatedList = state.savedSearches.where((item) {
        if (event.searchId != null && item.id == event.searchId) return false;
        if (event.keyword != null && item.title == event.keyword) return false;
        return true;
      }).toList();
      emit(state.copyWith(savedSearches: updatedList));
    } catch (error) {
      emit(state.copyWith(errorMessage: error.toString()));
    }
  }

  Future<void> _onCategoriesRequested(
    ProductSearchCategoriesRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    emit(
      state.copyWith(
        isCategoriesLoading: true,
        categoriesIndex: 0,
        hasReachedEndCategories: false,
        clearError: true,
      ),
    );
    try {
      final categories = await marketplaceRepository.getCategories(
        parentId: 0,
        index: 0,
        count: state.categoriesCount,
      );
      emit(
        state.copyWith(
          categories: categories,
          isCategoriesLoading: false,
          hasReachedEndCategories: categories.length < state.categoriesCount,
          categoriesIndex: categories.length,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isCategoriesLoading: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCategoriesLoadMoreRequested(
    ProductSearchCategoriesLoadMoreRequested event,
    Emitter<ProductSearchState> emit,
  ) async {
    if (state.isCategoriesLoadingMore || state.hasReachedEndCategories) return;
    emit(state.copyWith(isCategoriesLoadingMore: true, clearError: true));
    try {
      final more = await marketplaceRepository.getCategories(
        parentId: 0,
        index: state.categoriesIndex,
        count: state.categoriesCount,
      );
      final updatedCategories = [...state.categories];
      final existingIds = updatedCategories.map((c) => c.id).toSet();
      for (final c in more) {
        if (!existingIds.contains(c.id)) {
          updatedCategories.add(c);
        }
      }
      emit(
        state.copyWith(
          categories: updatedCategories,
          isCategoriesLoadingMore: false,
          hasReachedEndCategories: more.length < state.categoriesCount,
          categoriesIndex: updatedCategories.length,
          clearError: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isCategoriesLoadingMore: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
