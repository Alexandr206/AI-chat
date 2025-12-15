import os
import re
from neo4j import GraphDatabase
import chromadb
from chromadb.utils import embedding_functions

class KnowledgeBaseRetriever:
    def __init__(self):
        # Настройки Neo4j
        self.driver = GraphDatabase.driver(
            os.getenv("NEO4J_URI", "bolt://localhost:7687"),
            auth=(os.getenv("NEO4J_USERNAME"), os.getenv("NEO4J_PASSWORD"))
        )
        
        # Настройки Chroma
        self.chroma = chromadb.PersistentClient(path="./chroma_db")
        ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")
        self.collection = self.chroma.get_collection(name="incose_rules", embedding_function=ef)

    def close(self):
        self.driver.close()

    def _extract_ids(self, text: str):
        """Ищет прямые упоминания ID, например R1, C12"""
        return re.findall(r'\b([RC][0-9]+)\b', text.upper())

    def _query_vector(self, query: str, n=3):
        """Поиск по смыслу"""
        try:
            results = self.collection.query(query_texts=[query], n_results=n)
            entities = []
            if results['ids']:
                for i, uri in enumerate(results['ids'][0]):
                    label = results['metadatas'][0][i]['label']
                    entities.append({"uri": uri, "label": label})
            return entities
        except:
            return []

    def _query_graph_context(self, entities):
        """Сбор полного контекста из графа (Определения, Связи, Примеры)"""
        if not entities:
            return ""
            
        context_parts = []
        unique_uris = list(set([e['uri'] for e in entities]))

        with self.driver.session() as session:
            for uri in unique_uris:
                # Получаем данные узла
                node_q = """
                MATCH (n:Entity {uri: $uri})
                RETURN n.label as label, n.definition as definition,
                       n.rationale as rationale, n.guidance as guidance,
                       n.example as example
                """
                node = session.run(node_q, uri=uri).single()
                
                if node:
                    block = f"--- ТЕРМИН: {node['label']} ---\n"
                    if node['definition']: block += f"Определение: {node['definition']}\n"
                    if node['rationale']:  block += f"Обоснование: {node['rationale']}\n"
                    if node['guidance']:   block += f"Указания: {node['guidance']}\n"
                    if node['example']:    block += f"Пример: {node['example']}\n"
                    
                    # Получаем соседей (связи)
                    rel_q = """
                    MATCH (n:Entity {uri: $uri})-[r]-(m)
                    RETURN type(r) as type, r.original_name as name, m.label as other
                    LIMIT 10
                    """
                    rels = session.run(rel_q, uri=uri)
                    links = []
                    for r in rels:
                        name = r["name"] if r["name"] else r["type"]
                        links.append(f" -> [{name}] -> {r['other']}")
                    
                    if links:
                        block += "Связи:\n" + "\n".join(links)
                    
                    context_parts.append(block)
                    
        return "\n\n".join(context_parts)

    def search(self, query: str) -> str:
        """Главный метод поиска"""
        # 1. Прямой поиск ID (если юзер написал R1)
        # (в данном примере упростим и полагаемся на вектор, 
        # но можно добавить логику extract_ids для точного поиска)
        
        # 2. Векторный поиск
        found = self._query_vector(query)
        
        # 3. Обогащение графом
        context = self._query_graph_context(found)
        
        if not context:
            return "В Базе Знаний нет прямой информации по этому запросу."
            
        return context