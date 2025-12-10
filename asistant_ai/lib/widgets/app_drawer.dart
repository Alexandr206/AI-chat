import 'package:flutter/material.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onNewChat;
  final Function(String) onLoadChat; // Функция загрузки чата по ID
  final Map<String, String> chatHistory; // Список чатов (ID -> Название)

  const AppDrawer({
    super.key,
    required this.onOpenSettings,
    required this.onNewChat,
    required this.onLoadChat,
    required this.chatHistory,
  });

  @override
  Widget build(BuildContext context) {
    // Получаем ключи (ID) чатов, инвертируем, чтобы новые были сверху
    final chatIds = chatHistory.keys.toList().reversed.toList();

    return Drawer(
      child: Column(
        children: [
          // Шапка
          UserAccountsDrawerHeader(
            accountName: const Text("AI Assistant"),
            accountEmail: const Text("История переписок"),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Theme.of(context).colorScheme.surface,
              child: Icon(Icons.smart_toy, size: 40, color: Theme.of(context).colorScheme.primary),
            ),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
          ),

          // Кнопка "Новый чат"
          ListTile(
            leading: const Icon(Icons.add_comment_outlined, color: Colors.green),
            title: const Text('Новый чат', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            onTap: () {
              Navigator.pop(context);
              onNewChat();
            },
          ),
          
          const Divider(),
          
          // Заголовок списка
          const Padding(
            padding: EdgeInsets.only(left: 16.0, top: 8.0),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text("История:", style: TextStyle(color: Colors.grey)),
            ),
          ),

          // Список истории (занимает всё свободное место)
          Expanded(
            child: chatIds.isEmpty 
            ? const Center(child: Text("Пока нет истории"))
            : ListView.builder(
                padding: EdgeInsets.zero,
                itemCount: chatIds.length,
                itemBuilder: (context, index) {
                  final id = chatIds[index];
                  final title = chatHistory[id] ?? "Чат";
                  return ListTile(
                    leading: const Icon(Icons.chat_bubble_outline, size: 20),
                    title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    onTap: () {
                      Navigator.pop(context);
                      onLoadChat(id);
                    },
                  );
                },
              ),
          ),

          const Divider(),

          // Кнопка настроек в самом низу
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Настройки'),
            onTap: () {
              Navigator.pop(context);
              onOpenSettings();
            },
          ),
          const SizedBox(height: 10), // Отступ снизу
        ],
      ),
    );
  }
}