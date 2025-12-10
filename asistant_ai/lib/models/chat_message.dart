class ChatMessage {
  final String text;
  final bool isUser; // true если от пользователя, false если от ИИ
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}