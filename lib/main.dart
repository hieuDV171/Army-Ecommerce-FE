import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
import 'package:army_ecommerce/repositories/block_repository.dart';
import 'package:army_ecommerce/repositories/chat_repository.dart';
import 'package:army_ecommerce/repositories/follow_repository.dart';
import 'package:army_ecommerce/repositories/notification_repository.dart';
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
    // Setup Firebase message handlers
    FirebaseNotificationService.setupForegroundMessageHandler();
    FirebaseNotificationService.setupNotificationTapHandler();
  }

  @override
  Widget build(BuildContext context) {
    // MultiRepositoryProvider cung cấp tất cả repository cho toàn bộ cây widget
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider(
          create: (_) => AuthRepository(dioClient: widget.dioClient),
        ),
        RepositoryProvider(
          create: (_) => FollowRepository(dioClient: widget.dioClient),
        ),
        RepositoryProvider(
          create: (_) => BlockRepository(dioClient: widget.dioClient),
        ),
        RepositoryProvider(
          create: (_) => ChatRepository(dioClient: widget.dioClient),
        ),
        RepositoryProvider(
          create: (_) => NotificationRepository(dioClient: widget.dioClient),
        ),
      ],
      child: BlocProvider(
        create: (ctx) => AuthBloc(
          authRepository: ctx.read<AuthRepository>(),
        )..add(AppStarted()),
        child: MaterialApp(
          title: 'Army E-commerce',
          theme: ThemeData(primarySwatch: Colors.blue),
          home: BlocConsumer<AuthBloc, AuthState>(
            listenWhen: (_, current) => current is AuthSuccess,
            listener: (context, state) {
              if (state is AuthSuccess) {
                final authRepo = context.read<AuthRepository>();
                FirebaseNotificationService.registerDeviceToken(
                  authRepository: authRepo,
                );
                FirebaseNotificationService.listenTokenRefresh(
                  authRepository: authRepo,
                );
              }
            },
            buildWhen: (_, current) =>
                current is AuthSuccess ||
                current is Unauthenticated ||
                current is AuthInitial,
            builder: (context, state) {
              if (state is AuthSuccess) {
                return HomeScreen(
                  userId: state.user.id,
                  username: state.user.username,
                  token: state.user.token,
                );
              }
              if (state is Unauthenticated) {
                return const LoginScreen();
              }
              // Splash screen khi đang kiểm tra token
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
