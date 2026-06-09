import 'package:equatable/equatable.dart';
import '../../core/services/cart_manager.dart';
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

  CheckoutSubmitted({required this.items});

  @override
  List<Object?> get props => [items];
}

class CheckoutShipFeeRequested extends CheckoutEvent {
  final int productId;
  final int? addressId;

  CheckoutShipFeeRequested({required this.productId, this.addressId});

  @override
  List<Object?> get props => [productId, addressId];
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

abstract class NotificationEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class NotificationsRequested extends NotificationEvent {}

class NotificationsRefreshed extends NotificationEvent {}

class NotificationsLoadMoreRequested extends NotificationEvent {}

class NotificationReadRequested extends NotificationEvent {
  final String notificationId;

  NotificationReadRequested(this.notificationId);

  @override
  List<Object?> get props => [notificationId];
}

abstract class AddressEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AddressListRequested extends AddressEvent {}

class AddressAdded extends AddressEvent {
  final String address;
  final String fullAddress;
  final String receiverName;
  final String phone;
  final bool isDefault;
  final String? addressDetail;
  final String province;
  final String district;
  final String latitude;
  final String longitude;
  final List<int>? addressId;

  AddressAdded({
    required this.address,
    required this.fullAddress,
    required this.receiverName,
    required this.phone,
    this.isDefault = false,
    this.addressDetail,
    required this.province,
    required this.district,
    required this.latitude,
    required this.longitude,
    this.addressId,
  });

  @override
  List<Object?> get props => [address, fullAddress, receiverName, phone, isDefault, addressDetail, province, district, latitude, longitude, addressId];
}

class AddressUpdated extends AddressEvent {
  final String id;
  final String address;
  final String fullAddress;
  final String receiverName;
  final String phone;
  final bool isDefault;
  final String? addressDetail;
  final String province;
  final String district;
  final String latitude;
  final String longitude;
  final List<int>? addressId;

  AddressUpdated({
    required this.id,
    required this.address,
    required this.fullAddress,
    required this.receiverName,
    required this.phone,
    this.isDefault = false,
    this.addressDetail,
    required this.province,
    required this.district,
    required this.latitude,
    required this.longitude,
    this.addressId,
  });

  @override
  List<Object?> get props => [id, address, fullAddress, receiverName, phone, isDefault, addressDetail, province, district, latitude, longitude, addressId];
}

class AddressDeleted extends AddressEvent {
  final String id;

  AddressDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

