import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter/material.dart';

class PromptService {
  static const String _promptPath = 'assets/knowledge_base/prompt.txt';
  static const String _ontologyTtlPath = 'assets/knowledge_base/incose_full.ttl';
  // Новый файл с простой онтологией
  static const String _simpleOntologyPath = 'assets/knowledge_base/ontology.txt'; 

  String? _cachedSystemPrompt;

  Future<String> getFullSystemPrompt() async {
    if (_cachedSystemPrompt != null) {
      return _cachedSystemPrompt!;
    }

    try {
      // Загружаем все три файла
      final String basePrompt = await rootBundle.loadString(_promptPath);
      final String ontologyTtl = await rootBundle.loadString(_ontologyTtlPath);
      final String simpleOntology = await rootBundle.loadString(_simpleOntologyPath);

      // Склеиваем
      _cachedSystemPrompt = """
$basePrompt

###########################################################
### БАЗОВАЯ ОНТОЛОГИЯ ТРЕБОВАНИЙ
### (Основные аксиомы и связи)
###########################################################
$simpleOntology

###########################################################
### ДЕТАЛЬНАЯ БАЗА ЗНАНИЙ INCOSE (Rules & Characteristics)
### Формат: Turtle (TTL)
###########################################################
$ontologyTtl
""";

      debugPrint("Промпт собран. Общая длина: ${_cachedSystemPrompt!.length}");
      return _cachedSystemPrompt!;
    } catch (e) {
      debugPrint("Ошибка загрузки файлов промпта: $e");
      return "Ты полезный системный аналитик.";
    }
  }
}