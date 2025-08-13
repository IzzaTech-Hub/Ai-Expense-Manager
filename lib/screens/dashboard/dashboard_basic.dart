import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../routes/app_routes.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text('User not logged in'));
    }
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('budgets')
              .where('userId', isEqualTo: user.uid)
              .snapshots(),
          builder: (context, budgetSnapshot) {
            if (budgetSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (budgetSnapshot.hasError) {
              return Center(child: Text('Error: ${budgetSnapshot.error}'));
            }
            final budgetDocs = budgetSnapshot.data?.docs ?? [];
            final categories = budgetDocs.map((doc) => doc.data() as Map<String, dynamic>).toList();
            final double budgetLimit = categories.fold(0, (sum, cat) => sum + (cat['allocated'] ?? 0).toDouble());
            final double totalExpenses = categories.fold(0, (sum, cat) => sum + (cat['spent'] ?? 0).toDouble());
            final double remaining = budgetLimit - totalExpenses;
            final double progress = budgetLimit == 0 ? 0 : totalExpenses / budgetLimit;
            final Map<String, double> expenseCategories = {
              for (var cat in categories)
                if ((cat['spent'] ?? 0) > 0) cat['name'] as String: (cat['spent'] ?? 0).toDouble(),
            };

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
              builder: (context, transactionSnapshot) {
                if (transactionSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (transactionSnapshot.hasError) {
                  return Center(child: Text('Error: ${transactionSnapshot.error}'));
                }
                final transactionDocs = transactionSnapshot.data?.docs ?? [];
                final now = DateTime.now();
                List<double> monthlyIncome = List.filled(6, 0.0);
                List<double> monthlyExpense = List.filled(6, 0.0);
                for (var doc in transactionDocs) {
                  final data = doc.data() as Map<String, dynamic>;
                  final date = (data['date'] as Timestamp).toDate();
                  final amount = (data['amount'] ?? 0).toDouble();
                  final isIncome = data['type'] == 'income';
                  final monthDiff = (now.year - date.year) * 12 + (now.month - date.month);
                  if (monthDiff >= 0 && monthDiff < 6) {
                    if (isIncome) {
                      monthlyIncome[5 - monthDiff] += amount;
                    } else {
                      monthlyExpense[5 - monthDiff] += amount;
                    }
                  }
                }
                double totalIncome = monthlyIncome.reduce((a, b) => a + b);
                final double totalBalance = totalIncome - totalExpenses;
                final maxIncome = monthlyIncome.reduce((a, b) => a > b ? a : b);
                final maxExpense = monthlyExpense.reduce((a, b) => a > b ? a : b);
                final maxY = [maxIncome, maxExpense].reduce((a, b) => a > b ? a : b);
                final chartMaxY = maxY > 0 ? (maxY * 1.2).toDouble() : 1000.0;

                return LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenWidth * 0.05,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Greeting
                  FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                            .collection('users')
                                .doc(user.uid)
                            .get(),
                    builder: (context, snapshot) {
                      String greeting = 'Good morning, User';
                      if (snapshot.hasData && snapshot.data!.exists) {
                                greeting = 'Good morning, ${snapshot.data!.get('name') ?? 'User'}';
                      }
                      return Text(
                        greeting,
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.055,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Here's your financial overview",
                    style: GoogleFonts.poppins(
                      fontSize: screenWidth * 0.035,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _balanceCard(
                    context,
                            totalBalance,
                            totalIncome,
                            totalExpenses,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                                    Navigator.pushReplacementNamed(
                              context,
                                      '/analyticsBasic',
                            );
                          },
                          child: _quickCard(
                            context,
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
                                    Navigator.pushReplacementNamed(context, '/goalScreen');
                          },
                          child: _quickCard(
                            context,
                            Icons.track_changes,
                            'Goals',
                            'Track progress',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _sectionCard(
                    context,
                    title: 'Budget Overview',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Monthly Budget'),
                                    Text('PKR ${budgetLimit.toStringAsFixed(0)}'),
                          ],
                        ),
                        const SizedBox(height: 10),
                        LinearProgressIndicator(
                                  value: progress,
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
                                      'Used: ${(progress * 100).toStringAsFixed(0)}%',
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
                  _sectionCard(
                    context,
                    title: 'Expense Breakdown',
                    child: SizedBox(
                      height: screenWidth * 0.5,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: screenWidth * 0.3,
                            child: PieChart(
                              PieChartData(
                                sectionsSpace: 2,
                                centerSpaceRadius: 35,
                                sections: _buildPieChartSections(
                                          expenseCategories,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                                      children: expenseCategories.entries
                                      .map(
                                        (entry) => _expenseLegend(
                                          entry.key,
                                          entry.value,
                                          _getColor(entry.key),
                                        ),
                                      )
                                      .toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  _sectionCard(
                    context,
                    title: 'Monthly Trends',
                    child: SizedBox(
                      height: screenWidth * 0.55,
                      child: BarChart(
                        BarChartData(
                                  maxY: chartMaxY,
                          alignment: BarChartAlignment.spaceAround,
                          barGroups: _buildBarGroups(
                                    monthlyIncome,
                                    monthlyExpense,
                          ),
                          gridData: FlGridData(show: false),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                        reservedSize: 48,
                                        interval: chartMaxY / 4,
                                        getTitlesWidget: (value, meta) {
                                          final max = chartMaxY;
                                          if (value == 0) {
                                            return Text('PKR 0', style: TextStyle(color: Colors.black45, fontSize: 11, fontWeight: FontWeight.w600));
                                          }
                                          if ((value - max).abs() < 1) {
                                            String label;
                                            if (max >= 1000000) {
                                              label = 'PKR ${(max / 1000000).toStringAsFixed(1)}M';
                                            } else if (max >= 1000) {
                                              label = 'PKR ${(max / 1000).toStringAsFixed(1)}k';
                                            } else {
                                              label = 'PKR ${max.toInt()}';
                                            }
                                            return Text(label, style: TextStyle(color: Colors.black87, fontSize: 12, fontWeight: FontWeight.bold));
                                          }
                                          if (value == max / 2) {
                                            return Text(
                                              max >= 1000000
                                                ? '${(max / 2 / 1000000).toStringAsFixed(1)}M'
                                                : max >= 1000
                                                  ? '${(max / 2 / 1000).toStringAsFixed(1)}k'
                                                  : '${(max / 2).toInt()}',
                                              style: TextStyle(color: Colors.black45, fontSize: 11),
                                            );
                                          }
                                          if (value == max / 4 || value == 3 * max / 4) {
                                            return Text(
                                              max >= 1000000
                                                ? '${(value / 1000000).toStringAsFixed(1)}M'
                                                : max >= 1000
                                                  ? '${(value / 1000).toStringAsFixed(1)}k'
                                                  : '${value.toInt()}',
                                              style: TextStyle(color: Colors.black38, fontSize: 10),
                                            );
                                          }
                                          return const SizedBox.shrink();
                                        },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                        getTitlesWidget: (value, _) => Padding(
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
                  _sectionCard(
                    context,
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
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: screenWidth * 0.045,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Get AI insights, advanced analytics,\nand unlimited goals.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.poppins(
                              fontSize: screenWidth * 0.035,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(
                              Icons.upgrade,
                              color: Colors.white,
                            ),
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
                    );
                  },
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 0),
    );
  }

  Widget _balanceCard(
    BuildContext context,
    double total,
    double income,
    double expense,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
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
              fontSize: screenWidth * 0.065,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Income: PKR ${income.toStringAsFixed(0)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ),
              Flexible(
                child: Text(
                  'Expenses: PKR ${expense.toStringAsFixed(0)}',
                  style: const TextStyle(color: Color(0xFFFFCDD2)),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _quickCard(
    BuildContext context,
    IconData icon,
    String title,
    String subtitle,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade100),
      ),
      child: Column(
        children: [
          Icon(icon, size: screenWidth * 0.07, color: const Color(0xFF3B82F6)),
          const SizedBox(height: 8),
          Text(title, style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
          Text(
            subtitle,
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.03,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(
    BuildContext context, {
    required String title,
    required Widget child,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
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
          Text(
            title,
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: screenWidth * 0.045,
            ),
          ),
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
          Flexible(
            child: Text(
              '$label PKR ${amount.toStringAsFixed(0)}',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Color _getColor(String category) {
    switch (category) {
      case 'Food & Dining':
      case 'Food':
        return Colors.red;
      case 'Bills & Utilities':
      case 'Bills':
        return Colors.orange;
      case 'Shopping':
        return Colors.green;
      case 'Transport':
      case 'Transportation':
        return Colors.blue;
      case 'Entertainment':
        return Colors.purple;
      case 'Healthcare':
        return Colors.pink;
      case 'Education':
        return Colors.indigo;
      case 'Travel':
        return Colors.teal;
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
        title: '',
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
    final now = DateTime.now();
    final monthDate = DateTime(now.year, now.month - 5 + x, 1);
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return months[monthDate.month - 1];
  }
}
