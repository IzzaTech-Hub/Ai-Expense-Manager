import 'package:flutter/material.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;
  const AppBottomNavBar({Key? key, required this.currentIndex}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomNavigationBar(
      currentIndex: currentIndex,
      selectedItemColor: const Color(0xFF3B82F6),
      unselectedItemColor: Colors.grey,
      type: BottomNavigationBarType.fixed,
      onTap: (index) {
        if (index == currentIndex) return;
        switch (index) {
          case 0:
            Navigator.pushReplacementNamed(context, '/dashboardBasic');
            break;
          case 1:
            Navigator.pushReplacementNamed(context, '/analyticsBasic');
            break;
          case 2:
            Navigator.pushReplacementNamed(context, '/addTransaction');
            break;
          case 3:
            Navigator.pushReplacementNamed(context, '/budgetScreenBasic');
            break;
          case 4:
            Navigator.pushReplacementNamed(context, '/profileScreen');
            break;
        }
      },
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
        BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Analytics'),
        BottomNavigationBarItem(icon: Icon(Icons.add_circle_outline), label: 'Add'),
        BottomNavigationBarItem(icon: Icon(Icons.account_balance_wallet), label: 'Budget'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
} 