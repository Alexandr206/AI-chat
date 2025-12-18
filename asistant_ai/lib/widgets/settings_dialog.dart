import 'package:flutter/material.dart';
import '../main.dart';
import '../config/open_router_config.dart';

class SettingsDialog extends StatefulWidget {
  final String currentProvider;
  final String currentModel;
  final String currentPromptMode;
  
  // Текущие ключи, чтобы отобразить их в полях
  final String currentOpenRouterKey;
  final String currentGigaChatKey;

  final Function(String) onProviderChanged;
  final Function(String) onModelChanged;
  final Function(String) onPromptModeChanged;
  
  // Новый callback для сохранения ключа
  final Function(String provider, String newKey) onKeyChanged;

  const SettingsDialog({
    super.key,
    required this.currentProvider,
    required this.currentModel,
    required this.currentPromptMode,
    required this.currentOpenRouterKey,
    required this.currentGigaChatKey,
    required this.onProviderChanged,
    required this.onModelChanged,
    required this.onPromptModeChanged,
    required this.onKeyChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _selectedProvider;
  late String _selectedModel;
  late String _selectedPromptMode;
  
  // Контроллеры для полей ввода ключей
  late TextEditingController _orKeyController;
  late TextEditingController _gcKeyController;
  
  bool _obscureKey = true; // Скрывать ли ключ звездочками

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.currentProvider;
    _selectedModel = OpenRouterConfig.availableModels.containsKey(widget.currentModel)
        ? widget.currentModel
        : OpenRouterConfig.defaultModel;
    _selectedPromptMode = widget.currentPromptMode;

    // Инициализируем контроллеры текущими значениями
    _orKeyController = TextEditingController(text: widget.currentOpenRouterKey);
    _gcKeyController = TextEditingController(text: widget.currentGigaChatKey);
  }

  @override
  void dispose() {
    _orKeyController.dispose();
    _gcKeyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MyApp.themeNotifier.value == ThemeMode.dark;
    
    // Определяем, какой контроллер показывать сейчас
    final currentKeyController = _selectedProvider == 'OpenRouter' 
        ? _orKeyController 
        : _gcKeyController;

    return AlertDialog(
      title: const Text("Настройки"),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- РЕЖИМ АССИСТЕНТА ---
            const Text("Режим ассистента:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedPromptMode,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
              items: const [
                DropdownMenuItem(value: 'none', child: Text('Нет (Обычный чат)')),
                DropdownMenuItem(value: 'analyst', child: Text('Аналитик (INCOSE)')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPromptMode = value);
                  widget.onPromptModeChanged(value);
                }
              },
            ),
            const SizedBox(height: 16),
      
            // --- ВЫБОР ПРОВАЙДЕРА ---
            const Text("AI Провайдер:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedProvider,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              ),
              items: const [
                DropdownMenuItem(value: 'OpenRouter', child: Text('OpenRouter')),
                DropdownMenuItem(value: 'GigaChat', child: Text('Sber GigaChat')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedProvider = value);
                  widget.onProviderChanged(value);
                }
              },
            ),
            
            // --- ПОЛЕ ВВОДА КЛЮЧА (Динамическое) ---
            const SizedBox(height: 16),
            Text(
              "API Ключ ($_selectedProvider):", 
              style: const TextStyle(fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 8),
            TextField(
              controller: currentKeyController,
              obscureText: _obscureKey,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: _selectedProvider == 'OpenRouter' ? 'sk-or-...' : 'Base64 Auth Key',
                contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                suffixIcon: IconButton(
                  icon: Icon(_obscureKey ? Icons.visibility : Icons.visibility_off),
                  onPressed: () {
                    setState(() {
                      _obscureKey = !_obscureKey;
                    });
                  },
                ),
              ),
              onChanged: (value) {
                // Сохраняем ключ при изменении
                widget.onKeyChanged(_selectedProvider, value);
              },
            ),

            // --- ВЫБОР МОДЕЛИ (Только OpenRouter) ---
            if (_selectedProvider == 'OpenRouter') ...[
              const SizedBox(height: 16),
              const Text("Модель OpenRouter:", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                isExpanded: true,
                value: _selectedModel,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                ),
                items: OpenRouterConfig.availableModels.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.key,
                    child: Text(
                      entry.value, 
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _selectedModel = value);
                    widget.onModelChanged(value);
                  }
                },
              ),
            ],
      
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 10),
            
            // --- ТЕМА ---
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Темная тема", style: TextStyle(fontWeight: FontWeight.bold)),
                Switch(
                  value: isDark,
                  onChanged: (val) {
                    setState(() {
                      MyApp.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
                    });
                  },
                ),
              ],
            )
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Закрыть"),
        ),
      ],
    );
  }
}