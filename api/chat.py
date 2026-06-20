from fastapi import APIRouter

router = APIRouter(prefix="/chat", tags=["chat"])

@router.post("/completions")
async def chat_completions():
    # To be implemented: Multi-provider gateway
    return {"message": "Chat completions endpoint"}
