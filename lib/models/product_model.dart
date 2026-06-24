import 'model_helpers.dart';

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

class ProductImageModel {
  final String id;
  final String url;

  const ProductImageModel({required this.id, required this.url});

  factory ProductImageModel.fromJson(Map<String, dynamic> json) {
    return ProductImageModel(
      id: readString(json, ['id']),
      url: readString(json, ['url', 'image_url', 'image'], fallback: ''),
    );
  }
}

class ProductVideoModel {
  final String url;

  const ProductVideoModel({required this.url});

  factory ProductVideoModel.fromJson(Map<String, dynamic> json) {
    return ProductVideoModel(url: readString(json, ['url', 'video_url'], fallback: ''));
  }
}

class ProductSizeModel {
  final String id;
  final String name;
  final String? color;
  final int? stock;
  final num? weight;

  const ProductSizeModel({
    required this.id,
    required this.name,
    this.color,
    this.stock,
    this.weight,
  });

  factory ProductSizeModel.fromJson(Map<String, dynamic> json) {
    return ProductSizeModel(
      id: readString(json, ['id', 'size_id', 'variant_id']),
      name: readString(json, ['size_name', 'size', 'name'], fallback: ''),
      color: readOptionalString(json, ['color']),
      stock: readInt(json, ['stock', 'quantity']),
      weight: readNum(json, ['weight']),
    );
  }
}

class ProductBrandInfo {
  final String id;
  final String name;

  const ProductBrandInfo({required this.id, required this.name});

  factory ProductBrandInfo.fromJson(Map<String, dynamic> json) {
    return ProductBrandInfo(
      id: readString(json, ['id', 'brand_id']),
      name: readString(json, ['brand_name', 'name'], fallback: ''),
    );
  }
}

class ProductSellerInfo {
  final String id;
  final String name;
  final String? avatar;
  final String? score;
  final String? listing;
  final String? coverImage;
  final String? coverImageWeb;

  const ProductSellerInfo({
    required this.id,
    required this.name,
    this.avatar,
    this.score,
    this.listing,
    this.coverImage,
    this.coverImageWeb,
  });

  factory ProductSellerInfo.fromJson(Map<String, dynamic> json) {
    return ProductSellerInfo(
      id: readString(json, ['id', 'user_id']),
      name: readString(json, ['name', 'username'], fallback: ''),
      avatar: readOptionalString(json, ['avatar']),
      score: readOptionalString(json, ['score']),
      listing: readOptionalString(json, ['listing']),
      coverImage: readOptionalString(json, ['cover_image']),
      coverImageWeb: readOptionalString(json, ['cover_image_web']),
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
      id: readString(json, ['id', 'category_id']),
      name: readString(json, ['name', 'category_name'], fallback: ''),
      hasBrand: readOptionalString(json, ['has_brand']),
      hasName: readOptionalString(json, ['has_name']),
    );
  }
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
  final int commentCount;
  final bool isLiked;
  final bool isStock;
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
    this.commentCount = 0,
    this.isLiked = false,
    this.isStock = true,
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
    int? commentCount,
    bool? isLiked,
    bool? isStock,
    String? comment,
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
      comment: comment ?? this.comment,
      sellerName: sellerName,
      sellerLocation: sellerLocation,
      rating: rating,
      soldCount: soldCount,
      bestOffers: bestOffers,
      likeCount: likeCount ?? this.likeCount,
      commentCount: commentCount ?? this.commentCount,
      isLiked: isLiked ?? this.isLiked,
      isStock: isStock ?? this.isStock,
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
    final sellerJson = readMap(json, ['seller']);
    final rawBrandId = readOptionalString(json, ['brand_id', 'brandId']);
    final brandJson = readMap(json, ['brand']) ?? (rawBrandId != null ? {
      'id': rawBrandId,
      'name': '',
    } : null);
    final categoryJson = readMap(json, ['category']);

    final parsedImages = _readProductImageList(json, ['image', 'images']);
    final fallbackImageUrls = readStringList(json, [
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
    final likeText = readOptionalString(json, ['like', 'like_count', 'likes']);

    return ProductModel(
      id: readString(json, ['id', 'product_id']),
      title: readString(json, ['title', 'name'], fallback: 'Sản phẩm'),
      price: readNum(json, ['price', 'price_discount']),
      priceNew: readOptionalString(json, ['price_new']),
      priceDiscount: readOptionalString(json, ['price_discount']),
      described: readString(json, ['described', 'description', 'details'], fallback: ''),
      imageUrls: cleanImageUrls,
      images: cleanImages,
      videos: parsedVideos,
      sizes: parsedSizes,
      brand: brandJson == null ? null : ProductBrandInfo.fromJson(brandJson),
      seller: sellerJson == null ? null : ProductSellerInfo.fromJson(sellerJson),
      category: categoryJson == null ? null : ProductCategoryInfo.fromJson(categoryJson),
      shipsFrom: readOptionalString(json, ['ships_from']),
      shipsFromId: readOptionalString(json, ['ships_from_id']),
      condition: readOptionalString(json, ['condition']),
      created: readOptionalString(json, ['created', 'created_at']),
      like: likeText,
      comment: readOptionalString(json, ['comment', 'comment_count']),
      sellerName: readOptionalString(sellerJson ?? json, ['name', 'username', 'seller_name', 'seller']),
      sellerLocation: readOptionalString(json, ['location', 'seller_location', 'city', 'ships_from']),
      rating: readDouble(sellerJson ?? json, ['score', 'rating', 'rate', 'avg_rate']),
      soldCount: readInt(sellerJson ?? json, ['listing', 'sold', 'sold_count', 'total_sold']),
      bestOffers: readOptionalString(json, ['best_offers']),
      likeCount: readInt(json, ['like_count', 'likes', 'like']) ?? int.tryParse(likeText ?? '') ?? 0,
      commentCount: readInt(json, ['comment_count', 'comments', 'comment']) ?? int.tryParse(readOptionalString(json, ['comment', 'comment_count']) ?? '') ?? 0,
      isLiked: readBool(json, ['is_liked', 'liked']) ?? false,
      isStock: readBool(json, ['is_stock', 'isStock']) ?? true,
      state: readOptionalString(json, ['state']),
      isBlocked: readOptionalString(json, ['is_blocked']),
      canEdit: readOptionalString(json, ['can_edit']),
      banned: readOptionalString(json, ['banned']),
      shareUrl: readOptionalString(json, ['url']),
      weight: readOptionalString(json, ['weight']),
      dimension: readStringList(json, ['dimension']),
      messages: readStringList(json, ['messages']),
    );
  }
}

class ProductListResult {
  final List<ProductModel> products;
  final int? lastId;

  ProductListResult({required this.products, this.lastId});
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

class CommentModel {
  final String id;
  final String authorName;
  final String authorId;
  final String content;
  final String? createdAt;
  final String? avatar;
  final String? coverImageWeb;

  const CommentModel({
    required this.id,
    required this.authorName,
    required this.authorId,
    required this.content,
    this.createdAt,
    this.avatar,
    this.coverImageWeb,
  });

  CommentModel copyWith({
    String? authorName,
    String? avatar,
    String? coverImageWeb,
  }) {
    return CommentModel(
      id: id,
      authorName: authorName ?? this.authorName,
      authorId: authorId,
      content: content,
      createdAt: createdAt,
      avatar: avatar ?? this.avatar,
      coverImageWeb: coverImageWeb ?? this.coverImageWeb,
    );
  }

  factory CommentModel.fromJson(Map<String, dynamic> json) {
    return CommentModel(
      id: readString(json, ['id', 'comment_id']),
      authorName: readString(json, ['username', 'author', 'user_name', 'name'], fallback: 'Người dùng'),
      authorId: readString(json, ['user_id', 'author_id', 'id'], fallback: ''),
      content: readString(json, ['content', 'message'], fallback: ''),
      createdAt: readOptionalString(json, ['created_at', 'createdAt']),
      avatar: readOptionalString(json, ['avatar', 'image', 'user_avatar']),
      coverImageWeb: readOptionalString(json, ['cover_image_web', 'avatar_frame']),
    );
  }
}

class RateModel {
  final String id;
  final String author;
  final String? authorId;
  final String content;
  final int level;
  final String? createdAt;
  final String? productId;
  final String? avatar;
  final String? coverImageWeb;
  final String? purchaseId;

  const RateModel({
    required this.id,
    required this.author,
    this.authorId,
    required this.content,
    required this.level,
    this.createdAt,
    this.productId,
    this.avatar,
    this.coverImageWeb,
    this.purchaseId,
  });

  factory RateModel.fromJson(Map<String, dynamic> json) {
    return RateModel(
      id: readString(json, ['id', 'rate_id']),
      author: readString(json, ['username', 'author', 'user_name'], fallback: 'Người dùng'),
      authorId: readOptionalString(json, ['reviewer_id', 'author_id', 'user_id', 'userId']),
      content: readString(json, ['content', 'message', 'review'], fallback: ''),
      level: readInt(json, ['level', 'rate', 'rating']) ?? 0,
      createdAt: readOptionalString(json, ['created_at', 'createdAt', 'time', 'created']),
      productId: readOptionalString(json, ['product_id', 'productId']),
      avatar: readOptionalString(json, ['avatar']),
      coverImageWeb: readOptionalString(json, ['cover_image_web', 'avatar_frame']),
      purchaseId: readOptionalString(json, ['purchase_id', 'purchaseId']),
    );
  }
}
