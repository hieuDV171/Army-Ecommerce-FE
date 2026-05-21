import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../ui/auth/login_screen.dart';
import '../../ui/home/home_screen.dart';
import 'route_names.dart';

class AppRouter {
  static GoRouter create() {
    return GoRouter(
      initialLocation: '/login',
      routes: [
        GoRoute(
          name: RouteNames.login,
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          name: RouteNames.home,
          path: '/home',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is HomeRouteArgs) {
              return HomeScreen(
                username: extra.username,
                token: extra.token,
                phoneNumber: extra.phoneNumber,
              );
            }

            return const Scaffold(
              body: Center(child: Text('Thiếu thông tin phiên đăng nhập')),
            );
          },
        ),
      ],
    );
  }
}

class HomeRouteArgs {
  final String username;
  final String token;
  final String? phoneNumber;

  const HomeRouteArgs({
    required this.username,
    required this.token,
    this.phoneNumber,
  });
}
