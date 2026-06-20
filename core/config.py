from pydantic_settings import BaseSettings, SettingsConfigDict

class Settings(BaseSettings):
    app_name: str = "Athena"
    database_url: str = "sqlite:///./data/athena.db"
    secret_key: str = "CHANGE_ME_IN_PRODUCTION"
    
    # Multi-Provider LLM Gateway
    openai_api_key: str | None = None
    anthropic_api_key: str | None = None
    ollama_base_url: str | None = "http://localhost:11434"
    groq_api_key: str | None = None
    
    # Integrations
    searxng_url: str | None = "http://localhost:8080"
    
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

settings = Settings()
