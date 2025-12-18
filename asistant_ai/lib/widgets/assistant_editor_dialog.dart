import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/assistant.dart';

class AssistantEditorDialog extends StatefulWidget {
  final Assistant? assistantToEdit; // Если null, то мы создаем нового
  final Function(Assistant) onSave;

  const AssistantEditorDialog({
    super.key, 
    this.assistantToEdit, 
    required this.onSave
  });

  @override
  State<AssistantEditorDialog> createState() => _AssistantEditorDialogState();
}

class _AssistantEditorDialogState extends State<AssistantEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  
  late TextEditingController _nameController;
  late TextEditingController _promptController;
  late TextEditingController _ontologyController;

  @override
  void initState() {
    super.initState();
    // Если редактируем, заполняем поля текущими значениями
    _nameController = TextEditingController(text: widget.assistantToEdit?.name ?? '');
    _promptController = TextEditingController(text: widget.assistantToEdit?.systemPrompt ?? '');
    _ontologyController = TextEditingController(text: widget.assistantToEdit?.ontology ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _promptController.dispose();
    _ontologyController.dispose();
    super.dispose();
  }

  void _save() {
    if (_formKey.currentState!.validate()) {
      // Создаем объект ассистента
      final newAssistant = Assistant(
        // Если редактировали, оставляем старый ID, иначе генерируем новый
        id: widget.assistantToEdit?.id ?? const Uuid().v4(),
        name: _nameController.text.trim(),
        systemPrompt: _promptController.text.trim(),
        ontology: _ontologyController.text.trim(),
        isBuiltIn: false, // Пользовательские ассистенты всегда false
      );
      
      // Вызываем callback сохранения
      widget.onSave(newAssistant);
      
      // Закрываем диалог
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.assistantToEdit != null;

    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        // Ограничиваем высоту диалога, чтобы он не занимал весь экран, 
        // но был достаточно большим для ввода текста
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Заголовок
              Text(
                isEditing ? "Редактировать ассистента" : "Создать ассистента",
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              
              // Поля ввода (внутри Expanded для скролла)
              Expanded(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    // --- НАЗВАНИЕ ---
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Название *",
                        hintText: "Например: Юрист, Переводчик",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return "Введите название";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // --- СИСТЕМНЫЙ ПРОМПТ ---
                    TextFormField(
                      controller: _promptController,
                      maxLines: 5,
                      minLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Системный промпт (Роль)",
                        hintText: "Ты опытный программист на Python. Отвечай только кодом...",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // --- ОНТОЛОГИЯ ---
                    TextFormField(
                      controller: _ontologyController,
                      maxLines: 5,
                      minLines: 3,
                      decoration: const InputDecoration(
                        labelText: "Онтология / База знаний",
                        hintText: "Дополнительные правила, факты или RDF/Turtle данные...",
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Кнопки действий
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Отмена"),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save),
                    label: const Text("Сохранить"),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}