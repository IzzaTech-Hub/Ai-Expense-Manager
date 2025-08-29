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

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'allocated': allocated,
        'spent': spent,
        'userId': userId,
        'color': color,
        'createdAt': createdAt.toIso8601String(),
      };

  factory BudgetCategory.fromMap(Map<String, dynamic> map) {
    return BudgetCategory(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      allocated: (map['allocated'] ?? 0).toDouble(),
      spent: (map['spent'] ?? 0).toDouble(),
      userId: map['userId'] ?? '',
      color: map['color'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => toMap();
  factory BudgetCategory.fromJson(Map<String, dynamic> json) => BudgetCategory.fromMap(json);
}
