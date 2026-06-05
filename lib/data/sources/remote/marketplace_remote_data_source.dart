import 'package:dio/dio.dart';

import '../../../core/api/dio_client.dart';
import '../../../core/constants/api_paths.dart';
import '../../../models/api_response.dart';

class MarketplaceRemoteDataSource {
  final DioClient _dioClient;

  MarketplaceRemoteDataSource({required DioClient dioClient}) : _dioClient = dioClient;

  Future<ApiResponse<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.dio.post(path, data: data ?? <String, dynamic>{});
      return ApiResponse<dynamic>.fromDynamic(response.data, (json) => json);
    } on DioException catch (error) {
      throw Exception(error.error?.toString() ?? error.message ?? 'Lỗi kết nối mạng');
    }
  }

  Future<ApiResponse<dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dioClient.dio.get(path, queryParameters: queryParameters);
      return ApiResponse<dynamic>.fromDynamic(response.data, (json) => json);
    } on DioException catch (error) {
      throw Exception(error.error?.toString() ?? error.message ?? 'Lỗi kết nối mạng');
    }
  }

  Future<ApiResponse<dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dioClient.dio.patch(path, data: data ?? <String, dynamic>{});
      return ApiResponse<dynamic>.fromDynamic(response.data, (json) => json);
    } on DioException catch (error) {
      throw Exception(error.error?.toString() ?? error.message ?? 'Lỗi kết nối mạng');
    }
  }

  Future<ApiResponse<dynamic>> delete(String path) async {
    try {
      final response = await _dioClient.dio.delete(path);
      return ApiResponse<dynamic>.fromDynamic(response.data, (json) => json);
    } on DioException catch (error) {
      throw Exception(error.error?.toString() ?? error.message ?? 'Lỗi kết nối mạng');
    }
  }

  Future<ApiResponse<dynamic>> getCategories({int? parentId}) {
    final request = <String, dynamic>{};
    if (parentId != null) request['parent_id'] = parentId;

    return post(
      ApiPaths.categories,
      data: request,
    );
  }

  Future<ApiResponse<dynamic>> getBrands({
    String? categoryId,
    int index = 0,
    int count = 20,
  }) {
    final request = <String, dynamic>{
      'index': index,
      'count': count,
    };
    if (categoryId != null) request['category_id'] = categoryId;

    return post(
      ApiPaths.brands,
      data: request,
    );
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
    final request = <String, dynamic>{
      'index': index,
      'count': count,
    };
    if (keyword != null && keyword.isNotEmpty) request['keyword'] = keyword;
    if (categoryId != null && categoryId.isNotEmpty) request['category_id'] = categoryId;
    if (brandId != null && brandId.isNotEmpty) request['brand_id'] = brandId;
    if (productSizeId != null) request['product_size_id'] = productSizeId;
    if (priceMin != null) request['price_min'] = priceMin;
    if (priceMax != null) request['price_max'] = priceMax;
    if (order != null && order.isNotEmpty) request['order'] = order;
    if (latitude != null) request['latitude'] = latitude;
    if (longitude != null) request['longitude'] = longitude;
    if (lastId != null) request['last_id'] = lastId;

    return post(
      ApiPaths.listProducts,
      data: request,
    );
  }

  Future<ApiResponse<dynamic>> getProductDetail(String productId) {
    return post(ApiPaths.productDetail, data: {'id': int.tryParse(productId) ?? productId});
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
    if (categoryId != null && categoryId.isNotEmpty) request['category_id'] = normalizeId(categoryId, fallback: categoryId);
    if (type != null) request['type'] = type;
    if (state != null) request['state'] = state;
    if (token != null && token.isNotEmpty) request['token'] = token;

    return post(
      '/api/get_user_listings',
      data: request,
    );
  }
}
