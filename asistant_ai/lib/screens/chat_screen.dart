import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<ChatMessage> _messages = [];
  bool _isAiTyping = false; // Состояние "ИИ печатает"

  // Функция добавления сообщения
  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.insert(0, ChatMessage( // Добавляем в начало списка
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
  }

  // Обработка отправки сообщения пользователем
  void _handleSubmitted(String text) async {
    _addMessage(text, true); // 1. Показываем сообщение юзера
    
    setState(() {
      _isAiTyping = true;
    });

    // TODO: Здесь будет вызов API (LangChain / GigaChat / OpenRouter)
    // Пока имитируем задержку сети
    await Future.delayed(const Duration(seconds: 1));

    _addMessage("Это заглушка ответа ИИ. Здесь будет подключен GigaChat или OpenRouter.", false);

    setState(() {
      _isAiTyping = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("AI Чат"),
        centerTitle: true,
      ),
      drawer: const AppDrawer(), // Наша боковая панель
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              reverse: true, // Список снизу вверх (как в мессенджерах)
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
              child: LinearProgressIndicator(), // Индикатор загрузки ответа
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