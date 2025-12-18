import 'dart:convert';

class Assistant {
  final String id;
  final String name;
  final String systemPrompt;
  final String ontology;
  final bool isBuiltIn; // true для встроенных (Аналитик, Пустой), false для пользовательских

  Assistant({
    required this.id,
    required this.name,
    required this.systemPrompt,
    required this.ontology,
    this.isBuiltIn = false,
  });

  // Для сохранения в SharedPreferences
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'systemPrompt': systemPrompt,
      'ontology': ontology,
      'isBuiltIn': isBuiltIn,
    };
  }

  factory Assistant.fromJson(Map<String, dynamic> json) {
    return Assistant(
      id: json['id'],
      name: json['name'],
      systemPrompt: json['systemPrompt'] ?? "",
      ontology: json['ontology'] ?? "",
      isBuiltIn: json['isBuiltIn'] ?? false,
    );
  }
}