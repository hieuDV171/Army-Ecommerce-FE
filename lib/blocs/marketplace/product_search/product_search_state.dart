import 'package:army_ecommerce/models/brand_model.dart';
import 'package:army_ecommerce/models/category_model.dart';
import 'package:army_ecommerce/models/product_model.dart';
import 'package:army_ecommerce/models/model_helpers.dart';
import 'package:equatable/equatable.dart';

class ProductSearchState extends Equatable {
  final List<ProductModel> products;
  final List<BrandModel> brands;
  final List<CategoryModel> categories;
  final String keyword;
  final String? categoryId;
  final String? brandId;
  final num? priceMin;
  final num? priceMax;
  final bool useListProductsApi;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final bool isBrandsLoading;
  final bool isCategoriesLoading;
  final bool isCategoriesLoadingMore;
  final bool hasReachedEndCategories;
  final String? errorMessage;
  final int index;
  final int count;
  final int categoriesIndex;
  final int categoriesCount;
  final int? lastId;
  final List<MarketplaceItem> savedSearches;
  final bool isSavedSearchesLoading;

  const ProductSearchState({
    this.products = const [],
    this.brands = const [],
    this.categories = const [],
    this.keyword = '',
    this.categoryId,
    this.brandId,
    this.priceMin,
    this.priceMax,
    this.useListProductsApi = false,
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.isBrandsLoading = false,
    this.isCategoriesLoading = false,
    this.isCategoriesLoadingMore = false,
    this.hasReachedEndCategories = false,
    this.errorMessage,
    this.index = 0,
    this.count = 20,
    this.categoriesIndex = 0,
    this.categoriesCount = 10,
    this.lastId,
    this.savedSearches = const [],
    this.isSavedSearchesLoading = false,
  });

  ProductSearchState copyWith({
    List<ProductModel>? products,
    List<BrandModel>? brands,
    List<CategoryModel>? categories,
    String? keyword,
    String? Function()? categoryId,
    String? Function()? brandId,
    num? Function()? priceMin,
    num? Function()? priceMax,
    bool? useListProductsApi,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    bool? isBrandsLoading,
    bool? isCategoriesLoading,
    bool? isCategoriesLoadingMore,
    bool? hasReachedEndCategories,
    String? errorMessage,
    int? index,
    int? count,
    int? categoriesIndex,
    int? categoriesCount,
    int? Function()? lastId,
    List<MarketplaceItem>? savedSearches,
    bool? isSavedSearchesLoading,
    bool clearError = false,
  }) {
    return ProductSearchState(
      products: products ?? this.products,
      brands: brands ?? this.brands,
      categories: categories ?? this.categories,
      keyword: keyword ?? this.keyword,
      categoryId: categoryId != null ? categoryId() : this.categoryId,
      brandId: brandId != null ? brandId() : this.brandId,
      priceMin: priceMin != null ? priceMin() : this.priceMin,
      priceMax: priceMax != null ? priceMax() : this.priceMax,
      useListProductsApi: useListProductsApi ?? this.useListProductsApi,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isBrandsLoading: isBrandsLoading ?? this.isBrandsLoading,
      isCategoriesLoading: isCategoriesLoading ?? this.isCategoriesLoading,
      isCategoriesLoadingMore: isCategoriesLoadingMore ?? this.isCategoriesLoadingMore,
      hasReachedEndCategories: hasReachedEndCategories ?? this.hasReachedEndCategories,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      index: index ?? this.index,
      count: count ?? this.count,
      categoriesIndex: categoriesIndex ?? this.categoriesIndex,
      categoriesCount: categoriesCount ?? this.categoriesCount,
      lastId: lastId != null ? lastId() : this.lastId,
      savedSearches: savedSearches ?? this.savedSearches,
      isSavedSearchesLoading: isSavedSearchesLoading ?? this.isSavedSearchesLoading,
    );
  }

  @override
  List<Object?> get props => [
        products,
        brands,
        categories,
        keyword,
        categoryId,
        brandId,
        priceMin,
        priceMax,
        useListProductsApi,
        isInitialLoading,
        isRefreshing,
        isLoadingMore,
        hasReachedEnd,
        isBrandsLoading,
        isCategoriesLoading,
        isCategoriesLoadingMore,
        hasReachedEndCategories,
        errorMessage,
        index,
        count,
        categoriesIndex,
        categoriesCount,
        lastId,
        savedSearches,
        isSavedSearchesLoading,
      ];
}
