import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Для Clipboard
import 'package:flutter_markdown/flutter_markdown.dart'; // <-- Импорт Markdown
// ignore: depend_on_referenced_packages
import 'package:markdown/markdown.dart' as md; // Для настройки таблиц

import '../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    // Определение цветов фона
    final Color bubbleColor = isUser
        ? colorScheme.primary
        : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]!);

    // Определение основного цвета текста
    final Color textColor = isUser
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        // Сохраняем возможность копирования по долгому нажатию
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Текст скопирован"),
              duration: Duration(seconds: 1),
            ),
          );
        },
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
          // Ограничиваем ширину, чтобы таблицы не ломали верстку
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
          
          child: MarkdownBody(
            data: message.text,
            // Включаем поддержку таблиц (GitHub flavor)
            extensionSet: md.ExtensionSet.gitHubFlavored,
            
            // Настройка стилей, чтобы текст был читаемым на любом фоне
            styleSheet: MarkdownStyleSheet(
              // Основной текст
              p: TextStyle(color: textColor, fontSize: 16, height: 1.3),
              
              // Заголовки (#, ##)
              h1: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
              h2: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
              h3: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              
              // Жирный и курсив (**, *)
              strong: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              em: TextStyle(color: textColor, fontStyle: FontStyle.italic),
              
              // Списки (-, *)
              listBullet: TextStyle(color: textColor),
              
              // Код (```) - делаем фон чуть темнее/светлее пузыря
              code: TextStyle(
                color: isUser ? Colors.white : (isDark ? Colors.greenAccent : Colors.blue[800]),
                backgroundColor: isUser ? Colors.black26 : (isDark ? Colors.black45 : Colors.grey[300]),
                fontFamily: 'monospace',
              ),
              codeblockDecoration: BoxDecoration(
                color: isUser ? Colors.black26 : (isDark ? Colors.black45 : Colors.grey[300]),
                borderRadius: BorderRadius.circular(4),
              ),
              
              // Цитаты (>)
              blockquote: TextStyle(color: textColor.withOpacity(0.8)),
              blockquoteDecoration: BoxDecoration(
                border: Border(left: BorderSide(color: textColor.withOpacity(0.5), width: 2)),
              ),
              
              // ТАБЛИЦЫ (|...|)
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