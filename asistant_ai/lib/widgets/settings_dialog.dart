import 'package:flutter/material.dart';
import '../main.dart';
import '../config/open_router_config.dart'; // Импортируем конфиг

class SettingsDialog extends StatefulWidget {
  final String currentProvider;
  final String currentModel; // Текущая модель
  final Function(String) onProviderChanged;
  final Function(String) onModelChanged; // Callback для смены модели

  const SettingsDialog({
    super.key,
    required this.currentProvider,
    required this.currentModel,
    required this.onProviderChanged,
    required this.onModelChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _selectedProvider;
  late String _selectedModel;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.currentProvider;
    // Если текущей модели нет в списке (например, устарела), берем дефолтную
    _selectedModel = OpenRouterConfig.availableModels.containsKey(widget.currentModel)
        ? widget.currentModel
        : OpenRouterConfig.defaultModel;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = MyApp.themeNotifier.value == ThemeMode.dark;

    return AlertDialog(
      title: const Text("Настройки"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
          
          // --- ВЫБОР МОДЕЛИ (Только если выбран OpenRouter) ---
          if (_selectedProvider == 'OpenRouter') ...[
            const SizedBox(height: 16),
            const Text("Модель OpenRouter:", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              isExpanded: true, // Чтобы длинные названия влезали
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
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Закрыть"),
        ),
      ],
    );
  }
}