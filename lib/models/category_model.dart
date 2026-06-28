import 'model_helpers.dart';

class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;

  const CategoryModel({required this.id, required this.name, this.imageUrl});

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: readString(json, ['id', 'category_id']),
      name: readString(json, [
        'name',
        'title',
        'category_name',
      ], fallback: 'Danh mục'),
      imageUrl: readOptionalString(json, ['image', 'image_url', 'icon']),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CategoryModel &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
