import 'package:flutter/material.dart';

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
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/dashboardBasic', 
              (route) => false,
            );
            break;
          case 1:
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/analyticsBasic', 
              (route) => false,
            );
            break;
          case 2:
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/addTransaction', 
              (route) => false,
            );
            break;
          case 3:
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/budgetScreenBasic', 
              (route) => false,
            );
            break;
          case 4:
            Navigator.pushNamedAndRemoveUntil(
              context, 
              '/profileScreen', 
              (route) => false,
            );
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