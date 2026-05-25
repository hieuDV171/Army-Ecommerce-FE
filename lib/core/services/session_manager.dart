import 'package:shared_preferences/shared_preferences.dart';

import '../utils/logger.dart';

class SessionManager {
  static const String _keyToken = "auth_token";
  static const String _keyUsername = "username";
  static const String _keyPhoneNumber = "phone_number";
  static const String _keyAvatar = "avatar";
  static const String _keyLastDevToken = "last_dev_token";

  // Lưu thông tin khi đăng nhập thành công
  // token is required; username and phoneNumber are optional and will only be stored when not null
  static Future<void> saveSession(String token, String? username, String? phoneNumber) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    if (username != null) await prefs.setString(_keyUsername, username);
    if (phoneNumber != null) await prefs.setString(_keyPhoneNumber, phoneNumber);
    logger.i('SessionManager: saved token and username="${username ?? ''}" phone="${phoneNumber ?? ''}"');
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
    logger.d('SessionManager: setAvatar -> [SAVED]');
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

  // Xóa sạch khi đăng xuất
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    logger.i('SessionManager: cleared session');
  }
}