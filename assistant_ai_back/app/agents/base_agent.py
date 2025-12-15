from langchain.agents import create_react_agent, AgentExecutor
from langchain.prompts import PromptTemplate
from app.ontology.ontology_loader import OntologyLoader
from app.core.llm import get_llm # Твоя функция получения GigaChat/OpenRouter

class ArchitectAgent:
    def __init__(self, tools):
        self.llm = get_llm()
        self.tools = tools
        self.ontology = OntologyLoader().get_system_prompt_addition()

    def get_executor(self):
        # Базовый промпт ReAct
        template = """
        Ты - Системный Архитектор. Отвечай на вопросы пользователя, используя инструменты.
        
        {ontology_rules}
        
        TOOLS:
        ------
        У тебя есть доступ к следующим инструментам:
        {tools}
        
        Для использования инструмента используй формат:
        Action: название инструмента
        Action Input: ввод для инструмента
        
        Observation: результат работы инструмента
        ... (мысли/действия/наблюдения могут повторяться)
        Final Answer: окончательный ответ
        
        Вопрос: {input}
        Thought: {agent_scratchpad}
        """
        
        prompt = PromptTemplate.from_template(template).partial(
            ontology_rules=self.ontology
        )

        agent = create_react_agent(self.llm, self.tools, prompt)
        return AgentExecutor(agent=agent, tools=self.tools, verbose=True)