// Copy this file to chatbot_config.dart and fill in your own Groq API key.
// chatbot_config.dart is gitignored so real keys never get committed.

class ChatbotConfig {
  static const String groqApiKey  = 'YOUR_GROQ_API_KEY_HERE';
  static const String groqBaseUrl = 'https://api.groq.com/openai/v1';
  static const String llmModel    = 'llama-3.3-70b-versatile';

  // Rate limit safety delay for demo (ms)
  static const int requestDelayMs = 1000;
}
