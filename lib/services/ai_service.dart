import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../core/utils/ai_config.dart';

class AIService {
  late final GenerativeModel _model;

  AIService({String modelName = 'gemini-1.5-flash', String? apiKey}) {
    final key = apiKey ?? geminiApiKey;
    _model = GenerativeModel(model: modelName, apiKey: key);
  }

  Future<Map<String, dynamic>?> parseIntent(String userInput) async {
    final prompt = _systemPrompt(userInput);
    final response = await _model.generateContent([Content.text(prompt)]);
    final text = response.text ?? '';
    if (text.isEmpty) return null;
    return _extractJson(text);
  }

  Map<String, dynamic>? _extractJson(String raw) {
    try {
      final start = raw.indexOf('{');
      final end = raw.lastIndexOf('}');
      if (start == -1 || end == -1 || end <= start) return null;
      final jsonStr = raw.substring(start, end + 1);
      return Map<String, dynamic>.from(jsonDecode(jsonStr) as Map<String, dynamic>);
    } catch (_) {
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
- "Delete last transport expense" -> {"intent":"delete_transaction","category":"Transport"}
- "Show my spending last week" -> {"intent":"query_spending","timeRange":"last_7_days"}
- "What did I eat in the last 3 days?" -> {"intent":"query_spending","category":"Food","timeRange":"last_3_days"}
- "Income last month" -> {"intent":"query_income_expense","timeRange":"last_month"}

User message: "$userInput"
Only output the JSON.
''';
  }
}


