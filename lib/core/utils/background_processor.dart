import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Utility class for processing expensive operations in background
class BackgroundProcessor {
  
  /// Process JSON data in background to prevent main thread blocking
  static Future<Map<String, dynamic>> parseJsonInBackground(String jsonString) async {
    return await compute(_parseJson, jsonString);
  }
  
  /// Background method for JSON parsing
  static Map<String, dynamic> _parseJson(String jsonString) {
    try {
      return jsonDecode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      return {'error': 'Failed to parse JSON: $e'};
    }
  }
  
  /// Process large lists in background
  static Future<List<Map<String, dynamic>>> processListInBackground(
    List<Map<String, dynamic>> items,
  ) async {
    return await compute(_processList, items);
  }
  
  /// Background method for list processing
  static List<Map<String, dynamic>> _processList(List<Map<String, dynamic>> items) {
    // Process items in background
    return items.map((item) => Map<String, dynamic>.from(item)).toList();
  }
  
  /// Calculate complex analytics in background
  static Future<Map<String, double>> calculateAnalyticsInBackground(
    List<Map<String, dynamic>> transactions,
  ) async {
    return await compute(_calculateAnalytics, transactions);
  }
  
  /// Background method for analytics calculation
  static Map<String, double> _calculateAnalytics(List<Map<String, dynamic>> transactions) {
    double totalIncome = 0;
    double totalExpenses = 0;
    Map<String, double> categoryTotals = {};
    
    for (var transaction in transactions) {
      final amount = (transaction['amount'] as num).toDouble();
      final type = transaction['type'] as String;
      final category = transaction['category'] as String;
      
      if (type == 'income') {
        totalIncome += amount;
      } else {
        totalExpenses += amount;
        categoryTotals[category] = (categoryTotals[category] ?? 0) + amount;
      }
    }
    
    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'balance': totalIncome - totalExpenses,
      ...categoryTotals,
    };
  }
  
  /// Process image data in background (example for future use)
  static Future<Map<String, dynamic>> processImageInBackground(
    List<int> imageBytes,
    String operation,
  ) async {
    return await compute(_processImage, {
      'imageBytes': imageBytes,
      'operation': operation,
    });
  }
  
  /// Background method for image processing
  static Map<String, dynamic> _processImage(Map<String, dynamic> data) {
    final imageBytes = data['imageBytes'] as List<int>;
    final operation = data['operation'] as String;
    
    // Simulate image processing
    // In real app, you'd use image processing libraries here
    return {
      'processed': true,
      'operation': operation,
      'size': imageBytes.length,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }
}
