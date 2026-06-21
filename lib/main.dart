import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/core/navigation/navigator_service.dart';
import 'package:army_ecommerce/blocs/settings/push_setting_bloc.dart';
import 'package:army_ecommerce/core/config/app_config.dart';
import 'package:army_ecommerce/data/repositories/block_repository_impl.dart';
import 'package:army_ecommerce/data/repositories/follow_repository_impl.dart';
import 'package:army_ecommerce/data/repositories/notification_repository_impl.dart';
import 'package:army_ecommerce/data/sources/remote/block_remote_data_source.dart';
import 'package:army_ecommerce/data/sources/remote/follow_remote_data_source.dart';
import 'package:army_ecommerce/data/sources/remote/notification_remote_data_source.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:army_ecommerce/repositories/block_repository.dart';
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
import 'package:army_ecommerce/ui/util/widgets/network_status_wrapper.dart';
import 'package:army_ecommerce/ui/home/home_screen.dart';
import 'package:army_ecommerce/ui/profile/change_info_after_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/api/dio_client.dart';
import 'core/services/firebase_notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'ui/util/theme/app_theme.dart';
import 'ui/util/theme/special_app_theme.dart';
import 'blocs/theme_cubit.dart';
import 'package:army_ecommerce/core/utils/logger.dart';
import 'firebase_options.dart';

import 'core/services/cart_manager.dart';

Future<void> main() async {
  // Đảm bảo Flutter binding được khởi tạo trước khi chạy các setup bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized();

  // Load saved shopping cart
  await CartManager().loadCart();

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

  // Khởi tạo AppConfig
  await AppConfig.initialize();

  // Khởi tạo DioClient dùng chung cho toàn bộ app
  final dioClient = DioClient();

  // Load saved theme mode
  AppThemeMode initialTheme = AppThemeMode.army;
  int initialCustomPrimaryVal = 0xFF9C27B0;
  int initialCustomDarkVal = 0xFF673AB7;
  bool initialCustomUseGradient = true;
  try {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('theme_mode');
    if (savedTheme != null) {
      initialTheme = AppThemeMode.values.byName(savedTheme);
    }
    initialCustomPrimaryVal = prefs.getInt('theme_custom_primary') ?? 0xFF9C27B0;
    initialCustomDarkVal = prefs.getInt('theme_custom_dark') ?? 0xFF673AB7;
    initialCustomUseGradient = prefs.getBool('theme_custom_use_gradient') ?? true;
  } catch (_) {}

  runApp(MyApp(
    dioClient: dioClient,
    initialTheme: initialTheme,
    initialCustomPrimary: Color(initialCustomPrimaryVal),
    initialCustomDark: Color(initialCustomDarkVal),
    initialCustomUseGradient: initialCustomUseGradient,
  ));
}

class MyApp extends StatefulWidget {
  final DioClient dioClient;
  final AppThemeMode initialTheme;
  final Color initialCustomPrimary;
  final Color initialCustomDark;
  final bool initialCustomUseGradient;

  const MyApp({
    super.key,
    required this.dioClient,
    required this.initialTheme,
    required this.initialCustomPrimary,
    required this.initialCustomDark,
    required this.initialCustomUseGradient,
  });

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
          create: (context) {
            final repo = MarketplaceRepositoryImpl(
              remoteDataSource: MarketplaceRemoteDataSource(dioClient: widget.dioClient),
            );
            CartManager().setRepository(repo);
            return repo;
          },
        ),
        // Repository của thành viên phụ trách API follow/block/chat/notification
        RepositoryProvider<FollowRepository>(
          create: (context) => FollowRepositoryImpl(
            remoteDataSource: FollowRemoteDataSource(dioClient: widget.dioClient),
          ),
        ),
        RepositoryProvider<BlockRepository>(
          create: (context) => BlockRepositoryImpl(
            remoteDataSource: BlockRemoteDataSource(dioClient: widget.dioClient),
          ),
        ),
        RepositoryProvider<NotificationRepository>(
          create: (context) => NotificationRepositoryImpl(
            remoteDataSource: NotificationRemoteDataSource(dioClient: widget.dioClient),
          ),
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
          BlocProvider(
            create: (context) => ThemeCubit(
              initialTheme: widget.initialTheme,
              initialCustomPrimary: widget.initialCustomPrimary,
              initialCustomDark: widget.initialCustomDark,
              initialCustomUseGradient: widget.initialCustomUseGradient,
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            return MaterialApp(
              navigatorKey: NavigatorService.navigatorKey,
              title: 'Army E-commerce',
              theme: AppTheme.getTheme(
                themeState.themeMode,
                customPrimary: themeState.customPrimaryColor,
                customDark: themeState.customDarkColor,
                customUseGradient: themeState.customUseGradient,
              ),
              builder: (context, child) {
                return NetworkStatusWrapper(child: child!);
              },
          home: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (previous, current) {
              return current is AuthSuccess || current is AuthLogoutSuccess || current is Unauthenticated;
            },
            listener: (context, state) {
              if (state is AuthSuccess) {
                final authRepo = RepositoryProvider.of<AuthRepository>(context);
                final marketplaceRepo = RepositoryProvider.of<MarketplaceRepository>(context);
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
                // Khởi tạo kết nối Socket.IO khi đăng nhập hoặc tự động đăng nhập thành công
                try {
                  marketplaceRepo.initSocket(state.user.token);
                } catch (e) {
                  logger.e('Failed to init Socket.IO in main listener: $e');
                }

                // Kiểm tra và xử lý thông báo đang chờ điều hướng sau khi UI dựng xong
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  FirebaseNotificationService.checkPendingNotification();
                });

                CartManager().syncCart();
              }

              if (state is AuthLogoutSuccess || state is Unauthenticated) {
                CartManager().clearCartLocalOnly();
                // Đóng kết nối Socket.IO khi đăng xuất hoặc chưa xác thực
                try {
                  RepositoryProvider.of<MarketplaceRepository>(context).closeSocket();
                } catch (e) {
                  logger.e('Failed to close Socket.IO in main listener: $e');
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

              // Chưa đăng nhập hoặc vừa đăng xuất -> Cho phép vào HomeScreen lướt sản phẩm (Guest Mode)
              if (state is Unauthenticated || state is AuthLogoutSuccess) {
                return const HomeScreen(
                  userId: "",
                  username: "Khách",
                  token: "",
                );
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
        );
      },
    ),
  ),
    );
  }
}
