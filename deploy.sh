#!/usr/bin/env bash
set -euo pipefail

APP_DIR="/home/kali/catty-reminders-app"
ENV_FILE="$APP_DIR/.env.deploy"

echo "🚀 Deploying Catty..."

cd "$APP_DIR"

if [ ! -d .venv ]; then
  python3 -m venv .venv
fi

.venv/bin/pip install -r requirements.txt

DEPLOY_REF="$(git rev-parse HEAD)"
printf 'DEPLOY_REF=%s\n' "$DEPLOY_REF" > "$ENV_FILE"

echo "Using DEPLOY_REF=$DEPLOY_REF"

sudo systemctl restart catty-app.service

echo "✅ Catty deployed successfully"
