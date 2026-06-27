import 'package:equatable/equatable.dart';

abstract class WalletEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WalletRequested extends WalletEvent {}

class WalletLoadMoreRequested extends WalletEvent {}
