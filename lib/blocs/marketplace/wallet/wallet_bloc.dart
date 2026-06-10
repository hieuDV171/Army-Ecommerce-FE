import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import 'wallet_event.dart';
import 'wallet_state.dart';

class WalletBloc extends Bloc<WalletEvent, WalletState> {
  final MarketplaceRepository marketplaceRepository;

  WalletBloc({required this.marketplaceRepository}) : super(const WalletState()) {
    on<WalletRequested>(_onRequested);
  }

  Future<void> _onRequested(WalletRequested event, Emitter<WalletState> emit) async {
    emit(state.copyWith(isLoading: true));
    try {
      final balance = await marketplaceRepository.getCurrentBalance();
      final history = await marketplaceRepository.getBalanceHistory(index: 0, count: 20);
      emit(
        state.copyWith(
          balance: balance,
          history: history,
          isLoading: false,
        ),
      );
    } catch (error) {
      emit(state.copyWith(isLoading: false, errorMessage: error.toString()));
    }
  }
}
