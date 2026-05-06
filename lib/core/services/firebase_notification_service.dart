import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
import 'dart:io';

/// Service để quản lý Firebase Cloud Messaging (FCM) cho push notification
class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static bool _tokenRefreshListenerRegistered = false;

  /// Khởi tạo Firebase (chỉ gọi 1 lần trong main())
  static Future<void> initializeFirebase() async {
    try {
      await Firebase.initializeApp();
      logger.i('Firebase initialized successfully');

      // Cấu hình background message handler
      FirebaseMessaging.onBackgroundMessage(_handleBackgroundMessage);

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
      logger.e('Error initializing Firebase: $e');
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

  /// Background message handler (khi app không hoạt động)
  static Future<void> _handleBackgroundMessage(RemoteMessage message) async {
    logger.i('Background message received: ${message.notification?.title}');
    // Xử lý notification ở đây
    // Ví dụ: cập nhật cache, trigger UI update, v.v.
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




