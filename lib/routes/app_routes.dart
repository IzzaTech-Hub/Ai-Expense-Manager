import 'package:flutter/material.dart';

// Screens
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/dashboard/dashboard_basic.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/analytics/analytics_basic.dart';
import '../screens/budget/budget_screen_basic.dart';
import '../screens/budget/add_budget_category.dart';
import '../screens/budget/edit_budget_category.dart';
import '../screens/dashboard/ai_assistant_screen.dart';



class AppRoutes {
  // Main routes
  static const String splash = '/splash';
  static const String onboarding = '/onboarding';
  static const String dashboard = '/dashboard';
  static const String analytics = '/analytics';
  static const String addTransaction = '/add';
  static const String budget = '/budget';
  static const String aiAssistant = '/ai-assistant';

  // Transaction routes
  static const String editTransaction = '/edit-transaction';

  // Budget routes
  static const String addBudgetCategory = '/add-budget-category';
  static const String editBudgetCategory = '/edit-budget-category';

  // AI Assistant routes
  static const String aiChat = '/ai-chat';

  /// 🔁 Route generator
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen());

      case onboarding:
        return _buildRoute(const OnboardingScreen());
      case dashboard:
        return _buildRoute(const DashboardScreen());
      case analytics:
        return _buildRoute(const AnalyticsScreen());
      case addTransaction:
        return _buildRoute(const AddTransactionScreen());
      case budget:
        return _buildRoute(const BudgetScreenBasic());
      case aiAssistant:
        return _buildRoute(const AiAssistantScreen());

      case editTransaction:
        return _buildRoute(const AddTransactionScreen()); // Using add transaction for now

      case addBudgetCategory:
        return _buildRoute(const AddBudgetCategory());
      case editBudgetCategory:
        if (args is Map<String, dynamic>) {
          return _buildRoute(
            EditBudgetCategory(
              categoryId: args['categoryId'],
              initialName: args['initialName'],
              initialLimit: args['initialLimit'],
              spentAmount: args['spentAmount'],
              category:
                  args, // You are passing this but not using it in your constructor
            ),
          );
        }
        return _errorRoute("Budget category data is missing or invalid.");

      case aiChat:
        return _buildRoute(const AiAssistantScreen()); // Using existing AI assistant screen

      default:
        return _errorRoute("Page not found.");
    }
  }

  static MaterialPageRoute _buildRoute(Widget screen) {
    return MaterialPageRoute(builder: (_) => screen);
  }

  static Route<dynamic> _errorRoute(String message) {
    return MaterialPageRoute(
      builder:
          (_) => Scaffold(
            appBar: AppBar(title: const Text("Error")),
            body: Center(
              child: Text(
                message,
                style: const TextStyle(fontSize: 18, color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),
          ),
    );
  }
}
