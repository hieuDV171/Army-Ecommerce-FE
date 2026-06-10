import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import 'product_detail_event.dart';
import 'product_detail_state.dart';

class ProductDetailBloc extends Bloc<ProductDetailEvent, ProductDetailState> {
  final MarketplaceRepository marketplaceRepository;
  String? _productId;

  ProductDetailBloc({required this.marketplaceRepository})
      : super(const ProductDetailState()) {
    on<ProductDetailRequested>(_onRequested);
    on<ProductLikeToggled>(_onLikeToggled);
    on<ProductCommentSent>(_onCommentSent);
    on<ProductReported>(_onReported);
  }

  Future<void> _onRequested(
    ProductDetailRequested event,
    Emitter<ProductDetailState> emit,
  ) async {
    _productId = event.productId;
    emit(state.copyWith(isLoading: true, clearMessages: true));
    try {
      final product = await marketplaceRepository.getProductDetail(event.productId);
      final comments = await marketplaceRepository.getComments(event.productId);
      emit(
        state.copyWith(
          product: product,
          comments: comments,
          isLoading: false,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onLikeToggled(
    ProductLikeToggled event,
    Emitter<ProductDetailState> emit,
  ) async {
    final product = state.product;
    if (product == null) return;

    final optimistic = product.copyWith(
      isLiked: !product.isLiked,
      likeCount: product.likeCount + (product.isLiked ? -1 : 1),
    );
    emit(state.copyWith(product: optimistic, clearMessages: true));

    try {
      await marketplaceRepository.likeProduct(product.id);
    } catch (error) {
      emit(state.copyWith(product: product, errorMessage: error.toString()));
    }
  }

  Future<void> _onCommentSent(
    ProductCommentSent event,
    Emitter<ProductDetailState> emit,
  ) async {
    final productId = _productId;
    if (productId == null || event.content.trim().isEmpty) return;

    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      await marketplaceRepository.sendComment(productId, event.content.trim());
      final comments = await marketplaceRepository.getComments(productId);
      emit(
        state.copyWith(
          comments: comments,
          isSubmitting: false,
          successMessage: 'Đã gửi bình luận',
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onReported(
    ProductReported event,
    Emitter<ProductDetailState> emit,
  ) async {
    final productId = _productId;
    if (productId == null) return;

    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      await marketplaceRepository.reportProduct(productId, event.subject, event.details);
      emit(
        state.copyWith(
          isSubmitting: false,
          successMessage: 'Đã gửi báo cáo sản phẩm',
        ),
      );
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }
}
