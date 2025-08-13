import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/budget_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class AnalyticsScreen extends StatelessWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Analytics',
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.all(screenWidth * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Insights into your spending patterns',
                    style: GoogleFonts.poppins(fontSize: screenWidth * 0.032),
                    ),
                  SizedBox(height: screenHeight * 0.02),
                    Row(
                      children: [
                      _totalSpentSummaryCard(screenWidth),
                      SizedBox(width: screenWidth * 0.03),
                      _dailyAverageSummaryCard(screenWidth),
                      ],
                    ),
                  SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Spending by Category',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.04,
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.015),
                  _categorySpendingList(screenWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Income by Category',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.04,
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.015),
                  _incomeByCategoryList(screenWidth, screenHeight),
                  SizedBox(height: screenHeight * 0.03),
                    Text(
                      'Monthly Trends',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      fontSize: screenWidth * 0.04,
                      ),
                    ),
                  SizedBox(height: screenHeight * 0.015),
                  _monthlyTrendsSection(screenWidth, screenHeight),
                  ],
                ),
            );
          },
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 1),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/addTransaction');
        },
        backgroundColor: const Color(0xFF3B82F6),
        child: const Icon(Icons.add, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  Widget _summaryCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color iconColor,
    required String subtext,
    required Color borderColor,
    required double screenWidth,
  }) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
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
                fontSize: screenWidth * 0.035,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: screenWidth * 0.015),
            Row(
              children: [
                Text(
                  amount,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.055,
                    fontWeight: FontWeight.bold,
                    color: iconColor,
                  ),
                ),
                const Spacer(),
                Icon(icon, size: screenWidth * 0.055, color: iconColor),
              ],
            ),
            SizedBox(height: screenWidth * 0.01),
            Text(
              subtext,
              style: GoogleFonts.poppins(fontSize: screenWidth * 0.03, color: iconColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _totalSpentSummaryCard(double screenWidth) {
    final AuthService _authService = AuthService();
    final user = _authService.currentUser;

    if (user == null) {
      return _summaryCard(
        title: 'Total Spent',
        amount: 'PKR 0',
        icon: CupertinoIcons.arrow_down_circle,
        iconColor: Colors.red,
        subtext: '',
        borderColor: Colors.yellow,
        screenWidth: screenWidth,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('budgets')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        double totalSpent = 0;
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalSpent = docs.fold(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['spent'] ?? 0).toDouble();
          });
        }
        return _summaryCard(
          title: 'Total Spent',
          amount: 'PKR ${totalSpent.toStringAsFixed(0)}',
          icon: CupertinoIcons.arrow_down_circle,
          iconColor: Colors.red,
          subtext: '',
          borderColor: Colors.yellow,
          screenWidth: screenWidth,
        );
      },
    );
  }

  Widget _dailyAverageSummaryCard(double screenWidth) {
    final AuthService _authService = AuthService();
    final user = _authService.currentUser;

    if (user == null) {
      return _summaryCard(
        title: 'Daily Average',
        amount: 'PKR 0',
        icon: CupertinoIcons.chart_bar,
        iconColor: Colors.blue,
        subtext: '',
        borderColor: Colors.yellow,
        screenWidth: screenWidth,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('budgets')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        double totalSpent = 0;
        if (snapshot.hasData) {
          final docs = snapshot.data!.docs;
          totalSpent = docs.fold(0, (sum, doc) {
            final data = doc.data() as Map<String, dynamic>;
            return sum + (data['spent'] ?? 0).toDouble();
          });
        }
        final now = DateTime.now();
        final daysPassed = now.day;
        final dailyAverage = daysPassed > 0 ? totalSpent / daysPassed : 0.0;
        return _summaryCard(
          title: 'Daily Average',
          amount: 'PKR ${dailyAverage.toStringAsFixed(0)}',
          icon: CupertinoIcons.chart_bar,
          iconColor: Colors.blue,
          subtext: '',
          borderColor: Colors.yellow,
          screenWidth: screenWidth,
        );
      },
    );
  }

  Widget _dailyComparisonCard(double screenWidth) {
    final AuthService _authService = AuthService();
    final user = _authService.currentUser;

    if (user == null) {
      return SizedBox();
    }

    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final startOfToday = DateTime(now.year, now.month, now.day);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'expense')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .snapshots(),
      builder: (context, snapshot) {
        double totalSpent = 0;
        double todaySpent = 0;
        if (snapshot.hasData) {
          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['date'] as Timestamp).toDate();
            final amount = (data['amount'] ?? 0).toDouble();
            totalSpent += amount;
            if (date.year == now.year && date.month == now.month && date.day == now.day) {
              todaySpent += amount;
            }
          }
        }
        final daysPassed = now.day;
        final dailyAverage = daysPassed > 0 ? totalSpent / daysPassed : 0.0;

        String comparison;
        if (todaySpent > dailyAverage) {
          comparison = 'More than average';
        } else if (todaySpent < dailyAverage) {
          comparison = 'Less than average';
        } else {
          comparison = 'Equal to average';
        }

        return Text(
          'Today\'s spending: PKR ${todaySpent.toStringAsFixed(0)} ($comparison)',
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.035,
            color: todaySpent > dailyAverage ? Colors.red : Colors.green,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }

  Widget _categorySpendingList(double screenWidth, double screenHeight) {
    final AuthService _authService = AuthService();
    final user = _authService.currentUser;
    
    if (user == null) {
      return Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: Colors.yellow.withOpacity(0.4)),
        ),
        child: const Center(
          child: Text('Please log in to view budget data'),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('budgets')
          .where('userId', isEqualTo: user.uid)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              border: Border.all(color: Colors.yellow.withOpacity(0.4)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }
        
        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              border: Border.all(color: Colors.yellow.withOpacity(0.4)),
            ),
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        final categories = docs.map((doc) => BudgetCategory.fromFirestore(doc)).toList();
        
        if (categories.isEmpty) {
          return Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              border: Border.all(color: Colors.yellow.withOpacity(0.4)),
            ),
            child: const Center(
              child: Text('No budget categories found. Add some budgets to see analytics.'),
            ),
          );
        }

        // Convert budget categories to analytics format (spent, allocated, percent used)
        final analyticsCategories = categories.map((cat) {
          final spent = (cat.spent ?? 0.0);
          final allocated = (cat.allocated ?? 0.0);
          final percentUsed = allocated > 0 ? (spent / allocated) * 100 : 0.0;
          return {
            'label': cat.name,
            'spent': spent,
            'allocated': allocated,
            'percent': percentUsed,
            'color': Color(cat.color),
          };
        }).toList();

        return _categoryListWithActions(analyticsCategories, showActions: false, screenWidth: screenWidth, screenHeight: screenHeight);
      },
    );
  }

  void _deleteIncomeCategory(BuildContext context, String category) async {
    final user = AuthService().currentUser;
    if (user == null) return;
    final query = await FirebaseFirestore.instance
        .collection('transactions')
        .where('userId', isEqualTo: user.uid)
        .where('type', isEqualTo: 'income')
        .where('category', isEqualTo: category)
        .get();
    for (var doc in query.docs) {
      await doc.reference.delete();
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All income transactions for $category deleted.')),
    );
  }

  void _editIncomeCategory(BuildContext context, String oldCategory) async {
    final TextEditingController controller = TextEditingController(text: oldCategory);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Edit Category'),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Enter new category name'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                final newCategory = controller.text.trim();
                if (newCategory.isNotEmpty && newCategory != oldCategory) {
                  final user = AuthService().currentUser;
                  if (user != null) {
                    final query = await FirebaseFirestore.instance
                        .collection('transactions')
                        .where('userId', isEqualTo: user.uid)
                        .where('type', isEqualTo: 'income')
                        .where('category', isEqualTo: oldCategory)
                        .get();
                    for (var doc in query.docs) {
                      await doc.reference.update({'category': newCategory});
                    }
                  }
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Category updated to $newCategory.')),
                  );
                }
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  Widget _incomeByCategoryList(double screenWidth, double screenHeight) {
    final AuthService _authService = AuthService();
    final user = _authService.currentUser;

    if (user == null) {
      return Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          color: Colors.white,
          border: Border.all(color: Colors.yellow.withOpacity(0.4)),
        ),
        child: const Center(
          child: Text('Please log in to view income data'),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .where('type', isEqualTo: 'income')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              border: Border.all(color: Colors.yellow.withOpacity(0.4)),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Container(
            padding: EdgeInsets.all(screenWidth * 0.04),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Colors.white,
              border: Border.all(color: Colors.yellow.withOpacity(0.4)),
            ),
            child: Center(child: Text('Error: ${snapshot.error}')),
          );
        }

        final docs = snapshot.data?.docs ?? [];
        Map<String, double> categoryTotals = {};
        double totalIncome = 0.0;

        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final category = data['category'] ?? 'Other';
          final amount = (data['amount'] ?? 0).toDouble();
          categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
          totalIncome += amount;
        }

        // Assign a color for each category (you can customize this)
        final List<Color> colorPalette = [
          Colors.green, Colors.blue, Colors.purple, Colors.teal, Colors.orange, Colors.grey
        ];

        int colorIndex = 0;
        final analyticsCategories = categoryTotals.entries.map((entry) {
          final percent = totalIncome > 0 ? (entry.value / totalIncome) * 100 : 0.0;
          final color = colorPalette[colorIndex % colorPalette.length];
          colorIndex++;
          return {
            'label': entry.key,
            'spent': entry.value, // For income, this is the amount received
            'allocated': totalIncome, // For progress bar, total income is the 'allocated'
            'percent': percent,
            'color': color,
          };
        }).toList();

        return _categoryListWithActions(
          analyticsCategories,
          showActions: true,
          screenWidth: screenWidth,
          screenHeight: screenHeight,
          onEdit: (category) => _editIncomeCategory(context, category),
          onDelete: (category) => _deleteIncomeCategory(context, category),
        );
      },
    );
  }

  Widget _categoryListWithActions(
    List<Map<String, dynamic>> categories, {
    bool showActions = true,
    required double screenWidth,
    required double screenHeight,
    void Function(String category)? onEdit,
    void Function(String category)? onDelete,
  }) {
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
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.012,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: screenWidth * 0.025,
                          height: screenWidth * 0.025,
                          decoration: BoxDecoration(
                            color: cat['color'],
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.025),
                        Expanded(
                          child: Text(
                            cat['label'],
                            style: GoogleFonts.poppins(fontSize: screenWidth * 0.035),
                          ),
                        ),
                        Text(
                          'PKR ${(cat['spent'] ?? 0.0).toStringAsFixed(0)} / PKR ${(cat['allocated'] ?? 0.0).toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: screenWidth * 0.032,
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          '${(cat['percent'] ?? 0.0).toStringAsFixed(1)}%',
                          style: GoogleFonts.poppins(color: Colors.grey, fontSize: screenWidth * 0.032),
                        ),
                        if (showActions) ...[
                          SizedBox(width: screenWidth * 0.01),
                        PopupMenuButton<String>(
                            icon: Icon(Icons.more_vert, size: screenWidth * 0.045),
                            onSelected: (value) {
                              if (value == 'edit' && onEdit != null) onEdit(cat['label']);
                              if (value == 'delete' && onDelete != null) onDelete(cat['label']);
                            },
                            itemBuilder: (context) => const [
                              PopupMenuItem(value: 'edit', child: Text('Edit')),
                              PopupMenuItem(value: 'delete', child: Text('Delete')),
                            ],
                          ),
                        ],
                      ],
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: ((cat['percent'] ?? 0.0) / 100).clamp(0.0, 1.0),
                        minHeight: screenHeight * 0.012,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: AlwaysStoppedAnimation<Color>(cat['color']),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _monthlyTrendsSection(double screenWidth, double screenHeight) {
    final AuthService _authService = AuthService();
    final user = _authService.currentUser;

    if (user == null) {
      return Center(child: Text('Please log in to view monthly trends'));
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('transactions')
          .where('userId', isEqualTo: user.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return CircularProgressIndicator();

        // 1. Create a map to hold data for each month.
        Map<String, Map<String, double>> monthlyData = {};

        // 2. Loop through every transaction.
        for (var doc in snapshot.data!.docs) {
          final data = doc.data() as Map<String, dynamic>;
          
          // 3. Get the transaction's date.
          final date = (data['date'] as Timestamp).toDate(); 
          
          // 4. Create a unique key for that month (e.g., "2024-05").
          final monthKey = '${date.year}-${date.month.toString().padLeft(2, '0')}';
          
          final isIncome = data['type'] == 'income';
          final amount = (data['amount'] ?? 0).toDouble();

          // 5. Add the amount to the correct month's total.
          monthlyData.putIfAbsent(monthKey, () => {'income': 0.0, 'expenses': 0.0});
          if (isIncome) {
            monthlyData[monthKey]!['income'] = (monthlyData[monthKey]!['income'] ?? 0) + amount;
          } else {
            monthlyData[monthKey]!['expenses'] = (monthlyData[monthKey]!['expenses'] ?? 0) + amount;
          }
        }

        // 6. Convert the map to a list for display.
        final sortedMonths = monthlyData.keys.toList()..sort();
        final trends = sortedMonths.map((monthKey) {
          final data = monthlyData[monthKey]!;
          return {
            'month': monthKey, // e.g., "2024-05"
            'income': data['income'],
            'expenses': data['expenses'],
          };
        }).toList();
        
        // 7. Pass the correctly grouped data to your UI widget.
        return _monthlyTrendsList(trends, screenWidth, screenHeight);
      },
    );
  }

  Widget _monthlyTrendsList(List<Map<String, dynamic>> months, double screenWidth, double screenHeight) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.yellow.withOpacity(0.4)),
      ),
      child: Column(
        children: months.map((entry) {
          final income = (entry['income'] ?? 0.0) as double;
          final expenses = (entry['expenses'] ?? 0.0) as double;
              final balance = income - expenses;
              final month = entry['month'] as String;

          return Container(
            margin: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.01,
            ),
            padding: EdgeInsets.all(screenWidth * 0.035),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  month,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    fontSize: screenWidth * 0.04,
                  ),
                ),
                SizedBox(height: screenHeight * 0.008),
                Row(
                  children: [
                    Icon(Icons.circle, size: screenWidth * 0.025, color: Colors.green),
                    SizedBox(width: screenWidth * 0.015),
                        Text(
                      'Income: PKR ${income.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.032,
                        color: Colors.green.shade700,
                      ),
                        ),
                      ],
                    ),
                SizedBox(height: screenHeight * 0.004),
                Row(
                  children: [
                    Icon(Icons.circle, size: screenWidth * 0.025, color: Colors.red),
                    SizedBox(width: screenWidth * 0.015),
                    Text(
                      'Expenses: PKR ${expenses.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.032,
                        color: Colors.red.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: screenHeight * 0.008),
                Text(
                  'Balance: PKR ${balance.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                    color: balance >= 0 ? Colors.green : Colors.red,
                    fontSize: screenWidth * 0.035,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Future<void> deleteBudgetAndTransactions(String budgetId) async {
    // Delete the budget
    await FirebaseFirestore.instance.collection('budgets').doc(budgetId).delete();

    // Delete all transactions with this budgetId
    final transactions = await FirebaseFirestore.instance
        .collection('transactions')
        .where('budgetId', isEqualTo: budgetId)
        .get();

    for (var doc in transactions.docs) {
      await doc.reference.delete();
    }
  }
}
