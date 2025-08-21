import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../models/goal_model.dart';
import '../../routes/app_routes.dart';
import '../../services/goal_service.dart';
import '../../services/auth_service.dart';

class GoalScreenBasic extends StatelessWidget {
  GoalScreenBasic({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final user = AuthService().currentUser;
    final userId = user?.uid;

    // If user is not logged in (guest mode), show demo data
    if (userId == null) {
      return _buildGuestGoals(context, screenWidth);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboardBasic');
          },
        ),
        centerTitle: true,
        title: Text(
          'Goals',
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: StreamBuilder<List<Goal>>(
            stream: GoalService().getGoalsStream(userId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              }
              final goals = snapshot.data ?? [];
              double avgProgress = goals.isNotEmpty
                  ? goals
                          .map((g) => g.currentAmount / g.targetAmount)
                          .reduce((a, b) => a + b) /
                      goals.length
                  : 0.0;
                  return SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.04,
                      vertical: screenWidth * 0.04,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.arrow_back),
                                    onPressed: () => Navigator.of(context).pop(),
                                  ),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Financial Goals',
                                          style: GoogleFonts.poppins(
                                            fontSize: screenWidth * 0.05,
                                            fontWeight: FontWeight.w700,
                                            color: Colors.black,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Track your progress towards your dreams',
                                          style: GoogleFonts.poppins(
                                            fontSize: screenWidth * 0.035,
                                            color: Colors.black54,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
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
                                padding: EdgeInsets.symmetric(
                                  horizontal: screenWidth * 0.04,
                                  vertical: screenWidth * 0.025,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 20,
                          ),
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
                                '\\${goals.length}',
                                Colors.blue,
                              ),
                              _summaryTile(
                                Icons.trending_up,
                                'Avg Progress',
                                '\\${(avgProgress * 100).toStringAsFixed(0)}%',
                                Colors.green,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (goals.isEmpty)
                          Center(child: Text('No goals found.'))
                        else
                          ...goals.map((goal) => _goalCard(context, goal)).toList(),
                      ],
                    ),
                  );
                },
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 3, // Assuming 'Goals' is 3rd or change as needed
        selectedItemColor: const Color(0xFF3B82F6),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, AppRoutes.dashboardBasic);
              break;
            case 1:
              Navigator.pushNamed(context, AppRoutes.analyticsBasic);
              break;
            case 2:
              Navigator.pushNamed(context, AppRoutes.addTransaction);
              break;
            case 3:
              Navigator.pushNamed(context, AppRoutes.budgetScreenBasic);
              break;
            case 4:
              Navigator.pushNamed(context, AppRoutes.profileScreen);
              break;
          }
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
    final screenWidth = MediaQuery.of(context).size.width;

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
                onSelected: (value) async {
                  if (value == 'edit') {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.editGoalBasic,
                      arguments: goal,
                    );
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Delete Goal'),
                        content: const Text('Are you sure you want to delete this goal?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Delete', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      try {
                        await GoalService().deleteGoal(goal.id);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Goal deleted successfully')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed to delete goal: $e')),
                        );
                      }
                    }
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

  Widget _buildGuestGoals(BuildContext context, double screenWidth) {
    // Demo goals data for guest mode
    final demoGoals = [
      {
        'name': 'Emergency Fund',
        'targetAmount': 50000.0,
        'currentAmount': 25000.0,
        'deadline': DateTime.now().add(Duration(days: 120)),
        'color': Colors.blue,
      },
      {
        'name': 'Vacation to Europe',
        'targetAmount': 150000.0,
        'currentAmount': 75000.0,
        'deadline': DateTime.now().add(Duration(days: 200)),
        'color': Colors.green,
      },
      {
        'name': 'New Laptop',
        'targetAmount': 80000.0,
        'currentAmount': 60000.0,
        'deadline': DateTime.now().add(Duration(days: 45)),
        'color': Colors.orange,
      },
    ];

    final double avgProgress = demoGoals.fold(0.0, (sum, goal) => 
        sum + ((goal['currentAmount'] as double) / (goal['targetAmount'] as double))) / demoGoals.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF9FAFB),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/dashboardBasic');
          },
        ),
        centerTitle: true,
        title: Text(
          'Goals (Demo)',
          style: GoogleFonts.poppins(
            fontSize: screenWidth * 0.045,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.04,
            vertical: screenWidth * 0.04,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Your Goals (Demo)',
                      style: GoogleFonts.poppins(
                        fontSize: screenWidth * 0.06,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Sign in to create real goals!'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Goal'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      foregroundColor: Colors.white,
                      textStyle: GoogleFonts.poppins(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: screenWidth * 0.06),
              _buildDemoProgressCard(avgProgress, screenWidth),
              SizedBox(height: screenWidth * 0.06),
              Text(
                'All Goals',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.05,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: screenWidth * 0.04),
              ...demoGoals.map((goal) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildDemoGoalCard(goal, screenWidth),
              )).toList(),
              SizedBox(height: screenWidth * 0.04),
              Container(
                padding: EdgeInsets.all(screenWidth * 0.04),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.blue.shade700),
                    SizedBox(width: screenWidth * 0.03),
                    Expanded(
                      child: Text(
                        'This is demo data. Sign in to create and track real financial goals!',
                        style: GoogleFonts.poppins(
                          fontSize: screenWidth * 0.035,
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
      ),
    );
  }

  Widget _buildDemoProgressCard(double avgProgress, double screenWidth) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overall Progress',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.045,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            '${(avgProgress * 100).toStringAsFixed(1)}%',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.08,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: screenWidth * 0.04),
          LinearProgressIndicator(
            value: avgProgress,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            minHeight: 8,
          ),
          SizedBox(height: screenWidth * 0.02),
          Text(
            'You\'re doing great! Keep saving to reach your goals.',
            style: GoogleFonts.poppins(
              fontSize: screenWidth * 0.035,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDemoGoalCard(Map<String, dynamic> goal, double screenWidth) {
    final name = goal['name'] as String;
    final targetAmount = goal['targetAmount'] as double;
    final currentAmount = goal['currentAmount'] as double;
    final deadline = goal['deadline'] as DateTime;
    final color = goal['color'] as Color;
    
    final progress = currentAmount / targetAmount;
    final remaining = targetAmount - currentAmount;
    final daysLeft = deadline.difference(DateTime.now()).inDays;

    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Text(
                  name,
                  style: GoogleFonts.poppins(
                    fontSize: screenWidth * 0.045,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'PKR ${remaining.toStringAsFixed(0)} left',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.035,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.03),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PKR ${currentAmount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                'PKR ${targetAmount.toStringAsFixed(0)}',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.04,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          SizedBox(height: screenWidth * 0.02),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
          SizedBox(height: screenWidth * 0.02),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${(progress * 100).toStringAsFixed(1)}% completed',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.032,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                '$daysLeft days left',
                style: GoogleFonts.poppins(
                  fontSize: screenWidth * 0.032,
                  color: daysLeft < 30 ? Colors.red : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
