import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'core/services/push_notification_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/order_repository.dart';
import 'data/repositories/notification_repository.dart';
import 'presentation/bloc/auth/auth_cubit.dart';
import 'presentation/bloc/orders/orders_cubit.dart';
import 'presentation/bloc/notifications/notifications_cubit.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (Firebase.apps.isEmpty) {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  }

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  runApp(const KaliRiderApp());
}

class KaliRiderApp extends StatefulWidget {
  const KaliRiderApp({super.key});

  @override
  State<KaliRiderApp> createState() => _KaliRiderAppState();
}

class _KaliRiderAppState extends State<KaliRiderApp> {
  final _pushService = PushNotificationService();

  @override
  void initState() {
    super.initState();
    _pushService.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final authRepo = AuthRepository();
    final orderRepo = OrderRepository();
    final notifRepo = NotificationRepository();

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(authRepo)),
        BlocProvider(create: (_) => OrdersCubit(orderRepo)),
        BlocProvider(create: (_) => NotificationsCubit(notifRepo)),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp.router(
            title: 'Kali Rider',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light,
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}
