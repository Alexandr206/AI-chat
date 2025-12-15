import os
import sys
# Добавляем путь к app
sys.path.append(os.path.join(os.path.dirname(__file__), '..'))

from dotenv import load_dotenv
from rdflib import Graph as RDFGraph, RDF, RDFS, OWL, URIRef
from neo4j import GraphDatabase
import chromadb
from chromadb.utils import embedding_functions

load_dotenv()

# Настройки
NEO4J_URI = os.getenv("NEO4J_URI", "bolt://localhost:7687")
NEO4J_USER = os.getenv("NEO4J_USERNAME", "neo4j")
NEO4J_PASSWORD = os.getenv("NEO4J_PASSWORD", "password")

# Путь к твоему новому файлу
TTL_FILE_PATH = "app/ontology/incose_full.ttl"

# Namespaces из твоего файла
NS = "http://incose.org/guide/ru#"
PROP_RATIONALE = URIRef(NS + "hasRationale")
PROP_GUIDANCE = URIRef(NS + "hasGuidance")
PROP_EXAMPLE = URIRef(NS + "hasExample")

# Инициализация
driver = GraphDatabase.driver(NEO4J_URI, auth=(NEO4J_USER, NEO4J_PASSWORD))
chroma_client = chromadb.PersistentClient(path="./chroma_db")
ef = embedding_functions.SentenceTransformerEmbeddingFunction(model_name="all-MiniLM-L6-v2")
collection = chroma_client.get_or_create_collection(name="incose_rules", embedding_function=ef)

def clear_db():
    print("Очистка Neo4j...")
    with driver.session() as session:
        session.run("MATCH (n) DETACH DELETE n")
    print("Очистка ChromaDB...")
    try:
        chroma_client.delete_collection("incose_rules")
    except:
        pass
    # Создаем заново
    return chroma_client.get_or_create_collection(name="incose_rules", embedding_function=ef)

def get_literal_value(g, subject, predicate):
    val = g.value(subject, predicate)
    return str(val) if val else ""

def ingest():
    new_collection = clear_db()
    
    g = RDFGraph()
    try:
        g.parse(TTL_FILE_PATH, format="turtle")
        print(f"Онтология загружена: {len(g)} триплетов.")
    except Exception as e:
        print(f"Ошибка чтения TTL: {e}")
        return

    nodes_count = 0
    
    with driver.session() as session:
        processed_subjects = set()

        # 1. Загрузка Узлов (Classes, Individuals)
        for s, p, o in g:
            # Фильтруем только сущности из нашего namespace
            if isinstance(s, URIRef) and NS in str(s):
                if s in processed_subjects: continue
                
                # Извлекаем данные
                label = str(g.value(s, RDFS.label))
                if not label or label == "None": 
                    label = str(s).split("#")[-1]
                
                definition = str(g.value(s, RDFS.comment)) or ""
                rationale = get_literal_value(g, s, PROP_RATIONALE)
                guidance = get_literal_value(g, s, PROP_GUIDANCE)
                example = get_literal_value(g, s, PROP_EXAMPLE)
                
                # Тип узла
                node_type = "Concept"
                uri_str = str(s)
                
                if "R" in label and any(c.isdigit() for c in label[:4]): 
                    node_type = "Rule"
                elif "C" in label and any(c.isdigit() for c in label[:4]): 
                    node_type = "Characteristic"

                # Запись в Neo4j
                query = """
                MERGE (n:Entity {uri: $uri})
                SET n.label = $label, 
                    n.definition = $definition, 
                    n.rationale = $rationale,
                    n.guidance = $guidance,
                    n.example = $example,
                    n.type = $type
                """
                session.run(query, uri=uri_str, label=label, definition=definition,
                            rationale=rationale, guidance=guidance, example=example, type=node_type)
                
                # Запись в ChromaDB (Вектор)
                # Собираем богатый контекст для эмбеддинга
                full_text = f"{label}. Определение: {definition}. Обоснование: {rationale}. Пример: {example}"
                new_collection.add(
                    ids=[uri_str],
                    documents=[full_text],
                    metadatas=[{"uri": uri_str, "label": label, "type": node_type}]
                )
                
                processed_subjects.add(s)
                nodes_count += 1

        # 2. Загрузка Связей (supportsCharacteristic)
        rels_count = 0
        for s, p, o in g:
            if isinstance(s, URIRef) and isinstance(o, URIRef) and NS in str(s) and NS in str(o):
                if "supportsCharacteristic" in str(p):
                    query = """
                    MATCH (src:Entity {uri: $s_uri})
                    MATCH (dst:Entity {uri: $o_uri})
                    MERGE (src)-[:SUPPORTS]->(dst)
                    """
                    session.run(query, s_uri=str(s), o_uri=str(o))
                    rels_count += 1

    print(f"Готово! Загружено {nodes_count} сущностей и {rels_count} связей.")
    driver.close()

if __name__ == "__main__":
    ingest()