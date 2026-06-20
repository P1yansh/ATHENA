from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from core.database import init_db
from core.middleware import AuthMiddleware
from core.config import settings
from api.router import router as api_router

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup: Initialize the database and run raw migrations
    init_db()
    yield
    # Shutdown logic if necessary

app = FastAPI(
    title=settings.app_name,
    description="A local-first, privacy-centric AI operating environment.",
    version="0.1.0",
    lifespan=lifespan
)

# CORS middleware for frontend communication
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"], # In production, lock this down
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Custom Auth middleware
app.add_middleware(AuthMiddleware)

# Include API router
app.include_router(api_router, prefix="/api")

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
