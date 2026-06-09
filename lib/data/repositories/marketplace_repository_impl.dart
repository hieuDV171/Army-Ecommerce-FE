import 'dart:convert';
import 'dart:io';
import 'package:army_ecommerce/core/services/session_manager.dart';

import '../../core/constants/api_paths.dart';
import '../../models/marketplace_models.dart';
import '../../repositories/marketplace_repository.dart';
import '../sources/remote/marketplace_remote_data_source.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource remoteDataSource;

  MarketplaceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CategoryModel>> getCategories({int? parentId}) async {
    try {
      final response = await remoteDataSource.getCategories(parentId: parentId);
      // Cache response data for first level categories
      if (parentId == null || parentId == 0) {
        SessionManager.saveCachedCategoriesJson(jsonEncode(response.data));
      }
      return parseListFromData(response.data, CategoryModel.fromJson);
    } catch (e) {
      // Offline fallback: load categories from cache
      if (parentId == null || parentId == 0) {
        final cachedJson = await SessionManager.getCachedCategoriesJson();
        if (cachedJson != null) {
          final decoded = jsonDecode(cachedJson);
          return parseListFromData(decoded, CategoryModel.fromJson);
        }
      }
      rethrow;
    }
  }

  @override
  Future<List<BrandModel>> getBrands({
    String? categoryId,
    int index = 0,
    int count = 20,
  }) async {
    final response = await remoteDataSource.getBrands(
      categoryId: categoryId,
      index: index,
      count: count,
    );
    return parseListFromData(response.data, BrandModel.fromJson);
  }

  @override
  Future<ProductListResult> getListProducts({
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
  }) async {
    try {
      final response = await remoteDataSource.getListProducts(
        index: index,
        count: count,
        keyword: keyword,
        categoryId: categoryId,
        brandId: brandId,
        productSizeId: productSizeId,
        priceMin: priceMin,
        priceMax: priceMax,
        order: order,
        latitude: latitude,
        longitude: longitude,
        lastId: lastId,
      );
      // Cache the product list response for the first-load home page view
      if (index == 0 && keyword == null && categoryId == null && brandId == null) {
        SessionManager.saveCachedProductsJson(jsonEncode(response.data));
      }

      final products = parseListFromData(response.data, ProductModel.fromJson);
      final map = parseMapFromData(response.data);
      int? last;
      final rawLast = map['last_id'] ?? map['lastId'] ?? map['last'];
      if (rawLast is int) {
        last = rawLast;
      } else if (rawLast != null) {
        last = int.tryParse(rawLast.toString());
      }

      return ProductListResult(products: products, lastId: last);
    } catch (e) {
      // Offline fallback: load products from cache for home screen first-load
      if (index == 0 && keyword == null && categoryId == null && brandId == null) {
        final cachedJson = await SessionManager.getCachedProductsJson();
        if (cachedJson != null) {
          final decoded = jsonDecode(cachedJson);
          final products = parseListFromData(decoded, ProductModel.fromJson);
          final map = parseMapFromData(decoded);
          int? last;
          final rawLast = map['last_id'] ?? map['lastId'] ?? map['last'];
          if (rawLast is int) {
            last = rawLast;
          } else if (rawLast != null) {
            last = int.tryParse(rawLast.toString());
          }
          return ProductListResult(products: products, lastId: last);
        }
      }
      rethrow;
    }
  }

  @override
  Future<List<ProductModel>> searchProducts({
    String? keyword,
    String? categoryId,
    String? brandId,
    num? priceMin,
    num? priceMax,
    String? condition,
    int index = 0,
    int count = 20,
  }) async {
    final request = <String, dynamic>{
      'index': index,
      'count': count,
    };
    if (keyword != null && keyword.isNotEmpty) request['keyword'] = keyword;
    if (categoryId != null && categoryId.isNotEmpty) {
      request['category_id'] = _idValue(categoryId);
    }
    if (brandId != null && brandId.isNotEmpty) request['brand_id'] = _idValue(brandId);
    if (priceMin != null) request['price_min'] = priceMin;
    if (priceMax != null) request['price_max'] = priceMax;
    if (condition != null) request['condition'] = condition;

    final response = await remoteDataSource.post(
      ApiPaths.search,
      data: request,
    );
    return parseListFromData(response.data, ProductModel.fromJson);
  }

  @override
  Future<ProductModel?> getProductDetail(String productId) async {
    final response = await remoteDataSource.getProductDetail(productId);
    final map = parseMapFromData(response.data);
    if (map.isEmpty) return null;
    return ProductModel.fromJson(map);
  }

  @override
  Future<void> likeProduct(String productId) {
    return remoteDataSource.post(ApiPaths.likeProduct, data: {'product_id': _idValue(productId)});
  }

  @override
  Future<List<CommentModel>> getComments(
    String productId, {
    int index = 0,
    int count = 20,
  }) async {
    final response = await remoteDataSource.post(
      ApiPaths.getCommentsProduct,
      data: {'product_id': _idValue(productId), 'index': index, 'count': count},
    );
    return parseListFromData(response.data, CommentModel.fromJson);
  }

  @override
  Future<void> sendComment(String productId, String content) {
    return remoteDataSource.post(
      ApiPaths.setCommentsProduct,
      data: {
        'product_id': _idValue(productId),
        'content': content,
        'index': 0,
        'count': 20,
      },
    );
  }

  @override
  Future<void> reportProduct(String productId, String subject, String details) {
    return remoteDataSource.post(
      ApiPaths.reportProduct,
      data: {'product_id': _idValue(productId), 'subject': subject, 'details': details},
    );
  }

  @override
  Future<List<RateModel>> getRates({String? userId, String? productId, int? level, int index = 0, int count = 20}) async {
    final request = <String, dynamic>{'index': index, 'count': count};
    if (userId != null && userId.isNotEmpty) request['user_id'] = _idValue(userId);
    if (productId != null && productId.isNotEmpty) request['product_id'] = _idValue(productId);
    if (level != null) request['level'] = level;

    final response = await remoteDataSource.post(ApiPaths.getRates, data: request);
    return parseListFromData(response.data, RateModel.fromJson);
  }

  @override
  Future<void> setRates({required String userId, required int level, required String content, String? productId, String? purchaseId}) {
    final request = <String, dynamic>{
      'user_id': _idValue(userId),
      'level': level,
      'content': content,
    };
    if (productId != null && productId.isNotEmpty) request['product_id'] = _idValue(productId);
    if (purchaseId != null && purchaseId.isNotEmpty) request['purchase_id'] = _idValue(purchaseId);

    return remoteDataSource.post(ApiPaths.setRates, data: request);
  }

  @override
  Future<List<MarketplaceItem>> getSavedSearches({int index = 0, int count = 20}) async {
    final response = await remoteDataSource.post(
      ApiPaths.savedSearches,
      data: {'index': index, 'count': count},
    );
    return parseListFromData(response.data, MarketplaceItem.fromJson);
  }

  @override
  Future<void> saveSearch(String keyword) {
    return remoteDataSource.post(ApiPaths.saveSearch, data: {'keyword': keyword});
  }

  @override
  Future<List<MarketplaceItem>> getNews({int index = 0, int count = 20}) async {
    final response = await remoteDataSource.post(
      ApiPaths.listNews,
      data: {'index': index, 'count': count},
    );

    final raw = response.data;
    // Some backends return { list_news: [...], total: N } inside data
    if (raw is Map && raw['list_news'] is List) {
      return parseListFromData(raw['list_news'], MarketplaceItem.fromJson);
    }

    return parseListFromData(raw, MarketplaceItem.fromJson);
  }

  @override
  Future<MarketplaceItem?> getNewsDetail(String id) async {
    final response = await remoteDataSource.get(ApiPaths.newsDetail(id));
    final map = parseMapFromData(response.data);
    if (map.isEmpty) return null;
    return MarketplaceItem.fromJson(map);
  }

  @override
  Future<List<ProductModel>> getUserListings({
    required String userId,
    int index = 0,
    int count = 20,
    String keyword = '',
    String categoryId = '0',
  }) async {
    final token = await SessionManager.getToken();
    final response = await remoteDataSource.getUserListings(
      userId: userId,
      index: index,
      count: count,
      keyword: keyword.isEmpty ? null : keyword,
      categoryId: categoryId == '0' ? null : categoryId,
      token: token,
    );
    return parseListFromData(response.data, ProductModel.fromJson);
  }

  @override
  Future<List<AddressModel>> getAddresses() async {
    final response = await remoteDataSource.get(ApiPaths.getListOrderAddress);
    return parseListFromData(response.data, AddressModel.fromJson);
  }

  @override
  Future<void> addAddress(Map<String, dynamic> data) async {
    final response = await remoteDataSource.post(ApiPaths.addOrderAddress, data: data);
    if (response.code != '1000') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Lỗi thêm địa chỉ (Mã lỗi ${response.code})');
    }
  }

  @override
  Future<void> updateAddress(String id, Map<String, dynamic> data) async {
    final response = await remoteDataSource.patch(ApiPaths.updateAddress(id), data: data);
    if (response.code != '1000') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Lỗi cập nhật địa chỉ (Mã lỗi ${response.code})');
    }
  }

  @override
  Future<void> deleteAddress(String id) async {
    final response = await remoteDataSource.delete(ApiPaths.deleteAddress(id));
    if (response.code != '1000') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Lỗi xóa địa chỉ (Mã lỗi ${response.code})');
    }
  }

  @override
  Future<List<ProvinceModel>> getProvinces() async {
    final response = await remoteDataSource.getProvinces();
    return parseListFromData(response.data, ProvinceModel.fromJson);
  }

  @override
  Future<List<WardModel>> getWards(int provinceId) async {
    final response = await remoteDataSource.getWards(provinceId);
    return parseListFromData(response.data, WardModel.fromJson);
  }

  @override
  Future<List<OrderModel>> getOrders({
    String? state,
    int index = 0,
    int count = 20,
  }) async {
    final response = await remoteDataSource.post(
      ApiPaths.getListPurchases,
      data: {
        'index': index,
        'count': count,
        if (state != null && state.isNotEmpty) 'state': state,
      },
    );
    return parseListFromData(response.data, OrderModel.fromJson);
  }

  @override
  Future<OrderModel?> getOrderDetail(String id) async {
    final response = await remoteDataSource.post(ApiPaths.getPurchase, data: {'id': id});
    final map = parseMapFromData(response.data);
    if (map.isEmpty) return null;
    return OrderModel.fromJson(map);
  }

  @override
  Future<ShipFeeModel?> getShipFee(int productId, {int? addressId}) async {
    final response = await remoteDataSource.post(
      ApiPaths.getShipFee,
      data: {
        'product_id': productId,
        'address_id': addressId,
      },
    );
    final map = parseMapFromData(response.data);
    if (map.isEmpty) return null;
    return ShipFeeModel.fromJson(map);
  }

  @override
  Future<List<ShipFromModel>> getShipFrom({
    required String parentId,
    int? level,
    int index = 0,
    int count = 20,
  }) async {
    final response = await remoteDataSource.getShipFrom(
      parentId: parentId,
      level: level,
      index: index,
      count: count,
    );
    return parseListFromData(response.data, ShipFromModel.fromJson);
  }

  @override
  Future<void> createOrder(Map<String, dynamic> data) async {
    final response = await remoteDataSource.post(ApiPaths.createOrder, data: data);
    if (response.code != '1000') {
      throw Exception(response.message);
    }
  }

  @override
  Future<Map<String, dynamic>> editOrder(String purchaseId, Map<String, dynamic> data) async {
    final request = <String, dynamic>{'id': purchaseId, ...data};
    final response = await remoteDataSource.post(ApiPaths.editPurchase, data: request);
    if (response.code != '1000') {
      throw Exception(response.message);
    }
    return parseMapFromData(response.data);
  }

  @override
  Future<void> cancelOrder(String id, {String? reason}) async {
    final request = <String, dynamic>{
      'id': id,
      'reason': reason ?? '',
    };

    final response = await remoteDataSource.post(
      ApiPaths.cancelOrder,
      data: request,
    );
    if (response.code != '1000') {
      throw Exception(response.message);
    }
  }

  @override
  Future<void> confirmReceived(String purchaseId) async {
    final response = await remoteDataSource.post(
      ApiPaths.buyerConfirmReceived,
      data: {'purchase_id': purchaseId},
    );
    if (response.code != '1000') {
      throw Exception(response.message);
    }
  }

  @override
  Future<void> sellerMarkAsShipped(String purchaseId, {String? buyerId}) async {
    final request = <String, dynamic>{'purchase_id': purchaseId};
    if (buyerId != null) request['buyer_id'] = buyerId;
    final response = await remoteDataSource.post(ApiPaths.sellerMarkAsShipped, data: request);
    if (response.code != '1000') {
      throw Exception(response.message);
    }
  }

  @override
  Future<void> refundOrder(String purchaseId, {String? reason}) async {
    final request = <String, dynamic>{'purchase_id': purchaseId};
    if (reason != null) request['reason'] = reason;

    final response = await remoteDataSource.post(
      ApiPaths.refundOrder,
      data: request,
    );
    if (response.code != '1000') {
      throw Exception(response.message);
    }
  }

  @override
  Future<void> setAcceptBuyer(String purchaseId, String buyerId, bool accept) async {
    final request = <String, dynamic>{
      'purchase_id': purchaseId,
      'buyer_id': buyerId,
      'is_accept': accept ? 1 : 0,
    };
    final response = await remoteDataSource.post(ApiPaths.setAcceptBuyer, data: request);
    if (response.code != '1000') {
      throw Exception(response.message);
    }
  }

  @override
  Future<List<OrderTimelineModel>> getOrderTimeline(String purchaseId) async {
    final response = await remoteDataSource.post(ApiPaths.getOrderTimeline, data: {'purchase_id': purchaseId});
    return parseListFromData(response.data, OrderTimelineModel.fromJson);
  }

  @override
  Future<List<ConversationModel>> getConversations({int index = 0, int count = 20}) async {
    final response = await remoteDataSource.post(
      ApiPaths.getListConversation,
      data: {'index': index, 'count': count},
    );
    return parseListFromData(response.data, ConversationModel.fromJson);
  }

  @override
  Future<List<MessageModel>> getConversation({
    required String partnerId,
    required String conversationId,
    int index = 0,
    int count = 20,
  }) async {
    final response = await remoteDataSource.post(
      ApiPaths.getConversation,
      data: {
        'partner_id': _idValue(partnerId),
        'conversation_id': _idValue(conversationId),
        'index': index,
        'count': count,
      },
    );
    return parseListFromData(response.data, MessageModel.fromJson);
  }

  @override
  Future<MessageModel?> sendMessage({
    required String toId,
    required String message,
    String? productId,
    String typeMessage = 'text',
  }) async {
    // product_id bắt buộc theo spec — truyền 0 nếu không chat từ trang sản phẩm
    final request = <String, dynamic>{
      'to_id': _idValue(toId),
      'message': message,
      'type_message': typeMessage,
      'product_id': (productId != null && productId.isNotEmpty)
          ? _idValue(productId)
          : 0,
    };

    final response = await remoteDataSource.post(
      ApiPaths.sendMessage,
      data: request,
    );
    final map = parseMapFromData(response.data);
    if (map.isEmpty) return null;
    return MessageModel.fromJson(map);
  }

  @override
  Future<void> markConversationRead(String partnerId) {
    return remoteDataSource.post(
      ApiPaths.setReadMessage,
      data: {'partner_id': _idValue(partnerId)},
    );
  }

  @override
  Future<List<NotificationModel>> getNotifications({
    int group = 0,
    int index = 0,
    int count = 20,
  }) async {
    final response = await remoteDataSource.post(
      ApiPaths.getNotification,
      data: {'group': group, 'index': index, 'count': count},
    );
    return parseListFromData(response.data, NotificationModel.fromJson);
  }

  @override
  Future<void> markNotificationRead(String notificationId) {
    return remoteDataSource.post(
      ApiPaths.setReadNotification,
      data: {'notification_id': _idValue(notificationId)},
    );
  }

  @override
  Future<List<WalletHistoryModel>> getBalanceHistory({int index = 0, int count = 20}) async {
    final response = await remoteDataSource.post(
      ApiPaths.getBalanceHistory,
      data: {'index': index.toString(), 'count': count.toString()},
    );
    return parseListFromData(response.data, WalletHistoryModel.fromJson);
  }

  @override
  Future<List<MarketplaceItem>> getGenericList(
    String path, {
    Map<String, dynamic>? data,
    int index = 0,
    int count = 20,
  }) async {
    final response = await remoteDataSource.post(
      path,
      data: {...?data, 'index': index, 'count': count},
    );
    return parseListFromData(response.data, MarketplaceItem.fromJson);
  }

  @override
  Future<WalletBalanceModel> getCurrentBalance() async {
    final response = await remoteDataSource.post(ApiPaths.getCurrentBalance);
    return WalletBalanceModel.fromJson(parseMapFromData(response.data));
  }

  @override
  Future<void> postAction(String path, Map<String, dynamic> data) {
    return remoteDataSource.post(path, data: data);
  }

  // ─── STUB: BE chưa implement ───────────────────────────────────────────────

  /// [STUB] get_reward_history — endpoint chưa tồn tại trên BE.
  /// Khi BE sẵn sàng: thay bằng gọi remoteDataSource.post('/rewards/get_reward_history', ...)
  @override
  Future<List<RewardHistoryModel>> getRewardHistory({
    int index = 0,
    int count = 20,
  }) async {
    throw UnimplementedError(
      'get_reward_history: API chưa được cài đặt phía Backend.',
    );
  }

  /// [STUB] create_reward_appeal — endpoint chưa tồn tại trên BE.
  /// Khi BE sẵn sàng: thay bằng gọi remoteDataSource.post('/rewards/create_reward_appeal', ...)
  @override
  Future<RewardAppealModel> createRewardAppeal({
    required String rewardId,
    String? reason,
  }) async {
    throw UnimplementedError(
      'create_reward_appeal: API chưa được cài đặt phía Backend.',
    );
  }

  /// [STUB] uploadVideo — endpoint chưa tồn tại trên BE.
  /// Khi BE sẵn sàng: thay bằng gọi remoteDataSource.post('/media/upload_video', ...)
  @override
  Future<UploadVideoResponseModel> uploadVideo({
    required File videoFile,
  }) async {
    throw UnimplementedError(
      'upload_video: API chưa được cài đặt phía Backend.',
    );
  }

  @override
  Future<String?> uploadFile(File file) async {
    final response = await remoteDataSource.uploadFile(file);
    if (response.code != '1000') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Upload thất bại');
    }
    final map = response.data as Map<String, dynamic>?;
    return map?['url'] as String?;
  }

  @override
  Future<void> addProduct(Map<String, dynamic> data) async {
    final response = await remoteDataSource.addProduct(data);
    if (response.code != '1000') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Thêm sản phẩm thất bại');
    }
  }

  @override
  Future<void> updateProduct(String id, Map<String, dynamic> data) async {
    final response = await remoteDataSource.updateProduct(id, data);
    if (response.code != '1000') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Cập nhật sản phẩm thất bại');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    final response = await remoteDataSource.deleteProduct(id);
    if (response.code != '1000') {
      throw Exception(response.message.isNotEmpty ? response.message : 'Xóa sản phẩm thất bại');
    }
  }

  Object _idValue(String value) {
    return int.tryParse(value) ?? value;
  }
}
