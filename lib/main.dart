import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/blocs/settings/push_setting_bloc.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
import 'package:army_ecommerce/repositories/block_repository.dart';
import 'package:army_ecommerce/repositories/chat_repository.dart';
import 'package:army_ecommerce/repositories/follow_repository.dart';
import 'package:army_ecommerce/repositories/notification_repository.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/repositories/auth_repository_impl.dart';
import 'data/repositories/marketplace_repository_impl.dart';
import 'data/sources/remote/auth_remote_data_source.dart';
import 'data/sources/remote/marketplace_remote_data_source.dart';
import 'package:army_ecommerce/repositories/setting_repository.dart';
import 'data/repositories/setting_repository_impl.dart';
import 'data/sources/remote/setting_remote_data_source.dart';
import 'package:army_ecommerce/repositories/marketplace_repository.dart';
import 'package:army_ecommerce/ui/auth/login_screen.dart';
import 'package:army_ecommerce/ui/home/home_screen.dart';
import 'package:army_ecommerce/ui/profile/change_info_after_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/api/dio_client.dart';
import 'core/services/firebase_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'ui/theme/app_theme.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'firebase_options.dart';

Future<void> main() async {
  // Đảm bảo Flutter binding được khởi tạo trước khi chạy các setup bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized();

  // Ẩn system navigation bar và status bar (Immersive Sticky Mode)
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Khởi tạo Firebase — bọc try-catch để app vẫn chạy khi chưa có config thật
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    // Đăng ký background message handler chỉ khi Firebase khởi tạo thành công
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('⚠️ Firebase chưa được cấu hình — push notification bị tắt: $e');
  }

  // Load file .env
  await dotenv.load(fileName: ".env");

  // Khởi tạo DioClient dùng chung cho toàn bộ app
  final dioClient = DioClient();

  runApp(MyApp(dioClient: dioClient));
}

class MyApp extends StatefulWidget {
  final DioClient dioClient;
  const MyApp({super.key, required this.dioClient});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    try {
      FirebaseNotificationService.initializeFirebase();
      FirebaseNotificationService.setupForegroundMessageHandler();
      FirebaseNotificationService.setupNotificationTapHandler();
    } catch (e) {
      debugPrint('⚠️ Firebase notification setup bị bỏ qua: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    // MultiRepositoryProvider cung cấp tất cả repository cho toàn bộ cây widget
    return MultiRepositoryProvider(
      providers: [
        // Repository chính từ team (dùng RemoteDataSource pattern)
        RepositoryProvider<AuthRepository>(
          create: (context) => AuthRepositoryImpl(
            remoteDataSource: AuthRemoteDataSource(dioClient: widget.dioClient),
          ),
        ),
        RepositoryProvider<SettingRepository>(
          create: (context) => SettingRepositoryImpl(
            remoteDataSource: SettingRemoteDataSource(dioClient: widget.dioClient),
          ),
        ),
        RepositoryProvider<MarketplaceRepository>(
          create: (context) => MarketplaceRepositoryImpl(
            remoteDataSource: MarketplaceRemoteDataSource(dioClient: widget.dioClient),
          ),
        ),
        // Repository của thành viên phụ trách API follow/block/chat/notification
        RepositoryProvider<FollowRepository>(
          create: (_) => FollowRepository(dioClient: widget.dioClient),
        ),
        RepositoryProvider<BlockRepository>(
          create: (_) => BlockRepository(dioClient: widget.dioClient),
        ),
        RepositoryProvider<ChatRepository>(
          create: (_) => ChatRepository(dioClient: widget.dioClient),
        ),
        RepositoryProvider<NotificationRepository>(
          create: (_) => NotificationRepository(dioClient: widget.dioClient),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
            )..add(AppStarted()),
          ),
          BlocProvider(
            create: (context) => PushSettingBloc(
              settingRepository: RepositoryProvider.of<SettingRepository>(context),
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Army E-commerce',
          theme: AppTheme.light,
          home: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (previous, current) {
              return current is AuthSuccess || current is AuthLogoutSuccess || current is Unauthenticated;
            },
            listener: (context, state) {
              if (state is AuthSuccess) {
                final authRepo = RepositoryProvider.of<AuthRepository>(context);
                try {
                  FirebaseNotificationService.registerDeviceToken(
                    authRepository: authRepo,
                  );
                  FirebaseNotificationService.listenTokenRefresh(
                    authRepository: authRepo,
                  );
                } catch (e) {
                  debugPrint('⚠️ Không thể đăng ký FCM token: $e');
                }
              }

              if (state is AuthSuccess || state is AuthLogoutSuccess || state is Unauthenticated) {
                logger.i('MAIN LISTENER: State=$state — pop về root screen');
                Navigator.of(context).popUntil((route) => route.isFirst);
              }
            },
            buildWhen: (previous, current) {
              return current is AuthSuccess || current is Unauthenticated || current is AuthInitial || current is AuthLogoutSuccess;
            },
            builder: (context, state) {
              if (state is AuthSuccess) {
                final user = state.user;

                // Nếu tài khoản chưa hoàn tất thông tin (active == -1 + username là SĐT)
                if (user.active == -1 && RegExp(r'^0[0-9]{9}$').hasMatch(user.username)) {
                  final authBloc = BlocProvider.of<AuthBloc>(context);
                  return BlocProvider.value(
                    value: authBloc,
                    child: ChangeInfoAfterSignupScreen(currentUsername: user.username),
                  );
                }

                return HomeScreen(
                  userId: user.id,
                  username: user.username,
                  token: user.token,
                );
              }

              // Chưa đăng nhập hoặc vừa đăng xuất
              if (state is Unauthenticated || state is AuthLogoutSuccess) {
                return const LoginScreen();
              }

              // Màn hình chờ (Splash Screen) khi đang kiểm tra token
              return const Scaffold(
                body: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.military_tech, size: 80, color: Colors.lightGreen),
                      SizedBox(height: 20),
                      CircularProgressIndicator(),
                      SizedBox(height: 10),
                      Text('Đang kiểm tra dữ liệu quân nhu...'),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
