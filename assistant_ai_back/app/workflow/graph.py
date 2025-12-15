from langgraph.graph import StateGraph, END
from typing import TypedDict, Annotated
import operator

# --- ДОБАВЛЕННЫЕ ИМПОРТЫ ---
# Импортируем классы агентов из соответствующих файлов
# Проверь, что файлы base_agent.py и expert.py существуют в папке app/agents/
from app.agents.base_agent import ArchitectAgent
from app.agents.expert import ExpertAgent
# ---------------------------

class AgentState(TypedDict):
    input: str
    chat_history: list
    agent_outcome: str

# Инициализация агентов
# В реальном проекте вместо [] нужно передать список инструментов (tools)
architect_bot = ArchitectAgent(tools=[]).get_executor()
expert_bot = ExpertAgent(tools=[]).get_executor()

def route_question(state):
    # Простая логика: если есть слово "ГОСТ" -> Эксперт, иначе -> Архитектор
    userInput = state["input"].upper()
    if "ГОСТ" in userInput or "REQUIREMENT" in userInput or "ТРЕБОВАНИ" in userInput:
        return "expert"
    return "architect"

def run_architect(state):
    response = architect_bot.invoke({"input": state["input"]})
    return {"agent_outcome": response["output"]}

def run_expert(state):
    response = expert_bot.invoke({"input": state["input"]})
    return {"agent_outcome": response["output"]}

# Создание графа
workflow = StateGraph(AgentState)
workflow.add_node("architect", run_architect)
workflow.add_node("expert", run_expert)

# Условный переход (Conditional Edge)
workflow.set_conditional_entry_point(
    route_question,
    {
        "architect": "architect",
        "expert": "expert"
    }
)

workflow.add_edge("architect", END)
workflow.add_edge("expert", END)

app_graph = workflow.compile()