import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/blocs/settings/push_setting_bloc.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
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
  // Người dùng vẫn có thể gọi lại nếu swipe từ dưới lên hoặc cạnh màn hình
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  // Khởi tạo Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Đăng ký background message handler. The handler is a top-level
  // function in `firebase_notification_service.dart` and will initialize
  // Firebase again inside the background isolate if necessary.
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Load file .env
  await dotenv.load(fileName: ".env");

  // Khởi tạo DioClient
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
    // Setup Firebase message handlers
    FirebaseNotificationService.initializeFirebase();
    FirebaseNotificationService.setupForegroundMessageHandler();
    FirebaseNotificationService.setupNotificationTapHandler();
  }

  // Widget gốc (root) của ứng dụng.
  @override
  Widget build(BuildContext context) {
    // RepositoryProvider cung cấp Repository cho các Bloc sử dụng
    return MultiRepositoryProvider(
        providers: [
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
        ],
      // BlocProvider khởi tạo và cung cấp Bloc cho toàn bộ cây Widget
      child: MultiBlocProvider(
          providers: [
            BlocProvider(
              create: (context) => AuthBloc(
                  authRepository: RepositoryProvider.of<AuthRepository>(context),
              )
                ..add(AppStarted()), // GỌI NGAY sự kiện kiểm tra khi App vừa khởi tạo
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
                  // Lắng nghe khi user login thành công để đăng ký device token
                  return current is AuthSuccess;
                },
                listener: (context, state) {
                  if (state is AuthSuccess) {
                    // Lấy AuthRepository từ context và đăng ký device token
                    final authRepo = RepositoryProvider.of<AuthRepository>(context);
                    FirebaseNotificationService.registerDeviceToken(
                      authRepository: authRepo,
                    );
                    // Lắng nghe token refresh
                    FirebaseNotificationService.listenTokenRefresh(
                      authRepository: authRepo,
                    );
                  }
                },
                buildWhen: (previous, current) {
                  logger.i('DEBUG MAIN BUILDWHEN: previousState=$previous, currentState=$current');
                  // Chỉ vẽ lại màn hình chính khi trạng thái chuyển sang Success, Unauthenticated, hoặc LogoutSuccess
                  return current is AuthSuccess || current is Unauthenticated || current is AuthInitial || current is AuthLogoutSuccess;
                },
                builder: (context, state) {
                  logger.i('DEBUG MAIN BUILDER: currentState=$state');
                  // 1. Nếu xác định đã đăng nhập thành công từ token cũ hoặc mới
                  if (state is AuthSuccess) {
                    // Nếu backend trả active == -1 (yêu cầu hoàn tất thông tin) và username vẫn là định dạng số điện thoại -> hiển thị màn cập nhật hồ sơ
                    if (state.user.active == -1 && RegExp(r'^0[0-9]{9}$').hasMatch(state.user.username)) {
                      final authBloc = BlocProvider.of<AuthBloc>(context);
                      return BlocProvider.value(
                        value: authBloc,
                        child: ChangeInfoAfterSignupScreen(currentUsername: state.user.username),
                      );
                    }

                    return HomeScreen(
                      username: state.user.username,
                      token: state.user.token,
                    );
                  }

                  // 2. Nếu chưa đăng nhập, token hỏng, hoặc vừa đăng xuất thành công
                  if (state is Unauthenticated || state is AuthLogoutSuccess) {
                    return const LoginScreen();
                  }

                  // 3. Màn hình chờ (Splash Screen) khi đang kiểm tra token
                  return const Scaffold(
                      body: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.military_tech, size: 80, color: Colors.lightGreen),
                            SizedBox(height: 20),
                            CircularProgressIndicator(),
                            SizedBox(height: 10),
                            Text("Đang kiểm tra dữ liệu quân nhu..."),
                          ],
                        ),
                      ),
                  );
                }
            )
           ),
      ),
    );
  }
}
