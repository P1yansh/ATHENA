from fastapi import APIRouter
from api.chat import router as chat_router
from api.cookbook import router as cookbook_router
from api.memory import router as memory_router
from api.docs import router as docs_router
from api.email import router as email_router
from api.tasks import router as tasks_router
from api.research import router as research_router
from api.system import router as system_router

router = APIRouter()

@router.get("/health")
async def health_check():
    return {"status": "ok", "app": "Athena"}

# Include all sub-routers
router.include_router(chat_router)
router.include_router(cookbook_router)
router.include_router(memory_router)
router.include_router(docs_router)
router.include_router(email_router)
router.include_router(tasks_router)
router.include_router(research_router)
router.include_router(system_router)
