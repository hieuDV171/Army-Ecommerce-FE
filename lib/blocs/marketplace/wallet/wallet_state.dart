import 'package:army_ecommerce/models/wallet_model.dart';
import 'package:equatable/equatable.dart';

class WalletState extends Equatable {
  final WalletBalanceModel? balance;
  final List<WalletHistoryModel> history;
  final bool isLoading;
  final String? errorMessage;

  const WalletState({
    this.balance,
    this.history = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  WalletState copyWith({
    WalletBalanceModel? balance,
    List<WalletHistoryModel>? history,
    bool? isLoading,
    String? errorMessage,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [balance, history, isLoading, errorMessage];
}
