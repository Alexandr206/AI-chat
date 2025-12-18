class OpenRouterConfig {
  // Модель по умолчанию
  static const String defaultModel = "mistralai/devstral-2512:free";

  // Список доступных бесплатных моделей
  // key: ID модели (для API), value: Понятное название (для UI)
  static const Map<String, String> availableModels = {
    "xiaomi/mimo-v2-flash:free":"xiaomi/mimo-v2-flash",
    "google/gemini-2.0-flash-exp:free": "Google Gemini 2.0 Flash",
    "google/gemma-3-27b-it:free":"gemma3 27b it",
    "mistralai/devstral-2512:free": "Mistral Devstral",
    "meta-llama/llama-3-8b-instruct:free": "Llama 3 8B",
    "microsoft/phi-3-mini-128k-instruct:free": "Phi-3 Mini",
    "openai/gpt-oss-20b:free":"GPT20b",
    "kwaipilot/kat-coder-pro:free":"kwaipilot kat-coder-pro",
  };
}