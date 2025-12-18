import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для Clipboard
import 'package:flutter_markdown/flutter_markdown.dart';
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md;

import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback onDelete;
  final Function(String) onEdit;
  final VoidCallback? onRegenerate; // Может быть null, если сообщение от юзера

  const MessageBubble({
    super.key, 
    required this.message,
    required this.onDelete,
    required this.onEdit,
    this.onRegenerate,
  });

  // Показываем меню действий снизу
  void _showMessageOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) {
        return SafeArea(
          child: Wrap(
            children: [
              // 1. Копировать
              ListTile(
                leading: const Icon(Icons.copy),
                title: const Text('Копировать'),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: message.text));
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Текст скопирован"), duration: Duration(seconds: 1)),
                  );
                },
              ),
              
              // 2. Редактировать (только для сообщений пользователя)
              if (message.isUser)
                ListTile(
                  leading: const Icon(Icons.edit),
                  title: const Text('Редактировать'),
                  onTap: () {
                    Navigator.pop(ctx);
                    _showEditDialog(context);
                  },
                ),

              // 3. Перегенерировать (только для сообщений ИИ)
              if (!message.isUser && onRegenerate != null)
                ListTile(
                  leading: const Icon(Icons.refresh),
                  title: const Text('Перегенерировать ответ'),
                  onTap: () {
                    Navigator.pop(ctx);
                    onRegenerate!();
                  },
                ),

              const Divider(),

              // 4. Удалить
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Удалить', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(ctx);
                  onDelete();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // Диалоговое окно для редактирования текста
  void _showEditDialog(BuildContext context) {
    final controller = TextEditingController(text: message.text);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Редактировать сообщение"),
        content: TextField(
          controller: controller,
          maxLines: null,
          autofocus: true,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Отмена"),
          ),
          TextButton(
            onPressed: () {
              if (controller.text.trim().isNotEmpty) {
                onEdit(controller.text.trim());
              }
              Navigator.pop(ctx);
            },
            child: const Text("Сохранить"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final Color bubbleColor = isUser
        ? colorScheme.primary
        : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]!);

    final Color textColor = isUser
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        // Долгое нажатие вызывает меню
        onLongPress: () => _showMessageOptions(context),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
            ),
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          child: MarkdownBody(
            data: message.text,
            extensionSet: md.ExtensionSet.gitHubFlavored,
            styleSheet: MarkdownStyleSheet(
              p: TextStyle(color: textColor, fontSize: 16, height: 1.3),
              h1: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
              h2: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
              h3: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
              listBullet: TextStyle(color: textColor),
              code: TextStyle(
                color: isUser ? Colors.white : (isDark ? Colors.greenAccent : Colors.blue[800]),
                backgroundColor: isUser ? Colors.black26 : (isDark ? Colors.black45 : Colors.grey[300]),
                fontFamily: 'monospace',
              ),
              codeblockDecoration: BoxDecoration(
                color: isUser ? Colors.black26 : (isDark ? Colors.black45 : Colors.grey[300]),
                borderRadius: BorderRadius.circular(4),
              ),
              blockquote: TextStyle(color: textColor.withOpacity(0.8)),
              blockquoteDecoration: BoxDecoration(
                border: Border(left: BorderSide(color: textColor.withOpacity(0.5), width: 2)),
              ),
              tableBody: TextStyle(color: textColor),
              tableHead: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              tableBorder: TableBorder.all(color: textColor.withOpacity(0.3), width: 1),
            ),
          ),
        ),
      ),
    );
  }
}