import 'model_helpers.dart';

class BrandModel {
  final String id;
  final String name;

  const BrandModel({required this.id, required this.name});

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: readString(json, ['id', 'brand_id']),
      name: readString(json, [
        'name',
        'title',
        'brand_name',
      ], fallback: 'Thương hiệu'),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BrandModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
