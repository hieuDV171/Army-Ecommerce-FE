import 'package:equatable/equatable.dart';

abstract class ProductSearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductSearchRequested extends ProductSearchEvent {
  final String keyword;
  final String? categoryId;
  final String? brandId;
  final num? priceMin;
  final num? priceMax;

  ProductSearchRequested({
    this.keyword = '',
    this.categoryId,
    this.brandId,
    this.priceMin,
    this.priceMax,
  });

  @override
  List<Object?> get props => [keyword, categoryId, brandId, priceMin, priceMax];
}

class ProductSearchFiltered extends ProductSearchEvent {
  final String keyword;
  final String? categoryId;
  final String? brandId;
  final num? priceMin;
  final num? priceMax;

  ProductSearchFiltered({
    required this.keyword,
    this.categoryId,
    this.brandId,
    this.priceMin,
    this.priceMax,
  });

  @override
  List<Object?> get props => [keyword, categoryId, brandId, priceMin, priceMax];
}

class ProductSearchRefreshed extends ProductSearchEvent {}

class ProductSearchLoadMoreRequested extends ProductSearchEvent {}

class ProductSearchBrandsRequested extends ProductSearchEvent {
  final String? categoryId;

  ProductSearchBrandsRequested({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

class ProductSearchProductLikeToggled extends ProductSearchEvent {
  final String productId;

  ProductSearchProductLikeToggled(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ProductSearchSavedSearchesRequested extends ProductSearchEvent {}

class ProductSearchDelSavedSearchRequested extends ProductSearchEvent {
  final String? searchId;
  final String? keyword;

  ProductSearchDelSavedSearchRequested({this.searchId, this.keyword});

  @override
  List<Object?> get props => [searchId, keyword];
}
