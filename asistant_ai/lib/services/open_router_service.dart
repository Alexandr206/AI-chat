import 'dart:convert';
import 'package:http/http.dart' as http;

class OpenRouterService {
  // Вставь сюда свой ключ от OpenRouter, когда получишь его
  final String apiKey; 
  
  OpenRouterService(this.apiKey);

  Future<String?> sendMessage(String message, List<Map<String, String>> history) async {
    const String url = "https://openrouter.ai/api/v1/chat/completions";

    // Формируем историю для контекста
    // OpenRouter ожидает формат: [{"role": "user", "content": "..."}, {"role": "assistant", "content": "..."}]
    final List<Map<String, String>> messages = [
      {"role": "system", "content": "Ты полезный AI ассистент."},
      ...history,
      {"role": "user", "content": message}
    ];

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          // Обязательные заголовки для OpenRouter (требование документации)
          "HTTP-Referer": "https://github.com/yourname/myapp", 
          "X-Title": "Flutter AI App",
        },
        body: jsonEncode({
          "model": "mistralai/mistral-7b-instruct:free", // Бесплатная модель для теста
          "messages": messages,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        return "Ошибка API: ${response.statusCode} ${response.body}";
      }
    } catch (e) {
      return "Ошибка сети: $e";
    }
  }
}