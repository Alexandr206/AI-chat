class OpenRouterConfig {
  // Модель по умолчанию
  static const String defaultModel = "mistralai/devstral-2512:free";

  // Список доступных бесплатных моделей
  // key: ID модели (для API), value: Понятное название (для UI)
  static const Map<String, String> availableModels = {
    "mistralai/devstral-2512:free": "Mistral Devstral (Free)",
    "google/gemini-2.0-flash-lite-preview-02-05:free": "Google Gemini 2.0 Flash (Free)",
    "meta-llama/llama-3-8b-instruct:free": "Llama 3 8B (Free)",
    "microsoft/phi-3-mini-128k-instruct:free": "Phi-3 Mini (Free)",
  };
}