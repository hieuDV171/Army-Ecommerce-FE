import 'package:army_ecommerce/models/address_model.dart';
import 'package:equatable/equatable.dart';

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
  List<Object?> get props => [
    address,
    fullAddress,
    receiverName,
    phone,
    isDefault,
    addressDetail,
    province,
    district,
    latitude,
    longitude,
    addressId,
  ];
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
  final AddressModel? originalAddress;

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
    this.originalAddress,
  });

  @override
  List<Object?> get props => [
    id,
    address,
    fullAddress,
    receiverName,
    phone,
    isDefault,
    addressDetail,
    province,
    district,
    latitude,
    longitude,
    addressId,
    originalAddress,
  ];
}

class AddressDeleted extends AddressEvent {
  final String id;

  AddressDeleted(this.id);

  @override
  List<Object?> get props => [id];
}

class AddressSetDefault extends AddressEvent {
  final AddressModel address;

  AddressSetDefault(this.address);

  @override
  List<Object?> get props => [address];
}

class ProvincesRequested extends AddressEvent {}

class WardsRequested extends AddressEvent {
  final int provinceId;

  WardsRequested(this.provinceId);

  @override
  List<Object?> get props => [provinceId];
}

class AddressClearMessages extends AddressEvent {}
