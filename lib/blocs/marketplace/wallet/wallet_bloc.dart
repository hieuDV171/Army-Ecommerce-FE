import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final MarketplaceRepository marketplaceRepository;

  static const int _pageSize = 20;

  WalletBloc({required this.marketplaceRepository})
    : super(const WalletState()) {
    on<WalletRequested>(_onRequested);
    on<WalletLoadMoreRequested>(_onLoadMore);
  }

  Future<void> _onRequested(
    WalletRequested event,
    Emitter<WalletState> emit,
  ) async {
    emit(state.copyWith(isLoading: true));
    try {
      final balance = await marketplaceRepository.getCurrentBalance();
      final history = await marketplaceRepository.getBalanceHistory(
        index: 0,
        count: _pageSize,
      );
      emit(
        state.copyWith(
          balance: balance,
          history: history,
          isLoading: false,
          hasMore: history.length >= _pageSize,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }

  Future<void> _onLoadMore(
    WalletLoadMoreRequested event,
    Emitter<WalletState> emit,
  ) async {
    // Tránh gọi trùng khi đang tải hoặc đã hết dữ liệu
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    emit(state.copyWith(isLoadingMore: true));
    try {
      final more = await marketplaceRepository.getBalanceHistory(
        index: state.history.length,
        count: _pageSize,
      );
      emit(
        state.copyWith(
          history: [...state.history, ...more],
          isLoadingMore: false,
          hasMore: more.length >= _pageSize,
        ),
      );
    } catch (_) {
      // Lỗi tải thêm: dừng spinner, giữ nguyên danh sách hiện có
      emit(state.copyWith(isLoadingMore: false));
    }
  }
}
