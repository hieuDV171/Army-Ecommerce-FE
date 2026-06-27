import 'package:army_ecommerce/models/address_model.dart';
import 'package:army_ecommerce/models/brand_model.dart';
import 'package:army_ecommerce/models/category_model.dart';
import 'package:equatable/equatable.dart';

class ProductFormState extends Equatable {
  final List<CategoryModel> categories;
  final List<AddressModel> addresses;
  final List<BrandModel> brands;
  final bool isLoadingMetadata;
  final bool isLoadingBrands;
  final bool isSubmitting;
  final bool isSuccess;
  final String? errorMessage;
  final String? successMessage;
  final int categoriesIndex;
  final int categoriesCount;
  final bool hasReachedEndCategories;
  final bool isLoadingMoreCategories;

  const ProductFormState({
    this.categories = const [],
    this.addresses = const [],
    this.brands = const [],
    this.isLoadingMetadata = false,
    this.isLoadingBrands = false,
    this.isSubmitting = false,
    this.isSuccess = false,
    this.errorMessage,
    this.successMessage,
    this.categoriesIndex = 0,
    this.categoriesCount = 10,
    this.hasReachedEndCategories = false,
    this.isLoadingMoreCategories = false,
  });

  ProductFormState copyWith({
    List<CategoryModel>? categories,
    List<AddressModel>? addresses,
    List<BrandModel>? brands,
    bool? isLoadingMetadata,
    bool? isLoadingBrands,
    bool? isSubmitting,
    bool? isSuccess,
    String? errorMessage,
    String? successMessage,
    int? categoriesIndex,
    int? categoriesCount,
    bool? hasReachedEndCategories,
    bool? isLoadingMoreCategories,
    bool clearMessages = false,
  }) {
    return ProductFormState(
      categories: categories ?? this.categories,
      addresses: addresses ?? this.addresses,
      brands: brands ?? this.brands,
      isLoadingMetadata: isLoadingMetadata ?? this.isLoadingMetadata,
      isLoadingBrands: isLoadingBrands ?? this.isLoadingBrands,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: clearMessages ? null : errorMessage ?? this.errorMessage,
      successMessage: clearMessages ? null : successMessage ?? this.successMessage,
      categoriesIndex: categoriesIndex ?? this.categoriesIndex,
      categoriesCount: categoriesCount ?? this.categoriesCount,
      hasReachedEndCategories: hasReachedEndCategories ?? this.hasReachedEndCategories,
      isLoadingMoreCategories: isLoadingMoreCategories ?? this.isLoadingMoreCategories,
    );
  }

  @override
  List<Object?> get props => [
        categories,
        addresses,
        brands,
        isLoadingMetadata,
        isLoadingBrands,
        isSubmitting,
        isSuccess,
        errorMessage,
        successMessage,
        categoriesIndex,
        categoriesCount,
        hasReachedEndCategories,
        isLoadingMoreCategories,
      ];
}
