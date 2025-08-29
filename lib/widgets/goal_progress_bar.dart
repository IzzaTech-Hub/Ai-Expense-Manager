import 'package:flutter/material.dart';
import '../models/goal_model.dart';

class GoalProgressBar extends StatelessWidget {
  final Goal goal;
  const GoalProgressBar({super.key, required this.goal});

  @override
  Widget build(BuildContext context) {
    double progress = goal.targetAmount > 0 
        ? (goal.currentAmount / goal.targetAmount).clamp(0, 1)
        : 0;
    
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: LinearProgressIndicator(
        value: progress,
        minHeight: 10,
        backgroundColor: Colors.grey.shade300,
        valueColor: AlwaysStoppedAnimation<Color>(goal.color),
      ),
    );
  }
}
