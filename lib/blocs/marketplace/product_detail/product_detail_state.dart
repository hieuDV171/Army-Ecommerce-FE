import 'package:army_ecommerce/models/product_model.dart';
import 'package:equatable/equatable.dart';

class ProductDetailState extends Equatable {
  final ProductModel? product;
  final List<CommentModel> comments;
  final bool isLoading;
  final bool isSubmitting;
  final bool isFetchingMoreComments;
  final bool hasMoreComments;
  final String? errorMessage;
  final String? successMessage;

  const ProductDetailState({
    this.product,
    this.comments = const [],
    this.isLoading = false,
    this.isSubmitting = false,
    this.isFetchingMoreComments = false,
    this.hasMoreComments = true,
    this.errorMessage,
    this.successMessage,
  });

  ProductDetailState copyWith({
    ProductModel? product,
    List<CommentModel>? comments,
    bool? isLoading,
    bool? isSubmitting,
    bool? isFetchingMoreComments,
    bool? hasMoreComments,
    String? errorMessage,
    String? successMessage,
    bool clearMessages = false,
  }) {
    return ProductDetailState(
      product: product ?? this.product,
      comments: comments ?? this.comments,
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isFetchingMoreComments: isFetchingMoreComments ?? this.isFetchingMoreComments,
      hasMoreComments: hasMoreComments ?? this.hasMoreComments,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
    );
  }

  @override
  List<Object?> get props => [
    product,
    comments,
    isLoading,
    isSubmitting,
    isFetchingMoreComments,
    hasMoreComments,
    errorMessage,
    successMessage,
  ];
}
