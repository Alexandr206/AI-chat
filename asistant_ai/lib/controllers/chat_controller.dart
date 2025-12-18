import 'dart:convert'; // Для JSON
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/chat_message.dart';
import '../models/assistant.dart'; // <-- Убедись, что модель создана
import '../services/giga_chat_service.dart';
import '../services/open_router_service.dart';
import '../services/chat_storage_service.dart';
import '../services/prompt_service.dart';
import '../config/open_router_config.dart';

class ChatController extends ChangeNotifier {
  // === СОСТОЯНИЕ ЧАТА ===
  List<ChatMessage> messages = [];
  String? currentChatId;
  Map<String, String> chatHistoryIndex = {};
  bool isAiTyping = false;

  // === НАСТРОЙКИ ===
  String selectedProvider = 'OpenRouter';
  String selectedModel = OpenRouterConfig.defaultModel;
  
  // Вместо простого режима теперь список ассистентов
  List<Assistant> assistants = []; 
  String selectedAssistantId = 'analyst'; // ID выбранного по умолчанию

  // Ключи
  String openRouterKey = "";
  String gigaChatAuthKey = "";

  // Сервисы
  final ChatStorageService _storageService = ChatStorageService();
  final PromptService _promptService = PromptService();
  
  // Кэш для текста встроенного аналитика (загружается из файлов)
  String _builtInAnalystPrompt = "";

  // === ИНИЦИАЛИЗАЦИЯ ===
  ChatController() {
    _init();
  }

  Future<void> _init() async {
    await _loadApiKeys();
    await _loadHistoryIndex();
    await _loadAssistants(); // <-- Загружаем ассистентов
    notifyListeners();
  }

  // === ЗАГРУЗКА КЛЮЧЕЙ ===
  Future<void> _loadApiKeys() async {
    final prefs = await SharedPreferences.getInstance();
    openRouterKey = prefs.getString('key_openrouter') ?? dotenv.env['OPENROUTER_API_KEY'] ?? "";
    gigaChatAuthKey = prefs.getString('key_gigachat') ?? dotenv.env['GIGACHAT_AUTH_KEY'] ?? "";
  }

  Future<void> updateApiKey(String provider, String newKey) async {
    final prefs = await SharedPreferences.getInstance();
    if (provider == 'OpenRouter') {
      await prefs.setString('key_openrouter', newKey);
      openRouterKey = newKey;
    } else {
      await prefs.setString('key_gigachat', newKey);
      gigaChatAuthKey = newKey;
    }
    notifyListeners();
  }

  // === ЛОГИКА АССИСТЕНТОВ (CRUD) ===

  Future<void> _loadAssistants() async {
    // 1. Загружаем текст для встроенного аналитика из файлов assets
    try {
      _builtInAnalystPrompt = await _promptService.getFullSystemPrompt();
    } catch (e) {
      _builtInAnalystPrompt = "Ты системный аналитик.";
    }

    // 2. Определяем встроенных ассистентов
    final defaultAssistants = [
      Assistant(
        id: 'none',
        name: 'Обычный чат',
        systemPrompt: 'Ты полезный и вежливый AI помощник. Отвечай кратко и по делу.',
        ontology: '',
        isBuiltIn: true,
      ),
      Assistant(
        id: 'analyst',
        name: 'Аналитик (INCOSE)',
        // Промпт подставим динамически в _callAiApi
        systemPrompt: 'Используется встроенная база знаний INCOSE.', 
        ontology: '', 
        isBuiltIn: true,
      ),
    ];

    // 3. Загружаем пользовательских из SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final String? customAssistantsJson = prefs.getString('custom_assistants');
    
    List<Assistant> customAssistants = [];
    if (customAssistantsJson != null) {
      try {
        final List<dynamic> decoded = jsonDecode(customAssistantsJson);
        customAssistants = decoded.map((json) => Assistant.fromJson(json)).toList();
      } catch (e) {
        debugPrint("Ошибка загрузки ассистентов: $e");
      }
    }

    // 4. Объединяем списки
    assistants = [...defaultAssistants, ...customAssistants];
    
    // Проверка: если выбранного ID нет в списке, сбрасываем на 'analyst'
    if (!assistants.any((a) => a.id == selectedAssistantId)) {
      selectedAssistantId = 'analyst';
    }
  }

  // Сохранение списка пользовательских ассистентов
  Future<void> _saveCustomAssistants() async {
    final customList = assistants.where((a) => !a.isBuiltIn).toList();
    final jsonList = customList.map((a) => a.toJson()).toList();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('custom_assistants', jsonEncode(jsonList));
    notifyListeners();
  }

  // Добавление или обновление ассистента
  void saveAssistant(Assistant assistant) {
    final index = assistants.indexWhere((a) => a.id == assistant.id);
    if (index >= 0) {
      // Обновление существующего
      assistants[index] = assistant;
    } else {
      // Добавление нового
      assistants.add(assistant);
      selectedAssistantId = assistant.id; // Сразу выбираем созданного
    }
    _saveCustomAssistants();
  }

  // Удаление ассистента (можно добавить кнопку в UI позже)
  void deleteAssistant(String id) {
    // Нельзя удалять встроенных
    final assistant = assistants.firstWhere((a) => a.id == id, orElse: () => assistants.first);
    if (assistant.isBuiltIn) return;

    assistants.removeWhere((a) => a.id == id);
    
    if (selectedAssistantId == id) {
      selectedAssistantId = 'none';
    }
    _saveCustomAssistants();
  }

  void setAssistantId(String id) {
    selectedAssistantId = id;
    notifyListeners();
  }

  // Геттер текущего объекта ассистента
  Assistant? get currentAssistant {
    try {
      return assistants.firstWhere((a) => a.id == selectedAssistantId);
    } catch (e) {
      return assistants.isNotEmpty ? assistants.first : null;
    }
  }

  // === ИСТОРИЯ ЧАТОВ ===

  Future<void> _loadHistoryIndex() async {
    chatHistoryIndex = await _storageService.getChatHistoryIndex();
    notifyListeners();
  }

  void startNewChat() {
    messages = [];
    currentChatId = null;
    notifyListeners();
  }

  Future<void> loadChat(String chatId) async {
    final loadedMsgs = await _storageService.loadChat(chatId);
    currentChatId = chatId;
    messages = loadedMsgs.reversed.toList();
    notifyListeners();
  }

  Future<void> deleteChat(String chatId) async {
    await _storageService.deleteChat(chatId);
    await _loadHistoryIndex();
    if (currentChatId == chatId) {
      startNewChat();
    } else {
      notifyListeners();
    }
  }

  Future<void> renameCurrentChat(String newTitle) async {
    if (currentChatId == null) return;
    await _storageService.renameChat(currentChatId!, newTitle);
    await _loadHistoryIndex();
    notifyListeners();
  }

  // === ЛОГИКА СООБЩЕНИЙ ===
  void addMessage(String text, bool isUser) {
    messages.insert(0, ChatMessage(
      text: text,
      isUser: isUser,
      timestamp: DateTime.now(),
    ));
    _saveCurrentChat();
    notifyListeners();
  }

  void deleteMessage(int index) {
    messages.removeAt(index);
    _saveCurrentChat();
    notifyListeners();
  }

  void editMessage(int index, String newText) {
    final oldMsg = messages[index];
    messages[index] = ChatMessage(
      text: newText,
      isUser: oldMsg.isUser,
      timestamp: oldMsg.timestamp,
    );
    _saveCurrentChat();
    notifyListeners();
  }

  void _saveCurrentChat() {
    if (currentChatId == null && messages.isNotEmpty) {
      currentChatId = const Uuid().v4();
    }
    if (currentChatId != null) {
      _storageService.saveChat(currentChatId!, messages.reversed.toList()).then((_) {
        if (!chatHistoryIndex.containsKey(currentChatId)) {
          _loadHistoryIndex();
        }
      });
    }
  }

  // === AI ЛОГИКА ===
  
  Future<void> handleSubmitted(String text) async {
    addMessage(text, true);
    isAiTyping = true;
    notifyListeners();

    await _callAiApi(_getHistoryForApi());
  }

  Future<void> regenerateResponse(int index) async {
    final historyBeforeThisMessage = messages.sublist(index + 1);
    final apiHistory = historyBeforeThisMessage.reversed.map((m) {
      return {
        "role": m.isUser ? "user" : "assistant",
        "content": m.text
      };
    }).toList();

    messages.removeAt(index);
    isAiTyping = true;
    notifyListeners();

    await _callAiApi(apiHistory);
  }

  // Внутренний вызов API с учетом выбранного ассистента
  Future<void> _callAiApi(List<Map<String, String>> history) async {
    // 1. Формируем System Prompt
    String finalSystemPrompt = "Ты полезный ассистент.";
    
    final assistant = currentAssistant;
    if (assistant != null) {
      if (assistant.id == 'analyst') {
        // Для встроенного Аналитика берем загруженный большой файл
        finalSystemPrompt = _builtInAnalystPrompt;
      } else {
        // Для остальных: Промпт + Онтология
        finalSystemPrompt = assistant.systemPrompt;
        if (assistant.ontology.isNotEmpty) {
          finalSystemPrompt += "\n\n##################################\n### БАЗА ЗНАНИЙ / ОНТОЛОГИЯ:\n${assistant.ontology}";
        }
      }
    }

    String? responseText;
    try {
      if (selectedProvider == 'OpenRouter' && openRouterKey.isEmpty) {
         responseText = "Ошибка: Не введен API ключ для OpenRouter.";
      } else if (selectedProvider == 'GigaChat' && gigaChatAuthKey.isEmpty) {
         responseText = "Ошибка: Не введен Auth Key для GigaChat.";
      } else {
        // Подготовка контекста
        String lastMessage = "";
        List<Map<String, String>> historyContext = [];

        if (history.isNotEmpty) {
          lastMessage = history.last['content'] ?? "";
          if (history.length > 1) {
            historyContext = history.sublist(0, history.length - 1);
          }
        }

        if (selectedProvider == 'OpenRouter') {
          final service = OpenRouterService(openRouterKey);
          responseText = await service.sendMessage(
            lastMessage, selectedModel, historyContext, finalSystemPrompt
          );
        } else {
          final service = GigaChatService(gigaChatAuthKey);
          responseText = await service.sendMessage(
            lastMessage, historyContext, finalSystemPrompt
          );
        }
      }
    } catch (e) {
      responseText = "Ошибка: $e";
    }

    addMessage(responseText ?? "Нет ответа", false);
    isAiTyping = false;
    notifyListeners();
  }

  List<Map<String, String>> _getHistoryForApi() {
    return messages.take(10).toList().reversed.map((m) {
      return {
        "role": m.isUser ? "user" : "assistant",
        "content": m.text
      };
    }).toList();
  }

  // === СЕТТЕРЫ НАСТРОЕК ===
  void setProvider(String val) { selectedProvider = val; notifyListeners(); }
  void setModel(String val) { selectedModel = val; notifyListeners(); }
}