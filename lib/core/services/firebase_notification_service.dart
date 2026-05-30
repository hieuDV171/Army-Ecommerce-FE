import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:army_ecommerce/firebase_options.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
import 'dart:io';

/// Service để quản lý Firebase Cloud Messaging (FCM) cho push notification
// Background handler must be a top-level function and reachable from the
// background isolate. It should also call Firebase.initializeApp() because
// background isolates may need to initialize Firebase separately.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Try to initialize Firebase in the background isolate. If it's already
    // initialized this will throw/return and we ignore the error.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (_) {
    // ignore - already initialized or initialization not necessary
  }

  logger.i('Background message received: ${message.notification?.title}');
  // TODO: handle background message (update local DB, show notification, ...)
}


class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static bool _tokenRefreshListenerRegistered = false;

  /// Prepare FCM usage (do NOT call Firebase.initializeApp() here). Firebase
  /// should be initialized once in `main()` using `DefaultFirebaseOptions`.
  /// This method will request iOS permissions when needed.
  static Future<void> initializeFirebase() async {
    try {
      logger.i('Preparing Firebase messaging (assumes Firebase already initialized)');

      // Xin quyền notification trên iOS
      if (Platform.isIOS) {
        await _firebaseMessaging.requestPermission(
          alert: true,
          announcement: false,
          badge: true,
          criticalAlert: false,
          provisional: false,
          sound: true,
        );
      }
    } catch (e) {
      logger.e('Error preparing Firebase messaging: $e');
    }
  }

  /// Lấy FCM token có của thiết bị hiện tại
  /// devtype: '0' = iOS, '1' = Android
  static Future<String?> getFCMToken() async {
    try {
      final token = await _firebaseMessaging.getToken();
      logger.d('FCM Token: $token');
      return token;
    } catch (e) {
      logger.e('Error getting FCM token: $e');
      return null;
    }
  }

  /// Đăng ký lắng nghe token refresh và tự động send lên backend
  static void listenTokenRefresh({required AuthRepository authRepository}) {
    if (_tokenRefreshListenerRegistered) {
      logger.d('FCM token refresh listener already registered; skipping');
      return;
    }

    _tokenRefreshListenerRegistered = true;
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      logger.i('FCM Token refreshed: $newToken');
      // Gửi token mới lên backend
      _registerDeviceToken(authRepository: authRepository, devToken: newToken);
    });
  }

  /// Đăng ký device token với backend
  /// Gọi sau khi user login hoặc app start nếu có session
  static Future<void> registerDeviceToken({
    required AuthRepository authRepository,
  }) async {
    try {
      final token = await getFCMToken();
      if (token == null || token.isEmpty) {
        logger.w('FCM token is empty, cannot register');
        return;
      }

      final lastSentToken = await SessionManager.getLastDevToken();
      if (lastSentToken == token) {
        logger.i('Device token unchanged, skipping registration');
        return;
      }

      await _registerDeviceToken(
        authRepository: authRepository,
        devToken: token,
      );
    } catch (e) {
      logger.e('Error registering device token: $e');
    }
  }

  /// Helper method để gửi token lên backend
  static Future<void> _registerDeviceToken({
    required AuthRepository authRepository,
    required String devToken,
  }) async {
    try {
      // Xác định platform: '0' = iOS, '1' = Android
      final devType = Platform.isAndroid ? '1' : '0';

      final response = await authRepository.setDevToken(
        devToken: devToken,
        devType: devType,
      );

      final responseCode = ResponseCode.fromCode(response.code);

      if (responseCode == ResponseCode.ok) {
        await SessionManager.setLastDevToken(devToken);
        logger.i('Device token registered successfully');
      } else {
        logger.w('Failed to register device token: ${response.message}');
      }
    } catch (e) {
      logger.e('Error in _registerDeviceToken: $e');
    }
  }

  /// Lắng nghe foreground message (khi app đang chạy)
  static void setupForegroundMessageHandler() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      logger.i('Foreground message received: ${message.notification?.title}');
      // Hiển thị local notification hoặc cập nhật UI
    });
  }

  /// Lắng nghe user tap vào notification
  static void setupNotificationTapHandler() {
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? message) {
      if (message != null) {
        logger.i('App opened from notification: ${message.data}');
        // Chuyển hướng tới màn hình liên quan
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i('Notification tapped: ${message.data}');
      // Chuyển hướng tới màn hình liên quan
    });
  }
}

