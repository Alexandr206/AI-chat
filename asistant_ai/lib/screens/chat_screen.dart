import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // Не забудь добавить в pubspec.yaml
import '../models/chat_message.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/settings_dialog.dart';
import '../services/giga_chat_service.dart';
import '../services/open_router_service.dart';
import '../services/chat_storage_service.dart'; // Наш новый сервис

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  // Данные чата
  List<ChatMessage> _messages = [];
  String? _currentChatId; // ID текущего чата (null, если новый)
  Map<String, String> _chatHistoryIndex = {}; // Список чатов для меню

  // Состояние UI
  bool _isAiTyping = false;
  String _selectedProvider = 'OpenRouter';

  // Сервисы
  final ChatStorageService _storageService = ChatStorageService();
  final String _openRouterKey = "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"; 
  final String _gigaChatAuthKey = "MDE5OWYyMWMtOGU5Mi03ZmNjLThlYWItNjNkM2JmMDg3Y2NlOmJiYjAxM2RjLTJlOWQtNDQyNC1iNGM5LWI2MTc5MzYzNmYwYg=="; 

  @override
  void initState() {
    super.initState();
    _loadHistoryIndex(); // Загружаем список чатов при старте
  }

  // Загрузка списка чатов (для бокового меню)
  Future<void> _loadHistoryIndex() async {
    final history = await _storageService.getChatHistoryIndex();
    setState(() {
      _chatHistoryIndex = history;
    });
  }

  // Создание нового чата (очистка экрана)
  void _startNewChat() {
    setState(() {
      _messages = [];
      _currentChatId = null;
    });
  }

  // Загрузка старого чата
  Future<void> _loadChat(String chatId) async {
    final messages = await _storageService.loadChat(chatId);
    // Сортируем: новые в начале (для ListView reverse: true)
    // В JSON мы сохраняли как есть, но ListView требует обратный порядок
    // Если в saveChat мы сохраняли reverse список, то здесь надо проверить порядок.
    // В saveChat я делал map, порядок сохранялся. В UI _messages[0] - это последнее сообщение.
    
    // В нашем коде _messages хранит последнее сообщение под индексом 0.
    // При сохранении лучше сохранять в хронологическом порядке, а при загрузке переворачивать.
    // Упростим: просто перевернем загруженное, чтобы [0] был последним по времени.
    
    setState(() {
      _currentChatId = chatId;
      _messages = messages.reversed.toList(); 
    });
  }

  // Добавление сообщения и сохранение
  void _addMessage(String text, bool isUser) {
    final newMessage = ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, newMessage);
    });

    // Если это первое сообщение в новом чате - создаем ID
    if (_currentChatId == null) {
      _currentChatId = const Uuid().v4();
    }

    // Сохраняем историю
    // Внимание: _messages у нас перевернут (reverse), для сохранения лучше вернуть хронологию
    _storageService.saveChat(_currentChatId!, _messages.reversed.toList()).then((_) {
      _loadHistoryIndex(); // Обновляем список в меню (чтобы появилось название)
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
        title: Text(_currentChatId == null ? "Новый чат" : "AI Чат"),
        centerTitle: true,
      ),
      drawer: AppDrawer(
        onOpenSettings: _openSettingsDialog,
        onNewChat: _startNewChat,
        onLoadChat: _loadChat,
        chatHistory: _chatHistoryIndex,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty 
            ? Center(
                child: Text(
                  "Начните общение с AI\n(Модель: $_selectedProvider)",
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              )
            : ListView.builder(
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