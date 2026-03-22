#!/usr/bin/env bash
set -euo pipefail

echo "🧪 Running Catty tests..."

test -f requirements.txt
test -f app/main.py
test -d templates
test -d static

echo "✅ Basic file checks passed"

if [ ! -d .venv ]; then
  python3 -m venv .venv
fi

. .venv/bin/activate

python -m pip install --upgrade pip
pip install -r requirements.txt
pip install pytest pytest-playwright playwright
python -m playwright install chromium

uvicorn app.main:app --host 127.0.0.1 --port 8181 &
APP_PID=$!

cleanup() {
  kill "$APP_PID" || true
}
trap cleanup EXIT

sleep 5

export PYTHONPATH=.
pytest -q

echo "🎉 Catty tests finished"
