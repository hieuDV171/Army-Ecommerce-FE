import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/blocs/settings/push_setting_bloc.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
import 'package:army_ecommerce/repositories/setting_repository.dart';
import 'package:army_ecommerce/ui/auth/login_screen.dart';
import 'package:army_ecommerce/ui/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/api/dio_client.dart';
import 'core/services/firebase_notification_service.dart';

Future<void> main() async {
  // Đảm bảo Flutter binding được khởi tạo trước khi chạy các setup bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized();

  // Khởi tạo Firebase
  await FirebaseNotificationService.initializeFirebase();

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
    FirebaseNotificationService.setupForegroundMessageHandler();
    FirebaseNotificationService.setupNotificationTapHandler();
  }

  // Widget gốc (root) của ứng dụng.
  @override
  Widget build(BuildContext context) {
    // RepositoryProvider cung cấp Repository cho các Bloc sử dụng
    return MultiRepositoryProvider(
        providers: [
          RepositoryProvider(
            create: (context) => AuthRepository(dioClient: widget.dioClient),
          ),
          RepositoryProvider(
            create: (context) => SettingRepository(dioClient: widget.dioClient),
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
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
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
                  // Chỉ vẽ lại màn hình chính khi trạng thái chuyển sang Success hoặc Unauthenticated
                  return current is AuthSuccess || current is Unauthenticated || current is AuthInitial;
                },
                builder: (context, state) {
                  // 1. Nếu xác định đã đăng nhập thành công từ token cũ
                  if (state is AuthSuccess) {
                    return HomeScreen(
                      username: state.user.username,
                      token: state.user.token,
                    );
                  }

                  // 2. Nếu chưa đăng nhập hoặc token hỏng
                  if (state is Unauthenticated) {
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
