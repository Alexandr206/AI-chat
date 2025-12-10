import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("AI Assistant"),
            accountEmail: const Text("Модель: GigaChat / OpenRouter"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.smart_toy, size: 40, color: Colors.blue.shade800),
            ),
            decoration: BoxDecoration(color: Colors.blue.shade800),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('История чатов'),
            onTap: () {
              // TODO: Реализовать навигацию к истории
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              // TODO: Реализовать экран настроек (выбор API и т.д.)
              Navigator.pop(context);
            },
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