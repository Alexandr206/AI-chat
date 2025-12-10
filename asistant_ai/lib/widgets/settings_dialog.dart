import 'package:flutter/material.dart';
import '../main.dart'; // Чтобы иметь доступ к MyApp.themeNotifier

class SettingsDialog extends StatefulWidget {
  final String currentProvider;
  final Function(String) onProviderChanged;

  const SettingsDialog({
    super.key,
    required this.currentProvider,
    required this.onProviderChanged,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late String _selectedProvider;

  @override
  void initState() {
    super.initState();
    _selectedProvider = widget.currentProvider;
  }

  @override
  Widget build(BuildContext context) {
    // Получаем текущее состояние темы
    final isDark = MyApp.themeNotifier.value == ThemeMode.dark;

    return AlertDialog(
      title: const Text("Настройки"),
      content: Column(
        mainAxisSize: MainAxisSize.min, // Чтобы окно было компактным
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("AI Провайдер:", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: _selectedProvider,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            ),
            items: const [
              DropdownMenuItem(value: 'OpenRouter', child: Text('OpenRouter (Mistral/GPT)')),
              DropdownMenuItem(value: 'GigaChat', child: Text('Sber GigaChat')),
            ],
            onChanged: (value) {
              if (value != null) {
                setState(() => _selectedProvider = value);
                widget.onProviderChanged(value);
              }
            },
          ),
          const SizedBox(height: 20),
          const Divider(),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Темная тема", style: TextStyle(fontWeight: FontWeight.bold)),
              Switch(
                value: isDark,
                onChanged: (val) {
                  setState(() {
                    // Меняем тему глобально через main.dart
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