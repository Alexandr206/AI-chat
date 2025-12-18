import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../widgets/app_drawer.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/settings_dialog.dart';

import '../services/giga_chat_service.dart';
import '../services/open_router_service.dart';
import '../services/chat_storage_service.dart';
import '../services/prompt_service.dart';
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

  // Настройки
  String _selectedProvider = 'OpenRouter';
  String _selectedModel = OpenRouterConfig.defaultModel; 
  String _selectedPromptMode = 'analyst'; 
  
  final ChatStorageService _storageService = ChatStorageService();
  final PromptService _promptService = PromptService();
  String _fullSystemPrompt = "Ты полезный ассистент.";

  // Ключи
  String _openRouterKey = ""; 
  String _gigaChatAuthKey = "";

  @override
  void initState() {
    super.initState();
    _loadApiKeys();
    _loadHistoryIndex();
    _loadSystemPrompt();
  }

  Future<void> _loadApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _openRouterKey = prefs.getString('key_openrouter') ?? dotenv.env['OPENROUTER_API_KEY'] ?? "";
      _gigaChatAuthKey = prefs.getString('key_gigachat') ?? dotenv.env['GIGACHAT_AUTH_KEY'] ?? "";
    });
  }

  Future<void> _updateApiKey(String provider, String newKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (provider == 'OpenRouter') {
      await prefs.setString('key_openrouter', newKey);
      setState(() => _openRouterKey = newKey);
    } else {
      await prefs.setString('key_gigachat', newKey);
      setState(() => _gigaChatAuthKey = newKey);
    }
  }

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

  Future<void> _deleteChat(String chatId) async {
    await _storageService.deleteChat(chatId);
    await _loadHistoryIndex(); 
    if (_currentChatId == chatId) {
      _startNewChat();
    }
  }

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
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Отмена")),
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

  // Общий метод сохранения текущего состояния чата
  void _saveCurrentChat() {
    if (_currentChatId == null && _messages.isNotEmpty) {
      _currentChatId = const Uuid().v4();
    }
    if (_currentChatId != null) {
      _storageService.saveChat(_currentChatId!, _messages.reversed.toList()).then((_) {
        if (!_chatHistoryIndex.containsKey(_currentChatId)) {
          _loadHistoryIndex();
        }
      });
    }
  }

  void _addMessage(String text, bool isUser) {
    setState(() {
      _messages.insert(0, ChatMessage(
        text: text,
        isUser: isUser,
        timestamp: DateTime.now(),
      ));
    });
    _saveCurrentChat();
  }

  // --- НОВОЕ: Удаление сообщения ---
  void _deleteMessage(int index) {
    setState(() {
      _messages.removeAt(index);
    });
    _saveCurrentChat();
  }

  // --- НОВОЕ: Редактирование сообщения ---
  void _editMessage(int index, String newText) {
    setState(() {
      // ChatMessage иммутабелен, поэтому создаем новый с тем же статусом
      final oldMsg = _messages[index];
      _messages[index] = ChatMessage(
        text: newText,
        isUser: oldMsg.isUser,
        timestamp: oldMsg.timestamp, // оставляем старое время или обновляем
      );
    });
    _saveCurrentChat();
  }

  // --- НОВОЕ: Перегенерация ответа ---
  void _regenerateResponse(int index) async {
    // 1. Запоминаем контекст (все сообщения, которые были ДО этого ответа)
    // Так как список reversed, "до" означает сообщения с индексом > index
    final historyBeforeThisMessage = _messages.sublist(index + 1);
    
    // Форматируем историю для API
    final apiHistory = historyBeforeThisMessage.reversed.map((m) {
      return {
        "role": m.isUser ? "user" : "assistant",
        "content": m.text
      };
    }).toList();

    // 2. Удаляем старое (плохое) сообщение ИИ из UI, чтобы показать лоадер
    // Или можно просто включить лоадер, а потом заменить текст.
    // Давайте удалим старый ответ и запустим процесс генерации заново.
    setState(() {
      _messages.removeAt(index);
      _isAiTyping = true;
    });

    // 3. Вызываем API (переиспользуем логику из _handleSubmitted, но без добавления сообщения юзера)
    await _callAiApi(apiHistory);
  }

  // Вынесенная логика API, чтобы использовать и при отправке, и при перегенерации
  Future<void> _callAiApi(List<Map<String, String>> history) async {
    String systemPromptToUse;
    if (_selectedPromptMode == 'analyst') {
      systemPromptToUse = _fullSystemPrompt;
    } else {
      systemPromptToUse = "Ты полезный и вежливый AI помощник. Отвечай кратко и по делу.";
    }

    String? responseText;
    try {
      if (_selectedProvider == 'OpenRouter' && _openRouterKey.isEmpty) {
         responseText = "Ошибка: Не введен API ключ для OpenRouter в настройках.";
      } else if (_selectedProvider == 'GigaChat' && _gigaChatAuthKey.isEmpty) {
         responseText = "Ошибка: Не введен Auth Key для GigaChat в настройках.";
      } else {
        if (_selectedProvider == 'OpenRouter') {
          final service = OpenRouterService(_openRouterKey);
          responseText = await service.sendMessage(
            // Для OpenRouter последнее сообщение уже должно быть в history, 
            // но sendMessage требует аргумент message. 
            // Мы сделаем небольшой хак: 
            // sendMessage обычно берет (newMsg, history). 
            // Тут newMsg уже внутри history.
            // Придется вытащить последнее сообщение из history, чтобы передать как 'message'.
            history.last['content']!, 
            _selectedModel, 
            history.sublist(0, history.length - 1),
            systemPromptToUse
          );
        } else {
          final service = GigaChatService(_gigaChatAuthKey);
          // GigaChatService мы писали так, что он просто добавляет message к history.
          // Поэтому тоже разделяем.
          responseText = await service.sendMessage(
            history.last['content']!, 
            history.sublist(0, history.length - 1),
            systemPromptToUse
          );
        }
      }
    } catch (e) {
      responseText = "Ошибка: $e";
    }

    if (mounted) {
      _addMessage(responseText ?? "Нет ответа", false);
      setState(() => _isAiTyping = false);
    }
  }

  List<Map<String, String>> _getHistoryForApi() {
    return _messages.take(10).toList().reversed.map((m) {
      return {
        "role": m.isUser ? "user" : "assistant",
        "content": m.text
      };
    }).toList();
  }

  // Обычная отправка (User + AI)
  void _handleSubmitted(String text) async {
    _addMessage(text, true);
    setState(() => _isAiTyping = true);
    
    // Формируем историю ВКЛЮЧАЯ только что добавленное сообщение пользователя
    // _messages[0] это то, что мы только что добавили.
    // _getHistoryForApi берет топ-10.
    await _callAiApi(_getHistoryForApi());
  }

  void _openSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return SettingsDialog(
          currentProvider: _selectedProvider,
          currentModel: _selectedModel,
          currentPromptMode: _selectedPromptMode,
          currentOpenRouterKey: _openRouterKey,
          currentGigaChatKey: _gigaChatAuthKey,
          onProviderChanged: (newProvider) {
            setState(() => _selectedProvider = newProvider);
          },
          onModelChanged: (newModel) {
            setState(() => _selectedModel = newModel);
          },
          onPromptModeChanged: (newMode) {
            setState(() => _selectedPromptMode = newMode);
          },
          onKeyChanged: (provider, newKey) {
            _updateApiKey(provider, newKey);
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
                  return MessageBubble(
                    message: _messages[index],
                    // --- Передаем колбэки ---
                    onDelete: () => _deleteMessage(index),
                    onEdit: (newText) => _editMessage(index, newText),
                    onRegenerate: () => _regenerateResponse(index),
                  );
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