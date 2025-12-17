import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Импорты виджетов и моделей
import '../models/chat_message.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/settings_dialog.dart';

// Импорты сервисов и конфига
import '../services/giga_chat_service.dart';
import '../services/open_router_service.dart';
import '../services/chat_storage_service.dart';
import '../services/prompt_service.dart'; // <-- НОВЫЙ ИМПОРТ
import '../config/open_router_config.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  List<ChatMessage> _messages = [];
  String? _currentChatId;
  Map<String, String> _chatHistoryIndex = {};
  
  bool _isAiTyping = false;
  String _selectedProvider = 'OpenRouter';
  
  // Храним выбранную модель
  String _selectedModel = OpenRouterConfig.defaultModel; 

  final ChatStorageService _storageService = ChatStorageService();
  
  // --- НОВОЕ: Сервис для загрузки промптов ---
  final PromptService _promptService = PromptService();
  String _fullSystemPrompt = "Ты полезный ассистент."; // Значение по умолчанию

  // Получаем ключи из .env
  final String _openRouterKey = dotenv.env['OPENROUTER_API_KEY'] ?? ""; 
  final String _gigaChatAuthKey = dotenv.env['GIGACHAT_AUTH_KEY'] ?? "";

  @override
  void initState() {
    super.initState();
    _loadHistoryIndex();
    _loadSystemPrompt(); // <-- Загружаем системный промпт при старте
  }

  // --- НОВОЕ: Метод загрузки промпта ---
  Future<void> _loadSystemPrompt() async {
    final prompt = await _promptService.getFullSystemPrompt();
    if (mounted) {
      setState(() {
        _fullSystemPrompt = prompt;
      });
    }
  }

  Future<void> _loadHistoryIndex() async {
    final history = await _storageService.getChatHistoryIndex();
    setState(() {
      _chatHistoryIndex = history;
    });
  }

  void _startNewChat() {
    setState(() {
      _messages = [];
      _currentChatId = null;
    });
  }

  Future<void> _loadChat(String chatId) async {
    final messages = await _storageService.loadChat(chatId);
    setState(() {
      _currentChatId = chatId;
      _messages = messages.reversed.toList(); 
    });
  }

  // --- УДАЛЕНИЕ ЧАТА ---
  Future<void> _deleteChat(String chatId) async {
    await _storageService.deleteChat(chatId);
    await _loadHistoryIndex(); 
    
    if (_currentChatId == chatId) {
      _startNewChat();
    }
  }

  // --- ПЕРЕИМЕНОВАНИЕ ЧАТА ---
  void _renameCurrentChat() {
    if (_currentChatId == null) return;

    final currentTitle = _chatHistoryIndex[_currentChatId] ?? "Чат";
    final textController = TextEditingController(text: currentTitle);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Переименовать чат"),
        content: TextField(
          controller: textController,
          autofocus: true,
          decoration: const InputDecoration(hintText: "Новое название"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () async {
              if (textController.text.trim().isNotEmpty) {
                await _storageService.renameChat(_currentChatId!, textController.text.trim());
                await _loadHistoryIndex(); 
              }
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  void _addMessage(String text, bool isUser) {
    final newMessage = ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    );

    setState(() {
      _messages.insert(0, newMessage);
    });

    _currentChatId ??= const Uuid().v4();

    _storageService.saveChat(_currentChatId!, _messages.reversed.toList()).then((_) {
      if (!_chatHistoryIndex.containsKey(_currentChatId)) {
        _loadHistoryIndex();
      }
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

  // --- ОТПРАВКА СООБЩЕНИЯ ---
  void _handleSubmitted(String text) async {
    _addMessage(text, true);
    setState(() => _isAiTyping = true);

    String? responseText;
    try {
      if (_selectedProvider == 'OpenRouter') {
        final service = OpenRouterService(_openRouterKey);
        // !!! ВАЖНО: Передаем _fullSystemPrompt в сервис
        responseText = await service.sendMessage(
          text, 
          _selectedModel, 
          _getHistoryForApi(),
          _fullSystemPrompt // <-- Передаем загруженный промпт + онтологию
        );
      } else {
        final service = GigaChatService(_gigaChatAuthKey);
        // !!! ВАЖНО: Передаем _fullSystemPrompt в сервис GigaChat
        // (Убедись, что GigaChatService тоже обновлен для приема этого аргумента)
        responseText = await service.sendMessage(
          text, 
          _getHistoryForApi(),
          _fullSystemPrompt // <-- Передаем загруженный промпт + онтологию
        );
      }
    } catch (e) {
      responseText = "Ошибка: $e";
    }

    if (mounted) {
      _addMessage(responseText ?? "Нет ответа", false);
      setState(() => _isAiTyping = false);
    }
  }

  // --- ОТКРЫТИЕ НАСТРОЕК ---
  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SettingsDialog(
          currentProvider: _selectedProvider,
          currentModel: _selectedModel,
          onProviderChanged: (newProvider) {
            setState(() {
              _selectedProvider = newProvider;
            });
          },
          onModelChanged: (newModel) {
            setState(() {
              _selectedModel = newModel;
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    String chatTitle = "Новый чат";
    if (_currentChatId != null && _chatHistoryIndex.containsKey(_currentChatId)) {
      chatTitle = _chatHistoryIndex[_currentChatId]!;
    }

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: InkWell(
          onTap: _currentChatId == null ? null : _renameCurrentChat,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
            child: Column(
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      chatTitle, 
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    if (_currentChatId != null) 
                       const SizedBox(width: 4),
                    if (_currentChatId != null)
                       Icon(Icons.edit, size: 14, color: Colors.grey.withOpacity(0.7))
                  ],
                ),
                Text(
                  _selectedProvider == 'OpenRouter' 
                      ? "$_selectedProvider (${OpenRouterConfig.availableModels[_selectedModel]?.split(' ').first ?? 'Model'})"
                      : _selectedProvider,
                  style: TextStyle(
                    fontSize: 11, 
                    color: Theme.of(context).colorScheme.primary, 
                    fontWeight: FontWeight.w500
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      drawer: AppDrawer(
        onOpenSettings: _openSettingsDialog,
        onNewChat: _startNewChat,
        onLoadChat: _loadChat,
        onDeleteChat: _deleteChat,
        chatHistory: _chatHistoryIndex,
      ),
      body: Column(
        children: [
          Expanded(
            child: _messages.isEmpty 
            ? Center(
                child: Text(
                  "Начните общение с AI\n(Модель: $_selectedModel)",
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
          SafeArea(
            top: false, 
            child: ChatInput(
              onSendMessage: _handleSubmitted,
              isTyping: _isAiTyping,
            ),
          ),
        ],
      ),
    );
  }
}