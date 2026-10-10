import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../presentation/screens/splash/splash_screen.dart';
import '../../presentation/screens/auth/login_screen.dart';
import '../../presentation/screens/auth/rider_setup_screen.dart';
import '../../presentation/screens/home/home_shell.dart';
import '../../presentation/screens/home/home_tab.dart';
import '../../presentation/screens/orders/available_orders_tab.dart';
import '../../presentation/screens/earnings/earnings_tab.dart';
import '../../presentation/screens/profile/profile_tab.dart';
import '../../presentation/screens/orders/order_detail_screen.dart';
import '../../presentation/screens/delivery/active_delivery_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/rider-setup',
      builder: (context, state) => const RiderSetupScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellNavigatorKey,
      builder: (context, state, child) => HomeShell(child: child),
      routes: [
        GoRoute(
          path: '/home',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: HomeTab()),
        ),
        GoRoute(
          path: '/orders',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: AvailableOrdersTab()),
        ),
        GoRoute(
          path: '/earnings',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: EarningsTab()),
        ),
        GoRoute(
          path: '/profile',
          pageBuilder: (context, state) =>
              const NoTransitionPage(child: ProfileTab()),
        ),
      ],
    ),
    GoRoute(
      path: '/order/:id',
      builder: (context, state) =>
          OrderDetailScreen(orderId: state.pathParameters['id']!),
    ),
    GoRoute(
      path: '/delivery/:id',
      builder: (context, state) =>
          ActiveDeliveryScreen(orderId: state.pathParameters['id']!),
    ),
  ],
);
