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

export PYTHONPATH=.
pytest -v tests/test_unit.py --junitxml=test_result.xml

echo "🎉 Catty tests finished"
