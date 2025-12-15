from langchain.agents import create_react_agent, AgentExecutor
from langchain.prompts import PromptTemplate
from langchain.tools import Tool
from app.core.llm import get_llm
from app.knowledge_base.retriever import KnowledgeBaseRetriever
from app.core.prompts import ANALYST_SYSTEM_PROMPT

class ExpertAgent:
    def __init__(self, tools=None):
        self.llm = get_llm()
        self.retriever = KnowledgeBaseRetriever()
        
        # Инструмент поиска (RAG)
        self.kb_tool = Tool(
            name="SearchINCOSE",
            func=self.retriever.search,
            description="Ищи правила (R1-R44) и характеристики (C1-C14). Вводи запрос, например 'правила про время' или 'R37'."
        )
        
        self.tools = [self.kb_tool] + (tools or [])

    def get_executor(self):
        # Используем твой промпт + ReAct структуру
        template = """
        {system_prompt}
        
        У тебя есть доступ к инструментам:
        {tools}
        
        Чтобы использовать инструмент, используй формат:
        Action: название_инструмента
        Action Input: запрос
        Observation: результат
        
        Если информации достаточно, пиши:
        Final Answer: твой ответ в формате Markdown
        
        Запрос пользователя: {input}
        Thought: {agent_scratchpad}
        """
        
        prompt = PromptTemplate.from_template(template).partial(
            system_prompt=ANALYST_SYSTEM_PROMPT
        )

        agent = create_react_agent(self.llm, self.tools, prompt)
        return AgentExecutor(agent=agent, tools=self.tools, verbose=True, handle_parsing_errors=True)