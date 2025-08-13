import 'package:flutter/material.dart';

class Goal {
  final String id;
  final String title;
  final double targetAmount;
  final double currentAmount;
  final DateTime deadline;
  final String? category;
  final Color color; // <-- Make sure this is Color, not int
  final String userId;

  Goal({
    required this.id,
    required this.title,
    required this.targetAmount,
    required this.currentAmount,
    required this.deadline,
    this.category,
    required this.color,
    required this.userId,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline.toIso8601String(),
        'category': category,
        'color': color.value, // Store color as int
        'userId': userId,
      };

  factory Goal.fromJson(Map<String, dynamic> json) => Goal(
        id: json['id'] ?? '',
        title: json['title'] ?? '',
        targetAmount: (json['targetAmount'] ?? 0).toDouble(),
        currentAmount: (json['currentAmount'] ?? 0).toDouble(),
        deadline: DateTime.parse(json['deadline']),
        category: json['category'],
        color: Color(json['color'] ?? 0xFF000000),
        userId: json['userId'] ?? '',
      );

  // Add fromMap/toMap if needed, converting color to/from int if using database
}
