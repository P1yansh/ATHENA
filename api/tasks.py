from fastapi import APIRouter

router = APIRouter(prefix="/tasks", tags=["tasks"])

@router.post("/schedule")
async def schedule_task():
    # To be implemented: Cron scheduling
    return {"status": "scheduled"}
