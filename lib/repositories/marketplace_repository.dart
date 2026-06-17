import 'dart:io';

import 'package:army_ecommerce/core/services/cart_manager.dart';
import 'package:army_ecommerce/models/address_model.dart';
import 'package:army_ecommerce/models/brand_model.dart';
import 'package:army_ecommerce/models/category_model.dart';
import 'package:army_ecommerce/models/checkout_model.dart';
import 'package:army_ecommerce/models/conversation_model.dart';
import 'package:army_ecommerce/models/marketplace_chat_model.dart' as mk;
import 'package:army_ecommerce/models/message_model.dart';
import 'package:army_ecommerce/models/model_helpers.dart';
import 'package:army_ecommerce/models/order_model.dart';
import 'package:army_ecommerce/models/product_model.dart';
import 'package:army_ecommerce/models/wallet_model.dart';

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

  Future<List<ProvinceModel>> getProvinces();

  Future<List<WardModel>> getWards(int provinceId);

  Future<List<OrderModel>> getOrders({String? state, int index = 0, int count = 20});
  Future<List<OrderModel>> getOrdersSeller({
    String? state,
    int index = 0,
    int count = 20,
  });

  Future<OrderModel?> getOrderDetail(String id);

  Future<ShipFeeModel?> getShipFee(int productId, {int? addressId});

  /// Lấy danh sách kho hàng theo khu vực.
  /// [level]: 0 = phường/xã, 1 = tỉnh/thành phố (mặc định 1).
  /// [parentId]: mã tỉnh hoặc mã phường (bắt buộc).
  /// [index], [count]: phân trang.
  Future<List<ShipFromModel>> getShipFrom({
    required String parentId,
    int? level,
    int index = 0,
    int count = 20,
  });

  /// Create a new order. Accepts a raw request map to keep flexibility for
  /// different backend payload shapes.
  Future<void> createOrder(Map<String, dynamic> data);

  /// Edit purchase (buyer-side) when the order hasn't been shipped yet.
  Future<Map<String, dynamic>> editOrder(String purchaseId, Map<String, dynamic> data);

  /// Seller marks a purchase as shipped.
  Future<void> sellerMarkAsShipped(String purchaseId, {String? buyerId});

  /// Seller accepts/rejects a buyer's purchase request.
  Future<void> setAcceptBuyer(String purchaseId, String buyerId, bool accept);

  /// Get order timeline (history of status changes) for a purchase.
  Future<List<OrderTimelineModel>> getOrderTimeline(String purchaseId);

  Future<void> cancelOrder(String id, {String? reason});

  Future<void> confirmReceived(String purchaseId);

  Future<void> refundOrder(String purchaseId, {String? reason});

  Future<ConversationListResponse> getConversations({int index = 0, int count = 20});

  Future<MessageListResponse> getConversation({
    required String partnerId,
    required String conversationId,
    int index = 0,
    int count = 20,
  });

  Future<SendMessageResponse> sendMessage({
    required String toId,
    required String message,
    String? productId,
    String typeMessage = 'text',
  });

  Future<SimpleResponse> markConversationRead(String partnerId);

  // WebSocket / Real-time Streams
  void initSocket(String token);
  void closeSocket();
  Stream<MessageModel> get newMessagesStream;
  Stream<mk.NotificationModel> get newNotificationsStream;

  Future<List<mk.NotificationModel>> getNotifications({
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

  // Cart operations
  Future<List<CartItem>> getCart();
  Future<void> addCartItem(String productId, int quantity);
  Future<void> editCartItem(String productId, int quantity);
  Future<void> deleteCartItem(String productId);

  // Rewards operations
  Future<Map<String, dynamic>?> addRewardProof({
    required String description,
    String? videoUrl,
    String? imageUrl,
  });

  Future<Map<String, dynamic>> getRewardProof(String rewardId);

  /// Lịch sử quy đổi điểm thưởng.
  Future<List<RewardHistoryModel>> getRewardHistory({
    int index = 1,
    int count = 20,
  });

  /// Tạo yêu cầu khiếu nại điểm thưởng.
  Future<RewardAppealModel> createRewardAppeal({
    required String rewardId,
    String? reason,
  });

  /// [STUB — BE chưa implement] Tải video quy đổi điểm thưởng.
  /// Endpoint dự kiến: POST /media/upload_video
  Future<UploadVideoResponseModel> uploadVideo({
    required File videoFile,
  });

  /// Tải ảnh/tập tin sản phẩm lên máy chủ.
  Future<String?> uploadFile(File file);

  /// Thêm sản phẩm mới.
  Future<void> addProduct(Map<String, dynamic> data);

  /// Cập nhật thông tin sản phẩm.
  Future<void> updateProduct(String id, Map<String, dynamic> data);

  /// Xóa sản phẩm.
  Future<void> deleteProduct(String id);
}
