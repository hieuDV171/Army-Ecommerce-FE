import '../../core/constants/api_paths.dart';
import '../../models/marketplace_models.dart';
import '../../repositories/marketplace_repository.dart';
import '../sources/remote/marketplace_remote_data_source.dart';

class MarketplaceRepositoryImpl implements MarketplaceRepository {
  final MarketplaceRemoteDataSource remoteDataSource;

  MarketplaceRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<CategoryModel>> getCategories({int? parentId}) async {
    final response = await remoteDataSource.getCategories(parentId: parentId);
    return parseListFromData(response.data, CategoryModel.fromJson);
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
    return remoteDataSource.post('/api/like_product', data: {'product_id': _idValue(productId)});
  }

  @override
  Future<List<CommentModel>> getComments(
    String productId, {
    int index = 0,
    int count = 20,
  }) async {
    final response = await remoteDataSource.post(
      '/api/get_comments_product',
      data: {'product_id': _idValue(productId), 'index': index, 'count': count},
    );
    return parseListFromData(response.data, CommentModel.fromJson);
  }

  @override
  Future<void> sendComment(String productId, String content) {
    return remoteDataSource.post(
      '/api/set_comments_product',
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
      '/api/report_product',
      data: {'product_id': _idValue(productId), 'subject': subject, 'details': details},
    );
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
      '/News/list_news',
      data: {'index': index, 'count': count},
    );
    return parseListFromData(response.data, MarketplaceItem.fromJson);
  }

  @override
  Future<MarketplaceItem?> getNewsDetail(String id) async {
    final response = await remoteDataSource.get('/News/$id');
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
    final response = await remoteDataSource.getUserListings(
      userId: userId,
      index: index,
      count: count,
      keyword: keyword.isEmpty ? null : keyword,
      categoryId: categoryId == '0' ? null : categoryId,
    );
    return parseListFromData(response.data, ProductModel.fromJson);
  }

  @override
  Future<List<AddressModel>> getAddresses() async {
    final response = await remoteDataSource.get('/order/get_list_order_address');
    return parseListFromData(response.data, AddressModel.fromJson);
  }

  @override
  Future<void> addAddress(Map<String, dynamic> data) {
    return remoteDataSource.post('/order/add_order_address', data: data);
  }

  @override
  Future<void> updateAddress(String id, Map<String, dynamic> data) {
    return remoteDataSource.patch('/order/update/$id', data: data);
  }

  @override
  Future<void> deleteAddress(String id) {
    return remoteDataSource.delete('/order/delete/$id');
  }

  @override
  Future<List<OrderModel>> getOrders({
    String? state,
    int index = 0,
    int count = 20,
  }) async {
    final response = await remoteDataSource.post(
      '/order/get_list_purchases',
      data: {
        'index': index.toString(),
        'count': count.toString(),
        if (state != null && state.isNotEmpty) 'state': state,
      },
    );
    return parseListFromData(response.data, OrderModel.fromJson);
  }

  @override
  Future<OrderModel?> getOrderDetail(String id) async {
    final response = await remoteDataSource.post('/order/get_purchase', data: {'id': id});
    final map = parseMapFromData(response.data);
    if (map.isEmpty) return null;
    return OrderModel.fromJson(map);
  }

  @override
  Future<void> cancelOrder(String id, {int? reason}) {
    final request = <String, dynamic>{'id': id};
    if (reason != null) request['reason'] = reason;

    return remoteDataSource.post(
      '/order/cancel_order',
      data: request,
    );
  }

  @override
  Future<void> confirmReceived(String purchaseId) {
    return remoteDataSource.post(
      '/order/buyer_confirm_received',
      data: {'purchase_id': purchaseId},
    );
  }

  @override
  Future<void> refundOrder(String purchaseId, {String? reason}) {
    final request = <String, dynamic>{'purchase_id': purchaseId};
    if (reason != null) request['reason'] = reason;

    return remoteDataSource.post(
      '/order/refund_order',
      data: request,
    );
  }

  @override
  Future<List<ConversationModel>> getConversations({int index = 0, int count = 20}) async {
    final response = await remoteDataSource.post(
      '/conversation/get_list_conversation',
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
      '/conversation/get_conversation',
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
    required String productId,
    String typeMessage = 'text',
  }) async {
    final response = await remoteDataSource.post(
      '/conversation/send_message',
      data: {
        'to_id': _idValue(toId),
        'message': message,
        'type_message': typeMessage,
        'product_id': _idValue(productId),
      },
    );
    final map = parseMapFromData(response.data);
    if (map.isEmpty) return null;
    return MessageModel.fromJson(map);
  }

  @override
  Future<void> markConversationRead(String partnerId) {
    return remoteDataSource.post(
      '/conversation/set_read_message',
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
      '/notification/get_notification',
      data: {'group': group, 'index': index, 'count': count},
    );
    return parseListFromData(response.data, NotificationModel.fromJson);
  }

  @override
  Future<void> markNotificationRead(String notificationId) {
    return remoteDataSource.post(
      '/notification/set_read_notification',
      data: {'notification_id': _idValue(notificationId)},
    );
  }

  @override
  Future<List<WalletHistoryModel>> getBalanceHistory({int index = 0, int count = 20}) async {
    final response = await remoteDataSource.post(
      '/wallets/get_balance_history',
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
    final response = await remoteDataSource.post('/wallets/get_current_balance');
    return WalletBalanceModel.fromJson(parseMapFromData(response.data));
  }

  @override
  Future<void> postAction(String path, Map<String, dynamic> data) {
    return remoteDataSource.post(path, data: data);
  }

  Object _idValue(String value) {
    return int.tryParse(value) ?? value;
  }
}
