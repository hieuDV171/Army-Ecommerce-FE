import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

class SessionManager {
  static String _avatarCacheBustKey = DateTime.now().millisecondsSinceEpoch.toString();

  static String get avatarCacheBustKey => _avatarCacheBustKey;

  static void updateAvatarCacheBustKey() {
    _avatarCacheBustKey = DateTime.now().millisecondsSinceEpoch.toString();
  }

  static String bustAvatarUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('file://') || !url.startsWith('http')) {
      return url;
    }
    if (url.contains('?')) {
      return '$url&v=$_avatarCacheBustKey';
    }
    return '$url?v=$_avatarCacheBustKey';
  }

  static ImageProvider getImageProvider(String url) {
    if (url.startsWith('file://') || !url.startsWith('http')) {
      try {
        final cleanPath = url.startsWith('file://') ? Uri.parse(url).path : url;
        return FileImage(File(cleanPath));
      } catch (e) {
        logger.e('SessionManager: Error parsing local file URI: $e');
        return FileImage(File(url));
      }
    }
    return NetworkImage(bustAvatarUrl(url));
  }

  static const String _keyToken = "auth_token";
  static const String _keyUsername = "username";
  static const String _keyPhoneNumber = "phone_number";
  static const String _keyAvatar = "avatar";
  static const String _keyLastDevToken = "last_dev_token";
  static const String _keyCoverImage = "cover_image";
  static const String _keyCoverImageWeb = "cover_image_web";
  static const String _keyUserId = "user_id";

  // Lưu thông tin khi đăng nhập thành công
  // token is required; username and phoneNumber are optional and will only be stored when not null
  static Future<void> saveSession(String token, String? username, String? phoneNumber, {String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (username != null) await prefs.setString(_keyUsername, username);
    if (phoneNumber != null) await prefs.setString(_keyPhoneNumber, phoneNumber);
    if (userId != null) await prefs.setString(_keyUserId, userId);
    logger.i('SessionManager: saved token, username="${username ?? ''}", phone="${phoneNumber ?? ''}", userId="${userId ?? ''}"');
  }

  static Future<void> setUsername(String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUsername, username);
    logger.d('SessionManager: setUsername -> "$username"');
  }

  static Future<void> setPhoneNumber(String phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPhoneNumber, phoneNumber);
    logger.d('SessionManager: setPhoneNumber -> "$phoneNumber"');
  }

  // Lấy token để gọi các API khác
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(_keyToken);
    logger.d('SessionManager: getToken -> ${token != null ? "[REDACTED]" : "null"}');
    return token;
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    final username = prefs.getString(_keyUsername);
    logger.d('SessionManager: getUsername -> "$username"');
    return username;
  }

  static Future<String?> getPhoneNumber() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString(_keyPhoneNumber);
    logger.d('SessionManager: getPhoneNumber -> "$phone"');
    return phone;
  }

  static Future<void> setAvatar(String avatar) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAvatar, avatar);
    updateAvatarCacheBustKey();
    logger.d('SessionManager: setAvatar -> [SAVED] and updated cache bust key');
  }

  static Future<String?> getAvatar() async {
    final prefs = await SharedPreferences.getInstance();
    final avatar = prefs.getString(_keyAvatar);
    logger.d('SessionManager: getAvatar -> ${avatar != null ? "[RETRIEVED]" : "null"}');
    return avatar;
  }

  static Future<void> setLastDevToken(String devToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyLastDevToken, devToken);
    logger.d('SessionManager: setLastDevToken -> [SAVED]');
  }

  static Future<String?> getLastDevToken() async {
    final prefs = await SharedPreferences.getInstance();
    final devToken = prefs.getString(_keyLastDevToken);
    logger.d('SessionManager: getLastDevToken -> ${devToken != null ? "[RETRIEVED]" : "null"}');
    return devToken;
  }

  static Future<void> setCoverImage(String coverImage) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCoverImage, coverImage);
    updateAvatarCacheBustKey();
    logger.d('SessionManager: setCoverImage -> [SAVED] and updated cache bust key');
  }

  static Future<String?> getCoverImage() async {
    final prefs = await SharedPreferences.getInstance();
    final coverImage = prefs.getString(_keyCoverImage);
    logger.d('SessionManager: getCoverImage -> ${coverImage != null ? "[RETRIEVED]" : "null"}');
    return coverImage;
  }

  static Future<void> setCoverImageWeb(String coverImageWeb) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCoverImageWeb, coverImageWeb);
    updateAvatarCacheBustKey();
    logger.d('SessionManager: setCoverImageWeb -> [SAVED] and updated cache bust key');
  }

  static Future<String?> getCoverImageWeb() async {
    final prefs = await SharedPreferences.getInstance();
    final coverImageWeb = prefs.getString(_keyCoverImageWeb);
    logger.d('SessionManager: getCoverImageWeb -> ${coverImageWeb != null ? "[RETRIEVED]" : "null"}');
    return coverImageWeb;
  }

  static const String _keyCachedProducts = "cached_products_json";
  static const String _keyCachedCategories = "cached_categories_json";

  static Future<void> saveCachedProductsJson(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedProducts, jsonString);
  }

  static Future<String?> getCachedProductsJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedProducts);
  }

  static Future<void> saveCachedCategoriesJson(String jsonString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedCategories, jsonString);
  }

  static Future<String?> getCachedCategoriesJson() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyCachedCategories);
  }

  static Future<void> setOrderEdited(String orderId, bool edited) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('order_edited_$orderId', edited);
    logger.d('SessionManager: setOrderEdited -> $orderId : $edited');
  }

  static Future<bool> isOrderEdited(String orderId) async {
    final prefs = await SharedPreferences.getInstance();
    final edited = prefs.getBool('order_edited_$orderId') ?? false;
    logger.d('SessionManager: isOrderEdited -> $orderId : $edited');
    return edited;
  }

  static Future<void> setUserId(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserId, userId);
    logger.d('SessionManager: setUserId -> "$userId"');
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString(_keyUserId);
    logger.d('SessionManager: getUserId -> "$userId"');
    return userId;
  }

  // Xóa sạch khi đăng xuất
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    logger.i('SessionManager: cleared session');
  }
}