import 'package:equatable/equatable.dart';

import '../../models/marketplace_models.dart';

abstract class HomeEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class HomeRequested extends HomeEvent {}

class HomeRefreshed extends HomeEvent {}

class HomeLoadMoreRequested extends HomeEvent {}

//-------------------------------------------
abstract class ProductDetailEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductDetailRequested extends ProductDetailEvent {
  final String productId;

  ProductDetailRequested(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ProductLikeToggled extends ProductDetailEvent {}

class ProductCommentSent extends ProductDetailEvent {
  final String content;

  ProductCommentSent(this.content);

  @override
  List<Object?> get props => [content];
}

class ProductReported extends ProductDetailEvent {
  final String subject;
  final String details;

  ProductReported({required this.subject, required this.details});

  @override
  List<Object?> get props => [subject, details];
}

//---------------------------------------------
abstract class ProductSearchEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ProductSearchRequested extends ProductSearchEvent {
  final String keyword;
  final String? categoryId;
  final String? brandId;
  final num? priceMin;
  final num? priceMax;

  ProductSearchRequested({
    this.keyword = '',
    this.categoryId,
    this.brandId,
    this.priceMin,
    this.priceMax,
  });

  @override
  List<Object?> get props => [keyword, categoryId, brandId, priceMin, priceMax];
}

class ProductSearchFiltered extends ProductSearchEvent {
  final String keyword;
  final String? categoryId;
  final String? brandId;
  final num? priceMin;
  final num? priceMax;

  ProductSearchFiltered({
    required this.keyword,
    this.categoryId,
    this.brandId,
    this.priceMin,
    this.priceMax,
  });

  @override
  List<Object?> get props => [keyword, categoryId, brandId, priceMin, priceMax];
}

class ProductSearchRefreshed extends ProductSearchEvent {}

class ProductSearchLoadMoreRequested extends ProductSearchEvent {}

class ProductSearchBrandsRequested extends ProductSearchEvent {
  final String? categoryId;

  ProductSearchBrandsRequested({this.categoryId});

  @override
  List<Object?> get props => [categoryId];
}

//----------------------------------------
abstract class SimpleListEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class SimpleListRequested extends SimpleListEvent {}

class SimpleListRefreshed extends SimpleListEvent {}

class SimpleListLoadMoreRequested extends SimpleListEvent {}

class SimpleActionRequested extends SimpleListEvent {
  final String path;
  final Map<String, dynamic> data;

  SimpleActionRequested({required this.path, required this.data});

  @override
  List<Object?> get props => [path, data];
}

// ---------------------------------------
abstract class WalletEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class WalletRequested extends WalletEvent {}

//---------------------------------------------
abstract class CheckoutEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class CheckoutRequested extends CheckoutEvent {}

class CheckoutAddressSelected extends CheckoutEvent {
  final MarketplaceItem address;

  CheckoutAddressSelected(this.address);

  @override
  List<Object?> get props => [address];
}

class CheckoutSubmitted extends CheckoutEvent {
  final String productId;
  final int quantity;

  CheckoutSubmitted({
    required this.productId,
    required this.quantity,
  });

  @override
  List<Object?> get props => [productId, quantity];
}

//---------------------------------
abstract class ConversationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ConversationsRequested extends ConversationEvent {}

class ConversationsRefreshed extends ConversationEvent {}

class ConversationsLoadMoreRequested extends ConversationEvent {}

//-------------------------------------
abstract class ChatEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class ChatRequested extends ChatEvent {}

class ChatMessageSubmitted extends ChatEvent {
  final String message;

  ChatMessageSubmitted(this.message);

  @override
  List<Object?> get props => [message];
}
