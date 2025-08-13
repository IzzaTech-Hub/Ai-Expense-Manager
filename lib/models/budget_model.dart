import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class BudgetCategory {
  final String id;
  final String name;
  final double allocated;
  final double spent;
  final String userId;
  final int color;
  final DateTime createdAt;

  BudgetCategory({
    required this.id,
    required this.name,
    required this.allocated,
    required this.spent,
    required this.userId,
    required this.color,
    required this.createdAt,
  });

  double get remaining => allocated - spent;

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'allocated': allocated,
        'spent': spent,
        'userId': userId,
        'color': color,
        'createdAt': createdAt,
      };

  factory BudgetCategory.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BudgetCategory(
      id: doc.id,
      name: data['name'] ?? '',
      allocated: (data['allocated'] ?? 0).toDouble(),
      spent: (data['spent'] ?? 0).toDouble(),
      userId: data['userId'] ?? '',
      color: data['color'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
