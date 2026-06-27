import 'model_helpers.dart';

class AddressModel {
  final String id;
  final String receiverName;
  final String phone;
  final String fullAddress;
  final bool isDefault;
  final String? address;
  final String? addressDetail;
  final String? latitude;
  final String? longitude;
  final String? province;
  final String? district;

  const AddressModel({
    required this.id,
    required this.receiverName,
    required this.phone,
    required this.fullAddress,
    this.isDefault = false,
    this.address,
    this.addressDetail,
    this.latitude,
    this.longitude,
    this.province,
    this.district,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: readString(json, ['id', 'address_id']),
      receiverName: readString(json, ['receiver_name', 'name'], fallback: 'Người nhận'),
      phone: readString(json, ['phone', 'phone_number']),
      fullAddress: readString(
        json,
        ['full_address', 'address', 'address_detail'],
        fallback: 'Chưa có địa chỉ',
      ),
      isDefault: readBool(json, ['is_default', 'default']) ?? false,
      address: readOptionalString(json, ['address_name', 'address']),
      addressDetail: readOptionalString(json, ['address_detail']),
      latitude: readOptionalString(json, ['lat', 'latitude']),
      longitude: readOptionalString(json, ['lng', 'longitude']),
      province: readOptionalString(json, ['province']),
      district: readOptionalString(json, ['district']),
    );
  }

  MarketplaceItem toItem() {
    return MarketplaceItem(
      id: id,
      title: receiverName,
      subtitle: '$phone\n$fullAddress',
      trailing: isDefault ? 'Mặc định' : null,
    );
  }
}

class ProvinceModel {
  final int id;
  final String name;

  const ProvinceModel({required this.id, required this.name});

  factory ProvinceModel.fromJson(Map<String, dynamic> json) {
    return ProvinceModel(
      id: readInt(json, ['id']) ?? 0,
      name: readString(json, ['name'], fallback: ''),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProvinceModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class WardModel {
  final int id;
  final String name;
  final int provinceId;

  const WardModel({
    required this.id,
    required this.name,
    required this.provinceId,
  });

  factory WardModel.fromJson(Map<String, dynamic> json) {
    return WardModel(
      id: readInt(json, ['id']) ?? 0,
      name: readString(json, ['name'], fallback: ''),
      provinceId: readInt(json, ['province_id', 'provinces_id']) ?? 0,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WardModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
