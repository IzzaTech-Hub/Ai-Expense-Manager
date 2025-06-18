import 'dart:ui';

class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String? category;
  final Color color;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    this.category,
    required this.color,
  });

  // ✅ Add this getter to calculate progress between 0 and 1
  double get progress {
    if (targetAmount == 0) return 0;
    return (currentAmount / targetAmount).clamp(0.0, 1.0);
  }
}
