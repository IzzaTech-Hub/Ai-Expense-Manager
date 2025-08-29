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

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline.toIso8601String(),
        'category': category,
        'color': color.value, // Store color as int
        'userId': userId,
      };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
        id: map['id'] ?? '',
        title: map['title'] ?? '',
        targetAmount: (map['targetAmount'] ?? 0).toDouble(),
        currentAmount: (map['currentAmount'] ?? 0).toDouble(),
        deadline: DateTime.parse(map['deadline']),
        category: map['category'],
        color: Color(map['color'] ?? 0xFF000000),
        userId: map['userId'] ?? '',
      );

  Map<String, dynamic> toJson() => toMap();

  factory Goal.fromJson(Map<String, dynamic> json) => Goal.fromMap(json);
}
