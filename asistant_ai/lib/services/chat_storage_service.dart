import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/chat_message.dart';

class ChatStorageService {
  static const String _historyKey = 'chat_history_index';

  // Сохранить сообщение в конкретный чат
  Future<void> saveChat(String chatId, List<ChatMessage> messages) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Сохраняем сами сообщения
    final String messagesJson = jsonEncode(messages.map((m) => m.toJson()).toList());
    await prefs.setString('chat_$chatId', messagesJson);

    // 2. Обновляем индекс (список всех чатов)
    await _updateHistoryIndex(chatId, messages.isNotEmpty ? messages.last.text : 'Новый чат');
  }

  // Загрузить сообщения конкретного чата
  Future<List<ChatMessage>> loadChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString('chat_$chatId');
    if (data == null) return [];

    final List<dynamic> jsonList = jsonDecode(data);
    return jsonList.map((json) => ChatMessage.fromJson(json)).toList();
  }

  // Получить список всех чатов (Map: ID -> Заголовок)
  Future<Map<String, String>> getChatHistoryIndex() async {
    final prefs = await SharedPreferences.getInstance();
    final String? data = prefs.getString(_historyKey);
    if (data == null) return {};

    // Возвращаем Map<String, String>, где ключ - ID чата, значение - заголовок
    return Map<String, String>.from(jsonDecode(data));
  }

  // Внутренний метод для обновления заголовка чата в списке
  Future<void> _updateHistoryIndex(String chatId, String lastMessage) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getChatHistoryIndex();

    // Если чат новый или обновился, записываем (можно обрезать текст для заголовка)
    String title = lastMessage.length > 30 ? '${lastMessage.substring(0, 30)}...' : lastMessage;
    
    // Если это первое сообщение от юзера, оно станет названием чата. 
    // Если чат уже есть, название лучше не менять каждый раз (но для простоты оставим обновление)
    if (!history.containsKey(chatId)) {
       history[chatId] = title;
    }

    await prefs.setString(_historyKey, jsonEncode(history));
  }

  Future<void> renameChat(String chatId, String newTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getChatHistoryIndex();
    
    if (history.containsKey(chatId)) {
      history[chatId] = newTitle;
      await prefs.setString(_historyKey, jsonEncode(history));
    }
  }
  
  // Удаление чата (опционально)
  Future<void> deleteChat(String chatId) async {
    final prefs = await SharedPreferences.getInstance();
    final history = await getChatHistoryIndex();
    
    history.remove(chatId); // Удаляем из индекса
    await prefs.setString(_historyKey, jsonEncode(history));
    await prefs.remove('chat_$chatId'); // Удаляем сообщения
  }
}