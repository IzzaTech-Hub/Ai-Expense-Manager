import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Generated via `flutterfire configure`
import 'routes/app_routes.dart';
import 'package:provider/provider.dart';
import 'providers/profile_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    ChangeNotifierProvider(
      create: (_) => ProfileProvider(),
      child: const MyApp(),
    ),
  );

  // FCM foreground message handler
  FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
    // For now, just print the message since we removed local notifications
    print('Received FCM message: ${message.notification?.title}');
  });

  // FCM tap handler when app is terminated
  FirebaseMessaging.instance.getInitialMessage().then((RemoteMessage? message) {
    if (message != null) {
      final context = navigatorKey.currentContext;
      final route = message.data['route'] ?? '/profileScreen';
      final goalId = message.data['goalId'];
      if (context != null) {
        Navigator.pushNamed(
          context,
          route,
          arguments: goalId != null ? {'goalId': goalId} : null,
        );
      }
    }
  });

  // FCM tap handler when app is in background
  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    final context = navigatorKey.currentContext;
    final route = message.data['route'] ?? '/profileScreen';
    final goalId = message.data['goalId'];
    if (context != null) {
      Navigator.pushNamed(
        context,
        route,
        arguments: goalId != null ? {'goalId': goalId} : null,
      );
    }
  });
}

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      title: 'Expenso',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: const Color(0xFFF9FAFB),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
      ),
      // Set the initial route of your app
      initialRoute: AppRoutes.dashboardBasic,

      // Use your centralized route handler
      onGenerateRoute: AppRoutes.generateRoute,
    );
  }
}
