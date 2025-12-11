import 'dart:convert';
import 'package:flutter/material.dart'; // Нужно для debugPrint
import 'package:http/http.dart' as http;

class OpenRouterService {
  final String apiKey; 
  
  OpenRouterService(this.apiKey);

  Future<String?> sendMessage(String message, List<Map<String, String>> history) async {
    const String url = "https://openrouter.ai/api/v1/chat/completions";

    try {
      debugPrint("--- Запрос к OpenRouter ---");
      
      final response = await http.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
          "HTTP-Referer": "https://github.com/yourname/myapp", 
          "X-Title": "Flutter AI App",
        },
        body: jsonEncode({
          // МЕНЯЕМ МОДЕЛЬ на более стабильную бесплатную
          "model": "mistralai/devstral-2512:free", 
          "messages": [
             {"role": "system", "content": "Ты полезный AI ассистент."},
             ...history,
             {"role": "user", "content": message}
          ],
        }),
      );

      // ЛОГИРОВАНИЕ ОТВЕТА
      debugPrint("Status Code: ${response.statusCode}");
      debugPrint("Response: ${utf8.decode(response.bodyBytes)}");

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        
        // Проверяем, есть ли сообщение
        if (data['choices'] != null && data['choices'].isNotEmpty) {
           return data['choices'][0]['message']['content'];
        } else {
           return "Пришел пустой ответ от API (структура JSON корректна, но нет choices).";
        }
      } else {
        // Пытаемся достать текст ошибки
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