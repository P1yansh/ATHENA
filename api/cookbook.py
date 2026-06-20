from fastapi import APIRouter

router = APIRouter(prefix="/cookbook", tags=["cookbook"])

@router.get("/models")
async def list_models():
    # To be implemented: List available local/downloaded models
    return {"models": []}
