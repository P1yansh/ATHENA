from fastapi import APIRouter

router = APIRouter(prefix="/memory", tags=["memory"])

@router.get("/search")
async def search_memory(query: str):
    # To be implemented: Semantic vector search
    return {"results": []}
