import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _header(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _summaryCard(
                          title: 'Total Spent',
                          amount: '\$3,420',
                          icon: CupertinoIcons.arrow_down_circle,
                          iconColor: Colors.red,
                          subtext: '+12% from last month',
                          borderColor: Colors.yellow,
                        ),
                        const SizedBox(width: 12),
                        _summaryCard(
                          title: 'Daily Average',
                          amount: '\$114',
                          icon: CupertinoIcons.chart_bar,
                          iconColor: Colors.blue,
                          subtext: '-5% from last month',
                          borderColor: Colors.yellow,
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Spending by Category',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _categorySpendingList(),
                    const SizedBox(height: 24),
                    Text(
                      'Monthly Trends',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _monthlyTrendsList(),
                  ],
                ),
              ),
            ),
            _bottomNavigationBar(),
          ],
        ),
      ),
    );
  }

  Widget _header() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Analytics',
              style: GoogleFonts.poppins(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              'Insights into your spending patterns',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ],
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            children: [
              Text(
                'This Month',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 6),
              const Icon(CupertinoIcons.calendar, size: 18),
            ],
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
    required String subtext,
    required Color borderColor,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: borderColor.withOpacity(0.4), width: 1.5),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 2)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.poppins(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Text(
                  amount,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const Spacer(),
                Icon(icon, size: 22, color: iconColor),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              subtext,
              style: GoogleFonts.poppins(fontSize: 12, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySpendingList() {
    final categories = [
      {
        'label': 'Food & Dining',
        'amount': '\$850',
        'percent': '35%',
        'color': Colors.red,
      },
      {
        'label': 'Transportation',
        'amount': '\$420',
        'percent': '17%',
        'color': Colors.blue,
      },
      {
        'label': 'Entertainment',
        'amount': '\$320',
        'percent': '13%',
        'color': Colors.purple,
      },
      {
        'label': 'Bills & Utilities',
        'amount': '\$480',
        'percent': '20%',
        'color': Colors.orange,
      },
      {
        'label': 'Shopping',
        'amount': '\$380',
        'percent': '15%',
        'color': Colors.green,
      },
    ];

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(color: Colors.yellow.withOpacity(0.4)),
      ),
      child: Column(
        children:
            categories.map((cat) {
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: cat['color'] as Color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        cat['label'] as String,
                        style: GoogleFonts.poppins(fontSize: 14),
                      ),
                    ),
                    Text(
                      cat['amount'] as String,
                      style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      cat['percent'] as String,
                      style: GoogleFonts.poppins(color: Colors.grey),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _monthlyTrendsList() {
    final months = [
      {'month': 'Jan', 'income': 5800, 'expenses': 3200},
      {'month': 'Feb', 'income': 5800, 'expenses': 3600},
      {'month': 'Mar', 'income': 6200, 'expenses': 3400},
      {'month': 'Apr', 'income': 5800, 'expenses': 3800},
      {'month': 'May', 'income': 5800, 'expenses': 3420},
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.yellow.withOpacity(0.4)),
      ),
      child: Column(
        children:
            months.map((entry) {
              final income = entry['income'] as int;
              final expenses = entry['expenses'] as int;
              final balance = income - expenses;
              final month = entry['month'] as String;

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(month, style: GoogleFonts.poppins()),
                    Row(
                      children: [
                        Icon(Icons.circle, size: 10, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(
                          'Income: \$$income',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                        const SizedBox(width: 10),
                        Icon(Icons.circle, size: 10, color: Colors.red),
                        const SizedBox(width: 4),
                        Text(
                          'Expenses: \$$expenses',
                          style: GoogleFonts.poppins(fontSize: 13),
                        ),
                      ],
                    ),
                    Text(
                      '\$$balance',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _bottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 1,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      showUnselectedLabels: true,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard_outlined),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.bar_chart),
          label: 'Analytics',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.add_circle, size: 36),
          label: '',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.wallet), label: 'Budget'),
        BottomNavigationBarItem(
          icon: Icon(Icons.person_outline),
          label: 'Profile',
        ),
      ],
    );
  }
}
