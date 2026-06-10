import 'package:army_ecommerce/models/brand_model.dart';
import 'package:army_ecommerce/models/product_model.dart';
import 'package:equatable/equatable.dart';

class ProductSearchState extends Equatable {
  final List<ProductModel> products;
  final List<BrandModel> brands;
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
  final String? errorMessage;
  final int index;
  final int count;
  final int? lastId;

  const ProductSearchState({
    this.products = const [],
    this.brands = const [],
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
    this.errorMessage,
    this.index = 0,
    this.count = 20,
    this.lastId,
  });

  ProductSearchState copyWith({
    List<ProductModel>? products,
    List<BrandModel>? brands,
    String? keyword,
    String? categoryId,
    String? brandId,
    num? priceMin,
    num? priceMax,
    bool? useListProductsApi,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    bool? isBrandsLoading,
    String? errorMessage,
    int? index,
    int? count,
    int? lastId,
    bool clearError = false,
  }) {
    return ProductSearchState(
      products: products ?? this.products,
      brands: brands ?? this.brands,
      keyword: keyword ?? this.keyword,
      categoryId: categoryId ?? this.categoryId,
      brandId: brandId ?? this.brandId,
      priceMin: priceMin ?? this.priceMin,
      priceMax: priceMax ?? this.priceMax,
      useListProductsApi: useListProductsApi ?? this.useListProductsApi,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      isBrandsLoading: isBrandsLoading ?? this.isBrandsLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      index: index ?? this.index,
      count: count ?? this.count,
      lastId: lastId ?? this.lastId,
    );
  }

  @override
  List<Object?> get props => [
    products,
    brands,
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
    errorMessage,
    index,
    count,
    lastId,
  ];
}
