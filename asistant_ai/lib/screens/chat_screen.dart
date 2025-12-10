import 'package:flutter/material.dart';
import '../models/chat_message.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/settings_dialog.dart'; // Импорт нового диалога
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
  
  // Состояние: выбранный провайдер
  String _selectedProvider = 'OpenRouter'; 

  // --- КЛЮЧИ API (Лучше вынести в .env или SecureStorage) ---
  final String _openRouterKey = "sk-or-v1-YOUR-KEY"; 
  final String _gigaChatAuthKey = "YOUR-AUTH-KEY"; 

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.insert(0, ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
  }

  List<Map<String, String>> _getHistoryForApi() {
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
      responseText = "Ошибка: $e";
    }

    if (mounted) {
      _addMessage(responseText ?? "Нет ответа", false);
      setState(() => _isAiTyping = false);
    }
  }

  // Функция открытия диалога настроек
  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SettingsDialog(
          currentProvider: _selectedProvider,
          onProviderChanged: (newProvider) {
            setState(() {
              _selectedProvider = newProvider;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("AI Чат ($_selectedProvider)"),
        centerTitle: true,
      ),
      drawer: AppDrawer(
        onOpenSettings: _openSettingsDialog, // Передаем функцию открытия настроек
      ),
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