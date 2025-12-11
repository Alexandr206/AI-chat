import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String apiKey; 
  
  OpenRouterService(this.apiKey);

  // Добавляем аргумент model
  Future<String?> sendMessage(String message, String model, List<Map<String, String>> history) async {
    const String url = "https://openrouter.ai/api/v1/chat/completions";

    try {
      debugPrint("--- Запрос к OpenRouter ($model) ---");
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://github.com/yourname/myapp", 
          "X-Title": "Flutter AI App",
        },
        body: jsonEncode({
          "model": model, // Используем выбранную модель
          "messages": [
             {"role": "system", "content": "Ты полезный AI ассистент."},
             ...history,
             {"role": "user", "content": message}
          ],
        }),
      );

      debugPrint("Status Code: ${response.statusCode}");
      // debugPrint("Response: ${utf8.decode(response.bodyBytes)}"); // Раскомментируй для полной отладки

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        if (data['choices'] != null && data['choices'].isNotEmpty) {
           return data['choices'][0]['message']['content'];
        } else {
           return "Пришел пустой ответ от API.";
        }
      } else {
        try {
           final errData = jsonDecode(response.body);
           return "Ошибка API: ${errData['error']['message']}";
        } catch (_) {
           return "Ошибка API: ${response.statusCode} ${response.body}";
        }
      }
    } catch (e) {
      debugPrint("Exception: $e");
      return "Ошибка сети: $e";
    }
  }
}