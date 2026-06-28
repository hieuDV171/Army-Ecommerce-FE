import 'package:army_ecommerce/models/wallet_model.dart';
import 'package:equatable/equatable.dart';

class WalletState extends Equatable {
  final WalletBalanceModel? balance;
  final List<WalletHistoryModel> history;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final String? errorMessage;

  const WalletState({
    this.balance,
    this.history = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.errorMessage,
  });

  WalletState copyWith({
    WalletBalanceModel? balance,
    List<WalletHistoryModel>? history,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    String? errorMessage,
  }) {
    return WalletState(
      balance: balance ?? this.balance,
      history: history ?? this.history,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [
    balance,
    history,
    isLoading,
    isLoadingMore,
    hasMore,
    errorMessage,
  ];
}
