import 'package:flutter/material.dart';
import '../main.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  @override
  Widget build(BuildContext context) {
    final isDark = MyApp.themeNotifier.value == ThemeMode.dark;

    return AlertDialog(
      title: const Text("Настройки приложения"),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SwitchListTile(
            title: const Text("Темная тема", style: TextStyle(fontWeight: FontWeight.bold)),
            secondary: Icon(isDark ? Icons.dark_mode : Icons.light_mode),
            value: isDark,
            onChanged: (val) {
              setState(() {
                MyApp.themeNotifier.value = val ? ThemeMode.dark : ThemeMode.light;
              });
            },
          ),
          const SizedBox(height: 10),
          const Text(
            "Настройки чата и ключи перенесены в боковое меню справа 👉",
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
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