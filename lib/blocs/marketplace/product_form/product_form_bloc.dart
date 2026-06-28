import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../repositories/marketplace_repository.dart';
import 'product_form_event.dart';
import 'product_form_state.dart';

class ProductFormBloc extends Bloc<ProductFormEvent, ProductFormState> {
  final MarketplaceRepository marketplaceRepository;

  ProductFormBloc({required this.marketplaceRepository})
    : super(const ProductFormState()) {
    on<ProductFormMetadataRequested>(_onMetadataRequested);
    on<ProductFormCategoriesLoadMoreRequested>(_onCategoriesLoadMoreRequested);
    on<ProductFormBrandsRequested>(_onBrandsRequested);
    on<ProductFormSubmitted>(_onSubmitted);
  }

  Future<void> _onMetadataRequested(
    ProductFormMetadataRequested event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingMetadata: true,
        clearMessages: true,
        categoriesIndex: 0,
        hasReachedEndCategories: false,
      ),
    );
    try {
      final results = await Future.wait([
        marketplaceRepository.getCategories(
          parentId: 0,
          index: 0,
          count: state.categoriesCount,
        ),
        marketplaceRepository.getAddresses(),
      ]);

      final categories = results[0] as List;
      final addresses = results[1] as List;

      emit(
        state.copyWith(
          categories: List.from(categories),
          addresses: List.from(addresses),
          isLoadingMetadata: false,
          hasReachedEndCategories: categories.length < state.categoriesCount,
          categoriesIndex: categories.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingMetadata: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onCategoriesLoadMoreRequested(
    ProductFormCategoriesLoadMoreRequested event,
    Emitter<ProductFormState> emit,
  ) async {
    if (state.isLoadingMoreCategories ||
        state.hasReachedEndCategories ||
        state.isLoadingMetadata)
      return;
    emit(state.copyWith(isLoadingMoreCategories: true, clearMessages: true));
    try {
      final more = await marketplaceRepository.getCategories(
        parentId: 0,
        index: state.categoriesIndex,
        count: state.categoriesCount,
      );
      final updatedCategories = [...state.categories];
      final existingIds = updatedCategories.map((c) => c.id).toSet();
      for (final c in more) {
        if (!existingIds.contains(c.id)) {
          updatedCategories.add(c);
        }
      }
      emit(
        state.copyWith(
          categories: updatedCategories,
          isLoadingMoreCategories: false,
          hasReachedEndCategories: more.length < state.categoriesCount,
          categoriesIndex: updatedCategories.length,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          isLoadingMoreCategories: false,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onBrandsRequested(
    ProductFormBrandsRequested event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(
      state.copyWith(
        isLoadingBrands: true,
        clearMessages: true,
        brands: const [],
      ),
    );
    try {
      final brands = await marketplaceRepository.getBrands(
        categoryId: event.categoryId,
        index: 0,
        count: 50,
      );
      emit(
        state.copyWith(
          brands: brands,
          isLoadingBrands: false,
          clearMessages: true,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(isLoadingBrands: false, errorMessage: error.toString()),
      );
    }
  }

  Future<void> _onSubmitted(
    ProductFormSubmitted event,
    Emitter<ProductFormState> emit,
  ) async {
    emit(state.copyWith(isSubmitting: true, clearMessages: true));
    try {
      // 1. Upload new image files
      final uploadedUrls = <String>[];
      for (final file in event.newImages) {
        final url = await marketplaceRepository.uploadFile(file);
        if (url != null && url.isNotEmpty) {
          uploadedUrls.add(url);
        }
      }

      // 2. Prepare request payload
      final intWarehouseId = int.tryParse(event.warehouseId) ?? 0;
      final intCategoryId = event.categoryId != null
          ? int.tryParse(event.categoryId!)
          : null;
      final intBrandId = event.brandId != null
          ? int.tryParse(event.brandId!)
          : null;

      final variantsJson = event.variants.map((v) {
        final map = <String, dynamic>{
          'size': v.name,
          'color': v.color,
          'stock': v.stock,
          'weight': v.weight,
        };
        if (v.id.isNotEmpty) {
          map['id'] = int.tryParse(v.id) ?? v.id;
        }
        return map;
      }).toList();

      final List<Map<String, dynamic>> videos = [];
      if (event.videoUrl.isNotEmpty) {
        videos.add({'url': event.videoUrl});
      }

      if (event.product != null) {
        final payload = <String, dynamic>{
          'title': event.title,
          'price': event.price,
          'description': event.description,
          'ship_from_id': intWarehouseId,
          'variants': variantsJson,
          'category_id': intCategoryId,
          'brand_id': intBrandId,
          'image_urls': uploadedUrls,
          'image_urls_del': event.deletedImages,
          'videos': videos,
        };

        await marketplaceRepository.updateProduct(event.product!.id, payload);
        emit(
          state.copyWith(
            isSubmitting: false,
            isSuccess: true,
            successMessage: 'Cập nhật sản phẩm thành công',
          ),
        );
      } else {
        final payload = <String, dynamic>{
          'title': event.title,
          'price': event.price,
          'description': event.description,
          'ship_from_id': intWarehouseId,
          'variants': variantsJson,
          'category_id': intCategoryId,
          'brand_id': intBrandId,
          'image_urls': uploadedUrls,
          'videos': videos,
        };

        await marketplaceRepository.addProduct(payload);
        emit(
          state.copyWith(
            isSubmitting: false,
            isSuccess: true,
            successMessage: 'Thêm sản phẩm thành công',
          ),
        );
      }
    } catch (error) {
      emit(state.copyWith(isSubmitting: false, errorMessage: error.toString()));
    }
  }
}
