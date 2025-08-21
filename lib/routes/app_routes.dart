import 'package:flutter/material.dart';

// Screens
import '../screens/splash/splash_screen.dart';
import '../screens/auth/sign_in_screen.dart';
import '../screens/auth/sign_up_screen.dart';
import '../screens/auth/forget_password_screen.dart';
import '../screens/dashboard/dashboard_basic.dart';
import '../screens/goals/goal_screen_basic.dart';
import '../screens/goals/create_goal_basic.dart';
import '../screens/goals/edit_goal_basic.dart';
import '../screens/goals/add_money_to_goal_screen.dart';
import '../screens/transactions/add_transaction_screen.dart';
import '../screens/analytics/analytics_basic.dart';
import '../screens/budget/budget_screen_basic.dart';
import '../screens/budget/add_budget_category.dart';
import '../screens/budget/edit_budget_category.dart';
import '../screens/profile/profile_basic.dart'; // ✅ Import Profile screen
import '../screens/profile/edit_profile_screen.dart';
import '../screens/profile/change_password_screen.dart';
import '../screens/profile/notification_preferences_screen.dart';
import '../screens/profile/about_app_screen.dart';
import '../screens/profile/privacy_policy_screen.dart';
import '../screens/profile/terms_of_service_screen.dart';
import '../screens/dashboard/ai_assistant_screen.dart';

// Models
import '../models/goal_model.dart';

class AppRoutes {
  // 🔖 Route name constants
  static const String splash = '/splash';

  static const String signIn = '/signin';
  static const String signUp = '/signup';
  static const String forgotPassword = '/forgotPassword';

  static const String dashboardBasic = '/dashboardBasic';

  static const String goalScreen = '/goalScreen';
  static const String createGoalBasic = '/createGoalBasic';
  static const String editGoalBasic = '/editGoalBasic';
  static const String addMoneyToGoal = '/addMoneyToGoal';

  static const String addTransaction = '/addTransaction';

  static const String analyticsBasic = '/analyticsBasic';

  static const String budgetScreenBasic = '/budgetScreenBasic';
  static const String addBudgetCategory = '/addBudgetCategory';
  static const String editBudgetCategory = '/editBudgetCategory';

  static const String profileScreen = '/profileScreen'; // ✅ Profile route
  static const String editProfile = '/editProfile';
  static const String changePassword = '/changePassword';
  static const String notificationPreferences = '/notificationPreferences';
  static const String aboutApp = '/aboutApp';
  static const String privacyPolicy = '/privacyPolicy';
  static const String termsOfService = '/termsOfService';
  static const String aiAssistant = '/aiAssistant';

  /// 🔁 Route generator
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    final args = settings.arguments;

    switch (settings.name) {
      case splash:
        return _buildRoute(const SplashScreen());

      case signIn:
        return _buildRoute(const SignInScreen());
      case signUp:
        return _buildRoute(const SignUpScreen());
      case forgotPassword:
        return _buildRoute(const ForgetPasswordScreen());

      case dashboardBasic:
        return _buildRoute(const DashboardScreen());

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

      case addTransaction:
        return _buildRoute(const AddTransactionScreen());

      case analyticsBasic:
        return _buildRoute(const AnalyticsScreen());

      case budgetScreenBasic:
        return _buildRoute(const BudgetScreenBasic());

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

      case profileScreen:
        return _buildRoute(const ProfileScreen());
      case aiAssistant:
        return _buildRoute(const AiAssistantScreen());

      case editProfile:
        return _buildRoute(const EditProfileScreen());
      case changePassword:
        return _buildRoute(const ChangePasswordScreen());
      case notificationPreferences:
        return _buildRoute(const NotificationPreferencesScreen());
      case aboutApp:
        return _buildRoute(const AboutAppScreen());
      case privacyPolicy:
        return _buildRoute(const PrivacyPolicyScreen());
      case termsOfService:
        return _buildRoute(const TermsOfServiceScreen());

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
