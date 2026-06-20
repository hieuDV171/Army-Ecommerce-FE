import 'package:army_ecommerce/core/services/cart_manager.dart';
import 'package:army_ecommerce/models/model_helpers.dart';
import 'package:equatable/equatable.dart';

abstract class CheckoutEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckoutRequested extends CheckoutEvent {
  final int? productId;

  CheckoutRequested({this.productId});

  @override
  List<Object?> get props => [productId];
}

class CheckoutAddressSelected extends CheckoutEvent {
  final MarketplaceItem address;

  CheckoutAddressSelected(this.address);

  @override
  List<Object?> get props => [address];
}

class CheckoutSubmitted extends CheckoutEvent {
  final List<CartItem> items;
  final int orderSource;

  CheckoutSubmitted({required this.items, this.orderSource = 0});

  @override
  List<Object?> get props => [items, orderSource];
}

class CheckoutShipFeeRequested extends CheckoutEvent {
  final int productId;
  final int? addressId;

  CheckoutShipFeeRequested({required this.productId, this.addressId});

  @override
  List<Object?> get props => [productId, addressId];
}
