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

bool _isVideoUrl(String url) {
  final lower = url.toLowerCase().split('?').first;
  return lower.endsWith('.mp4') ||
      lower.endsWith('.mov') ||
      lower.endsWith('.avi') ||
      lower.endsWith('.mkv') ||
      lower.endsWith('.flv') ||
      lower.endsWith('.webm') ||
      lower.endsWith('.3gp');
}

class ProductModel {
  final String id;
  final String title;
  final num price;
  final String? priceNew;
  final String? priceDiscount;
  final String described;
  final List<String> imageUrls;
  final List<ProductImageModel> images;
  final List<ProductVideoModel> videos;
  final List<ProductSizeModel> sizes;
  final ProductBrandInfo? brand;
  final ProductSellerInfo? seller;
  final ProductCategoryInfo? category;
  final String? shipsFrom;
  final String? shipsFromId;
  final String? condition;
  final String? created;
  final String? like;
  final String? comment;
  final String? sellerName;
  final String? sellerLocation;
  final double? rating;
  final int? soldCount;
  final String? bestOffers;
  final int likeCount;
  final bool isLiked;
  final String? state;
  final String? isBlocked;
  final String? canEdit;
  final String? banned;
  final String? shareUrl;
  final String? weight;
  final List<String> dimension;
  final List<String> messages;

  const ProductModel({
    required this.id,
    required this.title,
    required this.price,
    this.priceNew,
    this.priceDiscount,
    required this.described,
    required this.imageUrls,
    this.images = const [],
    this.videos = const [],
    this.sizes = const [],
    this.brand,
    this.seller,
    this.category,
    this.shipsFrom,
    this.shipsFromId,
    this.condition,
    this.created,
    this.like,
    this.comment,
    this.sellerName,
    this.sellerLocation,
    this.rating,
    this.soldCount,
    this.bestOffers,
    this.likeCount = 0,
    this.isLiked = false,
    this.state,
    this.isBlocked,
    this.canEdit,
    this.banned,
    this.shareUrl,
    this.weight,
    this.dimension = const [],
    this.messages = const [],
  });

  ProductModel copyWith({
    int? likeCount,
    bool? isLiked,
  }) {
    return ProductModel(
      id: id,
      title: title,
      price: price,
      priceNew: priceNew,
      priceDiscount: priceDiscount,
      described: described,
      imageUrls: imageUrls,
      images: images,
      videos: videos,
      sizes: sizes,
      brand: brand,
      seller: seller,
      category: category,
      shipsFrom: shipsFrom,
      shipsFromId: shipsFromId,
      condition: condition,
      created: created,
      like: likeCount != null ? likeCount.toString() : like,
      comment: comment,
      sellerName: sellerName,
      sellerLocation: sellerLocation,
      rating: rating,
      soldCount: soldCount,
      bestOffers: bestOffers,
      likeCount: likeCount ?? this.likeCount,
      isLiked: isLiked ?? this.isLiked,
      state: state,
      isBlocked: isBlocked,
      canEdit: canEdit,
      banned: banned,
      shareUrl: shareUrl,
      weight: weight,
      dimension: dimension,
      messages: messages,
    );
  }

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final sellerJson = _readMap(json, ['seller']);
    final rawBrandId = _readOptionalString(json, ['brand_id', 'brandId']);
    final brandJson = _readMap(json, ['brand']) ?? (rawBrandId != null ? {
      'id': rawBrandId,
      'name': '',
    } : null);
    final categoryJson = _readMap(json, ['category']);

    final parsedImages = _readProductImageList(json, ['image', 'images']);
    final fallbackImageUrls = _readStringList(json, [
      'image',
      'image_urls',
      'image_url',
      'thumbnail',
    ]);

    final cleanImages = <ProductImageModel>[];
    final extraVideos = <ProductVideoModel>[];

    for (final img in parsedImages) {
      if (_isVideoUrl(img.url)) {
        extraVideos.add(ProductVideoModel(url: img.url));
      } else {
        cleanImages.add(img);
      }
    }

    final cleanImageUrls = <String>[];
    final rawImageUrls = cleanImages.isNotEmpty
        ? cleanImages.map((e) => e.url).toList()
        : fallbackImageUrls;

    for (final url in rawImageUrls) {
      if (_isVideoUrl(url)) {
        if (!extraVideos.any((v) => v.url == url)) {
          extraVideos.add(ProductVideoModel(url: url));
        }
      } else if (url.isNotEmpty) {
        cleanImageUrls.add(url);
      }
    }

    final originalVideos = _readProductVideoList(json, ['video', 'videos']);
    final parsedVideos = <ProductVideoModel>[];
    parsedVideos.addAll(originalVideos);
    for (final ev in extraVideos) {
      if (!parsedVideos.any((v) => v.url == ev.url)) {
        parsedVideos.add(ev);
      }
    }

    final parsedSizes = _readProductSizeList(json, ['size', 'sizes', 'variants']);
    final likeText = _readOptionalString(json, ['like', 'like_count', 'likes']);

    return ProductModel(
      id: _readString(json, ['id', 'product_id']),
      title: _readString(json, ['title', 'name'], fallback: 'Sản phẩm'),
      price: _readNum(json, ['price', 'price_discount']),
      priceNew: _readOptionalString(json, ['price_new']),
      priceDiscount: _readOptionalString(json, ['price_discount']),
      described: _readString(json, ['described', 'description', 'details'], fallback: ''),
      imageUrls: cleanImageUrls,
      images: cleanImages,
      videos: parsedVideos,
      sizes: parsedSizes,
      brand: brandJson == null ? null : ProductBrandInfo.fromJson(brandJson),
      seller: sellerJson == null ? null : ProductSellerInfo.fromJson(sellerJson),
      category: categoryJson == null ? null : ProductCategoryInfo.fromJson(categoryJson),
      shipsFrom: _readOptionalString(json, ['ships_from']),
      shipsFromId: _readOptionalString(json, ['ships_from_id']),
      condition: _readOptionalString(json, ['condition']),
      created: _readOptionalString(json, ['created', 'created_at']),
      like: likeText,
      comment: _readOptionalString(json, ['comment', 'comment_count']),
      sellerName: _readOptionalString(sellerJson ?? json, ['name', 'username', 'seller_name', 'seller']),
      sellerLocation: _readOptionalString(json, ['location', 'seller_location', 'city', 'ships_from']),
      rating: _readDouble(sellerJson ?? json, ['score', 'rating', 'rate', 'avg_rate']),
      soldCount: _readInt(sellerJson ?? json, ['listing', 'sold', 'sold_count', 'total_sold']),
      bestOffers: _readOptionalString(json, ['best_offers']),
      likeCount: _readInt(json, ['like_count', 'likes', 'like']) ?? int.tryParse(likeText ?? '') ?? 0,
      isLiked: _readBool(json, ['is_liked', 'liked']) ?? false,
      state: _readOptionalString(json, ['state']),
      isBlocked: _readOptionalString(json, ['is_blocked']),
      canEdit: _readOptionalString(json, ['can_edit']),
      banned: _readOptionalString(json, ['banned']),
      shareUrl: _readOptionalString(json, ['url']),
      weight: _readOptionalString(json, ['weight']),
      dimension: _readStringList(json, ['dimension']),
      messages: _readStringList(json, ['messages']),
    );
  }
}

class ProductImageModel {
  final String id;
  final String url;

  const ProductImageModel({required this.id, required this.url});

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: _readString(json, ['id']),
      url: _readString(json, ['url', 'image_url', 'image'], fallback: ''),
    );
  }
}

class ProductVideoModel {
  final String url;

  const ProductVideoModel({required this.url});

  factory ProductVideoModel.fromJson(Map<String, dynamic> json) {
    return ProductVideoModel(url: _readString(json, ['url', 'video_url'], fallback: ''));
  }
}

class ProductSizeModel {
  final String id;
  final String name;

  const ProductSizeModel({required this.id, required this.name});

  factory ProductSizeModel.fromJson(Map<String, dynamic> json) {
    return ProductSizeModel(
      id: _readString(json, ['id', 'size_id']),
      name: _readString(json, ['size_name', 'size', 'name'], fallback: ''),
    );
  }
}

class ProductBrandInfo {
  final String id;
  final String name;

  const ProductBrandInfo({required this.id, required this.name});

  factory ProductBrandInfo.fromJson(Map<String, dynamic> json) {
    return ProductBrandInfo(
      id: _readString(json, ['id', 'brand_id']),
      name: _readString(json, ['brand_name', 'name'], fallback: ''),
    );
  }
}

class ProductSellerInfo {
  final String id;
  final String name;
  final String? avatar;
  final String? score;
  final String? listing;

  const ProductSellerInfo({
    required this.id,
    required this.name,
    this.avatar,
    this.score,
    this.listing,
  });

  factory ProductSellerInfo.fromJson(Map<String, dynamic> json) {
    return ProductSellerInfo(
      id: _readString(json, ['id', 'user_id']),
      name: _readString(json, ['name', 'username'], fallback: ''),
      avatar: _readOptionalString(json, ['avatar']),
      score: _readOptionalString(json, ['score']),
      listing: _readOptionalString(json, ['listing']),
    );
  }
}

class ProductCategoryInfo {
  final String id;
  final String name;
  final String? hasBrand;
  final String? hasName;

  const ProductCategoryInfo({
    required this.id,
    required this.name,
    this.hasBrand,
    this.hasName,
  });

  factory ProductCategoryInfo.fromJson(Map<String, dynamic> json) {
    return ProductCategoryInfo(
      id: _readString(json, ['id', 'category_id']),
      name: _readString(json, ['name', 'category_name'], fallback: ''),
      hasBrand: _readOptionalString(json, ['has_brand']),
      hasName: _readOptionalString(json, ['has_name']),
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

class RateModel {
  final String id;
  final String author;
  final String content;
  final int level;
  final String? createdAt;
  final String? productId;

  const RateModel({
    required this.id,
    required this.author,
    required this.content,
    required this.level,
    this.createdAt,
    this.productId,
  });

  factory RateModel.fromJson(Map<String, dynamic> json) {
    return RateModel(
      id: _readString(json, ['id', 'rate_id']),
      author: _readString(json, ['username', 'author', 'user_name'], fallback: 'Người dùng'),
      content: _readString(json, ['content', 'message', 'review'], fallback: ''),
      level: _readInt(json, ['level', 'rate', 'rating']) ?? 0,
      createdAt: _readOptionalString(json, ['created_at', 'createdAt', 'time']),
      productId: _readOptionalString(json, ['product_id', 'productId']),
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
  final String? address;
  final String? addressDetail;
  final String? latitude;
  final String? longitude;
  final String? province;
  final String? district;

  const AddressModel({
    required this.id,
    required this.receiverName,
    required this.phone,
    required this.fullAddress,
    this.isDefault = false,
    this.address,
    this.addressDetail,
    this.latitude,
    this.longitude,
    this.province,
    this.district,
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
      address: _readOptionalString(json, ['address_name', 'address']),
      addressDetail: _readOptionalString(json, ['address_detail']),
      latitude: _readOptionalString(json, ['lat', 'latitude']),
      longitude: _readOptionalString(json, ['lng', 'longitude']),
      province: _readOptionalString(json, ['province']),
      district: _readOptionalString(json, ['district']),
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

class OrderLineItem {
  final String productId;
  final String name;
  final String? imageUrl;
  final num price;
  final int quantity;
  final num subtotal;

  const OrderLineItem({
    required this.productId,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.quantity,
    required this.subtotal,
  });

  factory OrderLineItem.fromJson(Map<String, dynamic> json) {
    final productJson = _readMap(json, ['product']);
    final unitPrice = _readNum(json, ['price', 'unit_price']);
    final quantity = _readInt(json, ['quantity']) ?? 0;
    final resolvedPrice = unitPrice == 0 ? _readNum(productJson ?? json, ['price']) : unitPrice;
    final resolvedSubtotal = _readNum(json, ['subtotal', 'total_price']);

    return OrderLineItem(
      productId: _readString(json, ['product_id', 'id', 'productId']),
      name: _readString(
        {...?productJson, ...json},
        ['name', 'title', 'product_name'],
        fallback: 'Sản phẩm',
      ),
      imageUrl: _readOptionalString(
        {...?productJson, ...json},
        ['image', 'image_url', 'thumbnail'],
      ),
      price: resolvedPrice,
      quantity: quantity,
      subtotal: resolvedSubtotal == 0 ? resolvedPrice * quantity : resolvedSubtotal,
    );
  }
}

class OrderModel {
  final String id;
  final String status;
  final num total;
  final num shipFee;
  final num finalPrice;
  final String? createdAt;
  final String? note;
  final String? sellerName;
  final String? buyerName;
  final String? buyerPhone;
  final String? buyerAddress;
  final String summary;
  final List<OrderLineItem> items;

  const OrderModel({
    required this.id,
    required this.status,
    required this.total,
    this.shipFee = 0,
    this.finalPrice = 0,
    this.createdAt,
    this.note,
    this.sellerName,
    this.buyerName,
    this.buyerPhone,
    this.buyerAddress,
    required this.summary,
    this.items = const [],
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    final parsedItems = <OrderLineItem>[];
    final rawItems = json['items'];
    if (rawItems is List) {
      for (final item in rawItems.whereType<Map>()) {
        parsedItems.add(OrderLineItem.fromJson(Map<String, dynamic>.from(item)));
      }
    }

    final sellerJson = _readMap(json, ['seller']);
    final buyerJson = _readMap(json, ['buyer']);
    final itemSummary = parsedItems.isNotEmpty
        ? parsedItems.map((item) => item.name).take(2).join(', ')
        : _readString(
            json,
            ['name', 'title', 'description', 'products'],
            fallback: 'Đơn hàng',
          );

    return OrderModel(
      id: _readString(json, ['id', 'purchase_id', 'order_id']),
      status: _readString(json, ['state', 'status'], fallback: 'pending'),
      total: _readNum(json, ['total_price', 'total', 'amount']),
      shipFee: _readNum(json, ['ship_fee', 'shipping_fee']),
      finalPrice: (() {
        final finalPrice = _readNum(json, ['final_price']);
        return finalPrice > 0
            ? finalPrice
            : _readNum(json, ['total_price', 'total', 'amount']) + _readNum(json, ['ship_fee', 'shipping_fee']);
      })(),
      createdAt: _readOptionalString(json, ['created_at', 'createdAt']),
      note: _readOptionalString(json, ['note']),
      sellerName: _readOptionalString(sellerJson ?? json, ['name', 'username', 'seller_name']),
      buyerName: _readOptionalString(buyerJson ?? json, ['name', 'username', 'buyer_name']),
      buyerPhone: _readOptionalString(buyerJson ?? json, ['phonenumber', 'phone', 'phone_number']),
      buyerAddress: _readOptionalString(buyerJson ?? json, ['address', 'full_address']),
      summary: itemSummary,
      items: parsedItems,
    );
  }

  MarketplaceItem toItem() {
    final displayTotal = finalPrice > 0 ? finalPrice : total;
    return MarketplaceItem(
      id: id,
      title: summary,
      subtitle: status,
      trailing: displayTotal == 0 ? createdAt : displayTotal.toString(),
    );
  }
}

class OrderTimelineModel {
  final String id;
  final String state;
  final String? message;
  final String? time;

  const OrderTimelineModel({
    required this.id,
    required this.state,
    this.message,
    this.time,
  });

  factory OrderTimelineModel.fromJson(Map<String, dynamic> json) {
    return OrderTimelineModel(
      id: _readString(json, ['id', 'timeline_id', 'history_id']),
      state: _readString(json, ['state', 'status', 'action'], fallback: ''),
      message: _readOptionalString(json, ['message', 'note', 'description']),
      time: _readOptionalString(json, ['created_at', 'time', 'time_stamp']),
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
  final int historyId;
  final String objectId;
  final String title;
  final String detail;
  final num balance;
  final String date;
  final String type;

  const WalletHistoryModel({
    required this.historyId,
    required this.objectId,
    required this.title,
    required this.detail,
    required this.balance,
    required this.date,
    required this.type,
  });

  factory WalletHistoryModel.fromJson(Map<String, dynamic> json) {
    final rawHistoryId = json['history_id'] ?? json['id'];
    int parsedId = 0;
    if (rawHistoryId is int) {
      parsedId = rawHistoryId;
    } else if (rawHistoryId != null) {
      parsedId = int.tryParse(rawHistoryId.toString()) ?? 0;
    }

    final balance = _readNum(json, ['balance', 'amount']);

    return WalletHistoryModel(
      historyId: parsedId,
      objectId: _readString(json, ['object_id']),
      title: _readString(json, ['title'], fallback: 'Biến động số dư'),
      detail: _readString(json, ['detail', 'description']),
      balance: balance,
      date: _readString(json, ['date', 'created_at', 'createdAt']),
      type: _readString(json, ['type'], fallback: balance >= 0 ? 'income' : 'expense'),
    );
  }

  MarketplaceItem toItem() {
    return MarketplaceItem(
      id: historyId.toString(),
      title: title,
      subtitle: date,
      trailing: balance.toString(),
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

class ProductListResult {
  final List<ProductModel> products;
  final int? lastId;

  ProductListResult({required this.products, this.lastId});
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

Map<String, dynamic>? _readMap(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is Map) return Map<String, dynamic>.from(value);
  }
  return null;
}

List<ProductImageModel> _readProductImageList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value.map((item) {
        if (item is Map) return ProductImageModel.fromJson(Map<String, dynamic>.from(item));
        return ProductImageModel(id: '', url: item?.toString() ?? '');
      }).toList();
    }
  }
  return const [];
}

List<ProductVideoModel> _readProductVideoList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value.map((item) {
        if (item is Map) return ProductVideoModel.fromJson(Map<String, dynamic>.from(item));
        return ProductVideoModel(url: item?.toString() ?? '');
      }).toList();
    }
  }
  return const [];
}

List<ProductSizeModel> _readProductSizeList(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List) {
      return value.map((item) {
        if (item is Map) return ProductSizeModel.fromJson(Map<String, dynamic>.from(item));
        return ProductSizeModel(id: '', name: item?.toString() ?? '');
      }).toList();
    }
  }
  return const [];
}

class ShipFeeModel {
  final num shipFee;
  final int leatime;

  const ShipFeeModel({required this.shipFee, required this.leatime});

  factory ShipFeeModel.fromJson(Map<String, dynamic> json) {
    return ShipFeeModel(
      shipFee: (json['ship_fee'] ?? json['shipfee'] ?? 0) as num,
      leatime: (json['leatime'] ?? 0) as int,
    );
  }
}

/// Model cho mỗi kho hàng trả về từ GET /order/get_ship_from
class ShipFromModel {
  final String id;
  final String name;
  final String? pickSupport;
  final String? messagePickSupport;

  const ShipFromModel({
    required this.id,
    required this.name,
    this.pickSupport,
    this.messagePickSupport,
  });

  factory ShipFromModel.fromJson(Map<String, dynamic> json) {
    return ShipFromModel(
      id: _readString(json, ['id']),
      name: _readString(json, ['name'], fallback: 'Kho hàng'),
      pickSupport: _readOptionalString(json, ['pick_support']),
      messagePickSupport: _readOptionalString(json, ['message_pick_support']),
    );
  }
}

/// Model cho mỗi bản ghi lịch sử quy đổi điểm thưởng (get_reward_history)
/// Input: token, index, count  →  Output: array[user_id, reward_id, received_coin, available_balance]
class RewardHistoryModel {
  final String userId;
  final String? rewardId;
  final int receivedCoin;
  final int availableBalance;

  const RewardHistoryModel({
    required this.userId,
    this.rewardId,
    required this.receivedCoin,
    required this.availableBalance,
  });

  factory RewardHistoryModel.fromJson(Map<String, dynamic> json) {
    return RewardHistoryModel(
      userId: _readString(json, ['user_id']),
      rewardId: _readOptionalString(json, ['reward_id']),
      receivedCoin: (json['received_coin'] ?? 0) as int,
      availableBalance: (json['available_balance'] ?? 0) as int,
    );
  }
}

/// Model kết quả tạo yêu cầu khiếu nại điểm thưởng (create_reward_appeal)
/// Input: token, reward_id, reason  →  Output: {appeal_id, reward_id, video_id, status}
class RewardAppealModel {
  final String? appealId;
  final String? rewardId;
  final String? videoId;
  final String? status;

  const RewardAppealModel({
    this.appealId,
    this.rewardId,
    this.videoId,
    this.status,
  });

  factory RewardAppealModel.fromJson(Map<String, dynamic> json) {
    return RewardAppealModel(
      appealId: _readOptionalString(json, ['appeal_id']),
      rewardId: _readOptionalString(json, ['reward_id']),
      videoId: _readOptionalString(json, ['video_id']),
      status: _readOptionalString(json, ['status']),
    );
  }
}

/// Model kết quả tải video quy đổi (upload_video)
class UploadVideoResponseModel {
  final String videoId;
  final String video; // url_video
  final String thumb; // url_thumb
  final int bonusCoin;

  const UploadVideoResponseModel({
    required this.videoId,
    required this.video,
    required this.thumb,
    required this.bonusCoin,
  });

  factory UploadVideoResponseModel.fromJson(Map<String, dynamic> json) {
    return UploadVideoResponseModel(
      videoId: _readString(json, ['video_id']),
      video: _readString(json, ['video']),
      thumb: _readString(json, ['thumb']),
      bonusCoin: _readInt(json, ['bonus_coin']) ?? 0,
    );
  }
}
