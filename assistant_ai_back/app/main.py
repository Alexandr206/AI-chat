from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from app.workflow.graph import app_graph

app = FastAPI()

class ChatRequest(BaseModel):
    message: str
    history: list = []

@app.post("/chat")
async def chat_endpoint(request: ChatRequest):
    try:
        # Запускаем LangGraph
        result = app_graph.invoke({"input": request.message, "chat_history": request.history})
        return {"response": result["agent_outcome"]}
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)