import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CartItem {
  final String productId;
  final String title;
  final num price;
  final String? imageUrl;
  int quantity;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'title': title,
    'price': price,
    'image_url': imageUrl,
    'quantity': quantity,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: json['product_id'] as String,
    title: json['title'] as String,
    price: json['price'] as num,
    imageUrl: json['image_url'] as String?,
    quantity: json['quantity'] as int,
  );
}

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  List<CartItem> _items = [];
  List<CartItem> get items => _items;

  int get totalCount => _items.fold(0, (sum, item) => sum + item.quantity);

  Future<void> loadCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = prefs.getString('local_cart');
      if (cartJson != null) {
        final List<dynamic> decoded = jsonDecode(cartJson);
        _items = decoded.map((e) => CartItem.fromJson(e)).toList();
      } else {
        _items = [];
      }
      notifyListeners();
    } catch (_) {
      _items = [];
      notifyListeners();
    }
  }

  Future<void> saveCart() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cartJson = jsonEncode(_items.map((e) => e.toJson()).toList());
      await prefs.setString('local_cart', cartJson);
    } catch (_) {}
  }

  Future<void> addToCart(String productId, String title, num price, String? imageUrl, {int quantity = 1}) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(
        productId: productId,
        title: title,
        price: price,
        imageUrl: imageUrl,
        quantity: quantity,
      ));
    }
    notifyListeners();
    await saveCart();
  }

  Future<void> updateQuantity(String productId, int quantity) async {
    final index = _items.indexWhere((item) => item.productId == productId);
    if (index >= 0) {
      if (quantity <= 0) {
        _items.removeAt(index);
      } else {
        _items[index].quantity = quantity;
      }
      notifyListeners();
      await saveCart();
    }
  }

  Future<void> clearCart() async {
    _items.clear();
    notifyListeners();
    await saveCart();
  }
}
