import 'package:army_ecommerce/blocs/auth/auth_bloc.dart';
import 'package:army_ecommerce/blocs/auth/auth_event.dart';
import 'package:army_ecommerce/blocs/auth/auth_state.dart';
import 'package:army_ecommerce/repositories/auth_repository.dart';
import 'package:army_ecommerce/ui/auth/login_screen.dart';
import 'package:army_ecommerce/ui/home/home_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'core/api/dio_client.dart';

Future<void> main() async {
  // Đảm bảo Flutter binding được khởi tạo trước khi chạy các setup bất đồng bộ
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env
  await dotenv.load(fileName: ".env");

  // Khởi tạo DioClient
  final dioClient = DioClient();

  runApp(MyApp(dioClient: dioClient));
}

class MyApp extends StatelessWidget {
  final DioClient dioClient;
  const MyApp({super.key, required this.dioClient});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // RepositoryProvider cung cấp AuthRepository cho các Bloc sử dụng
    return RepositoryProvider(
        create: (context) => AuthRepository(dioClient: dioClient),
      // BlocProvider khởi tạo và cung cấp AuthBloc cho toàn bộ cây Widget
      child: BlocProvider(
          create: (context) => AuthBloc(
              authRepository: RepositoryProvider.of<AuthRepository>(context),
          )
            ..add(AppStarted()), // GỌI NGAY sự kiện kiểm tra khi App vừa khởi tạo
          child: MaterialApp(
            title: 'Army E-commerce',
            theme: ThemeData(
              primarySwatch: Colors.blue,
            ),
            home: BlocBuilder<AuthBloc, AuthState>(
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
