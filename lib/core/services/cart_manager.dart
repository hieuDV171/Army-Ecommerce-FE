import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';

class CartItem {
  final String productId;
  final String title;
  final num price;
  final String? imageUrl;
  int quantity;
  final String? sellerId;

  CartItem({
    required this.productId,
    required this.title,
    required this.price,
    this.imageUrl,
    this.quantity = 1,
    this.sellerId,
  });

  Map<String, dynamic> toJson() => {
    'product_id': productId,
    'title': title,
    'price': price,
    'image_url': imageUrl,
    'quantity': quantity,
    'seller_id': sellerId,
  };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
    productId: (json['product_id'] ?? json['productId'] ?? '').toString(),
    title: (json['title'] ?? 'Sản phẩm').toString(),
    price: (json['price'] ?? 0) as num,
    imageUrl: json['image_url'] as String?,
    quantity: (json['quantity'] ?? 1) as int,
    sellerId: json['seller_id'] as String?,
  );
}

class CartManager extends ChangeNotifier {
  static final CartManager _instance = CartManager._internal();
  factory CartManager() => _instance;
  CartManager._internal();

  MarketplaceRepository? _repository;
  List<CartItem> _items = [];
  List<CartItem> get items => _items;

  int get totalCount => _items.fold(0, (sum, item) => sum + item.quantity);

  void setRepository(MarketplaceRepository repository) {
    _repository = repository;
    syncCart();
  }

  Future<bool> _isAuthenticated() async {
    final token = await SessionManager.getToken();
    return token != null && token.isNotEmpty;
  }

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

      // If already logged in, fetch server cart to keep in sync
      if (await _isAuthenticated()) {
        await _fetchServerCart();
      }
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

  Future<void> syncCart() async {
    if (_repository == null) return;
    if (!await _isAuthenticated()) return;

    try {
      // 1. Fetch server cart first
      final serverItems = await _repository!.getCart();

      // 2. If we have local guest items, sync/merge them to the server
      if (_items.isNotEmpty) {
        for (final localItem in _items) {
          final exists = serverItems.any((si) => si.productId == localItem.productId);
          if (exists) {
            // Edit quantity on server (add local quantity to server quantity)
            final serverItem = serverItems.firstWhere((si) => si.productId == localItem.productId);
            await _repository!.editCartItem(
              localItem.productId,
              serverItem.quantity + localItem.quantity,
            );
          } else {
            // Add new item to server
            await _repository!.addCartItem(localItem.productId, localItem.quantity);
          }
        }
      }

      // 3. Fetch consolidated final cart from server
      await _fetchServerCart();
    } catch (_) {
      // Fallback to local on error
    }
  }

  Future<void> _fetchServerCart() async {
    if (_repository == null) return;
    try {
      final serverItems = await _repository!.getCart();
      _items = serverItems;
      notifyListeners();
      await saveCart();
    } catch (_) {}
  }

  Future<void> addToCart(String productId, String title, num price, String? imageUrl, {int quantity = 1, String? sellerId}) async {
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
        sellerId: sellerId,
      ));
    }
    notifyListeners();
    await saveCart();

    // Sync to server if logged in
    if (await _isAuthenticated() && _repository != null) {
      try {
        await _repository!.addCartItem(productId, quantity);
      } catch (_) {}
    }
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

      // Sync to server if logged in
      if (await _isAuthenticated() && _repository != null) {
        try {
          if (quantity <= 0) {
            await _repository!.deleteCartItem(productId);
          } else {
            await _repository!.editCartItem(productId, quantity);
          }
        } catch (_) {}
      }
    }
  }

  Future<void> clearCart() async {
    final oldItems = List<CartItem>.from(_items);
    _items.clear();
    notifyListeners();
    await saveCart();

    // Sync to server if logged in
    if (await _isAuthenticated() && _repository != null) {
      try {
        for (final item in oldItems) {
          await _repository!.deleteCartItem(item.productId);
        }
      } catch (_) {}
    }
  }

  Future<void> clearCartLocalOnly() async {
    _items.clear();
    notifyListeners();
    await saveCart();
  }
}
