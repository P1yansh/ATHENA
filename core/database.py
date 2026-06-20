import sqlite3
from sqlalchemy import create_engine, Column, Integer, String, JSON, Boolean, DateTime
from sqlalchemy.orm import declarative_base, sessionmaker
from core.config import settings
from datetime import datetime, timezone

engine = create_engine(
    settings.database_url, connect_args={"check_same_thread": False}
)
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# --- Core Models ---

class User(Base):
    __tablename__ = "users"
    id = Column(Integer, primary_key=True, index=True)
    username = Column(String, unique=True, index=True)
    is_admin = Column(Boolean, default=False)

class Task(Base):
    """Represents a scheduled cron task or background job."""
    __tablename__ = "tasks"
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String)
    schedule = Column(String) # Cron syntax
    status = Column(String, default="pending")
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

class MemoryNode(Base):
    """Represents a persistent fact in the semantic vector memory (metadata only, vectors go to ChromaDB)"""
    __tablename__ = "memory_nodes"
    id = Column(String, primary_key=True, index=True)
    content_summary = Column(String)
    created_at = Column(DateTime, default=lambda: datetime.now(timezone.utc))

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

def run_migrations():
    """
    Execute raw SQLite ALTER TABLE commands for migrations.
    Odysseus (Athena) DOES NOT use Alembic.
    """
    db_path = settings.database_url.replace("sqlite:///", "")
    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    
    # Migrations will be added here as the schema evolves
    
    conn.commit()
    conn.close()

def init_db():
    """Initialize the database and run raw SQL migrations."""
    import constants
    # Ensure data dir exists before creating db
    constants.DATA_DIR.mkdir(parents=True, exist_ok=True)
    
    # Create tables
    Base.metadata.create_all(bind=engine)
    
    # Run migrations
    run_migrations()
