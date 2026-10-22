---
name: hermes-discipline
description: Enforces test-driven design (pytest via uv), FastAPI clean architecture, Gemma 2 prompt engineering, and DEV Hacktoberfest challenge strategy for the Hermes project.
---

# Hermes Development Protocols & Engineering Disciplines

When working on the **Hermes** project (`projects/hermes`), always adhere to the following 5 active disciplines:

## 1. Test-Driven Verification (`tdd-architect`)
- Run non-interactive tests with `uv run pytest -v` inside `projects/hermes` after every logic modification.
- Every route, connector, and calculation must have regression test coverage.

## 2. FastAPI & Pydantic v2 Best Practices (`backend-architect`)
- Use Pydantic v2 idioms: `model_dump()`, `Field(default_factory=...)`, `datetime.now(timezone.utc)`.
- Keep route handlers thin; delegate all business logic to dedicated agent/service classes.
- Ensure all I/O is asynchronous (`httpx.AsyncClient`).

## 3. Dual-Path LLM Fallbacks (`llm-prompt-engineer`)
- Calls to Gemma 2 via local `llama-server` must always be paired with robust deterministic fallback heuristics.
- The project must run flawlessly in CI, offline, and unit tests without an active LLM server.

## 4. Architectural Boundary Isolation
- Athena core files remain untouched.
- All new code, tests, and configuration belong strictly inside `projects/hermes`.

## 5. Hacktoberfest Week 3 Strategy (`devchallenge-strategist`)
- Align design with the theme: *Slow & Steady (Rewards Laziness)*.
- Maximize partner category eligibility: **Best Use of Gemma**, **Best Use of Render**, **Best Use of ElevenLabs**, and **Best Use of a .tech Domain**.
