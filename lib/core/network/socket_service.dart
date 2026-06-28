import 'dart:async';
import 'package:army_ecommerce/core/config/app_config.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'package:socket_io_client/socket_io_client.dart' as socket_io;

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  socket_io.Socket? _socket;

  // StreamControllers to publish socket events to listeners
  final _messageController = StreamController<Map<String, dynamic>>.broadcast();
  final _notificationController =
      StreamController<Map<String, dynamic>>.broadcast();

  // Streams exposed to consumers
  Stream<Map<String, dynamic>> get newMessagesStream =>
      _messageController.stream;
  Stream<Map<String, dynamic>> get newNotificationsStream =>
      _notificationController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void connect(String token) {
    if (_socket != null && _socket!.connected) {
      logger.d('SocketService: Already connected');
      return;
    }

    // Clean up any old connection before starting a new one
    disconnect();

    // Construct the Socket.IO URL from BASE_URL (pointing to domain/root)
    String socketUrl = AppConfig.baseUrl;
    if (socketUrl.endsWith('/api/')) {
      socketUrl = socketUrl.substring(0, socketUrl.length - 5);
    } else if (socketUrl.endsWith('/api')) {
      socketUrl = socketUrl.substring(0, socketUrl.length - 4);
    }

    logger.i('SocketService: Connecting to $socketUrl...');

    try {
      _socket = socket_io.io(
        socketUrl,
        socket_io.OptionBuilder()
            .setTransports(['websocket']) // Enforce pure WebSocket transport
            .setAuth({'jwt_token': token}) // Inject JWT auth token
            .enableAutoConnect()
            .enableReconnection()
            .setReconnectionDelay(5000)
            .build(),
      );

      _socket!.onConnect((_) {
        logger.i('SocketService: Connected to WebSocket server');
      });

      _socket!.onDisconnect((_) {
        logger.w('SocketService: Disconnected from WebSocket server');
      });

      _socket!.onConnectError((err) {
        logger.e('SocketService: Connection error: $err');
      });

      _socket!.onError((err) {
        logger.e('SocketService: Error: $err');
      });

      // Listen to new message event broadcasted by Backend
      _socket!.on('new_message', (data) {
        logger.d('SocketService: Received new_message event: $data');
        if (data is Map<String, dynamic>) {
          _messageController.add(data);
        } else if (data is Map) {
          _messageController.add(Map<String, dynamic>.from(data));
        }
      });

      // Listen to new notification event broadcasted by Backend
      _socket!.on('new_notification', (data) {
        logger.d('SocketService: Received new_notification event: $data');
        if (data is Map<String, dynamic>) {
          _notificationController.add(data);
        } else if (data is Map) {
          _notificationController.add(Map<String, dynamic>.from(data));
        }
      });
    } catch (e) {
      logger.e('SocketService: Failed to connect: $e');
    }
  }

  void disconnect() {
    if (_socket != null) {
      _socket!.disconnect();
      _socket!.destroy();
      _socket = null;
      logger.i('SocketService: Socket connection closed');
    }
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _notificationController.close();
  }
}
