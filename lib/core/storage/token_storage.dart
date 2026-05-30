import '../services/session_manager.dart';

class TokenStorage {
  Future<String?> readToken() => SessionManager.getToken();

  Future<void> saveToken({
    required String token,
    String? username,
    String? phoneNumber,
  }) {
    return SessionManager.saveSession(token, username, phoneNumber);
  }

  Future<void> clear() => SessionManager.clearSession();
}
