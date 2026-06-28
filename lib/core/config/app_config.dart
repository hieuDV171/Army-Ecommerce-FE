import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppConfig {
  static String _baseUrl = '';

  static String _normalizeUrl(String url) {
    String trimmed = url.trim();
    if (trimmed.endsWith('/')) {
      trimmed = trimmed.substring(0, trimmed.length - 1);
    }
    return trimmed;
  }

  static Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final customUrl = prefs.getString('custom_base_url');
      if (customUrl != null && customUrl.trim().isNotEmpty) {
        _baseUrl = _normalizeUrl(customUrl);
        return;
      }
    } catch (_) {}
    _baseUrl = _normalizeUrl(dotenv.env['BASE_URL'] ?? '');
  }

  static String get baseUrl => _baseUrl;

  static set baseUrl(String url) {
    _baseUrl = _normalizeUrl(url);
  }

  static bool get hasBaseUrl => _baseUrl.trim().isNotEmpty;
}
