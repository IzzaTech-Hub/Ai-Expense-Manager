import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dashboard_data.dart';
import '../../routes/app_routes.dart';

class DashboardScreen extends StatelessWidget {
  final DashboardData data;

  const DashboardScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    double usedPercent = data.totalExpenses / data.budgetLimit;
    double remaining = data.budgetLimit - data.totalExpenses;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting
              FutureBuilder<DocumentSnapshot>(
                future:
                    FirebaseFirestore.instance
                        .collection('users') // ✅ Correct collection name
                        .doc(
                          FirebaseAuth.instance.currentUser!.uid,
                        ) // ✅ UID as document ID
                        .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const CircularProgressIndicator(); // Loading
                  }

                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      !snapshot.data!.exists) {
                    return Text(
                      'Good morning, User',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }

                  final userName =
                      snapshot.data!.get('name') ??
                      'User'; // ✅ Fetching 'name' field

                  return Text(
                    'Good morning, $userName',
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),

              const SizedBox(height: 4),
              Text(
                "Here's your financial overview",
                style: GoogleFonts.poppins(fontSize: 14, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              // Total Balance
              _balanceCard(
                data.totalBalance,
                data.totalIncome,
                data.totalExpenses,
              ),
              const SizedBox(height: 20),

              // Quick Actions
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.analyticsBasic);
                      },
                      child: _quickCard(
                        Icons.show_chart,
                        'Analytics',
                        'View insights',
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, AppRoutes.goalScreen);
                      },
                      child: _quickCard(
                        Icons.track_changes,
                        'Goals',
                        'Track progress',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Budget Overview
              _sectionCard(
                title: 'Budget Overview',
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Monthly Budget'),
                        Text('PKR ${data.budgetLimit.toStringAsFixed(0)}'),
                      ],
                    ),
                    const SizedBox(height: 10),
                    LinearProgressIndicator(
                      value: usedPercent,
                      backgroundColor: Colors.grey.shade300,
                      valueColor: const AlwaysStoppedAnimation(
                        Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Used: ${(usedPercent * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(color: Colors.black54),
                        ),
                        Text(
                          'Remaining: PKR ${remaining.toStringAsFixed(0)}',
                          style: const TextStyle(color: Colors.green),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Expense Breakdown (Donut)
              _sectionCard(
                title: 'Expense Breakdown',
                child: SizedBox(
                  height: 200,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 130,
                        child: PieChart(
                          PieChartData(
                            sectionsSpace: 2,
                            centerSpaceRadius: 35,
                            sections: _buildPieChartSections(
                              data.expenseCategories,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 32),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children:
                            data.expenseCategories.entries.map((entry) {
                              return _expenseLegend(
                                entry.key,
                                entry.value,
                                _getColor(entry.key),
                              );
                            }).toList(),
                      ),
                    ],
                  ),
                ),
              ),

              // Monthly Trends Chart
              _sectionCard(
                title: 'Monthly Trends',
                child: SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      maxY: 8000,
                      alignment: BarChartAlignment.spaceAround,
                      barGroups: _buildBarGroups(
                        data.monthlyIncome,
                        data.monthlyExpense,
                      ),
                      gridData: FlGridData(show: false),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget:
                                (value, _) => Text(
                                  '${value.toInt()}',
                                  style: const TextStyle(
                                    color: Colors.black45,
                                    fontSize: 10,
                                  ),
                                ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget:
                                (value, _) => Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    _monthLabel(value.toInt()),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                          ),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Premium Card
              _sectionCard(
                title: 'Premium',
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF9DB),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.workspace_premium,
                        color: Colors.orange,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Unlock Premium Features',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Get AI insights, advanced analytics,\nand unlimited goals.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.upgrade, color: Colors.white),
                        label: const Text('Upgrade Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF39C12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          if (index == 1) {
            Navigator.pushNamed(context, AppRoutes.analyticsBasic);
          }
          // You can handle other indices if needed
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Dashboard'),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  // COMPONENT HELPERS

  Widget _balanceCard(double total, double income, double expense) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF3B82F6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PKR ${total.toStringAsFixed(0)}',
            style: GoogleFonts.poppins(
              fontSize: 28,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Income: PKR ${income.toStringAsFixed(0)}',
                style: const TextStyle(color: Colors.white70),
              ),
              Text(
                'Expenses: PKR ${expense.toStringAsFixed(0)}',
                style: const TextStyle(color: Color(0xFFFFCDD2)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickCard(IconData icon, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: 28, color: const Color(0xFF3B82F6)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Text(
            subtitle,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade200),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _expenseLegend(String label, double amount, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          CircleAvatar(radius: 5, backgroundColor: color),
          const SizedBox(width: 6),
          Text(
            '$label PKR ${amount.toStringAsFixed(0)}',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Color _getColor(String category) {
    switch (category) {
      case 'Food':
        return Colors.red;
      case 'Bills':
        return Colors.orange;
      case 'Shopping':
        return Colors.green;
      case 'Transport':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  List<PieChartSectionData> _buildPieChartSections(
    Map<String, double> categories,
  ) {
    return categories.entries.map((entry) {
      return PieChartSectionData(
        value: entry.value,
        color: _getColor(entry.key),
        radius: 25,
      );
    }).toList();
  }

  List<BarChartGroupData> _buildBarGroups(
    List<double> incomes,
    List<double> expenses,
  ) {
    return List.generate(incomes.length, (i) {
      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(toY: incomes[i], color: Colors.green, width: 10),
          BarChartRodData(toY: expenses[i], color: Colors.red, width: 10),
        ],
        barsSpace: 6,
      );
    });
  }

  String _monthLabel(int x) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
    return (x >= 0 && x < months.length) ? months[x] : '';
  }
}
