import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_budget_category.dart';
import 'edit_budget_category.dart';
import '../../models/budget_model.dart';
import '../../services/database_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../routes/app_routes.dart';

class BudgetScreenBasic extends StatefulWidget {
  const BudgetScreenBasic({super.key});

  @override
  State<BudgetScreenBasic> createState() => _BudgetScreenBasicState();
}

class _BudgetScreenBasicState extends State<BudgetScreenBasic> with WidgetsBindingObserver {
  final DatabaseService _databaseService = DatabaseService();
  List<BudgetCategory> _budgetCategories = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadBudgetData();
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
      _loadBudgetData();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh data when returning to this screen
    _loadBudgetData();
  }

  Future<void> _loadBudgetData() async {
    try {
      final categories = await _databaseService.getBudgetCategories();
      setState(() {
        _budgetCategories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading budget data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadBudgetData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF9FAFB),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Budget',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          LayoutBuilder(
            builder: (context, constraints) {
              final isSmallScreen = constraints.maxWidth < 400;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final result = await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const AddBudgetCategory(),
                      ),
                    );
                    if (result == true) {
                      _refreshData();
                    }
                  },
                  icon: const Icon(Icons.add, size: 18),
                  label: isSmallScreen ? const Text('Add') : const Text('Add Budget'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    textStyle: GoogleFonts.poppins(fontSize: isSmallScreen ? 12 : 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: isSmallScreen ? 8 : 12,
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: _budgetCategories.isEmpty
            ? LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.account_balance_wallet_outlined,
                              size: constraints.maxHeight < 600 ? 60 : 80,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: constraints.maxHeight < 600 ? 12 : 16),
                            Text(
                              'No budget categories found',
                              style: GoogleFonts.poppins(
                                fontSize: constraints.maxHeight < 600 ? 16 : 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                              ),
                            ),
                            SizedBox(height: constraints.maxHeight < 600 ? 6 : 8),
                            Text(
                              'Tap the "+" button to add your first budget',
                              style: GoogleFonts.poppins(
                                fontSize: constraints.maxHeight < 600 ? 12 : 14,
                                color: Colors.grey[600],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _headerCard(),
                  const SizedBox(height: 20),
                  ..._budgetCategories.map((cat) => _categoryCard(context, cat)),
                  const SizedBox(height: 20),
                  _budgetTip(),
                  const SizedBox(height: 60), // Reduced bottom padding
                ],
              ),
      ),
              bottomNavigationBar: AppBottomNavBar(
          currentIndex: 3,
          onTap: (index) {
            switch (index) {
              case 0:
                Navigator.pushReplacementNamed(context, AppRoutes.dashboard);
                break;
              case 1:
                Navigator.pushReplacementNamed(context, AppRoutes.analytics);
                break;
              case 2:
                Navigator.pushReplacementNamed(context, AppRoutes.addTransaction);
                break;
              case 3:
                // Already on budget
                break;
              case 4:
                Navigator.pushReplacementNamed(context, AppRoutes.aiAssistant);
                break;
            }
          },
        ),
    );
  }

  Widget _headerCard() {
    final double totalAllocated = _budgetCategories.fold(0, (sum, cat) => sum + cat.allocated);
    final double totalSpent = _budgetCategories.fold(0, (sum, cat) => sum + cat.spent);
    final double remaining = totalAllocated - totalSpent;
    final double progress = totalAllocated == 0 ? 0 : totalSpent / totalAllocated;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Total Budget Overview',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Allocated',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'PKR ${totalAllocated.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                      'Spent',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'PKR ${totalSpent.toStringAsFixed(0)}',
                      style: GoogleFonts.poppins(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
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
                      'Remaining',
                      style: GoogleFonts.poppins(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'PKR ${remaining.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                        color: remaining >= 0 ? Colors.white : Colors.red[200],
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                    'Progress',
                    style: GoogleFonts.poppins(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                backgroundColor: Colors.white.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  progress > 0.8 ? Colors.red[200]! : Colors.white,
                ),
                minHeight: 8,
              ),
            ],
            ),
        ],
      ),
    );
  }

  Widget _categoryCard(BuildContext context, BudgetCategory category) {
    final progress = category.allocated > 0 ? category.spent / category.allocated : 0.0;
    final remaining = category.allocated - category.spent;
    final isOverBudget = remaining < 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
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
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Color(category.color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(
            Icons.account_balance_wallet,
            color: Color(category.color),
            size: 24,
          ),
        ),
        title: Text(
          category.name,
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'PKR ${category.spent.toStringAsFixed(0)} / PKR ${category.allocated.toStringAsFixed(0)}',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Text(
                  '${(progress * 100).toStringAsFixed(1)}%',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: progress > 0.8 ? Colors.red : Colors.green,
            ),
          ),
        ],
      ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? Colors.red : Color(category.color),
              ),
              minHeight: 6,
            ),
            const SizedBox(height: 8),
            Text(
              isOverBudget
                  ? 'Over budget by PKR ${remaining.abs().toStringAsFixed(0)}'
                  : 'PKR ${remaining.toStringAsFixed(0)} remaining',
              style: GoogleFonts.poppins(
                fontSize: 12,
                color: isOverBudget ? Colors.red : Colors.green,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert),
          onSelected: (value) async {
            if (value == 'edit') {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => EditBudgetCategory(
                    categoryId: category.id,
                    initialName: category.name,
                    initialLimit: category.allocated,
                    spentAmount: category.spent,
                    category: category.toMap(),
                  ),
                ),
              );
              if (result == true) {
                _refreshData();
              }
            } else if (value == 'delete') {
              _showDeleteDialog(context, category);
            }
          },
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'edit',
              child: Row(
                children: [
                  Icon(Icons.edit, size: 18),
                  SizedBox(width: 8),
                  Text('Edit'),
                ],
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, size: 18, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Delete', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, BudgetCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Budget Category'),
        content: Text(
          'Are you sure you want to delete "${category.name}"? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteBudgetCategory(category.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteBudgetCategory(String categoryId) async {
    try {
      await _databaseService.deleteBudgetCategory(categoryId);
      _refreshData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget category deleted successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting budget category: $e')),
        );
      }
    }
  }

  Widget _budgetTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lightbulb_outline, color: Colors.blue[700]),
          const SizedBox(width: 12),
              Expanded(
                child: Text(
              'Tip: Try to keep your spending below 80% of your allocated budget to maintain financial health.',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                color: Colors.blue[700],
              ),
              ),
            ),
        ],
      ),
    );
  }
}
