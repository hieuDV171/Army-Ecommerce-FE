import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import 'seller_listings_event.dart';
import 'seller_listings_state.dart';

class SellerListingsBloc
    extends Bloc<SellerListingsEvent, SellerListingsState> {
  final MarketplaceRepository marketplaceRepository;

  SellerListingsBloc({required this.marketplaceRepository})
    : super(const SellerListingsState()) {
    on<SellerListingsRequested>(_onRequested);
    on<SellerListingsLoadMoreRequested>(_onLoadMoreRequested);
    on<SellerListingsLikeToggled>(_onLikeToggled);
  }

  Future<void> _onRequested(
    SellerListingsRequested event,
    Emitter<SellerListingsState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoading: true,
        clearMessages: true,
        index: 0,
        hasReachedEnd: false,
      ),
    );
    try {
      final products = await marketplaceRepository.getUserListings(
        userId: event.userId,
        index: 0,
        count: state.count,
      );
      emit(
        state.copyWith(
          products: products,
          isLoading: false,
          hasReachedEnd: products.length < state.count,
          index: products.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onLoadMoreRequested(
    SellerListingsLoadMoreRequested event,
    Emitter<SellerListingsState> emit,
  ) async {
    if (state.isLoadingMore || state.hasReachedEnd || state.isLoading) return;
    emit(state.copyWith(isLoadingMore: true, clearMessages: true));
    try {
      final moreProducts = await marketplaceRepository.getUserListings(
        userId: event.userId,
        index: state.index,
        count: state.count,
      );
      final updatedList = [...state.products, ...moreProducts];
      emit(
        state.copyWith(
          products: updatedList,
          isLoadingMore: false,
          hasReachedEnd: moreProducts.length < state.count,
          index: updatedList.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(isLoadingMore: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> _onLikeToggled(
    SellerListingsLikeToggled event,
    Emitter<SellerListingsState> emit,
  ) async {
    final product = event.product;
    final originalIsLiked = product.isLiked;
    final originalLikeCount = product.likeCount;

    // Optimistic UI update
    final updatedProducts = state.products.map((p) {
      if (p.id == product.id) {
        return p.copyWith(
          isLiked: !originalIsLiked,
          likeCount: originalIsLiked
              ? originalLikeCount - 1
              : originalLikeCount + 1,
        );
      }
      return p;
    }).toList();

    emit(state.copyWith(products: updatedProducts, clearMessages: true));

    try {
      await marketplaceRepository.likeProduct(product.id);
    } catch (error) {
      // Revert if failed
      final revertedProducts = state.products.map((p) {
        if (p.id == product.id) {
          return p.copyWith(
            isLiked: originalIsLiked,
            likeCount: originalLikeCount,
          );
        }
        return p;
      }).toList();
      emit(
        state.copyWith(
          products: revertedProducts,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
