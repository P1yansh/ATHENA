@echo off
echo Installing Athena AI Workspace...

echo 1. Installing Python dependencies...
:: Ensure uv is installed
where uv >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo uv could not be found, installing...
    powershell -ExecutionPolicy ByPass -c "Invoke-RestMethod -Uri https://astral.sh/uv/install.ps1 | Invoke-Expression"
)
uv sync

echo 2. Installing Frontend dependencies...
:: Ensure pnpm is installed
where pnpm >nul 2>nul
if %ERRORLEVEL% neq 0 (
    echo pnpm could not be found, installing...
    npm install -g pnpm
)
pnpm install

echo Athena is ready! To start:
echo Terminal 1: uv run uvicorn main:app --reload
echo Terminal 2: pnpm run dev
pause
