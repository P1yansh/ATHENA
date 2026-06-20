# ATHENA

Athena is a local-first, privacy-centric AI operating environment built on top of the Odysseus framework. It features advanced orchestration, hierarchical memory (B+Tree), deep research pipelines, and hardware-aware model serving.

## Quick Start (Docker)

The fastest and most reliable way to run the Athena workspace is via Docker. This ensures that all dependencies (Python backend, React frontend, and local databases) run perfectly without environment conflicts.

### Prerequisites
- Docker
- Docker Compose

### Running the Application

1. **Start the workspace**:
   Run the following command in the root of the project to build and start the containers:
   ```bash
   docker-compose up --build
   ```
   *(Add `-d` to run it in detached mode).*

2. **Access the Application**:
   - **Frontend (UI)**: Open your browser and navigate to [http://localhost:5173](http://localhost:5173).
   - **Backend API (Swagger Docs)**: Navigate to [http://localhost:8000/docs](http://localhost:8000/docs).

3. **Stopping the workspace**:
   To stop the containers, press `Ctrl+C` in the terminal, or if running in detached mode:
   ```bash
   docker-compose down
   ```

---

## Local Development (Without Docker)

If you prefer to run the workspace natively on your host machine, you can use the provided autonomous installation scripts:

**For macOS / Linux:**
```bash
chmod +x install.sh
./install.sh
```

**For Windows:**
```cmd
install.bat
```

Once installed, you will need two separate terminal windows:
1. **Backend**: `uv run uvicorn main:app --reload`
2. **Frontend**: `pnpm run dev`

## Configuration

Athena uses a unified `.env` file for API keys and configurations. You can customize the multi-provider LLM gateway by setting variables such as `OPENAI_API_KEY`, `ANTHROPIC_API_KEY`, or pointing `OLLAMA_BASE_URL` to your local instance.