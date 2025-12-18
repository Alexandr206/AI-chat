import 'package:flutter/material.dart';
import '../config/open_router_config.dart';
import '../models/assistant.dart';
import '../widgets/assistant_editor_dialog.dart'; // <-- Диалог редактора

class ChatSettingsDrawer extends StatefulWidget {
  final String currentProvider;
  final String currentModel;
  
  // Вместо currentPromptMode передаем список ассистентов и ID выбранного
  final List<Assistant> assistants; 
  final String selectedAssistantId;

  // Ключи
  final String currentOpenRouterKey;
  final String currentGigaChatKey;

  // Callbacks
  final Function(String) onProviderChanged;
  final Function(String) onModelChanged;
  final Function(String) onAssistantChanged; // <-- Новый callback для ID
  final Function(String provider, String newKey) onKeyChanged;
  final Function(Assistant) onSaveAssistant; // <-- Callback для сохранения

  const ChatSettingsDrawer({
    super.key,
    required this.currentProvider,
    required this.currentModel,
    required this.assistants,
    required this.selectedAssistantId,
    required this.currentOpenRouterKey,
    required this.currentGigaChatKey,
    required this.onProviderChanged,
    required this.onModelChanged,
    required this.onAssistantChanged,
    required this.onKeyChanged,
    required this.onSaveAssistant,
  });

  @override
  State<ChatSettingsDrawer> createState() => _ChatSettingsDrawerState();
}

class _ChatSettingsDrawerState extends State<ChatSettingsDrawer> {
  late TextEditingController _keyController;
  bool _obscureKey = true;

  @override
  void initState() {
    super.initState();
    _updateKeyController();
  }

  @override
  void didUpdateWidget(ChatSettingsDrawer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentProvider != widget.currentProvider ||
        oldWidget.currentOpenRouterKey != widget.currentOpenRouterKey ||
        oldWidget.currentGigaChatKey != widget.currentGigaChatKey) {
      _updateKeyController();
    }
  }

  void _updateKeyController() {
    String key = widget.currentProvider == 'OpenRouter' 
        ? widget.currentOpenRouterKey 
        : widget.currentGigaChatKey;
    _keyController = TextEditingController(text: key);
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  // Открытие редактора (для создания или правки)
  void _openEditor({Assistant? assistant}) {
    showDialog(
      context: context,
      builder: (ctx) => AssistantEditorDialog(
        assistantToEdit: assistant,
        onSave: widget.onSaveAssistant,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Ищем текущего выбранного ассистента для проверки, встроенный ли он
    final currentAssistant = widget.assistants.firstWhere(
      (a) => a.id == widget.selectedAssistantId,
      orElse: () => widget.assistants.first,
    );

    return Drawer(
      width: MediaQuery.of(context).size.width * 0.85,
      child: SafeArea(
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Параметры чата", style: Theme.of(context).textTheme.headlineSmall),
                  const SizedBox(height: 4),
                  const Text("Настройка LLM и Агента"),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // --- ПРОВАЙДЕР ---
                  const Text("AI Провайдер", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: widget.currentProvider,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: const [
                      DropdownMenuItem(value: 'OpenRouter', child: Text('OpenRouter')),
                      DropdownMenuItem(value: 'GigaChat', child: Text('Sber GigaChat')),
                    ],
                    onChanged: (value) {
                      if (value != null) widget.onProviderChanged(value);
                    },
                  ),
                  const SizedBox(height: 20),

                  // --- МОДЕЛЬ (OpenRouter) ---
                  if (widget.currentProvider == 'OpenRouter') ...[
                    const Text("Модель", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: widget.currentModel,
                      decoration: const InputDecoration(border: OutlineInputBorder()),
                      items: OpenRouterConfig.availableModels.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(
                            entry.value, 
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) widget.onModelChanged(value);
                      },
                    ),
                    const SizedBox(height: 20),
                  ],

                  // --- API КЛЮЧ ---
                  Text("API Ключ (${widget.currentProvider})", style: const TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _keyController,
                    obscureText: _obscureKey,
                    decoration: InputDecoration(
                      border: const OutlineInputBorder(),
                      hintText: widget.currentProvider == 'OpenRouter' ? 'sk-or-...' : 'Base64 Key',
                      suffixIcon: IconButton(
                        icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                        onPressed: () => setState(() => _obscureKey = !_obscureKey),
                      ),
                    ),
                    onChanged: (value) {
                      widget.onKeyChanged(widget.currentProvider, value);
                    },
                  ),

                  const Divider(height: 40),

                  // --- ВЫБОР АССИСТЕНТА ---
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Ассистент", style: TextStyle(fontWeight: FontWeight.bold)),
                      // Кнопка редактирования (только если не встроенный)
                      if (!currentAssistant.isBuiltIn)
                        IconButton(
                          icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                          tooltip: "Редактировать текущего",
                          onPressed: () => _openEditor(assistant: currentAssistant),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    isExpanded: true,
                    value: widget.selectedAssistantId,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: widget.assistants.map((assistant) {
                      return DropdownMenuItem<String>(
                        value: assistant.id,
                        child: Text(
                          assistant.name,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            // Жирным выделяем пользовательских
                            fontWeight: assistant.isBuiltIn ? FontWeight.normal : FontWeight.bold
                          ),
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) widget.onAssistantChanged(value);
                    },
                  ),

                  const SizedBox(height: 20),

                  // --- КНОПКА СОЗДАНИЯ ---
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      ),
                      onPressed: () => _openEditor(), // Создаем нового
                      icon: const Icon(Icons.add),
                      label: const Text("Создать ассистента"),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}