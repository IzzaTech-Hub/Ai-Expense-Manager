import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:api_key_pool/api_key_pool.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'providers/profile_provider.dart';
import 'routes/app_routes.dart';

void main() async {
  try {
    print('🚀 Starting Expense Manager app...');
    print('🔑 Initializing ApiKeyPool...');
    
    // Initialize ApiKeyPool
    await ApiKeyPool.init('expense manager');
    print('✅ ApiKeyPool initialized successfully');
    
    print('🎯 Running MyApp...');
    runApp(const MyApp());
  } catch (e) {
    print('❌ Error during app initialization: $e');
    print('🔄 Continuing with app launch...');
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

 // 🔹 Firebase Analytics instance
  static FirebaseAnalytics analytics = FirebaseAnalytics.instance;
  static FirebaseAnalyticsObserver observer =
      FirebaseAnalyticsObserver(analytics: analytics);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProfileProvider()),
      ],
      child: MaterialApp(
        title: 'Expense Manager',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B82F6)),
          useMaterial3: true,
        ),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}
