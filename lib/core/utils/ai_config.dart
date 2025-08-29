// AI Service Configuration
class AIConfig {
  static const String modelName = 'gemini-1.5-flash';
  static const int requestTimeoutSeconds = 30;
  static const int connectionTestTimeoutSeconds = 10;
  
  // API endpoints for debugging
  static const String baseUrl = 'https://generativelanguage.googleapis.com';
  static const String apiVersion = 'v1beta';
  
  // Validation method
  static bool isValidApiKey(String key) {
    return key.isNotEmpty && key.startsWith('AIza') && key.length > 30;
  }
}


