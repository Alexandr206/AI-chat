import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onOpenSettings; // Функция открытия настроек

  const AppDrawer({super.key, required this.onOpenSettings});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            accountName: const Text("AI Assistant"),
            accountEmail: const Text("Student Project"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(Icons.smart_toy, size: 40, color: Theme.of(context).colorScheme.primary),
            ),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
          ),
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('История чатов'),
            onTap: () {
              Navigator.pop(context);
              // Логика истории
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              Navigator.pop(context); // Закрываем меню
              onOpenSettings(); // Открываем диалог настроек
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