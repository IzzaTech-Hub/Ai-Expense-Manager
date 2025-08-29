import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/cupertino.dart';
import '../../models/budget_model.dart';
import '../../services/database_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  List<BudgetCategory> _budgetCategories = [];
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.resumed) {
      // Refresh data when app becomes active
      _loadData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      // Show loading state immediately
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Load data in parallel to improve performance
      final budgetCategories = await _databaseService.getBudgetCategories();
      final transactions = await _databaseService.getTransactions();
      
      if (mounted) {
        setState(() {
          _budgetCategories = budgetCategories;
          _transactions = transactions.map((t) => t.toMap()).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading analytics data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        automaticallyImplyLeading: false,
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
                  
                  // Spending by Category Section
                  _buildSectionHeader('Spending by Category', screenWidth),
                  SizedBox(height: screenHeight * 0.015),
                  _categorySpendingList(screenWidth),
                  SizedBox(height: screenHeight * 0.03),
                  
                  // Income by Category Section
                  _buildSectionHeader('Income by Category', screenWidth),
                  SizedBox(height: screenHeight * 0.015),
                  _incomeByCategoryList(screenWidth),
                  ],
                ),
            );
          },
        ),
      ),
              bottomNavigationBar: AppBottomNavBar(
          currentIndex: 1,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                break;
              case 1:
                // Already on analytics
                break;
              case 2:
                Navigator.pushReplacementNamed(context, AppRoutes.addTransaction);
                break;
              case 3:
                Navigator.pushReplacementNamed(context, AppRoutes.budget);
                break;
              case 4:
                Navigator.pushReplacementNamed(context, AppRoutes.aiAssistant);
                break;
            }
          },
        ),

    );
  }

  Widget _buildSectionHeader(String title, double screenWidth) {
    return Text(
      title,
      style: GoogleFonts.poppins(
        fontWeight: FontWeight.w600,
        fontSize: screenWidth * 0.04,
      ),
    );
  }

  Widget _totalSpentSummaryCard(double screenWidth) {
    final totalSpent = _budgetCategories.fold(0.0, (sum, cat) => sum + cat.spent);
    
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Spent',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.032,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              'PKR ${totalSpent.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: const Color(0xFFEF4444),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _dailyAverageSummaryCard(double screenWidth) {
    final totalSpent = _budgetCategories.fold(0.0, (sum, cat) => sum + cat.spent);
    final dailyAverage = totalSpent / 30; // Assuming 30 days
    
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(screenWidth * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Average',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.032,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: screenWidth * 0.02),
            Text(
              'PKR ${dailyAverage.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: screenWidth * 0.045,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF3B82F6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categorySpendingList(double screenWidth) {
    final expenseCategories = _budgetCategories.where((cat) => cat.spent > 0).toList();
    
    if (expenseCategories.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No spending data available',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: expenseCategories.map((category) {
          final percentage = (category.spent / _budgetCategories.fold(0.0, (sum, cat) => sum + cat.spent)) * 100;
          
              return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Color(category.color),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                      Text(
                        category.name,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}% of total',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                          ),
                        ),
                        Text(
                  'PKR ${category.spent.toStringAsFixed(0)}',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                    color: const Color(0xFFEF4444),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _incomeByCategoryList(double screenWidth) {
    final incomeTransactions = _transactions.where((t) => t['type'] == 'income').toList();
    
    if (incomeTransactions.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Text(
            'No income data available',
            style: GoogleFonts.poppins(color: Colors.grey[600]),
          ),
        ),
      );
    }

    // Group income by category
    Map<String, double> incomeByCategory = {};
    for (var transaction in incomeTransactions) {
      final category = transaction['category'] as String;
      final amount = (transaction['amount'] as num).toDouble();
      incomeByCategory[category] = (incomeByCategory[category] ?? 0) + amount;
    }

    final totalIncome = incomeByCategory.values.fold(0.0, (sum, amount) => sum + amount);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: incomeByCategory.entries.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = (amount / totalIncome) * 100;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                        Text(
                        category,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}% of total',
                        style: GoogleFonts.poppins(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'PKR ${amount.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF10B981),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
      ),
    );
  }




}
