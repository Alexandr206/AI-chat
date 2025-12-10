import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
// Импортируем сервисы
import '../services/giga_chat_service.dart';
import '../services/open_router_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false;
  
  // Настройки (в реальном приложении хранить в SharedPreferences)
  String _selectedProvider = 'OpenRouter'; // 'OpenRouter' или 'GigaChat'
  
  // !!! ЗАМЕНИ ЭТО НА СВОИ КЛЮЧИ ИЛИ ВВОДИ ЧЕРЕЗ UI !!!
  // Для OpenRouter ключ начинается с sk-or-...
  final String _openRouterKey = "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"; 
  // Для GigaChat нужен Client Secret/Auth Key (длинная строка base64)
  final String _gigaChatAuthKey = "MDE5OWYyMWMtOGU5Mi03ZmNjLThlYWItNjNkM2JmMDg3Y2NlOmJiYjAxM2RjLTJlOWQtNDQyNC1iNGM5LWI2MTc5MzYzNmYwYg=="; 

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.insert(0, ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
  }

  // Конвертация истории чата для API
  List<Map<String, String>> _getHistoryForApi() {
    // Берем последние 10 сообщений, переворачиваем (так как у нас reverse list), форматируем
    return _messages.take(10).toList().reversed.map((m) {
      return {
        "role": m.isUser ? "user" : "assistant",
        "content": m.text
      };
    }).toList();
  }

  void _handleSubmitted(String text) async {
    _addMessage(text, true);
    setState(() => _isAiTyping = true);

    String? responseText;

    try {
      if (_selectedProvider == 'OpenRouter') {
        final service = OpenRouterService(_openRouterKey);
        responseText = await service.sendMessage(text, _getHistoryForApi());
      } else {
        final service = GigaChatService(_gigaChatAuthKey);
        responseText = await service.sendMessage(text, _getHistoryForApi());
      }
    } catch (e) {
      responseText = "Произошла ошибка: $e";
    }

    if (mounted) {
      _addMessage(responseText ?? "Нет ответа", false);
      setState(() => _isAiTyping = false);
    }
  }

  // Метод для смены провайдера через Drawer (передадим его как callback)
  void _changeProvider(String provider) {
    setState(() {
      _selectedProvider = provider;
    });
    Navigator.pop(context); // Закрыть меню
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Выбран провайдер: $provider")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI Чат ($_selectedProvider)"),
        centerTitle: true,
      ),
      // Передаем функцию смены провайдера в Drawer
      drawer: AppDrawer(onProviderChanged: _changeProvider), 
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: const EdgeInsets.all(8.0),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                return MessageBubble(message: _messages[index]);
              },
            ),
          ),
          if (_isAiTyping)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: LinearProgressIndicator(),
            ),
          ChatInput(
            onSendMessage: _handleSubmitted,
            isTyping: _isAiTyping,
          ),
        ],
      ),
    );
  }
}