import rdflib
from rdflib.namespace import RDF, RDFS, OWL

class OntologyManager:
    def __init__(self, file_path: str = "app/ontology/merged_requirements.ttl"):
        self.g = rdflib.Graph()
        try:
            self.g.parse(file_path, format="turtle")
            print(f"Онтология загружена: {len(self.g)} триплетов.")
        except Exception as e:
            print(f"Ошибка загрузки онтологии: {e}")

    def get_rules_text(self) -> str:
        """
        Извлекает все правила (R1-R44), их описание и примеры для подачи в LLM.
        """
        # SPARQL запрос для поиска всех индивидов типа :Rule
        query = """
        PREFIX : <http://www.semanticweb.org/merged-requirements#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        
        SELECT ?label ?example
        WHERE {
            ?rule a :Rule ;
                  rdfs:label ?label .
            OPTIONAL { ?rule :hasExample ?example }
        }
        ORDER BY ?label
        """
        
        results = self.g.query(query)
        
        formatted_rules = "СПИСОК ПРАВИЛ INCOSE (из Онтологии):\n"
        for row in results:
            label = str(row.label)
            example = str(row.example) if row.example else "Нет примера"
            formatted_rules += f"- {label}. (Пример: {example})\n"
            
        return formatted_rules

    def get_concepts(self) -> list:
        """Получает список всех классов"""
        query = """
        PREFIX owl: <http://www.w3.org/2002/07/owl#>
        PREFIX rdfs: <http://www.w3.org/2000/01/rdf-schema#>
        
        SELECT ?label
        WHERE {
            ?concept a owl:Class ;
                     rdfs:label ?label .
        }
        """
        results = self.g.query(query)
        return [str(row.label) for row in results]

# Пример использования для тестов
if __name__ == "__main__":
    manager = OntologyManager()
    print(manager.get_rules_text())