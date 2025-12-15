import os
from dotenv import load_dotenv
from neo4j import GraphDatabase
from pyvis.network import Network
import textwrap

# Загрузка настроек
load_dotenv()

URI = os.getenv("MEMGRAPH_URI")
USER = os.getenv("MEMGRAPH_USERNAME")
PASSWORD = os.getenv("MEMGRAPH_PASSWORD")


def get_node_style(label, definition):
    """
    Определяет цвет и форму узла в зависимости от его названия
    и формирует красивый HTML-тултип.
    """
    color = "#97c2fc"  # Стандартный синий
    shape = "dot"
    size = 15

    # Логика раскраски
    if label.startswith("R") and any(char.isdigit() for char in label[:3]):
        # Правила (R1, R2...)
        color = "#ff6b6b"  # Красный
        shape = "hexagon"
        size = 25
    elif label.startswith("C") and any(char.isdigit() for char in label[:3]):
        # Свойства (C1, C3...)
        color = "#51cf66"  # Зеленый
        size = 20
    elif label in ["Требование", "Потребность", "Набор требований"]:
        # Основные артефакты
        color = "#fcc419"  # Желтый
        size = 30
        shape = "star"

    # Форматирование определения для тултипа (HTML)
    # Ограничиваем ширину текста, чтобы тултип не был огромным
    wrapped_def = "<br>".join(textwrap.wrap(definition, width=50)) if definition else "Нет описания"

    title_html = f"""
    <div style='font-family: Arial; font-size: 12px; background-color: white; padding: 5px;'>
        <b>{label}</b><br>
        <hr>
        <i>{wrapped_def}</i>
    </div>
    """

    return color, shape, size, title_html


def visualize_graph_pro():
    # 1. Подключение
    try:
        driver = GraphDatabase.driver(URI, auth=(USER, PASSWORD))
    except Exception as e:
        print(f"Ошибка подключения: {e}")
        return

    # 2. Настройка холста
    # select_menu=True добавляет выпадающий список для поиска узлов
    # filter_menu=True добавляет фильтры
    net = Network(height="800px", width="100%", bgcolor="#222222", font_color="white", select_menu=True)

    # Панель управления физикой (чтобы можно было успокоить граф)
    net.show_buttons(filter_=['physics'])

    print("Скачивание данных из Memgraph (расширенный режим)...")

    with driver.session() as session:
        # Запрашиваем узлы, их определения и связи
        # Увеличили лимит до 1000, чтобы захватить всё
        result = session.run("""
            MATCH (n)-[r]->(m) 
            RETURN n.label as src_lbl, n.definition as src_def,
                   type(r) as rel_type, r.original_name as rel_name,
                   m.label as dst_lbl, m.definition as dst_def
            LIMIT 1000
        """)

        count = 0
        for record in result:
            count += 1
            src = record["src_lbl"]
            src_def = record["src_def"]

            dst = record["dst_lbl"]
            dst_def = record["dst_def"]

            rel_label = record["rel_name"] if record["rel_name"] else record["rel_type"]

            # Стилизация источника
            s_color, s_shape, s_size, s_title = get_node_style(src, src_def)
            net.add_node(src, label=src, title=s_title, color=s_color, shape=s_shape, size=s_size)

            # Стилизация цели
            d_color, d_shape, d_size, d_title = get_node_style(dst, dst_def)
            net.add_node(dst, label=dst, title=d_title, color=d_color, shape=d_shape, size=d_size)

            # Добавление связи (стрелочки)
            net.add_edge(src, dst, title=rel_label, label=rel_label, font={'size': 10, 'align': 'middle'},
                         color='rgba(200,200,200,0.5)')

    driver.close()
    print(f"Обработано связей: {count}")

    # 3. Сохранение и настройка физики
    # BarnesHut - хороший алгоритм для больших графов, чтобы они не разлетались
    net.barnes_hut(gravity=-8000, central_gravity=0.3, spring_length=200)

    output_file = "incose_graph_pro.html"
    net.save_graph(output_file)

    print(f"Готово! Откройте файл {output_file} в браузере.")


if __name__ == "__main__":
    visualize_graph_pro()