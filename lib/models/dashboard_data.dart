class DashboardData {
  final double totalBalance;
  final double totalIncome;
  final double totalExpenses;
  final double budgetLimit;
  final Map<String, double> expenseCategories;
  final List<double> monthlyIncome;
  final List<double> monthlyExpense;

  DashboardData({
    required this.totalBalance,
    required this.totalIncome,
    required this.totalExpenses,
    required this.budgetLimit,
    required this.expenseCategories,
    required this.monthlyIncome,
    required this.monthlyExpense,
  });

  /// ✅ Factory constructor to create from optional map (useful for Firestore or fallback)
  factory DashboardData.fromMap(Map<String, dynamic> data) {
    return DashboardData(
      totalBalance: (data['totalBalance'] ?? 0).toDouble(),
      totalIncome: (data['totalIncome'] ?? 0).toDouble(),
      totalExpenses: (data['totalExpenses'] ?? 0).toDouble(),
      budgetLimit: (data['budgetLimit'] ?? 0).toDouble(),
      expenseCategories: Map<String, double>.from(
        (data['expenseCategories'] ?? {}) as Map,
      ),
      monthlyIncome: List<double>.from(
        (data['monthlyIncome'] ?? []).map((e) => e.toDouble()),
      ),
      monthlyExpense: List<double>.from(
        (data['monthlyExpense'] ?? []).map((e) => e.toDouble()),
      ),
    );
  }

  /// ✅ Convert object to map (optional for saving in Firestore)
  Map<String, dynamic> toMap() {
    return {
      'totalBalance': totalBalance,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'budgetLimit': budgetLimit,
      'expenseCategories': expenseCategories,
      'monthlyIncome': monthlyIncome,
      'monthlyExpense': monthlyExpense,
    };
  }
}
