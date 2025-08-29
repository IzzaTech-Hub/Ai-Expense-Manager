import 'dart:convert';
import 'dart:math';
import 'dart:io';
import 'dart:async';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:intl/intl.dart';
import 'package:api_key_pool/api_key_pool.dart';
import '../core/utils/ai_config.dart';
import 'database_service.dart';
import '../models/transaction_model.dart' as app_models;
import '../models/budget_model.dart';

class AIService {
  late final GenerativeModel _model;
  final DatabaseService _databaseService = DatabaseService();

  AIService({String? modelName, String? apiKey}) {
    // Get API key from ApiKeyPool or use provided key
    String key;
    try {
      key = apiKey ?? ApiKeyPool.getKey();
      print('AI Service: Successfully retrieved API key from ApiKeyPool');
    } catch (e) {
      print('AI Service: Failed to get API key from ApiKeyPool: $e');
      print('AI Service: Attempting to use fallback API key...');
      
      // Fallback to a default API key if ApiKeyPool fails
      // You can replace this with your actual API key for testing
      key = 'YOUR_FALLBACK_API_KEY_HERE'; // Replace with actual key
      
      if (!AIConfig.isValidApiKey(key)) {
        print('AI Service: Fallback API key also invalid');
        throw Exception('Failed to retrieve API key. Please check your ApiKeyPool configuration or set a fallback key.');
      }
      
      print('AI Service: Using fallback API key');
    }
    
    // Validate API key
    if (!AIConfig.isValidApiKey(key)) {
      print('AI Service: Invalid API key format');
      throw Exception('Invalid API key configuration');
    }
    
    // Get model name from parameter or fallback to AIConfig
    final modelToUse = modelName ?? AIConfig.modelName;
    
    _model = GenerativeModel(model: modelToUse, apiKey: key);
    print('AI Service: Initialized with model: $modelToUse');
    print('AI Service: API key length: ${key.length}');
    print('AI Service: Base URL: ${AIConfig.baseUrl}');
  }

  /// Check if device has internet connectivity
  Future<bool> _checkInternetConnectivity() async {
    try {
      // Try multiple reliable hosts for better connectivity detection
      final hosts = ['8.8.8.8', '1.1.1.1', 'google.com'];
      
      for (final host in hosts) {
        try {
          final result = await InternetAddress.lookup(host).timeout(
            const Duration(seconds: 5),
            onTimeout: () => throw TimeoutException('DNS lookup timeout', const Duration(seconds: 5)),
          );
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            print('AI Service: Internet connectivity confirmed via $host');
            return true;
          }
        } catch (e) {
          print('AI Service: Failed to connect to $host: $e');
          continue;
        }
      }
      
      print('AI Service: All connectivity tests failed');
      return false;
    } catch (e) {
      print('AI Service: Connectivity check error: $e');
      return false;
    }
  }

  /// Check if ApiKeyPool is properly initialized
  bool isApiKeyPoolReady() {
    try {
      print('AI Service: Checking ApiKeyPool status...');
      final key = ApiKeyPool.getKey();
      print('AI Service: ApiKeyPool returned key: ${key.substring(0, key.length > 10 ? 10 : key.length)}...');
      
      final isValid = AIConfig.isValidApiKey(key);
      print('AI Service: ApiKeyPool key validation: $isValid');
      return isValid;
    } catch (e) {
      print('AI Service: ApiKeyPool not ready: $e');
      print('AI Service: Error type: ${e.runtimeType}');
      return false;
    }
  }

  /// Test ApiKeyPool functionality
  Future<Map<String, dynamic>> testApiKeyPool() async {
    try {
      print('AI Service: Testing ApiKeyPool functionality...');
      
      // Test initialization
      final isReady = isApiKeyPoolReady();
      print('AI Service: ApiKeyPool ready: $isReady');
      
      if (isReady) {
        final key = ApiKeyPool.getKey();
        return {
          'status': 'success',
          'ready': true,
          'keyLength': key.length,
          'keyPreview': key.substring(0, key.length > 10 ? 10 : key.length),
          'isValid': AIConfig.isValidApiKey(key),
        };
      } else {
        return {
          'status': 'failed',
          'ready': false,
          'error': 'ApiKeyPool not ready',
        };
      }
    } catch (e) {
      print('AI Service: ApiKeyPool test failed: $e');
      return {
        'status': 'error',
        'ready': false,
        'error': e.toString(),
        'errorType': e.runtimeType.toString(),
      };
    }
  }

  /// Test basic internet connectivity without API calls
  Future<bool> testBasicConnectivity() async {
    return await _checkInternetConnectivity();
  }

  /// Test API connection to ensure the service is working
  Future<bool> testApiConnection() async {
    try {
      print('AI Service: Testing API connection...');
      print('AI Service: Current time: ${DateTime.now()}');
      
      // Check if ApiKeyPool is ready
      if (!isApiKeyPoolReady()) {
        print('AI Service: ApiKeyPool not ready');
        return false;
      }
      
      final hasInternet = await _checkInternetConnectivity();
      if (!hasInternet) {
        print('AI Service: No internet connectivity');
        return false;
      }
      
      print('AI Service: Internet connectivity confirmed, testing API...');
      
      // Test with a simple prompt
      final response = await _model.generateContent([Content.text('Hello')])
          .timeout(Duration(seconds: AIConfig.connectionTestTimeoutSeconds));
      
      final success = response.text != null && response.text!.isNotEmpty;
      print('AI Service: API test ${success ? 'successful' : 'failed'}');
      if (success) {
        print('AI Service: Response preview: ${response.text!.substring(0, response.text!.length > 50 ? 50 : response.text!.length)}');
      }
      return success;
    } catch (e) {
      print('AI Service: API connection test failed: $e');
      print('AI Service: Error type: ${e.runtimeType}');
      
      // If API test fails but internet is available, return true for internet connectivity
      // This allows the app to work even if the API is temporarily down
      if (e.toString().contains('timeout') || e.toString().contains('API')) {
        print('AI Service: API test failed but internet is available');
        return true; // Return true to indicate internet connectivity
      }
      
      return false;
    }
  }

  Future<Map<String, dynamic>?> parseIntent(String userInput) async {
    try {
      print('AI Service: Parsing intent for: "$userInput"');
    final prompt = _systemPrompt(userInput);
      print('AI Service: Generated prompt length: ${prompt.length}');
      
      final response = await _model.generateContent([Content.text(prompt)])
          .timeout(Duration(seconds: AIConfig.requestTimeoutSeconds), onTimeout: () {
        throw TimeoutException('AI response timeout', Duration(seconds: AIConfig.requestTimeoutSeconds));
      });
    final text = response.text ?? '';
      print('AI Service: Raw AI response: "$text"');
      
      if (text.isEmpty) {
        print('AI Service: Empty response from AI model');
        return null;
      }
      
      final intent = _extractJson(text);
      print('AI Service: Extracted intent: $intent');
      return intent;
    } catch (e) {
      print('AI Service: Error parsing intent: $e');
      
      // Handle specific network errors
      if (e.toString().contains('SocketException') || 
          e.toString().contains('NetworkException') ||
          e.toString().contains('timeout')) {
        throw Exception('Network error: Please check your internet connection and try again.');
      } else if (e.toString().contains('403') || e.toString().contains('Forbidden')) {
        throw Exception('API access denied. Please check your API key configuration.');
      } else if (e.toString().contains('429') || e.toString().contains('Too Many Requests')) {
        throw Exception('API rate limit exceeded. Please try again later.');
      } else if (e.toString().contains('500') || e.toString().contains('Internal Server Error')) {
        throw Exception('AI service temporarily unavailable. Please try again later.');
      }
      
      rethrow;
    }
  }

  Future<String> getResponse(String userInput, String userId) async {
    try {
      print('AI Service: Processing request: "$userInput" for user: $userId');
      
      // Check internet connectivity first
      final hasInternet = await _checkInternetConnectivity();
      if (!hasInternet) {
        print('AI Service: No internet connectivity detected');
        return "I'm sorry, but I can't connect to the internet right now. Please check your internet connection and try again. You can still use the app's offline features like viewing your transactions and budgets.";
      }
      
      print('AI Service: Internet connectivity confirmed, proceeding with AI request');
      
      // Parse user intent
      // Try to parse intent, but provide fallback if it fails
      Map<String, dynamic>? intent;
      try {
        intent = await parseIntent(userInput);
      } catch (e) {
        print('AI Service: Intent parsing failed, using fallback: $e');
        // Provide a basic fallback response
        if (userInput.toLowerCase().contains('expense') || userInput.toLowerCase().contains('spend')) {
          return "I can help you track your expenses! Currently, you don't have any transactions recorded. You can add expenses through the 'Add Transaction' button on the dashboard. Would you like me to show you how to add your first expense?";
        } else if (userInput.toLowerCase().contains('budget')) {
          return "I can help you manage your budget! You can create budget categories through the Budget section. Each category will help you track spending and stay within your financial goals. Would you like me to explain how to set up your first budget category?";
        } else if (userInput.toLowerCase().contains('last week') || userInput.toLowerCase().contains('week')) {
          return "I can see you're asking about last week's expenses. Currently, you don't have any transactions recorded in the system. To start tracking your expenses:\n\n1. Go to the dashboard\n2. Tap 'Add Transaction' \n3. Enter the amount, category, and date\n4. Save your transaction\n\nOnce you add some transactions, I'll be able to give you detailed insights about your spending patterns!";
        } else {
          return "I'm here to help you manage your finances! You can ask me about:\n\n• Setting up budgets\n• Tracking expenses\n• Financial insights\n• Spending patterns\n\nWhat would you like to know?";
        }
      }
      
      if (intent == null) {
        print('AI Service: Could not parse intent');
        return "I'm sorry, I couldn't understand your request. Could you please rephrase it?";
      }
      
      print('AI Service: Parsed intent: $intent');

      // Generate response based on intent
      String response;
      try {
        response = await _generateResponse(intent, userId);
        print('AI Service: Generated response: ${response.substring(0, response.length > 100 ? 100 : response.length)}...');
      } catch (e) {
        print('AI Service: Error generating response, using fallback: $e');
        response = "I understand you're asking about your finances. Let me help you with that. You can ask me about:\n\n• Your budget overview\n• Recent expenses\n• Spending patterns\n• Financial advice\n\nWhat would you like to know specifically?";
      }
      
      // Store chat history in SQLite
      try {
        await _databaseService.insertChatMessage(userId, userInput, response);
        print('AI Service: Chat history stored successfully');
      } catch (e) {
        print('AI Service: Failed to store chat history: $e');
        // Don't fail the whole request if storage fails
      }
      
      return response;
    } catch (e) {
      print('Error in AI service: $e');
      print('Error type: ${e.runtimeType}');
      print('Error details: ${e.toString()}');
      
      String errorMessage = "I'm sorry, I encountered an error. Please try again.";
      
      // Provide more specific error messages
      if (e.toString().contains('Network error')) {
        errorMessage = "I'm having trouble connecting to the internet. Please check your internet connection and try again.";
      } else if (e.toString().contains('API access denied')) {
        errorMessage = "There's an issue with the AI service configuration. Please contact support.";
      } else if (e.toString().contains('rate limit')) {
        errorMessage = "The AI service is busy right now. Please try again in a few minutes.";
      } else if (e.toString().contains('temporarily unavailable')) {
        errorMessage = "The AI service is temporarily unavailable. Please try again later.";
      } else if (e.toString().contains('Failed to retrieve API key')) {
        errorMessage = "There's an issue with the API key configuration. Please restart the app or contact support.";
      } else if (e.toString().contains('ApiKeyPool not ready')) {
        errorMessage = "The API service is not properly configured. Please restart the app.";
      }
      
      return errorMessage;
    }
  }

  Future<String> _generateResponse(Map<String, dynamic> intent, String userId) async {
    try {
      switch (intent['intent']) {
        case 'query_budget':
          return await _handleBudgetQuery(intent, userId);
        case 'add_budget_category':
          return await _handleAddBudgetCategory(intent, userId);
        case 'update_budget':
          return await _handleUpdateBudget(intent, userId);
        case 'delete_budget_category':
          return await _handleDeleteBudgetCategory(intent, userId);
        case 'add_transaction':
          return await _handleAddTransaction(intent, userId);
        case 'delete_transaction':
          return await _handleDeleteTransaction(intent, userId);
        case 'query_income_expense':
          return await _handleIncomeExpenseQuery(intent, userId);
        case 'query_spending':
          return await _handleSpendingQuery(intent, userId);
        default:
          return "I understand you want to manage your finances. How can I help you with budgeting, transactions, or financial insights?";
      }
    } catch (e) {
      print('Error generating response: $e');
      return "I'm sorry, I encountered an error while processing your request.";
    }
  }

  Future<String> _handleBudgetQuery(Map<String, dynamic> intent, String userId) async {
    final categories = await _databaseService.getBudgetCategories(userId: userId);
    if (categories.isEmpty) {
      return "You don't have any budget categories set up yet. Would you like me to help you create some?";
    }

    String response = "Here's your current budget overview:\n\n";
    for (var category in categories) {
      final remaining = category.allocated - category.spent;
      final percentage = (category.spent / category.allocated * 100).toStringAsFixed(1);
              response += "• ${category.name}: \$${category.spent.toStringAsFixed(0)} / \$${category.allocated.toStringAsFixed(0)} (${percentage}%)\n";
      if (remaining < 0) {
                  response += "  ⚠️ Over budget by \$${remaining.abs().toStringAsFixed(0)}\n";
      } else {
                  response += "  ✅ \$${remaining.toStringAsFixed(0)} remaining\n";
      }
      response += "\n";
    }
    return response;
  }

  Future<String> _handleAddBudgetCategory(Map<String, dynamic> intent, String userId) async {
    final name = intent['category'];
    final amount = intent['amount'];
    
    if (name == null || amount == null) {
      return "Please specify both the category name and amount for the budget.";
    }

    try {
      // Check if category already exists
      final existingCategories = await _databaseService.getBudgetCategories(userId: userId);
      final categoryNames = existingCategories.map((c) => c.name).toList();
      
      // Find the closest matching category
      final matchedCategory = _findClosestCategory(name, categoryNames);
      final wasCorrected = matchedCategory != name;
      
      if (wasCorrected && existingCategories.any((c) => c.name.toLowerCase() == matchedCategory.toLowerCase())) {
        // Category already exists, update it instead
        final existingCategory = existingCategories.firstWhere(
          (c) => c.name.toLowerCase() == matchedCategory.toLowerCase(),
        );
        
        final updatedCategory = BudgetCategory(
          id: existingCategory.id,
          name: existingCategory.name,
          allocated: existingCategory.allocated + amount.toDouble(),
          spent: existingCategory.spent,
          userId: userId,
          color: existingCategory.color,
          createdAt: existingCategory.createdAt,
        );
        
        await _databaseService.updateBudgetCategory(updatedCategory);
        
        String response = "✅ Successfully updated existing budget category!\n\n";
        response += "🔍 Category corrected from '$name' to '$matchedCategory'\n";
        response += "• Category: $matchedCategory\n";
        response += "• Amount added: \$${amount.toStringAsFixed(0)}\n";
        response += "• New total allocation: \$${updatedCategory.allocated.toStringAsFixed(0)}\n";
        response += "• Current spending: \$${updatedCategory.spent.toStringAsFixed(0)}";
        
        return response;
      } else {
        // Create a new budget category
        final budgetCategory = BudgetCategory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: wasCorrected ? matchedCategory : name,
          allocated: amount.toDouble(),
          spent: 0.0,
          userId: userId,
          color: _getRandomColor(),
          createdAt: DateTime.now(),
        );
        
        await _databaseService.insertBudgetCategory(budgetCategory);
        
        String response = "✅ Successfully created budget category!";
        if (wasCorrected) {
          response += "\n\n🔍 Category corrected from '$name' to '$matchedCategory'";
        }
        response += "\n\n• Category: ${wasCorrected ? matchedCategory : name}";
        response += "\n• Allocation: \$${amount.toStringAsFixed(0)}";
        response += "\n\nYou can now track your spending in this category. The budget will show how much you've spent vs. how much you've allocated.";
        
        return response;
      }
    } catch (e) {
      print('Error creating budget category: $e');
      return "❌ Sorry, I couldn't create the budget category. Please try again or create it manually through the Budget section.";
    }
  }

  Future<String> _handleUpdateBudget(Map<String, dynamic> intent, String userId) async {
    final name = intent['category'];
    final amount = intent['amount'];
    final updateMode = intent['updateMode'];
    
    if (name == null || amount == null) {
      return "Please specify both the category name and amount.";
    }

    try {
      final budgetCategories = await _databaseService.getBudgetCategories(userId: userId);
      final categoryNames = budgetCategories.map((c) => c.name).toList();
      
      // Find the closest matching category
      final matchedCategory = _findClosestCategory(name, categoryNames);
      final wasCorrected = matchedCategory != name;
      
      final existingCategory = budgetCategories.firstWhere(
        (cat) => cat.name.toLowerCase() == matchedCategory.toLowerCase(),
        orElse: () => BudgetCategory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: wasCorrected ? matchedCategory : name,
          allocated: 0,
          spent: 0,
          userId: userId,
          color: _getRandomColor(),
          createdAt: DateTime.now(),
        ),
      );
      
      double newAmount;
      if (updateMode == 'set') {
        newAmount = amount.toDouble();
      } else if (updateMode == 'increment') {
        newAmount = existingCategory.allocated + amount.toDouble();
      } else {
        newAmount = amount.toDouble();
      }
      
      final updatedCategory = BudgetCategory(
        id: existingCategory.id,
        name: existingCategory.name,
        allocated: newAmount,
        spent: existingCategory.spent,
        userId: userId,
        color: existingCategory.color,
        createdAt: existingCategory.createdAt,
      );
      
      if (existingCategory.id.isNotEmpty) {
        await _databaseService.updateBudgetCategory(updatedCategory);
      } else {
        await _databaseService.insertBudgetCategory(updatedCategory);
      }
      
      String response = "✅ Successfully updated budget!";
      if (wasCorrected) {
        response += "\n\n🔍 Category corrected from '$name' to '$matchedCategory'";
      }
      response += "\n\n";
      
      if (updateMode == 'set') {
        response += "Budget set to: \$${newAmount.toStringAsFixed(0)}";
      } else if (updateMode == 'increment') {
                  response += "Budget increased by: \$${amount.toStringAsFixed(0)}\n";
                  response += "New total: \$${newAmount.toStringAsFixed(0)}";
      } else {
                  response += "Budget updated to: \$${newAmount.toStringAsFixed(0)}";
      }
      
              response += "\n\n💰 Current spending: \$${existingCategory.spent.toStringAsFixed(0)}";
              response += "\n📊 Remaining: \$${(newAmount - existingCategory.spent).toStringAsFixed(0)}";
      
      return response;
    } catch (e) {
      print('Error updating budget: $e');
      return "❌ Sorry, I couldn't update the budget. Please try again or update it manually through the Budget section.";
    }
  }

  Future<String> _handleDeleteBudgetCategory(Map<String, dynamic> intent, String userId) async {
    final name = intent['category'];
    if (name == null) {
      return "Please specify which budget category you'd like to delete.";
    }
    return "I can help you delete the $name budget category. You can do this through the Budget section of the app.";
  }

  Future<String> _handleAddTransaction(Map<String, dynamic> intent, String userId) async {
    final category = intent['category'];
    final amount = intent['amount'];
    final type = intent['transactionType'];
    final date = intent['date'];
    final notes = intent['notes'];
    
    if (category == null || amount == null || type == null) {
      return "Please specify the category, amount, and type (income/expense) for the transaction.";
    }

    try {
      // Get existing categories for fuzzy matching
      final existingCategories = await _databaseService.getBudgetCategories(userId: userId);
      final categoryNames = existingCategories.map((c) => c.name).toList();
      
      // Find the closest matching category
      final matchedCategory = _findClosestCategory(category, categoryNames);
      final wasCorrected = matchedCategory != category;
      
      // Parse the date
      DateTime transactionDate;
      if (date == null || date == 'today') {
        transactionDate = DateTime.now();
      } else if (date == 'yesterday') {
        transactionDate = DateTime.now().subtract(const Duration(days: 1));
      } else {
        // Try to parse the date string
        try {
          transactionDate = DateTime.parse(date);
        } catch (e) {
          transactionDate = DateTime.now();
        }
      }

      // Create the transaction
      final transaction = app_models.Transaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        amount: amount.toDouble(),
        type: type,
        category: matchedCategory,
        date: transactionDate,
        notes: notes ?? '',
        createdAt: DateTime.now(),
      );
      
      await _databaseService.insertTransaction(transaction);
      
      // Update budget if it's an expense
      if (type == 'expense') {
        await _updateBudgetSpent(matchedCategory, amount.toDouble(), userId);
      }
      
      String response = "✅ Successfully added $type transaction!\n\n";
      if (wasCorrected) {
        response += "🔍 Category corrected from '$category' to '$matchedCategory'\n";
      }
      response += "• Category: $matchedCategory\n";
              response += "• Amount: \$${amount.toStringAsFixed(0)}\n";
      response += "• Date: ${DateFormat('MMM dd, yyyy').format(transactionDate)}\n";
      if (notes != null && notes.isNotEmpty) response += "• Notes: $notes\n";
      
      if (type == 'expense') {
        response += "\n💰 This expense has been deducted from your $matchedCategory budget.";
      } else {
        response += "\n💵 This income has been added to your total balance.";
      }
      
      return response;
    } catch (e) {
      print('Error creating transaction: $e');
      return "❌ Sorry, I couldn't create the transaction. Please try again or add it manually through the 'Add Transaction' section.";
    }
  }

  Future<void> _updateBudgetSpent(String category, double amount, String userId) async {
    try {
      final budgetCategories = await _databaseService.getBudgetCategories(userId: userId);
      final budgetCategory = budgetCategories.firstWhere(
        (cat) => cat.name.toLowerCase() == category.toLowerCase(),
        orElse: () => BudgetCategory(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: category,
          allocated: 0,
          spent: amount,
          userId: userId,
          color: _getRandomColor(),
          createdAt: DateTime.now(),
        ),
      );
      
      if (budgetCategory.id.isNotEmpty) {
        // Update existing budget
        final updatedCategory = BudgetCategory(
          id: budgetCategory.id,
          name: budgetCategory.name,
          allocated: budgetCategory.allocated,
          spent: budgetCategory.spent + amount,
          userId: userId,
          color: budgetCategory.color,
          createdAt: budgetCategory.createdAt,
        );
        await _databaseService.updateBudgetCategory(updatedCategory);
      } else {
        // Create new budget category if it doesn't exist
        await _databaseService.insertBudgetCategory(budgetCategory);
      }
    } catch (e) {
      print('Error updating budget: $e');
      // Don't fail the transaction if budget update fails
    }
  }

  Future<String> _handleDeleteTransaction(Map<String, dynamic> intent, String userId) async {
    final category = intent['category'];
    if (category == null) {
      return "Please specify which category of transaction you'd like to delete.";
    }

    try {
      final transactions = await _databaseService.getTransactions(userId: userId);
      final budgetCategories = await _databaseService.getBudgetCategories(userId: userId);
      final categoryNames = budgetCategories.map((c) => c.name).toList();
      
      // Find the closest matching category
      final matchedCategory = _findClosestCategory(category, categoryNames);
      final wasCorrected = matchedCategory != category;
      
      final categoryTransactions = transactions
          .where((t) => t.category.toLowerCase() == matchedCategory.toLowerCase())
          .toList();
      
      if (categoryTransactions.isEmpty) {
        return "No $category transactions found to delete.";
      }
      
      // Get the most recent transaction in that category
      categoryTransactions.sort((a, b) => b.date.compareTo(a.date));
      final latestTransaction = categoryTransactions.first;
      
      // Delete the transaction
      await _databaseService.deleteTransaction(latestTransaction.id);
      
      // Update budget if it was an expense
      if (latestTransaction.type == 'expense') {
        await _updateBudgetSpentOnDelete(matchedCategory, latestTransaction.amount, userId);
      }
      
      String response = "✅ Successfully deleted your latest transaction!";
      if (wasCorrected) {
        response += "\n\n🔍 Category corrected from '$category' to '$matchedCategory'";
      }
      response += "\n\n";
      response += "• Category: $matchedCategory\n";
              response += "• Amount: \$${latestTransaction.amount.toStringAsFixed(0)}\n";
      response += "• Type: ${latestTransaction.type}\n";
      response += "• Date: ${DateFormat('MMM dd, yyyy').format(latestTransaction.date)}\n\n";
      response += "💰 Your budget has been updated accordingly.";
      return response;
    } catch (e) {
      print('Error deleting transaction: $e');
      return "❌ Sorry, I couldn't delete the transaction. Please try again or delete it manually through the Transactions section.";
    }
  }

  Future<void> _updateBudgetSpentOnDelete(String category, double amount, String userId) async {
    try {
      final budgetCategories = await _databaseService.getBudgetCategories(userId: userId);
      final budgetCategory = budgetCategories.firstWhere(
        (cat) => cat.name.toLowerCase() == category.toLowerCase(),
        orElse: () => BudgetCategory(
          id: '',
          name: '',
          allocated: 0,
          spent: 0,
          userId: '',
          color: 0,
          createdAt: DateTime.now(),
        ),
      );
      
      if (budgetCategory.id.isNotEmpty) {
        final updatedCategory = BudgetCategory(
          id: budgetCategory.id,
          name: budgetCategory.name,
          allocated: budgetCategory.allocated,
          spent: budgetCategory.spent - amount,
          userId: userId,
          color: budgetCategory.color,
          createdAt: budgetCategory.createdAt,
        );
        await _databaseService.updateBudgetCategory(updatedCategory);
      }
    } catch (e) {
      print('Error updating budget on delete: $e');
      // Don't fail the deletion if budget update fails
    }
  }

  Future<String> _handleIncomeExpenseQuery(Map<String, dynamic> intent, String userId) async {
    final timeRange = intent['timeRange'];
    final startDate = intent['startDate'];
    final endDate = intent['endDate'];
    
    DateTime? start, end;
    if (startDate != null && endDate != null) {
      start = DateTime.parse(startDate);
      end = DateTime.parse(endDate);
    } else if (timeRange != null) {
      final now = DateTime.now();
      switch (timeRange) {
        case 'last_3_days':
          start = now.subtract(const Duration(days: 3));
          end = now;
          break;
        case 'last_7_days':
          start = now.subtract(const Duration(days: 7));
          end = now;
          break;
        case 'last_30_days':
          start = now.subtract(const Duration(days: 30));
          end = now;
          break;
        case 'this_month':
          start = DateTime(now.year, now.month, 1);
          end = now;
          break;
        case 'last_month':
          start = DateTime(now.year, now.month - 1, 1);
          end = DateTime(now.year, now.month, 0);
          break;
        case 'this_year':
          start = DateTime(now.year, 1, 1);
          end = now;
          break;
      }
    }

    try {
      final transactions = await _databaseService.getTransactions(userId: userId);

      if (transactions.isEmpty) {
        return "No transactions found for the specified time period.";
      }

      // Filter transactions by date range if specified
      List<app_models.Transaction> filteredTransactions = transactions;
      if (start != null && end != null) {
        filteredTransactions = transactions.where((t) => 
          t.date.isAfter(start!.subtract(const Duration(days: 1))) && 
          t.date.isBefore(end!.add(const Duration(days: 1)))
        ).toList();
      }

      if (filteredTransactions.isEmpty) {
        return "No transactions found for the specified time period.";
      }

      double totalIncome = 0;
      double totalExpenses = 0;
      
      for (var transaction in filteredTransactions) {
        if (transaction.type == 'income') {
          totalIncome += transaction.amount;
        } else {
          totalExpenses += transaction.amount;
        }
      }

      String response = "Here's your financial summary:\n\n";
              response += "💰 Total Income: \$${totalIncome.toStringAsFixed(0)}\n";
              response += "💸 Total Expenses: \$${totalExpenses.toStringAsFixed(0)}\n";
              response += "💵 Net Balance: \$${(totalIncome - totalExpenses).toStringAsFixed(0)}\n";
      
      return response;
    } catch (e) {
      return "I'm sorry, I couldn't retrieve your financial data. Please try again.";
    }
  }

  Future<String> _handleSpendingQuery(Map<String, dynamic> intent, String userId) async {
    final category = intent['category'];
    final timeRange = intent['timeRange'];
    
    DateTime? start, end;
    if (timeRange != null) {
      final now = DateTime.now();
      switch (timeRange) {
        case 'last_3_days':
          start = now.subtract(const Duration(days: 3));
          end = now;
          break;
        case 'last_7_days':
          start = now.subtract(const Duration(days: 7));
          end = now;
          break;
        case 'last_30_days':
          start = now.subtract(const Duration(days: 30));
          end = now;
          break;
        case 'this_month':
          start = DateTime(now.year, now.month, 1);
          end = now;
          break;
        case 'last_month':
          start = DateTime(now.year, now.month - 1, 1);
          end = DateTime(now.year, now.month, 0);
          break;
        case 'this_year':
          start = DateTime(now.year, 1, 1);
          end = now;
          break;
      }
    }

    try {
      final transactions = await _databaseService.getTransactions(userId: userId);

      if (transactions.isEmpty) {
        if (category != null) {
          return "No $category transactions found for the specified time period.";
        } else {
          return "No transactions found for the specified time period.";
        }
      }

      // Filter transactions by date range and category if specified
      List<app_models.Transaction> filteredTransactions = transactions;
      if (start != null && end != null) {
        filteredTransactions = transactions.where((t) => 
          t.date.isAfter(start!.subtract(const Duration(days: 1))) && 
          t.date.isBefore(end!.add(const Duration(days: 1)))
        ).toList();
      }
      
      if (category != null) {
        filteredTransactions = filteredTransactions.where((t) => t.category.toLowerCase() == category.toLowerCase()).toList();
      }

      if (filteredTransactions.isEmpty) {
        if (category != null) {
          return "No $category transactions found for the specified time period.";
        } else {
          return "No transactions found for the specified time period.";
        }
      }

      double totalSpent = 0;
      String response = category != null 
          ? "Here's your $category spending:\n\n"
          : "Here's your spending breakdown:\n\n";
      
      Map<String, double> categoryTotals = {};
      for (var transaction in filteredTransactions) {
        if (transaction.type == 'expense') {
          totalSpent += transaction.amount;
          categoryTotals[transaction.category] = (categoryTotals[transaction.category] ?? 0) + transaction.amount;
        }
      }

      if (category != null) {
        response += "Total spent on $category: \$${totalSpent.toStringAsFixed(0)}\n";
      } else {
                  response += "Total expenses: \$${totalSpent.toStringAsFixed(0)}\n\n";
        response += "By category:\n";
        categoryTotals.forEach((cat, amount) {
                      response += "• $cat: \$${amount.toStringAsFixed(0)}\n";
        });
      }
      
      return response;
    } catch (e) {
      return "I'm sorry, I couldn't retrieve your spending data. Please try again.";
    }
  }

  Future<List<Map<String, dynamic>>> getChatHistory(String userId, {int limit = 20}) async {
    return await _databaseService.getChatHistory(userId: userId, limit: limit);
  }

  Map<String, dynamic>? _extractJson(String raw) {
    try {
      print('AI Service: Extracting JSON from: "$raw"');
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      print('AI Service: JSON bounds: start=$start, end=$end');
      
      if (start == -1 || end == -1 || end <= start) {
        print('AI Service: Invalid JSON bounds');
        return null;
      }
      
      final jsonStr = raw.substring(start, end + 1);
      print('AI Service: Extracted JSON string: "$jsonStr"');
      
      final result = Map<String, dynamic>.from(jsonDecode(jsonStr) as Map<String, dynamic>);
      print('AI Service: Parsed JSON successfully: $result');
      return result;
    } catch (e) {
      print('AI Service: Error extracting JSON: $e');
      return null;
    }
  }

  String _systemPrompt(String userInput) {
    return '''
You are an assistant for a personal finance app. Always return a single JSON object only, no prose, following this schema:
{
  "intent": "query_budget | add_budget_category | update_budget | delete_budget_category | add_transaction | delete_transaction | query_income_expense | query_spending",
  "category": "string | null",
  "amount": number | null,
  "transactionType": "income | expense | null",
  "date": "YYYY-MM-DD | null",
  "notes": "string | null",
  "updateMode": "set | increment | null",
  "timeRange": "last_3_days | last_7_days | last_30_days | this_month | last_month | this_year | custom | null",
  "startDate": "YYYY-MM-DD | null",
  "endDate": "YYYY-MM-DD | null"
}

Interpret the user message and fill only the relevant fields. Examples:
- "What did I spend on food this month?" -> {"intent":"query_spending","category":"Food","timeRange":"this_month"}
- "Allocate 500 to transport budget" -> {"intent":"update_budget","category":"Transport","amount":500,"updateMode":"set"}
- "Add 500 to transport budget" -> {"intent":"update_budget","category":"Transport","amount":500,"updateMode":"increment"}
- "Add an expense of 1200 for groceries today" -> {"intent":"add_transaction","category":"Food","amount":1200,"transactionType":"expense","date":"today"}
- "I spent 500 on food yesterday" -> {"intent":"add_transaction","category":"Food","amount":500,"transactionType":"expense","date":"yesterday"}
- "I earned 2000 salary today" -> {"intent":"add_transaction","category":"Salary","amount":2000,"transactionType":"income","date":"today"}
- "Create a budget for food with 1000" -> {"intent":"add_budget_category","category":"Food","amount":1000}
- "Set food budget to 800" -> {"intent":"update_budget","category":"Food","amount":800,"updateMode":"set"}
- "Delete last transport expense" -> {"intent":"delete_transaction","category":"Transport"}
- "Show my spending last week" -> {"intent":"query_spending","timeRange":"last_7_days"}
- "What did I eat in the last 3 days?" -> {"intent":"query_spending","category":"Food","timeRange":"last_3_days"}
- "Income last month" -> {"intent":"query_income_expense","timeRange":"last_month"}

User message: "$userInput"
Only output the JSON.
''';
  }

  int _getRandomColor() {
    final colors = [
      0xFF3B82F6, // Blue
      0xFF10B981, // Green
      0xFFF59E0B, // Yellow
      0xFFEF4444, // Red
      0xFF8B5CF6, // Purple
      0xFF06B6D4, // Cyan
      0xFF84CC16, // Lime
      0xFFF97316, // Orange
    ];
    
    final random = Random();
    return colors[random.nextInt(colors.length)];
  }

  /// Find the closest matching category using fuzzy matching
  String _findClosestCategory(String inputCategory, List<String> existingCategories) {
    if (existingCategories.isEmpty) return inputCategory;
    
    // Convert to lowercase for comparison
    final input = inputCategory.toLowerCase();
    final categories = existingCategories.map((c) => c.toLowerCase()).toList();
    
    // First try exact match
    if (categories.contains(input)) {
      return existingCategories[categories.indexOf(input)];
    }
    
    // Try partial match (contains)
    for (int i = 0; i < categories.length; i++) {
      if (categories[i].contains(input) || input.contains(categories[i])) {
        return existingCategories[i];
      }
    }
    
    // Try fuzzy matching with edit distance
    int bestDistance = double.maxFinite.toInt();
    String bestMatch = inputCategory;
    
    for (int i = 0; i < categories.length; i++) {
      final distance = _calculateEditDistance(input, categories[i]);
      if (distance < bestDistance) {
        bestDistance = distance;
        bestMatch = existingCategories[i];
      }
    }
    
    // If the best match is reasonably close (edit distance <= 3), use it
    if (bestDistance <= 3) {
      return bestMatch;
    }
    
    // Otherwise return the original input
    return inputCategory;
  }

  /// Calculate Levenshtein edit distance between two strings
  int _calculateEditDistance(String s1, String s2) {
    if (s1.isEmpty) return s2.length;
    if (s2.isEmpty) return s1.length;
    
    List<List<int>> matrix = List.generate(
      s1.length + 1,
      (i) => List.generate(s2.length + 1, (j) => 0)
    );
    
    for (int i = 0; i <= s1.length; i++) {
      matrix[i][0] = i;
    }
    for (int j = 0; j <= s2.length; j++) {
      matrix[0][j] = j;
    }
    
    for (int i = 1; i <= s1.length; i++) {
      for (int j = 1; j <= s2.length; j++) {
        int cost = s1[i - 1] == s2[j - 1] ? 0 : 1;
        matrix[i][j] = [
          matrix[i - 1][j] + 1,      // deletion
          matrix[i][j - 1] + 1,      // insertion
          matrix[i - 1][j - 1] + cost // substitution
        ].reduce((a, b) => a < b ? a : b);
      }
    }
    
    return matrix[s1.length][s2.length];
  }
}


