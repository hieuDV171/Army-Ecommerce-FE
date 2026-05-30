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
                userId: extra.userId,
                username: extra.username,
                token: extra.token,
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
  final String userId;
  final String username;
  final String token;

  const HomeRouteArgs({
    required this.userId,
    required this.username,
    required this.token,
  });
}
