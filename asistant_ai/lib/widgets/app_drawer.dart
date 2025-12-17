import 'package:flutter/material.dart';
import '../screens/graph_screen.dart';

class AppDrawer extends StatelessWidget {
  final VoidCallback onOpenSettings;
  final VoidCallback onNewChat;
  final Function(String) onLoadChat;
  final Function(String) onDeleteChat;
  final Map<String, String> chatHistory;

  const AppDrawer({
    super.key,
    required this.onOpenSettings,
    required this.onNewChat,
    required this.onLoadChat,
    required this.onDeleteChat,
    required this.chatHistory,
  });

  void _confirmDelete(BuildContext context, String chatId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Удаление чата"),
        content: Text("Вы уверены, что хотите удалить чат \"$title\"?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDeleteChat(chatId);
            },
            child: const Text("Удалить", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final chatIds = chatHistory.keys.toList().reversed.toList();
    final theme = Theme.of(context);

    return Drawer(
      backgroundColor: theme.scaffoldBackgroundColor,
      // !!! ВАЖНО: Оборачиваем содержимое в SafeArea
      child: SafeArea(
        top: false, // Сверху не отступаем (чтобы цвет шапки был до самого верха)
        bottom: true, // Снизу отступаем (чтобы настройки не перекрывались шторкой)
        child: Column(
          children: [
            UserAccountsDrawerHeader(
              accountName: const Text("AI Assistant"),
              accountEmail: const Text("История переписок"),
              currentAccountPicture: CircleAvatar(
                backgroundColor: theme.colorScheme.surface,
                child: Icon(Icons.smart_toy, size: 40, color: theme.colorScheme.primary),
              ),
              decoration: BoxDecoration(color: theme.colorScheme.primary),
            ),
            ListTile(
              leading: const Icon(Icons.add_comment_outlined, color: Colors.green),
              title: const Text('Новый чат', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              onTap: () {
                Navigator.pop(context);
                onNewChat();
              },
            ),
            ListTile(
              leading: const Icon(Icons.hub_outlined, color: Colors.purple), // Иконка графа
              title: const Text('Граф Знаний', style: TextStyle(fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(context); // Закрываем меню
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const GraphScreen()),
                );
              },
            ),
            const Divider(),
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
                          title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
                          onTap: () {
                            Navigator.pop(context);
                            onLoadChat(id);
                          },
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.grey),
                            onPressed: () => _confirmDelete(context, id, title),
                          ),
                        );
                      },
                    ),
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Настройки'),
              onTap: () {
                Navigator.pop(context);
                onOpenSettings();
              },
            ),
            // Небольшой отступ снизу на всякий случай
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }
}