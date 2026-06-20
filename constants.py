import os
from pathlib import Path

# Base directory of the project
BASE_DIR = Path(__file__).resolve().parent

# Data directory for local storage (SQLite, etc.)
DATA_DIR = BASE_DIR / "data"

# Ensure data directory exists
DATA_DIR.mkdir(parents=True, exist_ok=True)
