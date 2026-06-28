import 'package:army_ecommerce/models/product_model.dart';
import 'package:equatable/equatable.dart';

class SellerListingsState extends Equatable {
  final List<ProductModel> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasReachedEnd;
  final String? errorMessage;
  final String? successMessage;
  final int index;
  final int count;

  const SellerListingsState({
    this.products = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasReachedEnd = false,
    this.errorMessage,
    this.successMessage,
    this.index = 0,
    this.count = 20,
  });

  SellerListingsState copyWith({
    List<ProductModel>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasReachedEnd,
    String? errorMessage,
    String? successMessage,
    int? index,
    int? count,
    bool clearMessages = false,
  }) {
    return SellerListingsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages
          ? null
          : successMessage ?? this.successMessage,
      index: index ?? this.index,
      count: count ?? this.count,
    );
  }

  @override
  List<Object?> get props => [
    products,
    isLoading,
    isLoadingMore,
    hasReachedEnd,
    errorMessage,
    successMessage,
    index,
    count,
  ];
}
