import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Нужно для Clipboard
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

    // Определение цветов
    final Color bubbleColor = isUser
        ? colorScheme.primary
        : (isDark ? const Color(0xFF2C2C2C) : Colors.grey[200]!);

    final Color textColor = isUser
        ? colorScheme.onPrimary
        : colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: GestureDetector(
        // --- ЛОГИКА КОПИРОВАНИЯ ---
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: message.text));
          
          // Показываем уведомление (SnackBar)
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Текст скопирован"),
              duration: Duration(seconds: 1),
            ),
          );
        },
        // ---------------------------
        
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          decoration: BoxDecoration(
            color: bubbleColor,
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(18),
              topRight: const Radius.circular(18),
              bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
              bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
            ),
          ),
          constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
          
          // Используем SelectableText для возможности выделения, 
          // либо оставляем Text, если копирование по долгому нажатию достаточно.
          // В данном случае GestureDetector работает поверх контейнера.
          child: Text(
            message.text,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              height: 1.3,
            ),
          ),
        ),
      ),
    );
  }
}