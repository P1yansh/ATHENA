from fastapi import APIRouter

router = APIRouter(prefix="/email", tags=["email"])

@router.get("/inbox")
async def fetch_inbox():
    # To be implemented: IMAP fetch
    return {"emails": []}
