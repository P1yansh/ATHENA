# Athena Workspace Agent Rules & Disciplines

## Core Principles
1. **Repository Boundary**: Base Athena configuration is decoupled from individual sub-projects in `projects/*`. Never bleed project dependencies into Athena root.
2. **Project Guidelines**: For Hermes (`projects/hermes`), strictly follow the `hermes-discipline` skill and `projects/hermes/AGENTS.md`.
3. **Verification**: Run non-interactive test suites (`uv run pytest` inside `projects/hermes`, or bash test suites in `tests/`) after modifying code.
4. **Git Safety**: Never commit secrets, credentials (`token.json`, `.env`), or alter git history without explicit user instruction.
