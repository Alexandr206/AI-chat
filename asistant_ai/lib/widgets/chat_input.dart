import 'package:flutter/material.dart';

class ChatInput extends StatefulWidget {
  final Function(String) onSendMessage;
  final bool isTyping;

  const ChatInput({
    super.key, 
    required this.onSendMessage, 
    this.isTyping = false
  });

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();

  void _handleSend() {
    if (_controller.text.trim().isEmpty) return;
    widget.onSendMessage(_controller.text.trim());
    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    // Получаем цвета текущей темы
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      // Фон панели ввода (адаптивный)
      decoration: BoxDecoration(
        color: colorScheme.surface, 
        // Легкая тень сверху для разделения, если тема светлая
        boxShadow: theme.brightness == Brightness.light 
          ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 5, offset: const Offset(0, -2))]
          : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end, // Выравнивание по низу (если много текста)
        children: [
          Expanded(
            child: Container(
              // Делаем фон самого поля немного отличным от фона панели
              decoration: BoxDecoration(
                color: theme.brightness == Brightness.light 
                    ? Colors.grey[100] 
                    : const Color(0xFF2C2C2C),
                borderRadius: BorderRadius.circular(24.0),
              ),
              child: TextField(
                controller: _controller,
                enabled: !widget.isTyping,
                textCapitalization: TextCapitalization.sentences,
                minLines: 1,
                maxLines: 5, // Поле растет до 5 строк
                style: TextStyle(color: colorScheme.onSurface), // Цвет текста
                decoration: InputDecoration(
                  hintText: 'Сообщение...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  isDense: true,
                ),
                onSubmitted: (_) => _handleSend(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Кнопка отправки
          GestureDetector(
            onTap: widget.isTyping ? null : _handleSend,
            child: CircleAvatar(
              radius: 22,
              backgroundColor: widget.isTyping 
                  ? colorScheme.surfaceContainerHighest 
                  : colorScheme.primary,
              child: widget.isTyping
                  ? SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2, 
                        color: colorScheme.onSurface
                      )
                    )
                  : const Icon(Icons.arrow_upward, color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}