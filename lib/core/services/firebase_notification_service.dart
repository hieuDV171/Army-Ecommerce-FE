import 'package:army_ecommerce/blocs/notification/notification_bloc.dart';
import 'package:army_ecommerce/blocs/notification/notification_event.dart';
import 'package:army_ecommerce/core/constants/response_code.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:army_ecommerce/firebase_options.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:army_ecommerce/core/services/session_manager.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/blocs/chat/chat_bloc.dart';
import 'package:army_ecommerce/ui/chat/chat_screen.dart';
import 'package:army_ecommerce/blocs/chat/chat_event.dart';
import 'package:army_ecommerce/ui/chat/conversation_list_screen.dart';
import 'package:army_ecommerce/core/navigation/navigator_service.dart';
import 'package:army_ecommerce/ui/marketplace/product/product_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (_) {
    // ignore - already initialized or initialization not necessary
  }

  logger.i('Background message received: ${message.notification?.title}');
}

class FirebaseNotificationService {
  static final FirebaseMessaging _firebaseMessaging =
      FirebaseMessaging.instance;
  static bool _tokenRefreshListenerRegistered = false;

  static final List<VoidCallback> _onMessageReceivedListeners = [];

  static void addMessageReceivedListener(VoidCallback listener) {
    _onMessageReceivedListeners.add(listener);
  }

  static void removeMessageReceivedListener(VoidCallback listener) {
    _onMessageReceivedListeners.remove(listener);
  }

  static void refreshBadges() {
    for (final listener in _onMessageReceivedListeners) {
      try {
        listener();
      } catch (e) {
        logger.e('Error refreshing badges: $e');
      }
    }
  }

  /// Prepare FCM usage (do NOT call Firebase.initializeApp() here). Firebase
  /// should be initialized once in `main()` using `DefaultFirebaseOptions`.
  /// This method will request iOS permissions when needed.
  static Future<void> initializeFirebase() async {
    try {
      logger.i(
        'Preparing Firebase messaging (assumes Firebase already initialized)',
      );

      // Xin quyền notification trên cả iOS và Android (đặc biệt Android 13+ yêu cầu xin quyền động)
      NotificationSettings settings = await _firebaseMessaging
          .requestPermission(
            alert: true,
            announcement: false,
            badge: true,
            criticalAlert: false,
            provisional: false,
            sound: true,
          );
      logger.i(
        'Notification permission status: ${settings.authorizationStatus}',
      );
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

      // Bỏ qua kiểm tra trùng token để luôn cập nhật mối liên kết mới nhất lên Server
      // final lastSentToken = await SessionManager.getLastDevToken();
      // if (lastSentToken == token) {
      //   logger.i('Device token unchanged, skipping registration');
      //   return;
      // }

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
      refreshBadges();

      // final data = message.data;
      // final type = data['type']?.toString();
      // final objectId = data['object_id']?.toString();
      // if (_isProductEngagementNotification(type) && objectId != null) {
      //   _showInAppBanner(message);
      // }
    });
  }

  /// Lắng nghe user tap vào notification
  static void setupNotificationTapHandler() {
    FirebaseMessaging.instance.getInitialMessage().then((
      RemoteMessage? message,
    ) {
      if (message != null) {
        logger.i('App opened from notification (cold start): ${message.data}');

        // Kiểm tra xem AuthSuccess đã được emit hay chưa
        BuildContext? context = NavigatorService.navigatorKey.currentContext;
        bool isAuthSuccess = false;
        if (context != null && context.mounted) {
          try {
            final authBloc = context.read<AuthBloc>();
            if (authBloc.state is AuthSuccess) {
              isAuthSuccess = true;
            }
          } catch (_) {}
        }

        if (isAuthSuccess) {
          logger.i('AuthSuccess already active. Redirecting immediately.');
          _handleNotificationTap(message);
        } else {
          logger.i('AuthSuccess not active yet. Queuing notification.');
          _pendingNotification = message;
        }
      }
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      logger.i('Notification tapped (hot start): ${message.data}');
      _handleNotificationTap(message);
    });
  }

  static RemoteMessage? _pendingNotification;

  static bool _isProductEngagementNotification(String? type) {
    return type == 'like_product' || type == 'comment_product';
  }

  static Future<BuildContext?> _waitForContext() async {
    BuildContext? context;

    for (int i = 0; i < 10; i++) {
      context = NavigatorService.navigatorKey.currentContext;
      if (context != null &&
          NavigatorService.navigatorKey.currentState != null &&
          context.mounted) {
        return context;
      }
      await Future.delayed(const Duration(milliseconds: 200));
    }

    return null;
  }

  static Future<void> _navigateToProductDetail(
    String productId, {
    bool scrollToComments = false,
  }) async {
    try {
      if (ProductDetailPage.activeProductId == productId) {
        logger.i(
          'User is already viewing this product ($productId). Ignoring notification redirect.',
        );
        return;
      }

      final context = await _waitForContext();
      if (context == null ||
          !context.mounted ||
          NavigatorService.navigatorKey.currentState == null) {
        logger.w('Navigator context not ready, cannot open product detail');
        return;
      }

      final token = await SessionManager.getToken();
      if (token == null || token.isEmpty) {
        logger.w('User not logged in locally, ignoring product notification');
        return;
      }

      NavigatorService.navigatorKey.currentState?.popUntil(
        (route) => route.isFirst,
      );

      NavigatorService.navigatorKey.currentState?.push(
        MaterialPageRoute(
          builder: (_) => ProductDetailPage(
            productId: productId,
            scrollToComments: scrollToComments,
          ),
        ),
      );
    } catch (e) {
      logger.e('Error navigating to product detail: $e');
    }
  }

  // static Future<void> _showInAppBanner(RemoteMessage message) async {
  //   final data = message.data;
  //   final type = data['type']?.toString();
  //   final objectId = data['object_id']?.toString();
  //   if (!_isProductEngagementNotification(type) || objectId == null) {
  //     return;
  //   }
  //
  //   final context = await _waitForContext();
  //   if (context == null || !context.mounted) {
  //     logger.w('Navigator context not ready, cannot show in-app banner');
  //     return;
  //   }
  //
  //   final title = message.notification?.title;
  //   final body = message.notification?.body;
  //   final content = [
  //     if (title != null && title.isNotEmpty) title,
  //     if (body != null && body.isNotEmpty) body,
  //   ].join('\n');
  //
  //   final fallbackText = type == 'comment_product'
  //       ? 'Sản phẩm của bạn có bình luận mới'
  //       : 'Sản phẩm của bạn có lượt thích mới';
  //
  //   final messenger = ScaffoldMessenger.of(context);
  //   messenger.removeCurrentSnackBar();
  //   messenger.showSnackBar(
  //     SnackBar(
  //       content: Text(content.isNotEmpty ? content : fallbackText),
  //       duration: const Duration(seconds: 5),
  //       action: SnackBarAction(
  //         label: 'Xem ngay',
  //         onPressed: () {
  //           _navigateToProductDetail(
  //             objectId,
  //             scrollToComments: type == 'comment_product',
  //           );
  //         },
  //       ),
  //     ),
  //   );
  // }

  static void checkPendingNotification() {
    if (_pendingNotification != null) {
      final message = _pendingNotification!;
      _pendingNotification = null;
      logger.i('Processing pending notification: ${message.data}');
      _handleNotificationTap(message);
    }
  }

  static void _handleNotificationTap(RemoteMessage message) async {
    PageRouteBuilder? dialogRoute;
    try {
      final data = message.data;
      final type = data['type']?.toString();
      final conversationId = data['conversation_id']?.toString();
      final objectId = data['object_id']?.toString();
      final notificationId = data['notification_id']?.toString();

      if (notificationId != null && notificationId.isNotEmpty) {
        logger.i(
          'Found notification_id: $notificationId. Calling set_read_notification API...',
        );

        final context = await _waitForContext();
        if (context != null && context.mounted) {
          context.read<NotificationBloc>().add(
            MarkNotificationReadRequested(notificationId: notificationId),
          );
        }
      }

      if (type == 'new_message' && conversationId != null) {
        // Kiểm tra xem ứng dụng đang ở sẵn màn hình hội thoại này không
        if (ChatScreen.activeConversationId == conversationId) {
          logger.i(
            'User is already viewing this conversation ($conversationId). Ignoring notification redirect.',
          );
          return;
        }

        final context = await _waitForContext();

        // Chờ tối đa 2 giây cho Navigator và context sẵn sàng
        if (context == null ||
            !context.mounted ||
            NavigatorService.navigatorKey.currentState == null) {
          logger.w('Navigator context not ready, queuing notification');
          _pendingNotification = message;
          return;
        }

        // Lấy token và userId từ SessionManager để xác minh đăng nhập
        final token = await SessionManager.getToken();
        final currentUserId = await SessionManager.getUserId();

        if (token == null ||
            token.isEmpty ||
            currentUserId == null ||
            currentUserId.isEmpty) {
          logger.w('User not logged in locally, ignoring notification tap');
          return;
        }

        // Hiện loading dialog bằng PageRouteBuilder để tránh lỗi context lookup trên root navigator
        dialogRoute = PageRouteBuilder(
          opaque: false,
          barrierDismissible: false,
          pageBuilder: (context, animation, secondaryAnimation) {
            return Container(
              color: Colors.black54,
              child: const Center(child: CircularProgressIndicator()),
            );
          },
        );
        NavigatorService.navigatorKey.currentState?.push(dialogRoute);

        if (!context.mounted) return;
        final marketplaceRepo = context.read<MarketplaceRepository>();
        final response = await marketplaceRepo.getConversations(
          index: 0,
          count: 50,
        );

        // Đóng loading dialog an toàn bằng removeRoute
        if (dialogRoute.isActive) {
          NavigatorService.navigatorKey.currentState?.removeRoute(dialogRoute);
          dialogRoute = null;
        }

        final conversations = response.data ?? [];
        final targetConv = conversations.firstWhere(
          (c) => c.id.toString() == conversationId,
          orElse: () => throw Exception(
            'Không tìm thấy cuộc trò chuyện trong danh sách: $conversationId',
          ),
        );

        // Đảm bảo ngăn xếp bắt đầu từ Home (root), sau đó đến danh sách cuộc hội thoại, và cuối cùng là phòng chat
        NavigatorService.navigatorKey.currentState?.popUntil(
          (route) => route.isFirst,
        );

        final listChatBloc = ChatBloc(marketplaceRepository: marketplaceRepo);

        NavigatorService.navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => BlocProvider(
              create: (_) => listChatBloc,
              child: ConversationListScreen(currentUserId: currentUserId),
            ),
          ),
        );

        NavigatorService.navigatorKey.currentState
            ?.push(
              MaterialPageRoute(
                builder: (_) => BlocProvider(
                  create: (context) =>
                      ChatBloc(marketplaceRepository: marketplaceRepo),
                  child: ChatScreen(
                    partnerId: targetConv.partner.id.toString(),
                    partnerUsername: targetConv.partner.username,
                    partnerAvatar: targetConv.partner.avatar,
                    currentUserId: currentUserId,
                    conversationId: conversationId,
                  ),
                ),
              ),
            )
            .then((_) {
              // Làm mới danh sách cuộc hội thoại ở chế độ ẩn khi quay lại
              listChatBloc.add(LoadConversationsRequested(isSilent: true));
            });
      } else if (_isProductEngagementNotification(type) && objectId != null) {
        await _navigateToProductDetail(
          objectId,
          scrollToComments: type == 'comment_product',
        );
      }
    } catch (e) {
      logger.e('Error handling notification tap: $e');
      if (dialogRoute != null && dialogRoute.isActive) {
        try {
          NavigatorService.navigatorKey.currentState?.removeRoute(dialogRoute);
        } catch (_) {}
      }
    }
  }
}
