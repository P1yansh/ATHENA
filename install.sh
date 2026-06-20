#!/bin/bash
set -e

echo "Installing Athena AI Workspace..."

echo "1. Installing Python dependencies..."
# Ensure uv is installed
if ! command -v uv &> /dev/null; then
    echo "uv could not be found, installing..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
fi
uv sync

echo "2. Installing Frontend dependencies..."
# Ensure pnpm is installed
if ! command -v pnpm &> /dev/null; then
    echo "pnpm could not be found, installing..."
    npm install -g pnpm
fi
pnpm install

echo "Athena is ready! To start:"
echo "Terminal 1: uv run uvicorn main:app --reload"
echo "Terminal 2: pnpm run dev"
