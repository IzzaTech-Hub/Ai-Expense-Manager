import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'add_budget_category.dart';
import 'edit_budget_category.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/budget_model.dart';
import '../../services/auth_service.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class BudgetScreenBasic extends StatelessWidget {
  const BudgetScreenBasic({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthService _authService = AuthService();
    final user = _authService.currentUser;
    
    // If user is not logged in (guest mode), show demo data
    if (user == null) {
      return _buildGuestBudget(context);
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
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const AddBudgetCategory(),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.poppins(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('budgets')
            .where('userId', isEqualTo: user.uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: \\${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          final categories = docs.map((doc) => BudgetCategory.fromFirestore(doc)).toList();
          if (categories.isEmpty) {
            return Center(
              child: Text('No budget categories found. Tap "+" to add.'),
            );
          }
          // Calculate totals
          final double totalAllocated = categories.fold(0, (sum, cat) => sum + cat.allocated);
          final double totalSpent = categories.fold(0, (sum, cat) => sum + cat.spent);
          final double remaining = totalAllocated - totalSpent;
          final double progress = totalAllocated == 0 ? 0 : totalSpent / totalAllocated;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _headerCard(totalAllocated, totalSpent, remaining, progress),
              const SizedBox(height: 20),
              ...categories.map((cat) => _categoryCard(context, cat)),
              const SizedBox(height: 20),
              _budgetTip(),
              const SizedBox(height: 80),
            ],
          );
        },
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _headerCard(
    double allocated,
    double spent,
    double remaining,
    double progress,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Monthly Budget',
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _budgetDetail("Allocated", allocated, Colors.white),
              _budgetDetail("Spent", spent, Colors.white),
              _budgetDetail("Remaining", remaining, Colors.white),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _budgetDetail(String label, double value, Color color) {
    return Column(
      children: [
        Text(
          'PKR ${value.toStringAsFixed(0)}',
          style: GoogleFonts.poppins(
            color: color,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(label, style: GoogleFonts.poppins(color: color, fontSize: 12)),
      ],
    );
  }

  Widget _categoryCard(BuildContext context, BudgetCategory cat) {
    final double percentUsed = cat.allocated == 0 ? 0 : cat.spent / cat.allocated;
    final bool isOver = percentUsed > 1;
    final bool isWarning = percentUsed >= 0.9;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.yellow.shade100),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.category, color: Color(cat.color)),
                  const SizedBox(width: 8),
                  Text(
                    cat.name,
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  if (isOver)
                    const Icon(Icons.error_outline, color: Colors.red)
                  else if (isWarning)
                    const Icon(
                      Icons.warning_amber_outlined,
                      color: Colors.orange,
                    )
                  else
                    const Icon(Icons.check_circle, color: Colors.green),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(
                      Icons.edit,
                      size: 18,
                      color: Colors.black45,
                    ),
                    tooltip: 'Edit Category',
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => EditBudgetCategory(
                            categoryId: cat.id,
                            initialName: cat.name,
                            initialLimit: cat.allocated,
                            spentAmount: cat.spent,
                            category: {},
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: percentUsed > 1 ? 1 : percentUsed,
            minHeight: 8,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(Color(cat.color)),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  '${(percentUsed * 100).toStringAsFixed(0)}% Used',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black87),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  isOver
                      ? 'Over: PKR ${(cat.spent - cat.allocated).toStringAsFixed(0)}'
                      : 'Remaining: PKR ${cat.remaining.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: isOver ? Colors.red : Colors.green,
                  ),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Allocated: PKR ${cat.allocated.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
              Text(
                'Spent: PKR ${cat.spent.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
              ),
            ],
          ),
          if (isOver || isWarning)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Budget warning: ${(percentUsed * 100).toStringAsFixed(0)}% used',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _budgetTip() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, color: Colors.amber),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Try to keep each category under 90% to maintain financial flexibility',
              style: GoogleFonts.poppins(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestBudget(BuildContext context) {
    // Demo budget categories for guest mode
    final demoBudgets = [
      {
        'name': 'Food & Dining',
        'allocated': 4000.0,
        'spent': 3000.0,
        'color': Colors.red,
      },
      {
        'name': 'Transportation',
        'allocated': 2500.0,
        'spent': 2000.0,
        'color': Colors.blue,
      },
      {
        'name': 'Shopping',
        'allocated': 3000.0,
        'spent': 2500.0,
        'color': Colors.green,
      },
      {
        'name': 'Bills & Utilities',
        'allocated': 2500.0,
        'spent': 2500.0,
        'color': Colors.orange,
      },
    ];

    final totalAllocated = demoBudgets.fold(0.0, (sum, budget) => sum + (budget['allocated'] as double));
    final totalSpent = demoBudgets.fold(0.0, (sum, budget) => sum + (budget['spent'] as double));
    final totalProgress = totalAllocated > 0 ? totalSpent / totalAllocated : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Budget (Demo)',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Sign in to add real budgets!'),
                  ),
                );
              },
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add Budget'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                textStyle: GoogleFonts.poppins(),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headerCard(totalAllocated, totalSpent, totalAllocated - totalSpent, totalProgress),
            const SizedBox(height: 24),
            Text(
              'Budget Categories (Demo)',
              style: GoogleFonts.poppins(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...demoBudgets.map((budget) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _demoBudgetCard(budget),
            )).toList(),
            const SizedBox(height: 16),
            _budgetTip(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue.shade700),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'This is demo data. Sign in to create and track real budgets!',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _demoBudgetCard(Map<String, dynamic> budget) {
    final name = budget['name'] as String;
    final allocated = budget['allocated'] as double;
    final spent = budget['spent'] as double;
    final color = budget['color'] as Color;
    
    final percentUsed = allocated > 0 ? spent / allocated : 0.0;
    final isOver = percentUsed > 1.0;
    final isWarning = percentUsed > 0.9;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: Colors.yellow.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                'PKR ${(allocated - spent).toStringAsFixed(0)} left',
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  color: isOver ? Colors.red : Colors.green,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentUsed.clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOver ? Colors.red : (isWarning ? Colors.orange : color),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Allocated: PKR ${allocated.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  'Spent: PKR ${spent.toStringAsFixed(0)}',
                  style: GoogleFonts.poppins(fontSize: 12, color: Colors.black54),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
          if (isOver || isWarning)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  const Icon(Icons.warning, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Budget warning: ${(percentUsed * 100).toStringAsFixed(0)}% used',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
