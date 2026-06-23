import 'package:army_ecommerce/models/category_model.dart';
import 'package:army_ecommerce/models/product_model.dart';
import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final List<CategoryModel> categories;
  final List<ProductModel> products;
  final bool isInitialLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? errorMessage;
  final int index;
  final int count;
  final int? lastId;
  final bool isLoadingMoreCategories;
  final bool hasReachedEndCategories;
  final int categoriesIndex;
  final int categoriesCount;

  const HomeState({
    this.categories = const [],
    this.products = const [],
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.index = 0,
    this.count = 20,
    this.lastId,
    this.isLoadingMoreCategories = false,
    this.hasReachedEndCategories = false,
    this.categoriesIndex = 0,
    this.categoriesCount = 10,
  });

  bool get isEmpty => !isInitialLoading && products.isEmpty;

  HomeState copyWith({
    List<CategoryModel>? categories,
    List<ProductModel>? products,
    bool? isInitialLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    String? errorMessage,
    bool clearError = false,
    int? index,
    int? count,
    int? lastId,
    bool? isLoadingMoreCategories,
    bool? hasReachedEndCategories,
    int? categoriesIndex,
    int? categoriesCount,
  }) {
    return HomeState(
      categories: categories ?? this.categories,
      products: products ?? this.products,
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      index: index ?? this.index,
      count: count ?? this.count,
      lastId: lastId ?? this.lastId,
      isLoadingMoreCategories: isLoadingMoreCategories ?? this.isLoadingMoreCategories,
      hasReachedEndCategories: hasReachedEndCategories ?? this.hasReachedEndCategories,
      categoriesIndex: categoriesIndex ?? this.categoriesIndex,
      categoriesCount: categoriesCount ?? this.categoriesCount,
    );
  }

  @override
  List<Object?> get props => [
    categories,
    products,
    isInitialLoading,
    isRefreshing,
    isLoadingMore,
    hasReachedEnd,
    errorMessage,
    index,
    count,
    lastId,
    isLoadingMoreCategories,
    hasReachedEndCategories,
    categoriesIndex,
    categoriesCount,
  ];
}
