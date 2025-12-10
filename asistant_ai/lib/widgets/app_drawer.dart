import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  // Callback функция для передачи выбора обратно на экран чата
  final Function(String) onProviderChanged;

  const AppDrawer({super.key, required this.onProviderChanged});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("AI Assistant"),
            accountEmail: const Text("Студент курса AI"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.smart_toy, size: 40, color: Colors.blue.shade800),
            ),
            decoration: BoxDecoration(color: Colors.blue.shade800),
          ),
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("Выберите AI Провайдера:", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_outlined),
            title: const Text('OpenRouter (Mistral/GPT)'),
            onTap: () => onProviderChanged('OpenRouter'),
          ),
          ListTile(
            leading: const Icon(Icons.shield_outlined),
            title: const Text('Sber GigaChat'),
            onTap: () => onProviderChanged('GigaChat'),
          ),
          const Spacer(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('О приложении'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}