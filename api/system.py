from fastapi import APIRouter

router = APIRouter(prefix="/system", tags=["system"])

@router.get("/config")
async def get_config():
    # To be implemented: UI control, theming
    return {"theme": "dark"}
