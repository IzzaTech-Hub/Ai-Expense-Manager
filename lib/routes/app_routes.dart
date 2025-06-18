import 'package:flutter/material.dart';

// Screens
import '../screens/splash/splash_screen.dart';
import '../screens/onboarding/welcome_screen_1.dart';
import '../screens/onboarding/welcome_screen_2.dart';
import '../screens/onboarding/welcome_screen_3.dart';
import '../screens/onboarding/welcome_screen_4.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/forget_password_screen.dart';
import '../screens/dashboard/dashboard_basic.dart';
import '../screens/goals/goal_screen_basic.dart';
import '../screens/goals/create_goal_basic.dart';
import '../screens/goals/edit_goal_basic.dart';
import '../screens/goals/add_money_to_goal_screen.dart'; // ✅ Added
import '../screens/analytics/analytics_basic.dart';

// Models
import '../models/dashboard_data.dart';
import '../models/goal_model.dart';

class AppRoutes {
  // 🔖 Route name constants
  static const String splash = '/splash';
  static const String welcome1 = '/welcome1';
  static const String welcome2 = '/welcome2';
  static const String welcome3 = '/welcome3';
  static const String welcome4 = '/welcome4';
  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgotPassword';
  static const String dashboardBasic = '/dashboardBasic';
  static const String goalScreen = '/goalScreen';
  static const String createGoalBasic = '/createGoalBasic';
  static const String editGoalBasic = '/editGoalBasic';
  static const String addMoneyToGoal = '/addMoneyToGoal'; // ✅ Added
  static const String analyticsBasic = '/analyticsBasic';

  /// 🔁 Central route generator
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen());

      case welcome1:
        return _buildRoute(const WelcomeScreen1());
      case welcome2:
        return _buildRoute(const WelcomeScreen2());
      case welcome3:
        return _buildRoute(const WelcomeScreen3());
      case welcome4:
        return _buildRoute(const WelcomeScreen4());

      case signIn:
        return _buildRoute(const SignInScreen());
      case signUp:
        return _buildRoute(const SignUpScreen());
      case forgotPassword:
        return _buildRoute(const ForgetPasswordScreen());

      case dashboardBasic:
        if (args is DashboardData) {
          return _buildRoute(DashboardScreen(data: args));
        }
        return _errorRoute("Dashboard data is missing or invalid.");

      case goalScreen:
        return _buildRoute(GoalScreenBasic());

      case createGoalBasic:
        return _buildRoute(const CreateGoalBasic());

      case editGoalBasic:
        if (args is Goal) {
          return _buildRoute(EditGoalScreen(goal: args));
        }
        return _errorRoute("Goal data is missing or invalid.");

      case addMoneyToGoal:
        if (args is Goal) {
          return _buildRoute(AddMoneyToGoalScreen(goal: args));
        }
        return _errorRoute("Goal data is missing or invalid.");

      case analyticsBasic:
        return _buildRoute(const AnalyticsScreen());

      default:
        return _errorRoute("Page not found.");
    }
  }

  /// ✅ Helper for building routes
  static MaterialPageRoute _buildRoute(Widget screen) {
    return MaterialPageRoute(builder: (_) => screen);
  }

  /// ❌ Error fallback
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
