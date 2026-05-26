class CategoryModel {
  final String id;
  final String name;
  final String? imageUrl;

  const CategoryModel({
    required this.id,
    required this.name,
    this.imageUrl,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) {
    return CategoryModel(
      id: _readString(json, ['id', 'category_id']),
      name: _readString(json, ['name', 'title', 'category_name'], fallback: 'Danh mục'),
      imageUrl: _readOptionalString(json, ['image', 'image_url', 'icon']),
    );
  }
}

class BrandModel {
  final String id;
  final String name;

  const BrandModel({required this.id, required this.name});

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      id: _readString(json, ['id', 'brand_id']),
      name: _readString(json, ['name', 'title', 'brand_name'], fallback: 'Thương hiệu'),
    );
  }
}

class ProductModel {
  final String id;
  final String title;
  final num price;
  final String description;
  final List<String> imageUrls;
  final String? sellerId;
  final String? sellerName;
  final String? sellerLocation;
  final double? rating;
  final int? soldCount;
  final int likeCount;
  final bool isLiked;

  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    required this.description,
    required this.imageUrls,
    this.sellerId,
    this.sellerName,
    this.sellerLocation,
    this.rating,
    this.soldCount,
    this.likeCount = 0,
    this.isLiked = false,
  });

  ProductModel copyWith({
    int? likeCount,
    bool? isLiked,
  }) {
    return ProductModel(
      id: id,
      title: title,
      price: price,
      description: description,
      imageUrls: imageUrls,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerLocation: sellerLocation,
      rating: rating,
      soldCount: soldCount,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final seller = json['seller'];
    final sellerMap = seller is Map ? Map<String, dynamic>.from(seller) : null;
    final images = _readStringList(json, [
      'image_urls',
      'images',
      'image',
      'image_url',
      'thumbnail',
    ]);

    return ProductModel(
      id: _readString(json, ['id', 'product_id']),
      title: _readString(json, ['title', 'name'], fallback: 'Sản phẩm'),
      price: _readNum(json, ['price', 'price_discount']),
      description: _readString(json, ['description', 'details'], fallback: ''),
      imageUrls: images,
      sellerId: _readOptionalString(json, ['seller_id']) ??
          (sellerMap == null ? null : _readOptionalString(sellerMap, ['id', 'user_id'])),
      sellerName: _readOptionalString(json, ['seller_name', 'username']) ??
          (sellerMap == null ? null : _readOptionalString(sellerMap, ['username', 'name'])),
      sellerLocation: _readOptionalString(json, ['location', 'seller_location', 'city']),
      rating: _readDouble(json, ['rating', 'rate', 'avg_rate']),
      soldCount: _readInt(json, ['sold', 'sold_count', 'total_sold']),
      likeCount: _readInt(json, ['like_count', 'likes']) ?? 0,
      isLiked: _readBool(json, ['is_liked', 'liked']) ?? false,
    );
  }
}

class CommentModel {
  final String id;
  final String author;
  final String content;
  final String? createdAt;

  const CommentModel({
    required this.id,
    required this.author,
    required this.content,
    this.createdAt,
  });

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: _readString(json, ['id', 'comment_id']),
      author: _readString(json, ['username', 'author', 'user_name'], fallback: 'Người dùng'),
      content: _readString(json, ['content', 'message'], fallback: ''),
      createdAt: _readOptionalString(json, ['created_at', 'createdAt']),
    );
  }
}

class MarketplaceItem {
  final String id;
  final String title;
  final String subtitle;
  final String? trailing;

  const MarketplaceItem({
    required this.id,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  factory MarketplaceItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceItem(
      id: _readString(json, ['id', 'notification_id', 'purchase_id', 'conversation_id']),
      title: _readString(json, ['title', 'name', 'username', 'status'], fallback: 'Mục dữ liệu'),
      subtitle: _readString(
        json,
        ['message', 'content', 'description', 'address', 'last_message'],
        fallback: '',
      ),
      trailing: _readOptionalString(json, ['created_at', 'time', 'state', 'total']),
    );
  }
}

class WalletBalanceModel {
  final num available;
  final num pending;

  const WalletBalanceModel({
    required this.available,
    required this.pending,
  });

  factory WalletBalanceModel.fromJson(Map<String, dynamic> json) {
    return WalletBalanceModel(
      available: _readNum(json, ['available_balance', 'available', 'balance', 'current_balance']),
      pending: _readNum(json, ['pending', 'pending_balance']),
    );
  }
}

class AddressModel {
  final String id;
  final String receiverName;
  final String phone;
  final String fullAddress;
  final bool isDefault;

  const AddressModel({
    required this.id,
    required this.receiverName,
    required this.phone,
    required this.fullAddress,
    this.isDefault = false,
  });

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    return AddressModel(
      id: _readString(json, ['id', 'address_id']),
      receiverName: _readString(json, ['receiver_name', 'name'], fallback: 'Người nhận'),
      phone: _readString(json, ['phone', 'phone_number']),
      fullAddress: _readString(
        json,
        ['full_address', 'address', 'address_detail'],
        fallback: 'Chưa có địa chỉ',
      ),
      isDefault: _readBool(json, ['is_default', 'default']) ?? false,
    );
  }

  MarketplaceItem toItem() {
    return MarketplaceItem(
      id: id,
      title: receiverName,
      subtitle: '$phone\n$fullAddress',
      trailing: isDefault ? 'Mặc định' : null,
    );
  }
}

class OrderModel {
  final String id;
  final String status;
  final num total;
  final String? createdAt;
  final String summary;

  const OrderModel({
    required this.id,
    required this.status,
    required this.total,
    this.createdAt,
    required this.summary,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final items = json['items'];
    final itemSummary = items is List && items.isNotEmpty
        ? items
            .whereType<Map>()
            .map((item) {
              final product = item['product'];
              if (product is Map && product['title'] != null) {
                return product['title'].toString();
              }
              return null;
            })
            .whereType<String>()
            .take(2)
            .join(', ')
        : '';

    return OrderModel(
      id: _readString(json, ['id', 'purchase_id', 'order_id']),
      status: _readString(json, ['state', 'status'], fallback: 'pending'),
      total: _readNum(json, ['total', 'total_price', 'amount']),
      createdAt: _readOptionalString(json, ['created_at', 'createdAt']),
      summary: itemSummary.isNotEmpty ? itemSummary : _readString(
        json,
        ['name', 'title', 'description', 'products'],
        fallback: 'Đơn hàng',
      ),
    );
  }

  MarketplaceItem toItem() {
    return MarketplaceItem(
      id: id,
      title: summary,
      subtitle: status,
      trailing: total == 0 ? createdAt : total.toString(),
    );
  }
}

class ConversationModel {
  final String id;
  final String partnerId;
  final String partnerName;
  final String lastMessage;
  final String? productId;
  final bool unread;

  const ConversationModel({
    required this.id,
    required this.partnerId,
    required this.partnerName,
    required this.lastMessage,
    this.productId,
    this.unread = false,
  });

  factory ConversationModel.fromJson(Map<String, dynamic> json) {
    return ConversationModel(
      id: _readString(json, ['conversation_id', 'id']),
      partnerId: _readString(json, ['partner_id', 'to_id', 'user_id']),
      partnerName: _readString(json, ['partner_name', 'username', 'name'], fallback: 'Người bán'),
      lastMessage: _readString(json, ['last_message', 'message', 'content']),
      productId: _readOptionalString(json, ['product_id']),
      unread: _readBool(json, ['unread', 'is_unread']) ?? false,
    );
  }

  MarketplaceItem toItem() {
    return MarketplaceItem(
      id: id,
      title: partnerName,
      subtitle: lastMessage,
      trailing: unread ? 'Mới' : null,
    );
  }
}

class MessageModel {
  final String id;
  final String senderId;
  final String content;
  final String type;
  final String? createdAt;
  final bool isLocalPending;
  final bool isFailed;

  const MessageModel({
    required this.id,
    required this.senderId,
    required this.content,
    this.type = 'text',
    this.createdAt,
    this.isLocalPending = false,
    this.isFailed = false,
  });

  MessageModel copyWith({
    String? senderId,
    bool? isLocalPending,
    bool? isFailed,
  }) {
    return MessageModel(
      id: id,
      senderId: senderId ?? this.senderId,
      content: content,
      type: type,
      createdAt: createdAt,
      isLocalPending: isLocalPending ?? this.isLocalPending,
      isFailed: isFailed ?? this.isFailed,
    );
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: _readString(json, ['id', 'message_id']),
      senderId: _readString(json, ['sender_id', 'from_id', 'user_id']),
      content: _readString(json, ['message', 'content']),
      type: _readString(json, ['type_message', 'type'], fallback: 'text'),
      createdAt: _readOptionalString(json, ['created_at', 'createdAt']),
    );
  }
}

class NotificationModel {
  final String id;
  final String title;
  final String message;
  final String? createdAt;
  final bool read;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    this.createdAt,
    this.read = false,
  });

  NotificationModel copyWith({bool? read}) {
    return NotificationModel(
      id: id,
      title: title,
      message: message,
      createdAt: createdAt,
      read: read ?? this.read,
    );
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: _readString(json, ['id', 'notification_id']),
      title: _readString(json, ['title', 'type'], fallback: 'Thông báo'),
      message: _readString(json, ['message', 'content', 'description']),
      createdAt: _readOptionalString(json, ['created_at', 'createdAt']),
      read: _readBool(json, ['read', 'is_read']) ?? false,
    );
  }

  MarketplaceItem toItem() {
    return MarketplaceItem(
      id: id,
      title: title,
      subtitle: message,
      trailing: read ? null : 'Mới',
    );
  }
}

class WalletHistoryModel {
  final String id;
  final String title;
  final num amount;
  final String? createdAt;
  final bool income;

  const WalletHistoryModel({
    required this.id,
    required this.title,
    required this.amount,
    this.createdAt,
    this.income = true,
  });

  factory WalletHistoryModel.fromJson(Map<String, dynamic> json) {
    final amount = _readNum(json, ['amount', 'value', 'balance']);
    return WalletHistoryModel(
      id: _readString(json, ['id', 'history_id']),
      title: _readString(json, ['title', 'description', 'type'], fallback: 'Biến động số dư'),
      amount: amount,
      createdAt: _readOptionalString(json, ['created_at', 'createdAt']),
      income: amount >= 0,
    );
  }

  MarketplaceItem toItem() {
    return MarketplaceItem(
      id: id,
      title: title,
      subtitle: createdAt ?? '',
      trailing: amount.toString(),
    );
  }
}

List<T> parseListFromData<T>(
  dynamic data,
  T Function(Map<String, dynamic> json) fromJson,
) {
  final rawList = _findList(data);
  return rawList
      .whereType<Map>()
      .map((item) => fromJson(Map<String, dynamic>.from(item)))
      .toList();
}

Map<String, dynamic> parseMapFromData(dynamic data) {
  final rawMap = _findMap(data);
  return rawMap == null ? <String, dynamic>{} : Map<String, dynamic>.from(rawMap);
}

List<dynamic> _findList(dynamic data) {
  if (data is List) return data;
  if (data is Map) {
    for (final key in ['items', 'data', 'products', 'categories', 'list', 'rows', 'result']) {
      final value = data[key];
      if (value is List) return value;
      if (value is Map || value is List) {
        final nested = _findList(value);
        if (nested.isNotEmpty) return nested;
      }
    }
  }
  return const [];
}

Map? _findMap(dynamic data) {
  if (data is Map) {
    final nestedData = data['data'];
    if (nestedData is Map) return nestedData;
    return data;
  }
  return null;
}

String _readString(
  Map<String, dynamic> json,
  List<String> keys, {
  String fallback = '',
}) {
  for (final key in keys) {
    final value = json[key];
    if (value != null && value.toString().isNotEmpty) return value.toString();
  }
  return fallback;
}

String? _readOptionalString(Map<String, dynamic> json, List<String> keys) {
  final value = _readString(json, keys);
  return value.isEmpty ? null : value;
}

num _readNum(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is num) return value;
    final parsed = num.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return 0;
}

int? _readInt(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is int) return value;
    final parsed = int.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

double? _readDouble(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is double) return value;
    if (value is int) return value.toDouble();
    final parsed = double.tryParse(value?.toString() ?? '');
    if (parsed != null) return parsed;
  }
  return null;
}

bool? _readBool(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is bool) return value;
    final normalized = value?.toString().toLowerCase();
    if (normalized == '1' || normalized == 'true') return true;
    if (normalized == '0' || normalized == 'false') return false;
  }
  return null;
}

List<String> _readStringList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value.map((item) => item.toString()).where((item) => item.isNotEmpty).toList();
    }
    if (value is String && value.isNotEmpty) return [value];
  }
  return const [];
}
