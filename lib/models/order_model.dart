import 'package:intl/intl.dart';
import 'model_helpers.dart';

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
    final productJson = readMap(json, ['product']);
    final unitPrice = readNum(json, ['price', 'unit_price']);
    final quantity = readInt(json, ['quantity']) ?? 0;
    final resolvedPrice = unitPrice == 0 ? readNum(productJson ?? json, ['price']) : unitPrice;
    final resolvedSubtotal = readNum(json, ['subtotal', 'total_price']);

    return OrderLineItem(
      productId: readString(json, ['product_id', 'id', 'productId']),
      name: readString(
        {...?productJson, ...json},
        ['name', 'title', 'product_name'],
        fallback: 'Sản phẩm',
      ),
      imageUrl: readOptionalString(
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
  final String? buyerId;
  final String? sellerId;
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
    this.buyerId,
    this.sellerId,
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

    final sellerJson = readMap(json, ['seller']);
    final buyerJson = readMap(json, ['buyer']);
    final itemSummary = parsedItems.isNotEmpty
        ? parsedItems.map((item) => item.name).take(2).join(', ')
        : readString(
            json,
            ['name', 'title', 'description', 'products'],
            fallback: 'Đơn hàng',
          );

    return OrderModel(
      id: readString(json, ['id', 'purchase_id', 'order_id']),
      status: readString(json, ['state', 'status'], fallback: 'pending'),
      total: readNum(json, ['total_price', 'total', 'amount']),
      shipFee: readNum(json, ['ship_fee', 'shipping_fee']),
      finalPrice: (() {
        final finalPrice = readNum(json, ['final_price']);
        return finalPrice > 0
            ? finalPrice
            : readNum(json, ['total_price', 'total', 'amount']) + readNum(json, ['ship_fee', 'shipping_fee']);
      })(),
      createdAt: readOptionalString(json, ['created_at', 'createdAt']),
      note: readOptionalString(json, ['note']),
      sellerName: readOptionalString(sellerJson ?? json, ['name', 'username', 'seller_name']),
      buyerName: readOptionalString(buyerJson ?? json, ['name', 'username', 'buyer_name']),
      buyerPhone: readOptionalString(buyerJson ?? json, ['phonenumber', 'phone', 'phone_number']),
      buyerAddress: readOptionalString(buyerJson ?? json, ['address', 'full_address']),
      buyerId: buyerJson != null
          ? readOptionalString(buyerJson, ['id', 'buyer_id', 'user_id', 'buyerId'])
          : readOptionalString(json, ['buyer_id', 'buyerId', 'user_id']),
      sellerId: sellerJson != null
          ? readOptionalString(sellerJson, ['id', 'seller_id', 'user_id', 'sellerId'])
          : readOptionalString(json, ['seller_id', 'sellerId', 'user_id']),
      summary: itemSummary,
      items: parsedItems,
    );
  }

  MarketplaceItem toItem() {
    final displayTotal = finalPrice > 0 ? finalPrice : total;
    final formattedPrice = displayTotal > 0
        ? '${NumberFormat.decimalPattern('vi_VN').format(displayTotal)} xu'
        : displayTotal.toString();
    return MarketplaceItem(
      id: id,
      title: summary,
      subtitle: status,
      trailing: displayTotal == 0 ? createdAt : formattedPrice,
    );
  }

  OrderModel copyWith({
    String? id,
    String? status,
    num? total,
    num? shipFee,
    num? finalPrice,
    String? createdAt,
    String? note,
    String? sellerName,
    String? buyerName,
    String? buyerPhone,
    String? buyerAddress,
    String? buyerId,
    String? sellerId,
    String? summary,
    List<OrderLineItem>? items,
  }) {
    return OrderModel(
      id: id ?? this.id,
      status: status ?? this.status,
      total: total ?? this.total,
      shipFee: shipFee ?? this.shipFee,
      finalPrice: finalPrice ?? this.finalPrice,
      createdAt: createdAt ?? this.createdAt,
      note: note ?? this.note,
      sellerName: sellerName ?? this.sellerName,
      buyerName: buyerName ?? this.buyerName,
      buyerPhone: buyerPhone ?? this.buyerPhone,
      buyerAddress: buyerAddress ?? this.buyerAddress,
      buyerId: buyerId ?? this.buyerId,
      sellerId: sellerId ?? this.sellerId,
      summary: summary ?? this.summary,
      items: items ?? this.items,
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
      id: readString(json, ['id', 'timeline_id', 'history_id']),
      state: readString(json, ['state', 'status', 'action'], fallback: ''),
      message: readOptionalString(json, ['message', 'note', 'description']),
      time: readOptionalString(json, ['created_at', 'time', 'time_stamp']),
    );
  }
}
