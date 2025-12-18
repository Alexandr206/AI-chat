import 'package:flutter/material.dart';

// Виджеты
import '../widgets/app_drawer.dart';
import '../widgets/chat_settings_drawer.dart';
import '../widgets/chat_input.dart';
import '../widgets/message_bubble.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/chat_app_bar_title.dart';

// Контроллер
import '../controllers/chat_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Инициализируем контроллер
  final ChatController _controller = ChatController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Диалог переименования
  void _showRenameDialog() {
    if (_controller.currentChatId == null) return;
    
    final currentTitle = _controller.chatHistoryIndex[_controller.currentChatId] ?? "Чат";
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
            onPressed: () {
              if (textController.text.trim().isNotEmpty) {
                _controller.renameCurrentChat(textController.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  void _openGlobalSettings() {
    showDialog(
      context: context,
      builder: (context) => const SettingsDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, child) {
        
        String chatTitle = "Новый чат";
        if (_controller.currentChatId != null && 
            _controller.chatHistoryIndex.containsKey(_controller.currentChatId)) {
          chatTitle = _controller.chatHistoryIndex[_controller.currentChatId]!;
        }

        return Scaffold(
          key: _scaffoldKey,
          
          appBar: AppBar(
            centerTitle: true,
            title: ChatAppBarTitle(
              title: chatTitle,
              provider: _controller.selectedProvider,
              model: _controller.selectedModel,
              isChatSelected: _controller.currentChatId != null,
              onRename: _controller.currentChatId == null ? null : _showRenameDialog,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.tune),
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
          ),

          // ЛЕВОЕ МЕНЮ (История)
          drawer: AppDrawer(
            onOpenSettings: _openGlobalSettings,
            onNewChat: _controller.startNewChat,
            onLoadChat: _controller.loadChat,
            onDeleteChat: _controller.deleteChat,
            chatHistory: _controller.chatHistoryIndex,
          ),

          // ПРАВОЕ МЕНЮ (Настройки LLM и Ассистентов)
          endDrawer: ChatSettingsDrawer(
            currentProvider: _controller.selectedProvider,
            currentModel: _controller.selectedModel,
            
            // Новые параметры ассистентов
            assistants: _controller.assistants,
            selectedAssistantId: _controller.selectedAssistantId,
            
            currentOpenRouterKey: _controller.openRouterKey,
            currentGigaChatKey: _controller.gigaChatAuthKey,
            
            onProviderChanged: _controller.setProvider,
            onModelChanged: _controller.setModel,
            
            // Обработка смены ассистента
            onAssistantChanged: _controller.setAssistantId,
            
            // Обработка сохранения/создания
            onSaveAssistant: _controller.saveAssistant,
            
            onKeyChanged: _controller.updateApiKey,
          ),

          body: Column(
            children: [
              Expanded(
                child: _controller.messages.isEmpty
                    ? Center(
                        child: Text(
                          "Начните общение с AI\n(Модель: ${_controller.selectedModel})",
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(8.0),
                        itemCount: _controller.messages.length,
                        itemBuilder: (context, index) {
                          return MessageBubble(
                            message: _controller.messages[index],
                            onDelete: () => _controller.deleteMessage(index),
                            onEdit: (newText) => _controller.editMessage(index, newText),
                            onRegenerate: () => _controller.regenerateResponse(index),
                          );
                        },
                      ),
              ),
              if (_controller.isAiTyping)
                const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: LinearProgressIndicator(),
                ),
              SafeArea(
                top: false,
                child: ChatInput(
                  onSendMessage: _controller.handleSubmitted,
                  isTyping: _controller.isAiTyping,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}