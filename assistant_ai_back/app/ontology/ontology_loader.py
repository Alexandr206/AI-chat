import json
import os

class OntologyLoader:
    def __init__(self, file_path: str = "app/ontology/schema.json"):
        self.file_path = file_path
        self.ontology_data = self._load()

    def _load(self):
        if not os.path.exists(self.file_path):
            return {}
        with open(self.file_path, 'r', encoding='utf-8') as f:
            return json.load(f)

    def get_system_prompt_addition(self) -> str:
        """
        Превращает онтологию в инструкцию для LLM.
        """
        # Пример: конвертируем JSON структуру в текст правил
        concepts = ", ".join(self.ontology_data.get("concepts", []))
        rules = "\n".join(self.ontology_data.get("rules", []))
        
        return f"""
        ВАЖНО: Твои рассуждения должны строго соответствовать следующей онтологической модели.
        Используй только эти концепты: {concepts}.
        Следуй этим правилам связей:
        {rules}
        """