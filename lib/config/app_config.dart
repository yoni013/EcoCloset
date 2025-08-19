/// Secure configuration management for API keys and environment variables
class AppConfig {
  static const String _geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY', 
    defaultValue: 'YOUR_GEMINI_API_KEY_HERE',
  );

  /// Gemini AI API Key for content analysis
  /// Note: When using Firebase AI, the API key is managed through Firebase project configuration
  /// This is kept here for potential future direct Gemini API usage
  static String get geminiApiKey {
    if (_geminiApiKey == 'YOUR_GEMINI_API_KEY_HERE') {
      // For Firebase AI (current implementation), we don't need direct API key management
      // The key is handled through Firebase project configuration
      return _geminiApiKey; 
    }
    return _geminiApiKey;
  }

  /// Check if running in development mode
  static bool get isDevelopment {
    return const bool.fromEnvironment('dart.vm.product') == false;
  }

  /// Check if running in production mode
  static bool get isProduction {
    return const bool.fromEnvironment('dart.vm.product') == true;
  }

  /// Environment name (dev, staging, prod)
  static String get environment {
    return const String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'development',
    );
  }

  /// Debug mode flag
  static bool get isDebug {
    return const bool.fromEnvironment('DEBUG', defaultValue: false);
  }
}
