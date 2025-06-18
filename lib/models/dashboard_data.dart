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
}
