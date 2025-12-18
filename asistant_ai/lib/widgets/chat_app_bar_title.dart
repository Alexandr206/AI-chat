import 'package:flutter/material.dart';
import '../config/open_router_config.dart';

class ChatAppBarTitle extends StatelessWidget {
  final String title;
  final String provider;
  final String model;
  final bool isChatSelected;
  final VoidCallback? onRename;

  const ChatAppBarTitle({
    super.key,
    required this.title,
    required this.provider,
    required this.model,
    required this.isChatSelected,
    this.onRename,
  });

  @override
  Widget build(BuildContext context) {
    // Получаем короткое имя модели для отображения
    String modelDisplay = model;
    if (provider == 'OpenRouter') {
      final fullModelName = OpenRouterConfig.availableModels[model] ?? 'Model';
      modelDisplay = fullModelName.split(' ').first; // Берем первое слово (напр. "Google")
    }

    return InkWell(
      onTap: onRename,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
        child: Column(
          children: [
            // Верхняя строка: Название чата + иконка
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                if (isChatSelected) const SizedBox(width: 4),
                if (isChatSelected)
                  Icon(Icons.edit, size: 14, color: Colors.grey.withOpacity(0.7))
              ],
            ),
            // Нижняя строка: Провайдер (Модель)
            Text(
              "$provider ($modelDisplay)",
              style: TextStyle(
                fontSize: 11,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}