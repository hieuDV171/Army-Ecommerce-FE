import 'dart:io';
import 'package:dio/dio.dart';
import 'package:army_ecommerce/core/network/api_exception.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/constants/api_paths.dart';
import '../../../models/api_response.dart';

class MarketplaceRemoteDataSource {
  final DioClient _dioClient;

  MarketplaceRemoteDataSource({required DioClient dioClient})
    : _dioClient = dioClient;

  Future<ApiResponse<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.dio.post(
        path,
        data: data ?? <String, dynamic>{},
      );
      return ApiResponse<dynamic>.fromDynamic(response.data, (json) => json);
    } on DioException catch (error) {
      if (error.error is ApiException) {
        throw error.error as ApiException;
      }
      throw ApiException.fromResponse(
        data: error.response?.data,
        statusCode: error.response?.statusCode,
        fallbackMessage: error.message,
      );
    }
  }

  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.dio.get(
        path,
        queryParameters: queryParameters,
      );
      return ApiResponse<dynamic>.fromDynamic(response.data, (json) => json);
    } on DioException catch (error) {
      if (error.error is ApiException) {
        throw error.error as ApiException;
      }
      throw ApiException.fromResponse(
        data: error.response?.data,
        statusCode: error.response?.statusCode,
        fallbackMessage: error.message,
      );
    }
  }

  Future<ApiResponse<dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.dio.patch(
        path,
        data: data ?? <String, dynamic>{},
      );
      return ApiResponse<dynamic>.fromDynamic(response.data, (json) => json);
    } on DioException catch (error) {
      if (error.error is ApiException) {
        throw error.error as ApiException;
      }
      throw ApiException.fromResponse(
        data: error.response?.data,
        statusCode: error.response?.statusCode,
        fallbackMessage: error.message,
      );
    }
  }

  Future<ApiResponse<dynamic>> delete(String path) async {
    try {
      final response = await _dioClient.dio.delete(path);
      return ApiResponse<dynamic>.fromDynamic(response.data, (json) => json);
    } on DioException catch (error) {
      if (error.error is ApiException) {
        throw error.error as ApiException;
      }
      throw ApiException.fromResponse(
        data: error.response?.data,
        statusCode: error.response?.statusCode,
        fallbackMessage: error.message,
      );
    }
  }

  Future<ApiResponse<dynamic>> getCategories({
    int? parentId,
    int? index,
    int? count,
  }) {
    final request = <String, dynamic>{};
    if (parentId != null) request['parent_id'] = parentId;
    if (index != null) request['index'] = index;
    if (count != null) request['count'] = count;

    return post(ApiPaths.categories, data: request);
  }

  Future<ApiResponse<dynamic>> getBrands({
    String? categoryId,
    int index = 0,
    int count = 20,
  }) {
    final request = <String, dynamic>{'index': index, 'count': count};
    if (categoryId != null && categoryId.isNotEmpty) {
      request['category_id'] = int.tryParse(categoryId) ?? categoryId;
    }

    return post(ApiPaths.brands, data: request);
  }

  Future<ApiResponse<dynamic>> getListProducts({
    int index = 0,
    int count = 20,
    String? keyword,
    String? categoryId,
    String? brandId,
    int? productSizeId,
    num? priceMin,
    num? priceMax,
    String? order,
    int? latitude,
    int? longitude,
    int? lastId,
  }) {
    final request = <String, dynamic>{'index': index, 'count': count};
    if (keyword != null && keyword.isNotEmpty) request['keyword'] = keyword;
    if (categoryId != null && categoryId.isNotEmpty) {
      request['category_id'] = int.tryParse(categoryId) ?? categoryId;
    }
    if (brandId != null && brandId.isNotEmpty) {
      request['brand_id'] = int.tryParse(brandId) ?? brandId;
    }
    if (productSizeId != null) request['product_size_id'] = productSizeId;
    if (priceMin != null) request['price_min'] = priceMin;
    if (priceMax != null) request['price_max'] = priceMax;
    if (order != null && order.isNotEmpty) request['order'] = order;
    if (latitude != null) request['latitude'] = latitude;
    if (longitude != null) request['longitude'] = longitude;
    if (lastId != null) request['last_id'] = lastId;

    return post(ApiPaths.listProducts, data: request);
  }

  Future<ApiResponse<dynamic>> getProductDetail(String productId) {
    return post(
      ApiPaths.productDetail,
      data: {'id': int.tryParse(productId) ?? productId},
    );
  }

  Future<ApiResponse<dynamic>> getUserListings({
    required String userId,
    int index = 0,
    int count = 20,
    String? keyword,
    String? categoryId,
    int? type,
    int? state,
    String? token,
  }) {
    dynamic normalizeId(String? value, {required dynamic fallback}) {
      if (value == null || value.isEmpty) return fallback;
      return int.tryParse(value) ?? value;
    }

    final request = <String, dynamic>{
      'user_id': normalizeId(userId, fallback: userId),
      'index': index,
      'count': count,
    };
    if (keyword != null && keyword.isNotEmpty) request['keyword'] = keyword;
    if (categoryId != null && categoryId.isNotEmpty) {
      request['category_id'] = normalizeId(categoryId, fallback: categoryId);
    }
    if (type != null) request['type'] = type;
    if (state != null) request['state'] = state;
    if (token != null && token.isNotEmpty) request['token'] = token;

    return post(ApiPaths.getUserListings, data: request);
  }

  /// GET /order/get_ship_from — Lấy danh sách kho hàng theo khu vực.
  Future<ApiResponse<dynamic>> getShipFrom({
    required String parentId,
    int? level,
    int index = 0,
    int count = 20,
  }) {
    final queryParams = <String, dynamic>{
      'parent_id': parentId,
      'index': index,
      'count': count,
    };
    if (level != null) queryParams['level'] = level;

    return get(ApiPaths.getShipFrom, queryParameters: queryParams);
  }

  /// POST /order/get_list_purchases - lấy danh sách đơn mua hàng
  Future<ApiResponse<dynamic>> getListPurchases({
    String? state,
    int index = 0,
    int count = 20,
  }) {
    final queryParams = <String, dynamic>{
      'index': index,
      'count': count,
      if (state != null && state.isNotEmpty) 'state': state,
    };

    return post(ApiPaths.getListPurchases, data: queryParams);
  }

  /// POST /order/get_list_purchases_seller - lấy danh sách đơn bán hàng
  Future<ApiResponse<dynamic>> getListPurchasesSeller({
    String? state,
    int index = 0,
    int count = 20,
  }) {
    final queryParams = <String, dynamic>{
      'index': index,
      'count': count,
      if (state != null && state.isNotEmpty) 'state': state,
    };

    return post(ApiPaths.getListPurchasesSeller, data: queryParams);
  }

  // ─── CART METHODS ──────────────────────────────────────────────────────────

  Future<ApiResponse<dynamic>> getCart() {
    return get(ApiPaths.getCart);
  }

  Future<ApiResponse<dynamic>> addCart(String productId, int quantity) {
    return post(
      ApiPaths.addCart,
      data: {
        'product_id': int.tryParse(productId) ?? productId,
        'quantity': quantity,
      },
    );
  }

  Future<ApiResponse<dynamic>> editCart(String productId, int quantity) {
    return post(
      ApiPaths.editCart,
      data: {
        'product_id': int.tryParse(productId) ?? productId,
        'quantity': quantity,
      },
    );
  }

  Future<ApiResponse<dynamic>> deleteCart(String productId) {
    return post(
      ApiPaths.deleteCart,
      data: {'product_id': int.tryParse(productId) ?? productId},
    );
  }

  // ─── REWARDS METHODS ───────────────────────────────────────────────────────

  Future<ApiResponse<dynamic>> addRewardProof({
    required String description,
    String? videoUrl,
    String? imageUrl,
  }) {
    final data = <String, dynamic>{'description': description};
    if (videoUrl != null && videoUrl.isNotEmpty) {
      data['video_url'] = videoUrl;
    }
    if (imageUrl != null && imageUrl.isNotEmpty) {
      data['image_url'] = imageUrl;
    }

    return post(ApiPaths.addRewardProof, data: data);
  }

  Future<ApiResponse<dynamic>> getRewardProof(String rewardId) {
    return post(
      ApiPaths.getRewardProof,
      data: {'reward_id': int.tryParse(rewardId) ?? 0},
    );
  }

  Future<ApiResponse<dynamic>> getRewardHistory({
    int index = 0,
    int count = 20,
  }) {
    return post(
      ApiPaths.getRewardHistory,
      data: {'index': index, 'count': count},
    );
  }

  Future<ApiResponse<dynamic>> createRewardAppeal({
    required String rewardId,
    String? reason,
  }) {
    final data = <String, dynamic>{'reward_id': int.tryParse(rewardId) ?? 0};
    if (reason != null) data['reason'] = reason;

    return post(ApiPaths.createRewardAppeal, data: data);
  }

  /// GET /order/provinces — Lấy danh sách tỉnh/thành phố.
  Future<ApiResponse<dynamic>> getProvinces() {
    return get(ApiPaths.getProvinces);
  }

  /// GET /order/wards — Lấy danh sách phường/xã theo tỉnh/thành phố.
  Future<ApiResponse<dynamic>> getWards(int provinceId) {
    return get(ApiPaths.getWards, queryParameters: {'province_id': provinceId});
  }

  /// POST /upload/file — Tải hình ảnh/tập tin lên máy chủ.
  Future<ApiResponse<dynamic>> uploadFile(File file) async {
    try {
      final fileName = file.path.split(Platform.pathSeparator).last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
      });

      final response = await _dioClient.dio.post(
        ApiPaths.uploadFile,
        data: formData,
        options: Options(contentType: 'multipart/form-data'),
      );
      return ApiResponse<dynamic>.fromDynamic(response.data, (json) => json);
    } on DioException catch (error) {
      throw Exception(
        error.error?.toString() ?? error.message ?? 'Lỗi kết nối mạng',
      );
    }
  }

  /// POST /api/add_product — Thêm sản phẩm mới.
  Future<ApiResponse<dynamic>> addProduct(Map<String, dynamic> data) {
    return post(ApiPaths.addProduct, data: data);
  }

  /// PATCH /api/update/:id — Cập nhật sản phẩm.
  Future<ApiResponse<dynamic>> updateProduct(
    String id,
    Map<String, dynamic> data,
  ) {
    return patch(ApiPaths.updateProduct(id), data: data);
  }

  /// DELETE /api/delete/:id — Xóa sản phẩm.
  Future<ApiResponse<dynamic>> deleteProduct(String id) {
    return delete(ApiPaths.deleteProduct(id));
  }
}
