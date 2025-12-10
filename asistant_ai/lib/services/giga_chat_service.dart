import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';
import 'package:uuid/uuid.dart';

class GigaChatService {
  // Authorization Key из кабинета разработчика Сбера (Base64 строка)
  final String authKey; 
  String? _accessToken;
  DateTime? _tokenExpiresAt;

  GigaChatService(this.authKey);

  // --- СПЕЦИАЛЬНЫЙ КЛИЕНТ ДЛЯ ОБХОДА SSL (Минцифры) ---
  http.Client _createHttpClient() {
    final ioc = HttpClient();
    ioc.badCertificateCallback = (X509Certificate cert, String host, int port) => true;
    return IOClient(ioc);
  }

  // 1. Получение токена
  Future<void> _authenticate() async {
    if (_accessToken != null && _tokenExpiresAt != null && DateTime.now().isBefore(_tokenExpiresAt!)) {
      return; // Токен еще жив
    }

    const String url = "https://ngw.devices.sberbank.ru:9443/api/v2/oauth";
    final client = _createHttpClient();
    final uuid = const Uuid().v4();

    try {
      final response = await client.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Basic $authKey",
          "RqUID": uuid,
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {"scope": "GIGACHAT_API_PERS"}, // Или GIGACHAT_API_CORP, если ты юрлицо
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _accessToken = data['access_token'];
        // Токен живет 30 мин, ставим запас чтобы обновить раньше
        _tokenExpiresAt = DateTime.now().add(const Duration(minutes: 25)); 
      } else {
        throw Exception("Ошибка авторизации GigaChat: ${response.body}");
      }
    } finally {
      client.close();
    }
  }

  // 2. Отправка сообщения
  Future<String?> sendMessage(String message, List<Map<String, String>> history) async {
    try {
      await _authenticate();
      
      const String url = "https://gigachat.devices.sberbank.ru/api/v1/chat/completions";
      final client = _createHttpClient();

      final List<Map<String, String>> messages = [
        {"role": "system", "content": "Ты полезный помощник."},
        ...history,
        {"role": "user", "content": message}
      ];

      final response = await client.post(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $_accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "GigaChat", // Проверь актуальное название модели в доке
          "messages": messages,
          "temperature": 0.7
        }),
      );
      
      client.close();

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      } else {
        return "Ошибка GigaChat: ${response.statusCode} ${response.body}";
      }
    } catch (e) {
      return "Ошибка: $e";
    }
  }
}