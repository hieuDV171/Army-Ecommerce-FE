import 'package:army_ecommerce/models/product_model.dart';
import 'package:equatable/equatable.dart';

abstract class SellerListingsEvent extends Equatable {
  const SellerListingsEvent();

  @override
  List<Object?> get props => [];
}

class SellerListingsRequested extends SellerListingsEvent {
  final String userId;
  final bool isRefresh;

  const SellerListingsRequested(this.userId, {this.isRefresh = false});

  @override
  List<Object?> get props => [userId, isRefresh];
}

class SellerListingsLoadMoreRequested extends SellerListingsEvent {
  final String userId;

  const SellerListingsLoadMoreRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}

class SellerListingsLikeToggled extends SellerListingsEvent {
  final ProductModel product;

  const SellerListingsLikeToggled(this.product);

  @override
  List<Object?> get props => [product];
}
