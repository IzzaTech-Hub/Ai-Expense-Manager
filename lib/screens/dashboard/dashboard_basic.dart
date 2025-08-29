import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../models/transaction_model.dart';
import '../../models/budget_model.dart';
import '../../services/database_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../routes/app_routes.dart';
import '../transactions/add_transaction_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  final DatabaseService _databaseService = DatabaseService();
  List<Transaction> _transactions = [];
  List<BudgetCategory> _budgetCategories = [];
  bool _isLoading = true;
  int _currentIndex = 0;
  
  // Refresh animation controller
  late AnimationController _refreshController;
  late Animation<double> _refreshAnimation;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Initialize refresh animation
    _refreshController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _refreshAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _refreshController,
      curve: Curves.easeInOut,
    ));
    
    _loadData();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _refreshController.dispose();
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

  // Method to refresh data when returning to dashboard
  void _refreshOnReturn() {
    // Add a small delay to ensure the screen is fully loaded
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        _loadData();
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Reset navigation index to dashboard (index 0) when returning to this screen
    if (_currentIndex != 0) {
      setState(() {
        _currentIndex = 0;
      });
    }
  }

  Future<void> _loadData() async {
    try {
      // Show loading state immediately
      if (mounted) {
        setState(() {
          _isLoading = true;
        });
      }

      // Get transactions and budget categories for UI updates
      final transactions = await _databaseService.getTransactions(userId: 'default_user');
      final budgetCategories = await _databaseService.getBudgetCategories(userId: 'default_user');
      
      if (mounted) {
        setState(() {
          _transactions = transactions;
          _budgetCategories = budgetCategories;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: ${e.toString()}')),
        );
      }
    }
  }

  void _onBottomNavTap(int index) {
    if (index == _currentIndex) return;
    
    setState(() {
      _currentIndex = index;
    });

    switch (index) {
      case 0:
        // Already on dashboard
        break;
      case 1:
        Navigator.pushNamed(context, AppRoutes.analytics).then((_) {
          // Refresh data when returning from analytics
          _refreshOnReturn();
        });
        break;
      case 2:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const AddTransactionScreen(),
          ),
        ).then((result) {
          // If a transaction was added successfully, refresh the dashboard
          if (result == true) {
            _loadData();
          } else {
            // Also refresh when returning, even if no transaction was added
            _refreshOnReturn();
          }
        });
        break;
      case 3:
        Navigator.pushNamed(context, AppRoutes.budget).then((_) {
          // Refresh data when returning from budget
          _refreshOnReturn();
        });
        break;
      case 4:
        Navigator.pushNamed(context, AppRoutes.aiAssistant).then((_) {
          // Refresh data when returning from AI Assistant
          _refreshOnReturn();
        });
        break;
    }
  }

  // Refresh functionality
  Future<void> _refreshData() async {
    // Haptic feedback
    HapticFeedback.lightImpact();
    
    // Start refresh animation with multiple rotations
    _refreshController.repeat();
    
    // Refresh data
    await _loadData();
    
    // Stop animation and reverse to original position
    _refreshController.stop();
    _refreshController.reverse();
    
    // Success haptic feedback
    HapticFeedback.mediumImpact();
    
    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 8),
              const Text('Balance updated successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Build refresh button with animation
  Widget _buildRefreshButton() {
    return AnimatedBuilder(
      animation: _refreshAnimation,
      builder: (context, child) {
        return Transform.rotate(
          angle: _refreshAnimation.value * 2 * 3.14159, // Full rotation
          child: Transform.scale(
            scale: _isLoading ? 0.9 : 1.0,
            child: IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: Color(0xFF3B82F6),
                size: 28,
              ),
              onPressed: _isLoading ? null : _refreshData,
              tooltip: 'Refresh Balance',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: _isLoading ? 0 : 2,
              ),
            ),
          ),
        );
      },
    );
  }

  // Optimized getters that cache calculations
  double get _totalIncome {
    if (_transactions.isEmpty) return 0;
    return _transactions
        .where((t) => t.type == 'income')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _totalExpenses {
    if (_transactions.isEmpty) return 0;
    return _transactions
        .where((t) => t.type == 'expense')
        .fold(0, (sum, t) => sum + t.amount);
  }

  double get _balance => _totalIncome - _totalExpenses;





  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Dashboard',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: [
          _buildRefreshButton(),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Card
              _buildBalanceCard(),
              const SizedBox(height: 24),
              
              // Quick Actions
              _buildQuickActions(),
              const SizedBox(height: 24),
              
              // Recent Transactions
              _buildRecentTransactions(),
              const SizedBox(height: 24),
              
              // Budget Overview
              if (_budgetCategories.isNotEmpty) ...[
                _buildBudgetOverview(),
                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),

      bottomNavigationBar: AppBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildBalanceCard() {
    return AnimatedBuilder(
      animation: _refreshAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isLoading ? 0.98 : 1.0,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Total Balance',
                  style: GoogleFonts.poppins(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '\$${NumberFormat('#,###').format(_balance)}',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Income',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '\$${NumberFormat('#,###').format(_totalIncome)}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Expenses',
                            style: GoogleFonts.poppins(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            '\$${NumberFormat('#,###').format(_totalExpenses)}',
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.add_circle_outline,
                label: 'Add Transaction',
                color: const Color(0xFF10B981),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AddTransactionScreen(),
                  ),
                ).then((result) {
                  if (result == true) {
                    _loadData();
                  } else {
                    _refreshOnReturn();
                  }
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.account_balance_wallet,
                label: 'Manage Budget',
                color: const Color(0xFFF59E0B),
                onTap: () => Navigator.pushNamed(context, AppRoutes.budget).then((_) {
                  _refreshOnReturn();
                }),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildActionButton(
                icon: Icons.psychology,
                label: 'AI Assistant Chat Bot',
                color: const Color(0xFF8B5CF6),
                onTap: () => Navigator.pushNamed(context, AppRoutes.aiAssistant).then((_) {
                  _refreshOnReturn();
                }),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions() {
    final recentTransactions = _transactions.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
          style: GoogleFonts.poppins(
                fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
            TextButton(
              onPressed: () => Navigator.pushNamed(context, AppRoutes.analytics).then((_) {
                _refreshOnReturn();
              }),
              child: Text(
                'View All',
                style: GoogleFonts.poppins(
                  color: const Color(0xFF3B82F6),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (recentTransactions.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                Icon(
                  Icons.receipt_long,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                  Text(
                  'No transactions yet',
                    style: GoogleFonts.poppins(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                  Text(
                  'Add your first transaction to get started',
                    style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          )
        else
          ...recentTransactions.map((transaction) => _buildTransactionTile(transaction)),
      ],
    );
  }

  Widget _buildTransactionTile(Transaction transaction) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: transaction.type == 'income' 
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : const Color(0xFFEF4444).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              transaction.type == 'income' ? Icons.arrow_upward : Icons.arrow_downward,
              color: transaction.type == 'income' 
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                  transaction.category,
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                if (transaction.notes != null && transaction.notes!.isNotEmpty)
                  Text(
                    transaction.notes!,
                                style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Colors.grey[600],
                                ),
                    maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                  DateFormat('MMM dd, yyyy').format(transaction.date),
                                style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        ),
          Text(
            '${transaction.type == 'income' ? '+' : '-'}\$${NumberFormat('#,###').format(transaction.amount)}',
                              style: GoogleFonts.poppins(
              fontSize: 16,
                                fontWeight: FontWeight.w600,
              color: transaction.type == 'income' 
                  ? const Color(0xFF10B981)
                  : const Color(0xFFEF4444),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildBudgetOverview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
        Text(
          'Budget Overview',
          style: GoogleFonts.poppins(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 16),
        ..._budgetCategories.map((category) => _buildBudgetTile(category)),
      ],
    );
  }

  Widget _buildBudgetTile(BudgetCategory category) {
    final progress = category.allocated > 0 ? category.spent / category.allocated : 0.0;
    final remaining = category.allocated - category.spent;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
              Text(
                category.name,
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87,
                ),
              ),
                            Text(
                '\$${NumberFormat('#,###').format(remaining)} left',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: remaining < 0 ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                ),
                            ),
                          ],
                        ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress > 1.0 ? const Color(0xFFEF4444) : Color(category.color),
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(width: 16),
              Text(
                '${(progress * 100).toStringAsFixed(0)}%',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
          const SizedBox(height: 8),
          Text(
            '\$${NumberFormat('#,###').format(category.spent)} / \$${NumberFormat('#,###').format(category.allocated)}',
            style: GoogleFonts.poppins(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }


}
