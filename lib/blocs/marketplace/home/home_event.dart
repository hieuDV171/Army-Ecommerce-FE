import 'package:equatable/equatable.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeRequested extends HomeEvent {}

class HomeRefreshed extends HomeEvent {}

class HomeLoadMoreRequested extends HomeEvent {}

class HomeLoadMoreCategoriesRequested extends HomeEvent {}

class HomeProductLikeToggled extends HomeEvent {
  final String productId;

  HomeProductLikeToggled(this.productId);

  @override
  List<Object?> get props => [productId];
}
