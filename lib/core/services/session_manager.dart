import 'package:shared_preferences/shared_preferences.dart';

class SessionManager {
  static const String _keyToken = "auth_Token";
  static const String _keyUsername = "username";

  // Lưu thông tin khi đăng nhập thành công
  static Future<void> saveSession(String token, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, token);
    await prefs.setString(_keyUsername, username);
  }

  // Lấy token để gọi các API khác
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyToken);
  }

  // Xóa sạch khi đăng xuất
  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}