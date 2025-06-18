import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/goal_model.dart';
import '../../routes/app_routes.dart';

class GoalScreenBasic extends StatelessWidget {
  final List<Goal> goals = [
    Goal(
      id: '1',
      title: 'Emergency Fund',
      targetAmount: 10000,
      currentAmount: 6500,
      deadline: DateTime(2024, 12, 31),
      category: 'Savings',
      color: Colors.blue,
    ),
    Goal(
      id: '2',
      title: 'Vacation to Europe',
      targetAmount: 5000,
      currentAmount: 2800,
      deadline: DateTime(2024, 9, 15),
      category: 'Travel',
      color: Colors.green,
    ),
    Goal(
      id: '3',
      title: 'New Laptop',
      targetAmount: 2000,
      currentAmount: 1200,
      deadline: DateTime(2024, 8, 1),
      category: 'Electronics',
      color: Colors.purple,
    ),
  ];

  GoalScreenBasic({super.key});

  @override
  Widget build(BuildContext context) {
    double avgProgress =
        goals.isNotEmpty
            ? goals
                    .map((g) => g.currentAmount / g.targetAmount)
                    .reduce((a, b) => a + b) /
                goals.length
            : 0.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 4),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Financial Goals',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Track your progress towards your dreams',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.createGoalBasic);
                },
                icon: const Icon(Icons.add, size: 18, color: Colors.white),
                label: Text(
                  'Add Goal',
                  style: GoogleFonts.poppins(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Summary Card
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.yellow.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12.withOpacity(0.05),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _summaryTile(
                  Icons.track_changes,
                  'Active Goals',
                  '${goals.length}',
                  Colors.blue,
                ),
                _summaryTile(
                  Icons.trending_up,
                  'Avg Progress',
                  '${(avgProgress * 100).toStringAsFixed(0)}%',
                  Colors.green,
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          for (var goal in goals) _goalCard(context, goal),
          const SizedBox(height: 16),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.add_circle), label: 'Add'),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Budget',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  Widget _summaryTile(IconData icon, String label, String value, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withOpacity(0.15),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: GoogleFonts.poppins(fontSize: 13, color: Colors.black54),
        ),
      ],
    );
  }

  Widget _goalCard(BuildContext context, Goal goal) {
    double progress = goal.currentAmount / goal.targetAmount;
    bool isOverdue = goal.deadline.isBefore(DateTime.now());

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.yellow.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title and menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: goal.color,
                    child: const Icon(
                      Icons.track_changes,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal.title,
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        goal.category ?? '',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'edit') {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.editGoalBasic,
                      arguments: goal,
                    );
                  } else if (value == 'delete') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Delete tapped")),
                    );
                  }
                },
                itemBuilder:
                    (context) => const [
                      PopupMenuItem(value: 'edit', child: Text('Edit')),
                      PopupMenuItem(value: 'delete', child: Text('Delete')),
                    ],
              ),
            ],
          ),

          const SizedBox(height: 12),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Target ₨${goal.targetAmount.toStringAsFixed(0)}',
              style: GoogleFonts.poppins(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text('Progress', style: GoogleFonts.poppins(fontSize: 13)),
          const SizedBox(height: 4),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(goal.color),
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(0)}% Complete',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '₨${goal.currentAmount.toStringAsFixed(0)} / ₨${goal.targetAmount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              const Icon(Icons.calendar_today, size: 14, color: Colors.black45),
              const SizedBox(width: 4),
              Text(
                isOverdue
                    ? 'Overdue (${_formatDate(goal.deadline)})'
                    : _formatDate(goal.deadline),
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  color: isOverdue ? Colors.red : Colors.black54,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // ✅ Add Money Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.add, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.addMoneyToGoal,
                  arguments: goal,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: goal.color,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              label: Text(
                'Add Money to Goal',
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}
