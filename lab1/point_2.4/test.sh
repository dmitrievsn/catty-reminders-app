#!/usr/bin/env bash
set -euo pipefail

PORT="${1:?usage: test.sh <port> <venv_dir>}"
VENV_DIR="${2:?usage: test.sh <port> <venv_dir>}"

PY="$VENV_DIR/bin/python"
UVICORN="$VENV_DIR/bin/uvicorn"

INPUTS_BAK=".inputs.json.bak"
cp -f inputs.json "$INPUTS_BAK"

cat > inputs.json <<EOF
{ "base_url": "http://127.0.0.1:${PORT}", "users": [ { "username": "heisenberg", "password": "P@ssw0rd" }, { "username": "tester", "password": "foobar123" } ] }
EOF

cleanup() { mv -f "$INPUTS_BAK" inputs.json || true; }
trap cleanup EXIT

"$UVICORN" app.main:app --host 127.0.0.1 --port "$PORT" --log-level warning &
PID=$!
trap 'kill "$PID" 2>/dev/null || true; wait "$PID" 2>/dev/null || true; cleanup' EXIT

for i in $(seq 1 30); do
  if curl -fsS "http://127.0.0.1:${PORT}/docs" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

"$PY" -m pytest -q tests/test_unit.py
"$PY" -m pytest -q tests/test_api.py
