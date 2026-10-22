#!/usr/bin/env bash
set -euo pipefail

ATHENA_BIN="$(cd "$(dirname "${BASH_SOURCE[0]}")/../bin" && pwd)/athena-ctl"
TEST_DIR="$(mktemp -d -t athena-test-XXXXXX)"
trap 'rm -rf "$TEST_DIR"' EXIT

echo "🧪 Running Athena-ctl Feature & Regression Tests in $TEST_DIR"
cd "$TEST_DIR"

# 1. Test listing helpers
echo "[Test 1/6] Testing catalog query helpers..."
SKILLS_OUT="$("$ATHENA_BIN" _list-skills)"
grep -q "python-testing" <<< "$SKILLS_OUT" || { echo "FAIL: python-testing not found in _list-skills"; exit 1; }

AGENTS_OUT="$("$ATHENA_BIN" _list-agents)"
grep -q "code-reviewer" <<< "$AGENTS_OUT" || { echo "FAIL: code-reviewer not found in _list-agents"; exit 1; }
echo "  -> PASS: Query helpers output clean names."

# 2. Test completion syntax validity
echo "[Test 2/6] Validating Zsh and Bash completion scripts syntax..."
"$ATHENA_BIN" completion zsh | zsh -n || { echo "FAIL: Invalid Zsh completion syntax"; exit 1; }
"$ATHENA_BIN" completion bash | bash -n || { echo "FAIL: Invalid Bash completion syntax"; exit 1; }
echo "  -> PASS: Completion scripts compile cleanly."

# 3. Test space-separated multi-skill linking
echo "[Test 3/6] Testing space-separated multi-skill linking..."
"$ATHENA_BIN" add-skill python-testing tdd-workflow
[[ -L ".opencode/skills/python-testing" ]] || { echo "FAIL: python-testing symlink not created"; exit 1; }
[[ -L ".opencode/skills/tdd-workflow" ]] || { echo "FAIL: tdd-workflow symlink not created"; exit 1; }
echo "  -> PASS: Space-separated skills linked."

# 4. Test comma-separated multi-skill linking
echo "[Test 4/6] Testing comma-separated multi-skill linking..."
"$ATHENA_BIN" add-skill docker-patterns,git-workflow
[[ -L ".opencode/skills/docker-patterns" ]] || { echo "FAIL: docker-patterns symlink not created"; exit 1; }
[[ -L ".opencode/skills/git-workflow" ]] || { echo "FAIL: git-workflow symlink not created"; exit 1; }
echo "  -> PASS: Comma-separated skills linked."

# 5. Test multi-agent linking (mixed comma and space)
echo "[Test 5/6] Testing multi-agent linking..."
"$ATHENA_BIN" add-agent code-reviewer,architect planner
[[ -L ".opencode/agents/code-reviewer.md" ]] || { echo "FAIL: code-reviewer.md symlink not created"; exit 1; }
[[ -L ".opencode/agents/architect.md" ]] || { echo "FAIL: architect.md symlink not created"; exit 1; }
[[ -L ".opencode/agents/planner.md" ]] || { echo "FAIL: planner.md symlink not created"; exit 1; }
echo "  -> PASS: Multi-agent linking succeeded."

# 6. Test resilience to non-existent skills
echo "[Test 6/6] Testing warning on invalid skill without failing valid skills..."
ERR_OUTPUT="$("$ATHENA_BIN" add-skill fake-skill-xyz python-patterns 2>&1)"
[[ -L ".opencode/skills/python-patterns" ]] || { echo "FAIL: python-patterns should have linked despite fake skill"; exit 1; }
grep -qi "warning: skill 'fake-skill-xyz' not found" <<< "$ERR_OUTPUT" || { echo "FAIL: Expected warning for fake-skill-xyz"; exit 1; }
echo "  -> PASS: Resilient to invalid inputs."

echo "✅ All 6 Athena-ctl test suites passed successfully!"
