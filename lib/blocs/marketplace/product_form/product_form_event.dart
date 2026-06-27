import 'dart:io';
import 'package:army_ecommerce/models/product_model.dart';
import 'package:equatable/equatable.dart';

abstract class ProductFormEvent extends Equatable {
  const ProductFormEvent();

  @override
  List<Object?> get props => [];
}

class ProductFormMetadataRequested extends ProductFormEvent {}

class ProductFormCategoriesLoadMoreRequested extends ProductFormEvent {}

class ProductFormBrandsRequested extends ProductFormEvent {
  final String categoryId;

  const ProductFormBrandsRequested(this.categoryId);

  @override
  List<Object?> get props => [categoryId];
}

class ProductFormSubmitted extends ProductFormEvent {
  final ProductModel? product; // null if create, else edit
  final String title;
  final double price;
  final String description;
  final String? categoryId;
  final String? brandId;
  final String warehouseId;
  final List<File> newImages;
  final List<String> existingImages;
  final List<String> deletedImages;
  final List<ProductSizeModel> variants;
  final String videoUrl;

  const ProductFormSubmitted({
    required this.product,
    required this.title,
    required this.price,
    required this.description,
    required this.categoryId,
    required this.brandId,
    required this.warehouseId,
    required this.newImages,
    required this.existingImages,
    required this.deletedImages,
    required this.variants,
    required this.videoUrl,
  });

  @override
  List<Object?> get props => [
        product,
        title,
        price,
        description,
        categoryId,
        brandId,
        warehouseId,
        newImages,
        existingImages,
        deletedImages,
        variants,
        videoUrl,
      ];
}
