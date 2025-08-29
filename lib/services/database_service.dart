import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart' as app_models;
import '../models/budget_model.dart';
import '../models/goal_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;

  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      String path = join(await getDatabasesPath(), 'expense_manager.db');
      print('Database path: $path');
      final db = await openDatabase(
        path,
        version: 1,
        onCreate: _onCreate,
      );
      print('Database initialized successfully');
      return db;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create users table
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        email TEXT,
        createdAt TEXT NOT NULL
      )
    ''');

    // Create transactions table
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create budget_categories table
    await db.execute('''
      CREATE TABLE budget_categories (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        allocated REAL NOT NULL,
        spent REAL NOT NULL,
        userId TEXT NOT NULL,
        color INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create goals table
    await db.execute('''
      CREATE TABLE goals (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        targetAmount REAL NOT NULL,
        currentAmount REAL NOT NULL,
        deadline TEXT NOT NULL,
        category TEXT NOT NULL,
        color INTEGER NOT NULL,
        userId TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Create ai_chat_history table
    await db.execute('''
      CREATE TABLE ai_chat_history (
        id TEXT PRIMARY KEY,
        userId TEXT NOT NULL,
        message TEXT NOT NULL,
        response TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (userId) REFERENCES users (id)
      )
    ''');

    // Insert default user with zero values
    await db.insert('users', {
      'id': 'default_user',
      'name': 'User',
      'email': 'user@example.com',
      'createdAt': DateTime.now().toIso8601String(),
    });

    // Create indexes for better performance
    await _createIndexes(db);
  }

  Future<void> _createIndexes(Database db) async {
    // Index for transactions by user and date (most common query)
    await db.execute('''
      CREATE INDEX idx_transactions_user_date 
      ON transactions(userId, date DESC)
    ''');

    // Index for transactions by user and type
    await db.execute('''
      CREATE INDEX idx_transactions_user_type 
      ON transactions(userId, type)
    ''');

    // Index for budget categories by user
    await db.execute('''
      CREATE INDEX idx_budget_user 
      ON budget_categories(userId)
    ''');

    // Index for goals by user
    await db.execute('''
      CREATE INDEX idx_goals_user 
      ON goals(userId)
    ''');

    // Index for chat history by user and timestamp
    await db.execute('''
      CREATE INDEX idx_chat_user_timestamp 
      ON ai_chat_history(userId, timestamp DESC)
    ''');
  }

  // User operations
  Future<void> insertUser(User user) async {
    final db = await database;
    await db.insert('users', user.toMap());
  }

  Future<User?> getUser(String id) async {
    try {
      final db = await database;
      print('Querying user with ID: $id');
      final maps = await db.query('users', where: 'id = ?', whereArgs: [id]);
      print('Found ${maps.length} users');
      if (maps.isNotEmpty) {
        final user = User.fromMap(maps.first);
        print('User loaded: ${user.name}');
        return user;
      }
      print('No user found with ID: $id');
      return null;
    } catch (e) {
      print('Error getting user: $e');
      rethrow;
    }
  }

  Future<void> updateUser(User user) async {
    final db = await database;
    await db.update('users', user.toMap(), where: 'id = ?', whereArgs: [user.id]);
  }

  // Transaction operations
  Future<void> insertTransaction(app_models.Transaction transaction) async {
    final db = await database;
    await db.insert('transactions', transaction.toMap());
  }

  // Optimized method using compute() for heavy operations
  Future<List<app_models.Transaction>> getTransactions({String? userId}) async {
    final db = await database;
    final maps = await db.query(
      'transactions',
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'date DESC',
    );
    
    // Use compute() to parse transactions in background
    return await compute(_parseTransactions, maps);
  }

  // Background method for parsing transactions
  static List<app_models.Transaction> _parseTransactions(List<Map<String, dynamic>> maps) {
    return List<app_models.Transaction>.from(
      maps.map((map) => app_models.Transaction.fromMap(map))
    );
  }

  Future<void> updateTransaction(app_models.Transaction transaction) async {
    final db = await database;
    await db.update('transactions', transaction.toMap(), where: 'id = ?', whereArgs: [transaction.id]);
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Budget operations
  Future<void> insertBudgetCategory(BudgetCategory category) async {
    final db = await database;
    await db.insert('budget_categories', category.toMap());
  }

  // Optimized method for budget categories
  Future<List<BudgetCategory>> getBudgetCategories({String? userId}) async {
    final db = await database;
    final maps = await db.query(
      'budget_categories',
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
    );
    
    // Use compute() to parse budget categories in background
    return await compute(_parseBudgetCategories, maps);
  }

  // Background method for parsing budget categories
  static List<BudgetCategory> _parseBudgetCategories(List<Map<String, dynamic>> maps) {
    return List<BudgetCategory>.from(
      maps.map((map) => BudgetCategory.fromMap(map))
    );
  }

  Future<void> updateBudgetCategory(BudgetCategory category) async {
    final db = await database;
    await db.update('budget_categories', category.toMap(), where: 'id = ?', whereArgs: [category.id]);
  }

  Future<void> deleteBudgetCategory(String id) async {
    final db = await database;
    await db.delete('budget_categories', where: 'id = ?', whereArgs: [id]);
  }

  // Goal operations
  Future<void> insertGoal(Goal goal) async {
    final db = await database;
    await db.insert('goals', goal.toMap());
  }

  // Optimized method for goals
  Future<List<Goal>> getGoals({String? userId}) async {
    final db = await database;
    final maps = await db.query(
      'goals',
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
    );
    
    // Use compute() to parse goals in background
    return await compute(_parseGoals, maps);
  }

  // Background method for parsing goals
  static List<Goal> _parseGoals(List<Map<String, dynamic>> maps) {
    return List<Goal>.from(
      maps.map((map) => Goal.fromMap(map))
    );
  }

  Future<void> updateGoal(Goal goal) async {
    final db = await database;
    await db.update('goals', goal.toMap(), where: 'id = ?', whereArgs: [goal.id]);
  }

  Future<void> deleteGoal(String id) async {
    final db = await database;
    await db.delete('goals', where: 'id = ?', whereArgs: [id]);
  }

  // AI Chat History operations
  Future<void> insertChatMessage(String userId, String message, String response) async {
    final db = await database;
    await db.insert('ai_chat_history', {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'userId': userId,
      'message': message,
      'response': response,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<List<Map<String, dynamic>>> getChatHistory({String? userId, int limit = 20}) async {
    final db = await database;
    final maps = await db.query(
      'ai_chat_history',
      where: userId != null ? 'userId = ?' : null,
      whereArgs: userId != null ? [userId] : null,
      orderBy: 'timestamp DESC',
      limit: limit,
    );
    // Convert QueryResultSet to mutable List
    return List<Map<String, dynamic>>.from(maps);
  }

  Future<void> clearChatHistory({String? userId}) async {
    final db = await database;
    if (userId != null) {
      await db.delete(
        'ai_chat_history',
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } else {
      await db.delete('ai_chat_history');
    }
  }

  // Optimized analytics queries using compute()
  Future<Map<String, dynamic>> getAnalyticsData(String userId) async {
    final db = await database;
    
    // Get all data in parallel
    final results = await Future.wait([
      db.query('transactions', where: 'userId = ?', whereArgs: [userId]),
      db.query('budget_categories', where: 'userId = ?', whereArgs: [userId]),
    ]);
    
    // Process analytics in background
    return await compute(_processAnalyticsData, {
      'transactions': results[0],
      'budgetCategories': results[1],
    });
  }

  // Background method for processing analytics
  static Map<String, dynamic> _processAnalyticsData(Map<String, dynamic> data) {
    final transactions = data['transactions'] as List<Map<String, dynamic>>;
    final budgetCategories = data['budgetCategories'] as List<Map<String, dynamic>>;
    
    // Calculate analytics
    double totalIncome = 0;
    double totalExpenses = 0;
    Map<String, double> categorySpending = {};
    
    for (var transaction in transactions) {
      final amount = transaction['amount'] as double;
      final type = transaction['type'] as String;
      final category = transaction['category'] as String;
      
      if (type == 'income') {
        totalIncome += amount;
      } else {
        totalExpenses += amount;
        categorySpending[category] = (categorySpending[category] ?? 0) + amount;
      }
    }
    
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'balance': totalIncome - totalExpenses,
      'categorySpending': categorySpending,
      'budgetCategories': budgetCategories,
    };
  }

  // Analytics queries
  Future<Map<String, double>> getMonthlyExpenses(String userId, int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0).toIso8601String();
    
    final maps = await db.query(
      'transactions',
      where: 'userId = ? AND type = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, 'expense', startDate, endDate],
    );
    
    double total = 0;
    Map<String, double> categoryTotals = {};
    
    for (var map in maps) {
      final amount = map['amount'] as double;
      final category = map['category'] as String;
      total += amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }
    
    return {
      'total': total,
      ...categoryTotals,
    };
  }

  Future<Map<String, double>> getMonthlyIncome(String userId, int year, int month) async {
    final db = await database;
    final startDate = DateTime(year, month, 1).toIso8601String();
    final endDate = DateTime(year, month + 1, 0).toIso8601String();
    
    final maps = await db.query(
      'transactions',
      where: 'userId = ? AND type = ? AND date >= ? AND date <= ?',
      whereArgs: [userId, 'income', startDate, endDate],
    );
    
    double total = 0;
    Map<String, double> categoryTotals = {};
    
    for (var map in maps) {
      final amount = map['amount'] as double;
      final category = map['category'] as String;
      total += amount;
      categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
    }
    
    return {
      'total': total,
      ...categoryTotals,
    };
  }

  Future<double> getTotalBalance(String userId) async {
    final db = await database;
    final incomeMaps = await db.query(
      'transactions',
      where: 'userId = ? AND type = ?',
      whereArgs: [userId, 'income'],
    );
    final expenseMaps = await db.query(
      'transactions',
      where: 'userId = ? AND type = ?',
      whereArgs: [userId, 'expense'],
    );
    
    double totalIncome = 0;
    double totalExpense = 0;
    
    for (var map in incomeMaps) {
      totalIncome += map['amount'] as double;
    }
    for (var map in expenseMaps) {
      totalExpense += map['amount'] as double;
    }
    
    return totalIncome - totalExpense;
  }
}
