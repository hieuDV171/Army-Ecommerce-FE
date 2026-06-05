import '../models/marketplace_models.dart';

abstract class MarketplaceRepository {
  Future<List<CategoryModel>> getCategories({int? parentId});

  Future<List<BrandModel>> getBrands({String? categoryId, int index = 0, int count = 20});

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
  });

  Future<List<ProductModel>> searchProducts({
    String? keyword,
    String? categoryId,
    String? brandId,
    num? priceMin,
    num? priceMax,
    String? condition,
    int index = 0,
    int count = 20,
  });

  Future<ProductModel?> getProductDetail(String productId);

  Future<void> likeProduct(String productId);

  Future<List<CommentModel>> getComments(String productId, {int index = 0, int count = 20});

  Future<void> sendComment(String productId, String content);

  Future<void> reportProduct(String productId, String subject, String details);

  // Ratings
  Future<List<RateModel>> getRates({String? userId, String? productId, int? level, int index = 0, int count = 20});

  Future<void> setRates({required String userId, required int level, required String content, String? productId, String? purchaseId});

  Future<List<MarketplaceItem>> getSavedSearches({int index = 0, int count = 20});

  Future<void> saveSearch(String keyword);

  Future<List<MarketplaceItem>> getNews({int index = 0, int count = 20});

  Future<MarketplaceItem?> getNewsDetail(String id);

  Future<List<ProductModel>> getUserListings({
    required String userId,
    int index = 0,
    int count = 20,
    String keyword = '',
    String categoryId = '0',
  });

  Future<List<AddressModel>> getAddresses();

  Future<void> addAddress(Map<String, dynamic> data);

  Future<void> updateAddress(String id, Map<String, dynamic> data);

  Future<void> deleteAddress(String id);

  Future<List<OrderModel>> getOrders({String? state, int index = 0, int count = 20});

  Future<OrderModel?> getOrderDetail(String id);

  Future<ShipFeeModel?> getShipFee(int productId, {int? addressId});

  /// Create a new order. Accepts a raw request map to keep flexibility for
  /// different backend payload shapes.
  Future<void> createOrder(Map<String, dynamic> data);

  /// Edit purchase (buyer-side) when the order hasn't been shipped yet.
  Future<void> editOrder(String purchaseId, Map<String, dynamic> data);

  /// Seller marks a purchase as shipped.
  Future<void> sellerMarkAsShipped(String purchaseId, {String? buyerId});

  /// Seller accepts/rejects a buyer's purchase request.
  Future<void> setAcceptBuyer(String purchaseId, String buyerId, bool accept);

  /// Get order timeline (history of status changes) for a purchase.
  Future<List<OrderTimelineModel>> getOrderTimeline(String purchaseId);

  Future<void> cancelOrder(String id, {String? reason});

  Future<void> confirmReceived(String purchaseId);

  Future<void> refundOrder(String purchaseId, {String? reason});

  Future<List<ConversationModel>> getConversations({int index = 0, int count = 20});

  Future<List<MessageModel>> getConversation({
    required String partnerId,
    required String conversationId,
    int index = 0,
    int count = 20,
  });

  Future<MessageModel?> sendMessage({
    required String toId,
    required String message,
    String? productId,
    String typeMessage = 'text',
  });

  Future<void> markConversationRead(String partnerId);

  Future<List<NotificationModel>> getNotifications({
    int group = 0,
    int index = 0,
    int count = 20,
  });

  Future<void> markNotificationRead(String notificationId);

  Future<List<WalletHistoryModel>> getBalanceHistory({int index = 0, int count = 20});

  Future<List<MarketplaceItem>> getGenericList(
    String path, {
    Map<String, dynamic>? data,
    int index = 0,
    int count = 20,
  });

  Future<WalletBalanceModel> getCurrentBalance();

  Future<void> postAction(String path, Map<String, dynamic> data);
}
